--------------------------------------------------------------------------------
-- AXI Memory Mapped R/W or Read Only 32bit Register Space
--------------------------------------------------------------------------------
--
-- Francesco Martina @ 2023
-- v1.0
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.reg_space_pack.all;
use IEEE.math_real.all;

-- read/write (or read only) register space interfaced by AXI Memory Mapped.
-- Each register is 32bit wide. Unaligned read access will return the adjacent aligned register
-- (the 2 LSBs of s_axi_awaddr and s_axi_araddr will be ignored).
-- Single byte write transactions can be performed by exploiting the s_axi_wstrb port.

-- Requires VHDL-2008
entity axi_register_space is
    Generic (

        -- If READ_ONLY is false, the reg_space port is presented as an entity output and the module accepts read and write transactions.
        -- Otherwise, the reg_space is an input that can only acquire data from outside (used to map diagnostic/result values of your logics).
        READ_ONLY : boolean := false;

        -- number of 32 bit registers to be allocated (min 1)
        REGISTERS_N : integer := 4;

        -- if true, an 'OKAY' RRESP is returned even when the reading address points to 
        -- a location outside the allocated space. Otherwise it returns 'SLVERR' and a null data value.
        ALLOW_INVALID_READ_ADDRESSES : boolean := false;

        -- In any cases, no data will be touched if the writing address points outside the allocated space.
        -- However, if such a condition occurs and this parameter is "true", an 'OKAY' BRESP is returned.
        -- If the parameter is false, 'SLVERR' BRESP is returned.
        -- 'SLVERR' BRESP is always returned if READ_ONLY is true (dummy write).
        ALLOW_INVALID_WRITE_ADDRESSES : boolean := false

    );
    Port (

        ---- Reset / Clock
        reset : in std_logic;
        clock : in std_logic;

        ---- Slave AXI-Lite Interface
        s_axi_awaddr  : in  std_logic_vector(31 downto 0);
        s_axi_awvalid : in  std_logic;
        s_axi_awready : out std_logic;

        s_axi_wdata  : in  std_logic_vector(31 downto 0);
        s_axi_wstrb  : in  std_logic_vector(3 downto 0);
        s_axi_wvalid : in  std_logic;
        s_axi_wready : out std_logic;

        s_axi_bresp  : out std_logic_vector(1 downto 0);
        s_axi_bvalid : out std_logic;
        s_axi_bready : in  std_logic;

        s_axi_araddr  : in  std_logic_vector(31 downto 0);
        s_axi_arvalid : in  std_logic;
        s_axi_arready : out std_logic;

        s_axi_rdata  : out std_logic_vector(31 downto 0);
        s_axi_rresp  : out std_logic_vector(1 downto 0);
        s_axi_rvalid : out std_logic;
        s_axi_rready : in  std_logic;

        ---- Register Outputs
        reg_space_i : in  reg_space_t(REGISTERS_N - 1 downto 0)(31 downto 0);
        reg_space_o : out reg_space_t(REGISTERS_N - 1 downto 0)(31 downto 0)

    );
end axi_register_space;


architecture Behavioral of axi_register_space is


    signal reg_space : reg_space_t(REGISTERS_N - 1 downto 0)(31 downto 0);
    ----------------------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------------------

    -- BRESP and RRESP return values
    constant OKAY   : std_logic_vector := "00";
    constant SLVERR : std_logic_vector := "10";

    ----------------------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------------------

    -- Allocated Register Space
    signal reg_space_allocated : reg_space_t(REGISTERS_N - 1 downto 0)(31 downto 0);

    -- address masks (to mask the leading address bits out of the mapping range, the 2 lowest bits of the AXI 32 bit address are not used since registers are 4 Bytes each)
    constant ADDRESS_MASK_LSBs : std_logic_vector(integer(ceil(log2(realmax(real(REGISTERS_N), 2.0)))) - 1 downto 0) := (others => '1');
    constant ADDRESS_MASK_MSBs : std_logic_vector(29 downto integer(ceil(log2(realmax(real(REGISTERS_N), 2.0)))))    := (others => '0');
    constant ADDRESS_MASK      : std_logic_vector(29 downto 0)                                                       := ADDRESS_MASK_MSBs & ADDRESS_MASK_LSBs;

    -- Addresses Handling
    signal s_axi_araddr_reg_masked : std_logic_vector(29 downto 0);  -- 30 MSbits of the registered s_axi_araddr, masked to the required bits only
    signal s_axi_awaddr_reg_masked : std_logic_vector(29 downto 0);  -- 30 MSbits of the registered s_axi_awaddr, masked to the required bits only
    signal read_ADD_idx            : integer range 0 to (2**30 - 1); -- indexed 32 bit register to read
    signal write_ADD_idx           : integer range 0 to (2**30 - 1); -- indexed 32 bit register to write
    signal read_ADD_valid          : std_logic;                      -- asserted if the read address resides into the allocated space
    signal write_ADD_valid         : std_logic;                      -- asserted if the write address resides into the allocated space

    -- Data Handling
    signal indexed_DATA : std_logic_vector(31 downto 0); -- data of the selected register

    -- FSM Read
    type read_fsm_status_t is (READ_ADD, READ_DATA);
    signal read_fsm_status : read_fsm_status_t;

    -- FSM Write
    type write_fsm_status_t is (WRITE_ADD, WRITE_DATA, WRITE_RESP);
    signal write_fsm_status : write_fsm_status_t;

begin

    ----------------------------------------------------------------------------
    -- Combinatorial
    ----------------------------------------------------------------------------

    read_ADD_idx   <= To_Integer(Unsigned(s_axi_araddr_reg_masked));
    read_ADD_valid <= '1' when read_ADD_idx < REGISTERS_N else '0';

    s_axi_rdata <= indexed_DATA; -- presents the indexed data to the output
    process(read_ADD_idx, read_ADD_valid, reg_space_allocated)
    begin
        if read_ADD_valid = '1' then
            indexed_DATA <= reg_space_allocated(read_ADD_idx);
        else
            indexed_DATA <= (others => '0');
        end if;
    end process;

    REG_SPACE_PORT_DIR_GEN : if READ_ONLY = true generate
        -- reg_space is used as an input
        reg_space_allocated <= reg_space;
        reg_space <= reg_space_i;
    else generate
        -- reg_space is used as an output
        reg_space <= reg_space_allocated;
        reg_space_o <= reg_space;
    end generate REG_SPACE_PORT_DIR_GEN;

    write_ADD_idx   <= To_Integer(Unsigned(s_axi_awaddr_reg_masked));
    write_ADD_valid <= '1' when write_ADD_idx < REGISTERS_N else '0';

    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- Reading FSM
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------

    -- FSM
    process(reset, clock)
    begin
        if reset = '1' then
            read_fsm_status <= READ_ADD;
        elsif rising_edge(clock) then
            case read_fsm_status is
                ------------------------------------------------------------
                when READ_ADD =>
                    -- wait for receiving the read address
                    if s_axi_arvalid = '1' then
                        -- register the MSBs of the reading address
                        s_axi_araddr_reg_masked <= s_axi_araddr(31 downto 2) and ADDRESS_MASK;
                        read_fsm_status         <= READ_DATA;
                    end if;

                ------------------------------------------------------------
                when READ_DATA =>
                    -- wait for propagating the read data and RRESP
                    if s_axi_rready = '1' then
                        read_fsm_status <= READ_ADD;
                    end if;
            end case;
        end if;
    end process;

    -- FSM Combinatorial Output
    process(read_fsm_status, read_ADD_valid)
    begin
        case read_fsm_status is
            ------------------------------------------------------------
            when READ_ADD =>
                s_axi_arready <= '1';
                s_axi_rvalid  <= '0';
                s_axi_rresp   <= OKAY;

            ------------------------------------------------------------
            when READ_DATA =>
                s_axi_arready <= '0';
                s_axi_rvalid  <= '1';
                if read_ADD_valid = '0' and ALLOW_INVALID_READ_ADDRESSES = false then
                    s_axi_rresp <= SLVERR;
                else
                    s_axi_rresp <= OKAY;
                end if;
        end case;
    end process;

    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------
    -- Writing FSM
    ----------------------------------------------------------------------------
    ----------------------------------------------------------------------------

    -- FSM
    process(reset, clock)
    begin
        if reset = '1' then
            write_fsm_status <= WRITE_ADD;

            -- in READ_ONLY mode, the 'reg_space_allocated' is driven by reg_space (entity input)
            if READ_ONLY = false then
                reg_space_allocated <= (others => (others => '0'));
            end if;

        elsif rising_edge(clock) then
            case write_fsm_status is
                ------------------------------------------------------------
                when WRITE_ADD =>
                    -- wait for the write address
                    if s_axi_awvalid = '1' then
                        s_axi_awaddr_reg_masked <= s_axi_awaddr(31 downto 2) and ADDRESS_MASK;
                        write_fsm_status        <= WRITE_DATA;
                    end if;

                ------------------------------------------------------------
                when WRITE_DATA =>
                    -- wait for the data 
                    if s_axi_wvalid = '1' then
                        -- the effective operation occurs only if the address is valid
                        if write_ADD_valid = '1' and READ_ONLY = false then
                            -- write the strobed data bytes
                            -- the non-strobed ones remain untouched
                            for i in 0 to 3 loop
                                if s_axi_wstrb(i) = '1' then
                                    reg_space_allocated(write_ADD_idx)(8*(i+1)-1 downto 8*i) <= s_axi_wdata(8*(i+1)-1 downto 8*i);
                                end if;
                            end loop;
                        end if;
                        write_fsm_status <= WRITE_RESP;
                    end if;

                ------------------------------------------------------------
                when WRITE_RESP =>
                    -- wait for the reception of the acknowledge
                    if s_axi_bready = '1' then
                        write_fsm_status <= WRITE_ADD;
                    end if;

            end case;
        end if;
    end process;

    -- FSM Combinatorial Output
    process(write_fsm_status, write_ADD_valid)
    begin
        case write_fsm_status is
            ------------------------------------------------------------
            when WRITE_ADD =>
                s_axi_awready <= '1';
                s_axi_wready  <= '0';
                s_axi_bvalid  <= '0';
                s_axi_bresp   <= OKAY;

            ------------------------------------------------------------
            when WRITE_DATA =>
                s_axi_awready <= '0';
                s_axi_wready  <= '1';
                s_axi_bvalid  <= '0';
                s_axi_bresp   <= OKAY;

            ------------------------------------------------------------
            when WRITE_RESP =>
                s_axi_awready <= '0';
                s_axi_wready  <= '0';
                s_axi_bvalid  <= '1';
                if (write_ADD_valid = '0' and ALLOW_INVALID_WRITE_ADDRESSES = false) or READ_ONLY = true then
                    s_axi_bresp <= SLVERR;
                else
                    s_axi_bresp <= OKAY;
                end if;

        end case;
    end process;

end Behavioral;

