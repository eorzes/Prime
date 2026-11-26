--- Designed at CERN - EP-ESE-BE - HPTD
--- APB3 master controller
--- Inspired by drp_to_apb3_bridge.vhd (v2.0) APB3 timing, without DRP remapping.

-- Simple single-transfer APB3 master.
-- The user-side master starts a transaction with start_i.
--   write_i = '1' -> write addr_i / wdata_i
--   write_i = '0' -> read  addr_i, result on rdata_o when done_o pulses
--
-- APB3 protocol (same as the source bridge):
--   IDLE    : bus idle, PSEL=0, PENABLE=0
--   SETUP   : PSEL=1, PENABLE=0, address / write / wdata driven
--   ACCESS  : PENABLE=1, wait for PREADY (or timeout)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity apb3_controller is
  generic (
    ADDR_WIDTH      : integer := 16;   -- APB3 address width (matches attached bridge)
    DATA_WIDTH      : integer := 32;   -- APB3 data width
    TIMEOUT_CYCLES  : integer := 1000  -- ACCESS-phase timeout in clk cycles (0 = disable)
  );
  port (
    -- common clock and reset (APB3 clock domain)
    clk             : in  std_logic;
    rst             : in  std_logic;   -- synchronous reset, active high

    -- user / master control
    addr_i          : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    write_i         : in  std_logic;   -- '1' write, '0' read
    start_i         : in  std_logic;   -- pulse: start transfer at addr_i
    wdata_i         : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- user / master status
    rdata_o         : out std_logic_vector(DATA_WIDTH-1 downto 0);
    busy_o          : out std_logic;   -- '1' while a transfer is in progress
    done_o          : out std_logic;   -- 1-cycle pulse when transfer completes (success or error)
    slverr_o        : out std_logic;   -- sticky until rst: slave error seen
    timeout_error_o : out std_logic;   -- sticky until rst: ACCESS timeout

    -- APB3 master interface (same ports as drp_to_apb3_bridge)
    apb3paddr       : out std_logic_vector(15 downto 0);
    apb3psel        : out std_logic;
    apb3penable     : out std_logic;
    apb3pwrite      : out std_logic;
    apb3pwdata      : out std_logic_vector(31 downto 0);
    apb3prdata      : in  std_logic_vector(31 downto 0);
    apb3pready      : in  std_logic;
    apb3pslverr     : in  std_logic
  );
end entity apb3_controller;

architecture behavioral of apb3_controller is

  type state_type is (IDLE, SETUP, S_ACCESS);
  signal state : state_type := IDLE;

  -- latched command
  signal addr_reg   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal write_reg  : std_logic := '0';
  signal wdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal rdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  -- errors
  signal slverr_reg   : std_logic := '0';
  signal timeout_reg  : std_logic := '0';
  signal timeout_cnt  : integer range 0 to TIMEOUT_CYCLES := 0;

  -- registered APB3 outputs (avoid combo glitches on the bus)
  signal paddr_r    : std_logic_vector(15 downto 0) := (others => '0');
  signal psel_r     : std_logic := '0';
  signal penable_r  : std_logic := '0';
  signal pwrite_r   : std_logic := '0';
  signal pwdata_r   : std_logic_vector(31 downto 0) := (others => '0');

  signal done_r     : std_logic := '0';

  -- pad / trim address and data to the fixed APB3 widths used by the attached GT interface
  function to_paddr(a : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(15 downto 0) := (others => '0');
  begin
    if a'length >= 16 then
      r := a(15 downto 0);
    else
      r(a'length-1 downto 0) := a;
    end if;
    return r;
  end function;

  function to_pdata(d : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0) := (others => '0');
  begin
    if d'length >= 32 then
      r := d(31 downto 0);
    else
      r(d'length-1 downto 0) := d;
    end if;
    return r;
  end function;

begin

  apb3paddr   <= paddr_r;
  apb3psel    <= psel_r;
  apb3penable <= penable_r;
  apb3pwrite  <= pwrite_r;
  apb3pwdata  <= pwdata_r;

  rdata_o         <= rdata_reg;
  busy_o          <= '0' when state = IDLE else '1';
  done_o          <= done_r;
  slverr_o        <= slverr_reg;
  timeout_error_o <= timeout_reg;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state        <= IDLE;
        addr_reg     <= (others => '0');
        write_reg    <= '0';
        wdata_reg    <= (others => '0');
        rdata_reg    <= (others => '0');
        slverr_reg   <= '0';
        timeout_reg  <= '0';
        timeout_cnt  <= 0;
        paddr_r      <= (others => '0');
        psel_r       <= '0';
        penable_r    <= '0';
        pwrite_r     <= '0';
        pwdata_r     <= (others => '0');
        done_r       <= '0';
      else
        done_r <= '0'; -- default: 1-cycle pulse on completion

        case state is

          -- wait for start_i. start_i is ignored while busy.
          when IDLE =>
            psel_r      <= '0';
            penable_r   <= '0';
            pwrite_r    <= '0';
            timeout_cnt <= 0;

            if start_i = '1' then
              addr_reg  <= addr_i;
              write_reg <= write_i;
              wdata_reg <= wdata_i;
              state     <= SETUP;
            end if;

          -- SETUP phase: PSEL=1, PENABLE=0, address and control valid
          when SETUP =>
            psel_r    <= '1';
            penable_r <= '0';
            pwrite_r  <= write_reg;
            paddr_r   <= to_paddr(addr_reg);
            if write_reg = '1' then
              pwdata_r <= to_pdata(wdata_reg);
            end if;
            timeout_cnt <= 0;
            state       <= S_ACCESS;

          -- ACCESS phase: PENABLE=1, wait for PREADY or timeout
          when S_ACCESS =>
            psel_r    <= '1';
            penable_r <= '1';
            pwrite_r  <= write_reg;
            paddr_r   <= to_paddr(addr_reg);

            if apb3pready = '1' or (TIMEOUT_CYCLES > 0 and timeout_cnt = TIMEOUT_CYCLES-1) then
              psel_r    <= '0';
              penable_r <= '0';
              pwrite_r  <= '0';

              if write_reg = '0' then
                if DATA_WIDTH >= 32 then
                  rdata_reg <= apb3prdata;
                else
                  rdata_reg <= apb3prdata(DATA_WIDTH-1 downto 0);
                end if;
              end if;

              -- sticky error flags (cleared only by rst), same idea as the source bridge
              if apb3pslverr = '1' then
                slverr_reg <= '1';
              end if;
              if TIMEOUT_CYCLES > 0 and timeout_cnt = TIMEOUT_CYCLES-1 and apb3pready = '0' then
                timeout_reg <= '1';
              end if;

              done_r <= '1';
              state  <= IDLE;
              timeout_cnt <= 0;
            elsif TIMEOUT_CYCLES > 0 and timeout_cnt < TIMEOUT_CYCLES-1 then
              timeout_cnt <= timeout_cnt + 1;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture behavioral;
