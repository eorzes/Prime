--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
--Date        : Fri Sep 25 13:07:59 2026
--Host        : eorzes-pc running 64-bit major release  (build 9200)
--Command     : generate_target PCS_PMA_gt_wrapper.bd
--Design      : PCS_PMA_gt_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity PCS_PMA_gt_wrapper is
  port (
    GT_Serial_grx_n : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_grx_p : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_n : out STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_p : out STD_LOGIC_VECTOR ( 3 downto 0 );
    apb3clk_quad : in STD_LOGIC;
    configuration_vector_0 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    gmii_isolate_0 : out STD_LOGIC;
    gmii_pcs_pma_0_rx_dv : out STD_LOGIC;
    gmii_pcs_pma_0_rx_er : out STD_LOGIC;
    gmii_pcs_pma_0_rxd : out STD_LOGIC_VECTOR ( 7 downto 0 );
    gmii_pcs_pma_0_tx_en : in STD_LOGIC;
    gmii_pcs_pma_0_tx_er : in STD_LOGIC;
    gmii_pcs_pma_0_txd : in STD_LOGIC_VECTOR ( 7 downto 0 );
    gtpowergood : out STD_LOGIC;
    independent_clock_bufg_0 : in STD_LOGIC;
    mmcm_locked_0 : in STD_LOGIC;
    mmcm_reset_0 : out STD_LOGIC;
    pma_reset_0 : in STD_LOGIC;
    reset_0 : in STD_LOGIC;
    resetdone_0 : out STD_LOGIC;
    rxmcommaalignen_out_0 : out STD_LOGIC;
    rxpcommaalignen_out_0 : out STD_LOGIC;
    rxuserclk : out STD_LOGIC;
    rxuserclk2 : out STD_LOGIC;
    signal_detect_0 : in STD_LOGIC;
    status_vector_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    userclk : out STD_LOGIC;
    userclk2 : out STD_LOGIC
  );
end PCS_PMA_gt_wrapper;

architecture STRUCTURE of PCS_PMA_gt_wrapper is
  component PCS_PMA_gt is
  port (
    gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    GT_Serial_grx_n : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_grx_p : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_n : out STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_p : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gmii_pcs_pma_0_rx_dv : out STD_LOGIC;
    gmii_pcs_pma_0_rx_er : out STD_LOGIC;
    gmii_pcs_pma_0_rxd : out STD_LOGIC_VECTOR ( 7 downto 0 );
    gmii_pcs_pma_0_tx_en : in STD_LOGIC;
    gmii_pcs_pma_0_tx_er : in STD_LOGIC;
    gmii_pcs_pma_0_txd : in STD_LOGIC_VECTOR ( 7 downto 0 );
    apb3clk_quad : in STD_LOGIC;
    rxuserclk2 : out STD_LOGIC;
    rxuserclk : out STD_LOGIC;
    userclk2 : out STD_LOGIC;
    userclk : out STD_LOGIC;
    independent_clock_bufg_0 : in STD_LOGIC;
    pma_reset_0 : in STD_LOGIC;
    mmcm_locked_0 : in STD_LOGIC;
    reset_0 : in STD_LOGIC;
    signal_detect_0 : in STD_LOGIC;
    gmii_isolate_0 : out STD_LOGIC;
    mmcm_reset_0 : out STD_LOGIC;
    status_vector_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    resetdone_0 : out STD_LOGIC;
    rxpcommaalignen_out_0 : out STD_LOGIC;
    rxmcommaalignen_out_0 : out STD_LOGIC;
    configuration_vector_0 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    gtpowergood : out STD_LOGIC
  );
  end component PCS_PMA_gt;
begin
PCS_PMA_gt_i: component PCS_PMA_gt
     port map (
      GT_Serial_grx_n(3 downto 0) => GT_Serial_grx_n(3 downto 0),
      GT_Serial_grx_p(3 downto 0) => GT_Serial_grx_p(3 downto 0),
      GT_Serial_gtx_n(3 downto 0) => GT_Serial_gtx_n(3 downto 0),
      GT_Serial_gtx_p(3 downto 0) => GT_Serial_gtx_p(3 downto 0),
      apb3clk_quad => apb3clk_quad,
      configuration_vector_0(4 downto 0) => configuration_vector_0(4 downto 0),
      gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_n(0) => gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_n(0),
      gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p(0) => gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p(0),
      gmii_isolate_0 => gmii_isolate_0,
      gmii_pcs_pma_0_rx_dv => gmii_pcs_pma_0_rx_dv,
      gmii_pcs_pma_0_rx_er => gmii_pcs_pma_0_rx_er,
      gmii_pcs_pma_0_rxd(7 downto 0) => gmii_pcs_pma_0_rxd(7 downto 0),
      gmii_pcs_pma_0_tx_en => gmii_pcs_pma_0_tx_en,
      gmii_pcs_pma_0_tx_er => gmii_pcs_pma_0_tx_er,
      gmii_pcs_pma_0_txd(7 downto 0) => gmii_pcs_pma_0_txd(7 downto 0),
      gtpowergood => gtpowergood,
      independent_clock_bufg_0 => independent_clock_bufg_0,
      mmcm_locked_0 => mmcm_locked_0,
      mmcm_reset_0 => mmcm_reset_0,
      pma_reset_0 => pma_reset_0,
      reset_0 => reset_0,
      resetdone_0 => resetdone_0,
      rxmcommaalignen_out_0 => rxmcommaalignen_out_0,
      rxpcommaalignen_out_0 => rxpcommaalignen_out_0,
      rxuserclk => rxuserclk,
      rxuserclk2 => rxuserclk2,
      signal_detect_0 => signal_detect_0,
      status_vector_0(15 downto 0) => status_vector_0(15 downto 0),
      userclk => userclk,
      userclk2 => userclk2
    );
end STRUCTURE;
