--- Designed at CERN - EP-ESE-BE - HPTD
--- By Edoardo Orzes
--- v1.0 - 30/09/2025
--- v2.0 - 06/06/2026

-- QUAD APB3 interface bridge for DRP transactions.
-- Tested for tx_phase_aligner's DRP controller.

-- It interfaces up to 4 DRP controllers to the QUAD APB3 interface.
-- it serves one channel at a time and stores write requests from other channels.
-- it preserves the 3-writes structure of the tx_phase_aligner (to toggle the strobe bit in the TXPI register).

-- Note: DRP writes from tx_phase_aligner start with drpen(i) toggling at 1 for 1 cycle, 
--       if the machine is not listening and saving or processing the request, it gets lost and no alignment is performed.
--       the bridge stores up to 1 request per channel, the DRP controller is expected to wait for the acknowledgement. 

-- type integer_array is array (natural range <>) of integer; 
-- type array_nb is array (natural range <>) of std_logic_vector;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.arrays_pkg.all;

entity drp_to_apb3_bridge is
  generic (
    DRP_ADDR_WIDTH    : integer := 9;      -- width of DRP address
    DRP_DATA_WIDTH    : integer := 16;     -- width of DRP data
    CHANNEL_BASE      : unsigned(15 downto 0) := x"0C00";  -- base address offset for CH0 register block
    CHANNEL_EN        : integer_array(0 to 3) := (0, -1, -1, -1); -- (CH0, CH1, CH2, CH3), enabled when > -1
    TXPI_ADDR_DRP     : std_logic_vector(8 downto 0) := "010011010"; -- ('0' & x"9A") TxPI PPM regster for APB3 GTs
    TXPI_ADDR_APB3    : std_logic_vector(15 downto 0) := x"00A7"; -- TxPI PPM regster for DRP GTs
    CH_REG_ADDR_DELTA : integer := 16#0100#; -- registers distance between adjacent channels, in base 16
    WAIT_3_WRITES     : boolean := true -- waits for 3 writes from the same channel before serving other channels
  );
  port (
    -- common clock and reset (assume DRPCLK = APB3CLK)
    clk            : in  std_logic;                -- gt system clock (freerunning)
    rst            : in  std_logic;                -- general synchronous reset
    rst_ch         : in  std_logic_vector(0 to 3); -- individual synchronous reset per channel

    -- DRP slave interface (from tx_phase_aligner controller, per channel)
    drpen          : in  std_logic_vector(0 to 3);
    drpwe          : in  std_logic_vector(0 to 3);
    drpaddr        : in  array_nb(0 to 3)(DRP_ADDR_WIDTH-1 downto 0);
    drpdi          : in  array_nb(0 to 3)(DRP_DATA_WIDTH-1 downto 0);
    drpdo          : out array_nb(0 to 3)(DRP_DATA_WIDTH-1 downto 0);
    drprdy         : out std_logic_vector(0 to 3);

    -- APB3 master interface (to Versal transceiver, shared)
    apb3paddr      : out std_logic_vector(15 downto 0);
    apb3psel       : out std_logic;
    apb3penable    : out std_logic;
    apb3pwrite     : out std_logic;
    apb3pwdata     : out std_logic_vector(31 downto 0);
    apb3prdata     : in  std_logic_vector(31 downto 0);
    apb3pready     : in  std_logic;
    apb3pslverr    : in  std_logic;
    
    -- the value of the register, used as a base to be partially overridden for the writings
	-- for tx_phase_aligner in DRP, tie to 32'h0200000A 
	-- need to apply the property: set_property CH0_TX_PIPPM_CFG 32'h0200000A [get_cells -hier -filter {NAME =~ *quad_inst}]
    apb3_start_val : in  array_nb(0 to 3)(31 downto 0);
    
    -- error flags
    apb3pslverr_o  : out  std_logic; -- sticky up to reset, if '1', alignemnt is not performed
    timeout_error  : out  std_logic  -- sticky up to reset, if '1', alignemnt is not performed
  );
end entity drp_to_apb3_bridge;

architecture behavioral of drp_to_apb3_bridge is

  constant TIMEOUT_CYCLES  : integer := 1000; -- APB3 transfer timeout in cycles (0 to disable)
  constant CHANNEL_TIMEOUT : integer := 500;  -- when WAIT_3_WRITES, timeout for 3-writes sequence before selecting a new channel to be served

  type state_type is (IDLE, SETUP, S_ACCESS); 
  signal state : state_type := IDLE;
  
  -- channel selection signals
  signal ch_run     : integer range -1 to 3 := -1;               -- channel index of the channel being served, -1 is no channel selected
  signal ch_moves   : integer_array(0 to 3) := (others => 0);    -- count of consecutive transfers for 3-writes sequence
  signal ch_timeout : integer range 0 to CHANNEL_TIMEOUT-1 := 0; -- timeout for 3-writes sequence to serve the next channel
  
  -- registers of DRP configuration (in IDLE)
  signal drpaddr_reg   : std_logic_vector(15 downto 0); -- extended to APB3 size
  signal drpwe_reg     : std_logic;    
  signal drpdi_reg     : std_logic_vector(DRP_DATA_WIDTH-1 downto 0);  
  signal apb3rdata_reg : std_logic_vector(31 downto 0); -- used for init
  
  -- registers of paused DRP transfers (per channel)
  signal drpaddr_temp : array_nb(0 to 3)(DRP_ADDR_WIDTH-1 downto 0);
  signal drpen_temp   : std_logic_vector(0 to 3);
  signal drpdi_temp   : array_nb(0 to 3)(DRP_DATA_WIDTH-1 downto 0);
  signal drpwe_temp   : std_logic_vector(0 to 3);
  
  -- error flags
  signal apb3error : std_logic := '0'; 
  signal timeout_counter : integer range 0 to TIMEOUT_CYCLES-1 := 0;  
  
  --debug
  attribute ENUM_ENCODING: string;
  attribute ENUM_ENCODING of state_type: type is "00 01 10";
  signal intState  : integer range 0 to 2 := 0;
  signal st : std_logic_vector(1 downto 0) := "00";
  signal ch_run_v : std_logic_vector(2 downto 0) := "000";
  signal ch_mov_v : std_logic_vector(2 downto 0) := "000";
  signal ch_tmo_v : std_logic_vector(9 downto 0) := (others => '0');  
  
begin

  process(clk) begin
    if rising_edge(clk) then
        if rst = '1' then
          state           <= IDLE;
          ch_run          <= -1;
          ch_timeout      <= 0;
          timeout_counter <= 0;
          timeout_error   <= '0';
          apb3error       <= '0';
          
          apb3psel        <= '0';
          apb3penable     <= '0';
          apb3pwrite      <= '0';
          apb3paddr       <= (others => '0');
          apb3pwdata      <= (others => '0');
          apb3rdata_reg   <= (others => '0');
          drpwe_reg       <= '0';
          drpdi_reg       <= (others => '0');
          drpaddr_reg     <= (others => '0');
          
          ch_moves        <= (others => 0); 
          drprdy          <= (others => '0');
          drpaddr_temp    <= (others => (others => '0'));
          drpen_temp      <= (others => '0');
          drpdi_temp      <= (others => (others => '0'));
          drpwe_temp      <= (others => '0');
        elsif or_reduce(rst_ch) = '1' then
            for i in rst_ch'range loop
                if rst_ch(i) = '1' then
                    ch_moves(i)     <=  0 ; 
                    drprdy(i)       <= '0';
                    drpaddr_temp(i) <= (others => '0');
                    drpen_temp(i)   <= '0';
                    drpdi_temp(i)   <= (others => '0');
                    drpwe_temp(i)   <= '0';
                    if ch_run = i then
                        ch_run <= -1;
                        state <= IDLE;
                        ch_timeout <= 0;
                        timeout_counter <= 0;
                        apb3psel     <= '0';
                        apb3penable  <= '0';
                        apb3pwrite   <= '0';
                        apb3paddr       <= (others => '0');
                        apb3pwdata      <= (others => '0');
                        apb3rdata_reg   <= (others => '0');
                        drpwe_reg       <= '0';
                        drpdi_reg       <= (others => '0');
                        drpaddr_reg     <= (others => '0');
                    end if;
                end if;
            end loop;
        else
    
            -- selection of the channel to serve, checks if channel i is used (CHANNEL_EN), 
            -- selected if there is/was a DRP request (drpen/drpen_temp toggling).
            for i in 0 to 3 loop
                if ch_run < 0 and CHANNEL_EN(i) > -1 and (drpen(i) = '1' or drpen_temp(i) = '1') then
                    ch_run <= i;
                    exit;
                end if;
            end loop;
    
            for i in 0 to 3 loop
                drprdy(i) <= '0'; -- flag of completed DRP transfer
            end loop;
            
            -- saves DRP requests (per channel) when the interface is busy with other channels or at init
            for i in 0 to 3 loop
                if CHANNEL_EN(i) > -1 and drpen(i) = '1' and ch_run /= i then
                    drpen_temp(i)   <= '1'; 
                    drpwe_temp(i)   <= drpwe(i);
                    drpaddr_temp(i) <= drpaddr(i);
                    drpdi_temp(i)   <= drpdi(i);
                end if;
            end loop;

            if ch_run > -1 then
                case state is
                
                  -- in IDLE state waits for DRP requests and prepares address and data
                  when IDLE =>
                    timeout_counter <= 0;
                    apb3psel    <= '0';     
                    apb3penable <= '0';
                    -- DRP transfer is requested pulsing drpen, stored in drpen_temp if busy
                    if drpen(ch_run) = '1' or drpen_temp(ch_run) = '1' then
                        drpwe_reg <= drpwe(ch_run) when drpen_temp(ch_run) = '0' else drpwe_temp(ch_run);
                        -- remapping TXPI register address from DRP GTs to APB3 GTs
                        if drpaddr(ch_run) = TXPI_ADDR_DRP or (drpaddr_temp(ch_run) = TXPI_ADDR_DRP and drpen_temp(ch_run)= '1') then 
                            drpaddr_reg <= std_logic_vector(CHANNEL_BASE + unsigned(TXPI_ADDR_APB3      ) + to_unsigned(ch_run * CH_REG_ADDR_DELTA, 16));
                        -- add other DRP to APB3 address mappings here if needed
                        -- if the address is not recognised, treats the DRP address as APB3 address 
                        elsif drpen_temp(ch_run) = '1' then
                            drpaddr_reg <= std_logic_vector(CHANNEL_BASE + resize(unsigned(drpaddr_temp(ch_run)), 16) + to_unsigned(ch_run * CH_REG_ADDR_DELTA, 16));
                        else
                            drpaddr_reg <= std_logic_vector(CHANNEL_BASE + resize(unsigned(drpaddr(     ch_run)), 16) + to_unsigned(ch_run * CH_REG_ADDR_DELTA, 16));
                        end if;
                        drpdi_reg            <= drpdi(ch_run) when drpen_temp(ch_run) = '0' else drpdi_temp(ch_run);
                        drpen_temp(ch_run)   <= '0';
                        drpwe_temp(ch_run)   <= '0';
                        drpaddr_temp(ch_run) <= (others => '0');
                        drpdi_temp(ch_run)   <= (others => '0');
                        state                <= SETUP;
                    elsif not(WAIT_3_WRITES) or ch_moves(ch_run) > 2 or ch_timeout = CHANNEL_TIMEOUT-1 then 
                        -- CHANNEL_TIMEOUT is the max time spent on IDLE waiting for a transfer to start (a transfer waiting is about 300 cycles), before moving to another channel
                        ch_moves(ch_run) <= 0;
                        ch_run <= -1; -- no channel selected (ch_run = -1) after a 3-writes sequence is complete, allowing for a new channel to be served 
                        ch_timeout <= 0;
                    else
                        ch_timeout <= ch_timeout + 1;
                    end if;
    
                  -- SETUP phase prepares the APB3 transfer (Sel, Enable, Write, Address and Data signals)
                  when SETUP =>
                    apb3psel    <= '1';
                    apb3penable <= '0';
                    apb3pwrite  <= drpwe_reg;
                    apb3paddr   <= drpaddr_reg;
                    if drpwe_reg = '1' then
                        if drpaddr_reg = std_logic_vector(CHANNEL_BASE + unsigned(TXPI_ADDR_APB3) + to_unsigned(ch_run * CH_REG_ADDR_DELTA, 16)) then
                            apb3pwdata              <= apb3_start_val(ch_run); -- the read and modified config (from init) it the base for writing
                            apb3pwdata(11 downto 4) <= drpdi_reg(7 downto 0);   -- tx_phase_aligner sends 8 bits by DRP, remapped to the APB3 GT register
                        else 
                            -- handle here other eventual registers
                            apb3pwdata                            <= apb3_start_val(ch_run);
                            apb3pwdata(DRP_DATA_WIDTH-1 downto 0) <= drpdi_reg;
                        end if;
                    end if;
                    state <= S_ACCESS;
    
                  -- transfer starts with apb3penable pulse, GT responds with apb3pready pulse
                  when S_ACCESS =>
                    apb3penable <= '1';
                    if apb3pready = '1' or timeout_counter = TIMEOUT_CYCLES-1 then
                        apb3psel      <= '0';
                        apb3penable   <= '0';
                        apb3pwrite    <= '0';
                        if drpwe_reg = '0' then
                            drpdo(ch_run) <= apb3prdata(15 downto 0);
                        end if;
                        -- flag of completed DRP transfer, tx_phase_aligner waits for it to send the next write
                        drprdy(ch_run) <= '1'; 
                        if apb3pwrite = '0' then
                            apb3rdata_reg <= apb3prdata; -- apb3rdata_reg stores the read value, not used
                        end if;
                        -- at each phase shift tx_phase_aligner sends 3 times the same phase shift control, toggling the upper bit ('0'->'1'->'0').
                        -- this is needed to safely edit the TXPI phase shift control, as reported by the GT user guide.
                        ch_moves(ch_run) <= ch_moves(ch_run) + 1; 
                        state <= IDLE;
                        
                        timeout_counter <= 0;
                        timeout_error <= '1' when timeout_counter = TIMEOUT_CYCLES-1 else timeout_error; -- sticky
                        apb3error     <= '1' when apb3pslverr     = '1'              else apb3error;     -- sticky
                        
                    elsif timeout_counter < TIMEOUT_CYCLES-1 then
                        timeout_counter <= timeout_counter + 1; 
                    end if;
                    
                end case;
            end if;
       end if;
    end if;
  end process;
  
  apb3pslverr_o <= apb3error;
  
  
  -- debug
  ch_run_v <= std_logic_vector(to_signed(ch_run, 3));
  ch_mov_v <= std_logic_vector(to_unsigned(ch_moves(0), 3));
  ch_tmo_v <= std_logic_vector(to_unsigned(ch_timeout, 10));
  intState <= state_type'POS(state);
  st       <= std_logic_vector(to_unsigned(intState, 2));
  
--  ila_apb3: entity work.ila_apb3_drp
--    port map(
--      clk           => clk,
--      probe0(0)     => rst,
--      probe1        => drpaddr(0), 
--      probe2(0)     => drpen(0)  , 
--      probe3        => drpdi(0)  , 
--      probe4        => drpdo(0)  , 
--      probe5(0)     => drprdy(0) , 
--      probe6(0)     => drpwe(0)  , 
--      probe7(0)     => txpippmovrden(0), 
--      probe8(0)     => txpippmsel(0)   , 
--      probe9(0)     => txpippmpd(0)    , 
--      probe10       => apb3paddr    ,
--      probe11(0)    => apb3penable  ,
--      probe12       => apb3prdata ,
--      probe13(0)    => apb3pready ,
--      probe14(0)    => apb3psel     ,
--      probe15(0)    => apb3pslverr,
--      probe16       => apb3pwdata   ,
--      probe17(0)    => apb3pwrite,
--      probe18       => "00",
--      probe19       => st,
--      probe20       => drpaddr_reg,
--      probe21(0)    => drpwe_reg,
--      probe22       => drpdi_reg,
--      probe23(0)    => drpen_temp(1),  
--      probe24(0)    => '0'    ,
--      probe25(0)    => drpen_temp(0)  ,
--      probe26(0)    => drpwe_temp(0)  ,
--      probe27       => drpaddr_temp(0),
--      probe28       => drpdi_temp(0)  ,
--      probe29       => ch_run_v,
--      probe30       => ch_mov_v,
--      probe31       => ch_tmo_v
--  );

end architecture behavioral;
