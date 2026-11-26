--------------------------------------------------------------------------------
-- PCS and PMA module using the FPGA transceiver for 1G Ethernet communication
-- plus the dedicated MAC module with a basic configuration
--------------------------------------------------------------------------------
--
-- Francesco Martina @ 2023
--------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity mac_pcs_pma is
    Port (

        reset            : in std_logic; -- general reset
        freerun_clk_62_5 : in std_logic; -- free-running clock @ 62.5 MHz
        apb3clk_quad     : in std_logic; -- 125MHz freerun

        -- Transceiver reference clock @ 125 MHz
        gtrefclk_p : in std_logic;
        gtrefclk_n : in std_logic;

        -- Transceiver lane
        txn : out std_logic;
        txp : out std_logic;
        rxn : in  std_logic;
        rxp : in  std_logic;

        ---- MAC AXI4-S Interface

        -- RX
        rx_reset           : out std_logic;
        rx_mac_aclk        : out std_logic;
        rx_axis_mac_tdata  : out std_logic_vector(7 downto 0);
        rx_axis_mac_tvalid : out std_logic;
        rx_axis_mac_tlast  : out std_logic;
        rx_axis_mac_tuser  : out std_logic;

        -- TX
        tx_reset           : out std_logic;
        tx_mac_aclk        : out std_logic;
        tx_axis_mac_tdata  : in  std_logic_vector(7 downto 0);
        tx_axis_mac_tvalid : in  std_logic;
        tx_axis_mac_tlast  : in  std_logic;
        tx_axis_mac_tready : out std_logic

    );
end mac_pcs_pma;

architecture Behavioral of mac_pcs_pma is

    -- clocks
    signal PCS_PMA_clk125_tx : std_logic;
    signal PCS_PMA_clk125_rx : std_logic;

    -- Flags / Reset
    signal PMA_gtpowergood     : std_logic;
    signal PMA_resetdone       : std_logic;
    signal PMA_reset_async     : std_logic;
    signal PMA_reset           : std_logic;
    signal PCS_logic_resetn    : std_logic;
    signal vio_reset           : std_logic := '0';


    -- GMII interface
    signal gmii_txd   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal gmii_tx_en : STD_LOGIC;
    signal gmii_tx_er : STD_LOGIC;
    signal gmii_rxd   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal gmii_rx_dv : STD_LOGIC;
    signal gmii_rx_er : STD_LOGIC;
    
    --debug edo
    signal pcsRxusrClk2 : std_logic_vector(7 downto 0);
    signal pcsRxusrClk  : std_logic_vector(7 downto 0);
    signal pcs_rxusrclk : std_logic;

begin

  PMA_reset_async <= reset or vio_reset;
  
  core_resets_i : entity work.PCS_PMA_resets
   port map (
      reset                     => PMA_reset_async, 
      independent_clock_bufg    => freerun_clk_62_5,
      pma_reset                 => PMA_reset
   );
        
  PCS_PMA_i : entity work.PCS_PMA_gt_wrapper
      port map (
        gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_n(0) => gtrefclk_n,
        gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p(0) => gtrefclk_p,
        
        GT_Serial_grx_n(2)          => rxn,
        GT_Serial_grx_n(1 downto 0) => "00",
        GT_Serial_grx_n(3)          => '0',
        
        GT_Serial_grx_p(2)          => rxp,
        GT_Serial_grx_p(1 downto 0) => "00",
        GT_Serial_grx_p(3)          => '0',
        
        GT_Serial_gtx_n(2)          => txn,
        GT_Serial_gtx_n(1 downto 0) => open,
        GT_Serial_gtx_n(3)          => open,
        
        GT_Serial_gtx_p(2)          => txp,
        GT_Serial_gtx_p(1 downto 0) => open,
        GT_Serial_gtx_p(3)          => open,
        
        apb3clk_quad                => apb3clk_quad, 
        configuration_vector_0      => "00000",
        gmii_isolate_0              => open, 
        gmii_pcs_pma_0_rx_dv        => gmii_rx_dv,
        gmii_pcs_pma_0_rx_er        => gmii_rx_er, 
        gmii_pcs_pma_0_rxd          => gmii_rxd,
        gmii_pcs_pma_0_tx_en        => gmii_tx_en,
        gmii_pcs_pma_0_tx_er        => gmii_tx_er,
        gmii_pcs_pma_0_txd          => gmii_txd,
        independent_clock_bufg_0    => freerun_clk_62_5,
        gtpowergood                 => PMA_gtpowergood,
        mmcm_locked_0               => '1', 
        mmcm_reset_0                => open,
        pma_reset_0                 => PMA_reset,
        reset_0                     => PMA_reset,
        resetdone_0                 => PMA_resetdone,
        rxmcommaalignen_out_0       => open,
        rxpcommaalignen_out_0       => open,
        rxuserclk                   => pcs_rxusrclk,
        rxuserclk2                  => PCS_PMA_clk125_rx,
        signal_detect_0             => '1', -- Fibre LOS / SFP module disconnection (Not Used)
        status_vector_0             => open,
        userclk                     => open,             
        userclk2                    => PCS_PMA_clk125_tx
      );
        
--    freq_meas_pcsrxusr2 : entity work.clock_monitor_full
--        port map (
--            clk_ref         => freerun_clk_62_5, -- The reference clock
--            clk_monitored   => PCS_PMA_clk125_rx, -- The clock to measure
--            measured_period => pcsRxusrClk2
--        );
--    freq_meas_pcsrxusr : entity work.clock_monitor_full
--        port map (
--            clk_ref         => freerun_clk_62_5, -- The reference clock
--            clk_monitored   => pcs_rxusrclk, -- The clock to measure
--            measured_period => pcsRxusrClk
--        );
--    vio_clk_free_PCS : entity work.vio_2
--        port map (
--            clk       => freerun_clk_62_5,
--            probe_in0 => pcsRxusrClk2,
--            probe_in1 => pcsRxusrClk
--        );
--    vio_status_pcspma : entity work.vio_axi_pcspma
--        port map (
--            clk        => freerun_clk_62_5,
--            probe_in0(0)  => reset,
--            probe_in1(0)  => PMA_resetdone,
--            probe_in2(0)  => PMA_gtpowergood,
--            probe_in3(0)  => PMA_reset,
--            probe_in4(0)  => PMA_reset,
--            probe_out0(0) => vio_reset,
--            probe_out1(0) => open
--        );

    PCS_logic_resetn <= PMA_gtpowergood and PMA_resetdone and not(PMA_reset);

    -- MAC module
    MAC : entity work.MAC
        port map (
            gtx_clk                 => PCS_PMA_clk125_tx,
            --rx_usr_clk2             => PCS_PMA_clk125_rx,
            glbl_rstn               => PCS_logic_resetn,
            rx_axi_rstn             => PCS_logic_resetn,
            tx_axi_rstn             => PCS_logic_resetn,
            rx_statistics_vector    => open,
            rx_statistics_valid     => open,
            rx_mac_aclk             => rx_mac_aclk,
            rx_reset                => rx_reset,
            rx_axis_mac_tdata       => rx_axis_mac_tdata,
            rx_axis_mac_tvalid      => rx_axis_mac_tvalid,
            rx_axis_mac_tlast       => rx_axis_mac_tlast,
            rx_axis_mac_tuser       => rx_axis_mac_tuser,
            tx_ifg_delay            => X"00",
            tx_statistics_vector    => open,
            tx_statistics_valid     => open,
            tx_mac_aclk             => tx_mac_aclk,
            tx_reset                => tx_reset,
            tx_axis_mac_tdata       => tx_axis_mac_tdata,
            tx_axis_mac_tvalid      => tx_axis_mac_tvalid,
            tx_axis_mac_tlast       => tx_axis_mac_tlast,
            tx_axis_mac_tuser(0)    => '0',
            tx_axis_mac_tready      => tx_axis_mac_tready,
            pause_req               => '0',
            pause_val               => X"0000",
            speedis100              => open,
            speedis10100            => open,
            gmii_txd                => gmii_txd,
            gmii_tx_en              => gmii_tx_en,
            gmii_tx_er              => gmii_tx_er,
            gmii_rxd                => gmii_rxd,
            gmii_rx_dv              => gmii_rx_dv,
            gmii_rx_er              => gmii_rx_er,
            rx_configuration_vector => X"0000_0000_0000_0000_0802", -- RX Enabled in promiscuous mode (Jumbo pkt not enabled)
            tx_configuration_vector => X"0000_0000_0000_0000_0002"  -- TX Enabled (Jumbo pkt not enabled)
        );

end Behavioral;
