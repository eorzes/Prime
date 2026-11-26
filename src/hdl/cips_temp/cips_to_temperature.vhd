-- =============================================================================
-- versal_sysmon_temp_reader.vhd
--
-- Reads the on-chip temperature from the Versal SYSMON_PMC registers
-- entirely from PL logic. No PS (APU/RPU) involvement required.
--
-- Architecture facts (AM006 v1.3):
--   - SYSMON base address : 0xF127_0000
--   - Temperature register: base + 0x0 (first channel result, mapped by CIPS)
--     More precisely the device temperature register is at offset 0x0 after
--     the CIPS has configured the channel map.
--     The DEVICE_TEMP register in the register reference (AM012) is at
--     absolute address 0xF127_0000.
--   - Format: signed Q8.7 fixed-point, directly in degrees Celsius
--             bits[15:0], bit[15] = sign, bits[14:7] = integer part,
--             bits[6:0] = fractional part (1/128 deg resolution)
--   - Register width: 32 bits, temperature in lower 16 bits
--
-- Requirements to use this block:
--   1. Instantiate CIPS IP in your block design (mandatory for all Versal).
--      In CIPS, enable "S_AXI_LPD" (PL-to-PS LPD slave port).
--      The PMC/LPD domain is powered by default after boot.
--   2. In CIPS SYSMON tab (Device Integrity), enable temperature monitoring.
--      The CIPS/PLM configures XPPU to allow PL access — by default in most
--      designs this is open, but if locked down you must enable it.
--   3. Connect your AXI NoC or direct AXI path from this master to S_AXI_LPD
--      on the CIPS, routed to address 0xF127_0000.
--   4. No APU, RPU, or Linux required. PMC alone is sufficient.
--
-- Interface:
--   clk          : PL fabric clock (connect to pl0_ref_clk from CIPS)
--   rst_n        : active-low synchronous reset
--   temp_pulse   : pulses high for 1 cycle when temp_celsius_int/_frac valid
--   temp_celsius_int : integer part of temperature (signed, degrees C)
--   temp_celsius_frac: fractional part (0..127, units of 1/128 degree)
--   temp_raw     : raw 16-bit Q8.7 register value for debug
--   error        : AXI SLVERR or DECERR received (address/permission problem)
--
-- AXI4-Lite master ports (connect to NoC/CIPS S_AXI_LPD):
--   m_axi_*
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity versal_sysmon_temp_reader is
    generic (
        -- SYSMON_PMC base address (AM006 v1.3 / AM012)
        -- DEVICE_TEMP register = base + 0x0
        C_SYSMON_BASE_ADDR  : std_logic_vector(31 downto 0) := x"F1271030";

        -- How many clocks to wait between temperature reads
        -- At 100 MHz clock, 100_000_000 = 1 second interval
        C_READ_INTERVAL_CYC : integer := 100_000_000
    );
    port (
        -- PL clock and reset
        clk             : in  std_logic;
        rst_n           : in  std_logic;

        -- Temperature output (updated when temp_pulse='1')
        temp_pulse      : out std_logic;
        temp_raw        : out std_logic_vector(15 downto 0);
        error           : out std_logic;

        -- AXI4-Lite Master interface
        -- Connect to S_AXI_LPD on CIPS (via NoC or direct), address space 0xF127_0000
        m_axi_araddr    : out std_logic_vector(31 downto 0);
        m_axi_arvalid   : out std_logic;
        m_axi_arready   : in  std_logic;
        m_axi_rdata     : in  std_logic_vector(31 downto 0);
        m_axi_rresp     : in  std_logic_vector(1 downto 0);
        m_axi_rvalid    : in  std_logic;
        m_axi_rready    : out std_logic

        -- Write channels (tied off - read-only access needed)
--        m_axi_awaddr    : out std_logic_vector(31 downto 0);
--        m_axi_awvalid   : out std_logic;
--        m_axi_wdata     : out std_logic_vector(31 downto 0);
--        m_axi_wstrb     : out std_logic_vector(3 downto 0);
--        m_axi_wvalid    : out std_logic;
--        m_axi_bready    : out std_logic;
--        m_axi_awready   : in  std_logic;
--        m_axi_wready    : in  std_logic;
--        m_axi_bresp     : in  std_logic_vector(1 downto 0);
--        m_axi_bvalid    : in  std_logic
    );
end entity versal_sysmon_temp_reader;

architecture rtl of versal_sysmon_temp_reader is

    -- State machine
    type t_state is (IDLE, SEND_ARADDR, WAIT_RDATA, DONE, ERROR_ST);
    signal state : t_state := IDLE;

    -- Interval counter
    signal interval_cnt : integer range 0 to C_READ_INTERVAL_CYC - 1 := 0;
    signal do_read      : std_logic := '0';

    -- Internal registers
    signal raw_reg      : std_logic_vector(15 downto 0) := (others => '0');

    -- AXI control signals
    signal arvalid_r    : std_logic := '0';
    signal rready_r     : std_logic := '0';

    -- Output registers
    signal temp_pulse_r      : std_logic := '0';
    signal temp_int_r        : signed(8 downto 0) := (others => '0');
    signal temp_frac_r       : unsigned(6 downto 0) := (others => '0');
    signal error_r           : std_logic := '0';

begin

    -- -------------------------------------------------------------------------
    -- Tie off write channels (we only read)
    -- -------------------------------------------------------------------------
--    m_axi_awaddr  <= (others => '0');
--    m_axi_awvalid <= '0';
--    m_axi_wdata   <= (others => '0');
--    m_axi_wstrb   <= (others => '0');
--    m_axi_wvalid  <= '0';
--    m_axi_bready  <= '1';  -- absorb any spurious write responses

    -- -------------------------------------------------------------------------
    -- Drive AXI read address channel
    -- -------------------------------------------------------------------------
    m_axi_araddr  <= C_SYSMON_BASE_ADDR;  -- DEVICE_TEMP at offset 0x0
    m_axi_arvalid <= arvalid_r;
    m_axi_rready  <= rready_r;

    -- -------------------------------------------------------------------------
    -- Drive outputs
    -- -------------------------------------------------------------------------
    temp_pulse       <= temp_pulse_r;
--    temp_celsius_int <= temp_int_r;
--    temp_celsius_frac<= temp_frac_r;
    temp_raw         <= raw_reg;
    error            <= error_r;

    -- -------------------------------------------------------------------------
    -- Periodic read trigger
    -- -------------------------------------------------------------------------
    p_interval : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                interval_cnt <= 0;
                do_read      <= '0';
            else
                do_read <= '0';
                if interval_cnt = C_READ_INTERVAL_CYC - 1 then
                    interval_cnt <= 0;
                    do_read      <= '1';
                else
                    interval_cnt <= interval_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- AXI4-Lite read state machine
    -- -------------------------------------------------------------------------
    p_axi_read : process(clk)
        variable raw16 : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state        <= IDLE;
                arvalid_r    <= '0';
                rready_r     <= '0';
                temp_pulse_r <= '0';
                error_r      <= '0';
                raw_reg      <= (others => '0');
                temp_int_r   <= (others => '0');
                temp_frac_r  <= (others => '0');
            else
                -- Default
                temp_pulse_r <= '0';

                case state is

                    -- ---------------------------------------------------------
                    when IDLE =>
                        arvalid_r <= '0';
                        rready_r  <= '0';
                        if do_read = '1' then
                            state     <= SEND_ARADDR;
                            arvalid_r <= '1';
                        end if;

                    -- ---------------------------------------------------------
                    -- Assert AR address until slave accepts (ARREADY)
                    when SEND_ARADDR =>
                        if m_axi_arready = '1' then
                            arvalid_r <= '0';
                            rready_r  <= '1';   -- ready to accept read data
                            state     <= WAIT_RDATA;
                        end if;

                    -- ---------------------------------------------------------
                    -- Wait for RVALID with read data
                    when WAIT_RDATA =>
                        if m_axi_rvalid = '1' then
                            rready_r <= '0';

                            if m_axi_rresp = "00" then
                                -- OKAY response — decode temperature
                                -- Temperature is in bits[15:0], Q8.7 signed
                                -- format (AM006): bits[15:7] = signed integer
                                -- part (degrees C), bits[6:0] = fractional
                                raw16   := m_axi_rdata(15 downto 0);
                                raw_reg <= raw16;

                                -- Integer part: signed, bits[15:7]
                                -- Sign-extend the 9-bit signed value
--                                temp_int_r  <= signed(raw16(15 downto 7));

--                                -- Fractional part: bits[6:0], units of 1/128 C
--                                temp_frac_r <= unsigned(raw16(6 downto 0));

                                temp_pulse_r <= '1';
                                error_r      <= '0';
                                state        <= DONE;
                            else
                                -- SLVERR or DECERR — address/protection issue
                                -- Check CIPS XPPU configuration and S_AXI_LPD
                                error_r <= '1';
                                state   <= ERROR_ST;
                            end if;
                        end if;

                    -- ---------------------------------------------------------
                    -- One cycle gap before going idle
                    when DONE =>
                        state <= IDLE;

                    -- ---------------------------------------------------------
                    -- Hold error state until reset
                    -- Likely cause: XPPU blocking access or wrong address mapping
                    when ERROR_ST =>
                        -- Retry after next interval tick
                        if do_read = '1' then
                            error_r   <= '0';
                            arvalid_r <= '1';
                            state     <= SEND_ARADDR;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture rtl;