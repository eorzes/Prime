--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
--Date        : Sun Mar  8 22:39:12 2026
--Host        : pcphese71 running 64-bit major release  (build 9200)
--Command     : generate_target gty_quad_wrapper.bd
--Design      : gty_quad_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity gty_quad_wrapper is
  port (
    APB3_INTF_0_paddr : in STD_LOGIC_VECTOR ( 15 downto 0 );
    APB3_INTF_0_penable : in STD_LOGIC;
    APB3_INTF_0_prdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    APB3_INTF_0_pready : out STD_LOGIC;
    APB3_INTF_0_psel : in STD_LOGIC;
    APB3_INTF_0_pslverr : out STD_LOGIC;
    APB3_INTF_0_pwdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    APB3_INTF_0_pwrite : in STD_LOGIC;
    GT_Serial_grx_n : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_grx_p : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_n : out STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_p : out STD_LOGIC_VECTOR ( 3 downto 0 );
    apb3clk_gt_bridge_ip_0 : in STD_LOGIC;
    apb3clk_gt_bridge_ip_1 : in STD_LOGIC;
    apb3clk_quad : in STD_LOGIC;
    ch0_rxbufstatus_ext_0 : out STD_LOGIC_VECTOR ( 2 downto 0 );
    ch0_rxbyteisaligned_ext_0 : out STD_LOGIC;
    ch0_rxbyterealign_ext_0 : out STD_LOGIC;
    ch0_rxcommadet_ext_0 : out STD_LOGIC;
    ch0_rxctrl0_ext_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_rxctrl1_ext_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_rxctrl2_ext_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_rxctrl3_ext_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_rxdata_ext_0 : out STD_LOGIC_VECTOR ( 127 downto 0 );
    ch0_rxpmaresetdone_ext_0 : out STD_LOGIC;
    ch0_rxslide_ext_0 : in STD_LOGIC;
    ch0_txbufstatus_ext_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ch0_txbufstatus_ext_1 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ch0_txctrl0_ext_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl0_ext_1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl1_ext_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl1_ext_1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl2_ext_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_txctrl2_ext_1 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_txdata_ext_0 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    ch0_txdata_ext_1 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    ch0_txpippmen_ext_0 : in STD_LOGIC;
    ch0_txpippmen_ext_1 : in STD_LOGIC;
    ch0_txpippmstepsize_ext_0 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    ch0_txpippmstepsize_ext_1 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    ch0_txpmaresetdone_ext_0 : out STD_LOGIC;
    ch0_txpmaresetdone_ext_1 : out STD_LOGIC;
    gt_bridge_ip_0_diff_gt_ref_clock_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    gt_bridge_ip_0_diff_gt_ref_clock_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    gt_reset_gt_bridge_ip_0 : in STD_LOGIC;
    gt_reset_gt_bridge_ip_1 : in STD_LOGIC;
    gtpowergood : out STD_LOGIC;
    lcpll_lock_gt_bridge_ip_0 : out STD_LOGIC;
    lcpll_lock_gt_bridge_ip_1 : out STD_LOGIC;
    link_status_gt_bridge_ip_0 : out STD_LOGIC;
    link_status_gt_bridge_ip_1 : out STD_LOGIC;
    rate_sel_gt_bridge_ip_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rate_sel_gt_bridge_ip_1 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    refclk : out STD_LOGIC;
    reset_rx_datapath_in_0 : in STD_LOGIC;
    reset_rx_pll_and_datapath_in_0 : in STD_LOGIC;
    reset_tx_datapath_in_0 : in STD_LOGIC;
    reset_tx_datapath_in_1 : in STD_LOGIC;
    reset_tx_pll_and_datapath_in_0 : in STD_LOGIC;
    reset_tx_pll_and_datapath_in_1 : in STD_LOGIC;
    rpll_lock_gt_bridge_ip_0 : out STD_LOGIC;
    rpll_lock_gt_bridge_ip_1 : out STD_LOGIC;
    rx_resetdone_out_gt_bridge_ip_0 : out STD_LOGIC;
    rx_resetdone_out_gt_bridge_ip_1 : out STD_LOGIC;
    rxusrclk_gt_bridge_ip_0 : out STD_LOGIC;
    rxusrclk_gt_bridge_ip_1 : out STD_LOGIC;
    tx_resetdone_out_gt_bridge_ip_0 : out STD_LOGIC;
    tx_resetdone_out_gt_bridge_ip_1 : out STD_LOGIC;
    txusrclk_gt_bridge_ip_0 : out STD_LOGIC;
    txusrclk_gt_bridge_ip_1 : out STD_LOGIC
  );
end gty_quad_wrapper;

architecture STRUCTURE of gty_quad_wrapper is
  component gty_quad is
  port (
    gt_bridge_ip_0_diff_gt_ref_clock_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    gt_bridge_ip_0_diff_gt_ref_clock_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    GT_Serial_grx_n : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_grx_p : in STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_n : out STD_LOGIC_VECTOR ( 3 downto 0 );
    GT_Serial_gtx_p : out STD_LOGIC_VECTOR ( 3 downto 0 );
    APB3_INTF_0_paddr : in STD_LOGIC_VECTOR ( 15 downto 0 );
    APB3_INTF_0_penable : in STD_LOGIC;
    APB3_INTF_0_prdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    APB3_INTF_0_pready : out STD_LOGIC;
    APB3_INTF_0_psel : in STD_LOGIC;
    APB3_INTF_0_pslverr : out STD_LOGIC;
    APB3_INTF_0_pwdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    APB3_INTF_0_pwrite : in STD_LOGIC;
    apb3clk_quad : in STD_LOGIC;
    gt_reset_gt_bridge_ip_0 : in STD_LOGIC;
    link_status_gt_bridge_ip_0 : out STD_LOGIC;
    txusrclk_gt_bridge_ip_0 : out STD_LOGIC;
    rxusrclk_gt_bridge_ip_0 : out STD_LOGIC;
    rpll_lock_gt_bridge_ip_0 : out STD_LOGIC;
    lcpll_lock_gt_bridge_ip_0 : out STD_LOGIC;
    tx_resetdone_out_gt_bridge_ip_0 : out STD_LOGIC;
    rx_resetdone_out_gt_bridge_ip_0 : out STD_LOGIC;
    rate_sel_gt_bridge_ip_0 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    apb3clk_gt_bridge_ip_0 : in STD_LOGIC;
    reset_rx_pll_and_datapath_in_0 : in STD_LOGIC;
    reset_rx_datapath_in_0 : in STD_LOGIC;
    reset_tx_pll_and_datapath_in_0 : in STD_LOGIC;
    reset_tx_datapath_in_0 : in STD_LOGIC;
    ch0_rxdata_ext_0 : out STD_LOGIC_VECTOR ( 127 downto 0 );
    ch0_txdata_ext_0 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    ch0_rxctrl0_ext_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_rxctrl1_ext_0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_rxctrl2_ext_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_rxctrl3_ext_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_txctrl0_ext_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl1_ext_0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl2_ext_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ch0_rxcommadet_ext_0 : out STD_LOGIC;
    ch0_rxbyteisaligned_ext_0 : out STD_LOGIC;
    ch0_rxbyterealign_ext_0 : out STD_LOGIC;
    gt_reset_gt_bridge_ip_1 : in STD_LOGIC;
    link_status_gt_bridge_ip_1 : out STD_LOGIC;
    txusrclk_gt_bridge_ip_1 : out STD_LOGIC;
    rxusrclk_gt_bridge_ip_1 : out STD_LOGIC;
    rpll_lock_gt_bridge_ip_1 : out STD_LOGIC;
    lcpll_lock_gt_bridge_ip_1 : out STD_LOGIC;
    tx_resetdone_out_gt_bridge_ip_1 : out STD_LOGIC;
    rx_resetdone_out_gt_bridge_ip_1 : out STD_LOGIC;
    rate_sel_gt_bridge_ip_1 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    apb3clk_gt_bridge_ip_1 : in STD_LOGIC;
    reset_tx_pll_and_datapath_in_1 : in STD_LOGIC;
    reset_tx_datapath_in_1 : in STD_LOGIC;
    ch0_txdata_ext_1 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    gtpowergood : out STD_LOGIC;
    refclk : out STD_LOGIC;
    ch0_txpippmen_ext_0 : in STD_LOGIC;
    ch0_txbufstatus_ext_0 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ch0_txpippmstepsize_ext_0 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    ch0_txpmaresetdone_ext_0 : out STD_LOGIC;
    ch0_rxpmaresetdone_ext_0 : out STD_LOGIC;
    ch0_rxbufstatus_ext_0 : out STD_LOGIC_VECTOR ( 2 downto 0 );
    ch0_rxslide_ext_0 : in STD_LOGIC;
    ch0_txpippmen_ext_1 : in STD_LOGIC;
    ch0_txbufstatus_ext_1 : out STD_LOGIC_VECTOR ( 1 downto 0 );
    ch0_txpippmstepsize_ext_1 : in STD_LOGIC_VECTOR ( 4 downto 0 );
    ch0_txpmaresetdone_ext_1 : out STD_LOGIC;
    ch0_txctrl0_ext_1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl1_ext_1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ch0_txctrl2_ext_1 : in STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component gty_quad;
begin
gty_quad_i: component gty_quad
     port map (
      APB3_INTF_0_paddr(15 downto 0) => APB3_INTF_0_paddr(15 downto 0),
      APB3_INTF_0_penable => APB3_INTF_0_penable,
      APB3_INTF_0_prdata(31 downto 0) => APB3_INTF_0_prdata(31 downto 0),
      APB3_INTF_0_pready => APB3_INTF_0_pready,
      APB3_INTF_0_psel => APB3_INTF_0_psel,
      APB3_INTF_0_pslverr => APB3_INTF_0_pslverr,
      APB3_INTF_0_pwdata(31 downto 0) => APB3_INTF_0_pwdata(31 downto 0),
      APB3_INTF_0_pwrite => APB3_INTF_0_pwrite,
      GT_Serial_grx_n(3 downto 0) => GT_Serial_grx_n(3 downto 0),
      GT_Serial_grx_p(3 downto 0) => GT_Serial_grx_p(3 downto 0),
      GT_Serial_gtx_n(3 downto 0) => GT_Serial_gtx_n(3 downto 0),
      GT_Serial_gtx_p(3 downto 0) => GT_Serial_gtx_p(3 downto 0),
      apb3clk_gt_bridge_ip_0 => apb3clk_gt_bridge_ip_0,
      apb3clk_gt_bridge_ip_1 => apb3clk_gt_bridge_ip_1,
      apb3clk_quad => apb3clk_quad,
      ch0_rxbufstatus_ext_0(2 downto 0) => ch0_rxbufstatus_ext_0(2 downto 0),
      ch0_rxbyteisaligned_ext_0 => ch0_rxbyteisaligned_ext_0,
      ch0_rxbyterealign_ext_0 => ch0_rxbyterealign_ext_0,
      ch0_rxcommadet_ext_0 => ch0_rxcommadet_ext_0,
      ch0_rxctrl0_ext_0(15 downto 0) => ch0_rxctrl0_ext_0(15 downto 0),
      ch0_rxctrl1_ext_0(15 downto 0) => ch0_rxctrl1_ext_0(15 downto 0),
      ch0_rxctrl2_ext_0(7 downto 0) => ch0_rxctrl2_ext_0(7 downto 0),
      ch0_rxctrl3_ext_0(7 downto 0) => ch0_rxctrl3_ext_0(7 downto 0),
      ch0_rxdata_ext_0(127 downto 0) => ch0_rxdata_ext_0(127 downto 0),
      ch0_rxpmaresetdone_ext_0 => ch0_rxpmaresetdone_ext_0,
      ch0_rxslide_ext_0 => ch0_rxslide_ext_0,
      ch0_txbufstatus_ext_0(1 downto 0) => ch0_txbufstatus_ext_0(1 downto 0),
      ch0_txbufstatus_ext_1(1 downto 0) => ch0_txbufstatus_ext_1(1 downto 0),
      ch0_txctrl0_ext_0(15 downto 0) => ch0_txctrl0_ext_0(15 downto 0),
      ch0_txctrl0_ext_1(15 downto 0) => ch0_txctrl0_ext_1(15 downto 0),
      ch0_txctrl1_ext_0(15 downto 0) => ch0_txctrl1_ext_0(15 downto 0),
      ch0_txctrl1_ext_1(15 downto 0) => ch0_txctrl1_ext_1(15 downto 0),
      ch0_txctrl2_ext_0(7 downto 0) => ch0_txctrl2_ext_0(7 downto 0),
      ch0_txctrl2_ext_1(7 downto 0) => ch0_txctrl2_ext_1(7 downto 0),
      ch0_txdata_ext_0(127 downto 0) => ch0_txdata_ext_0(127 downto 0),
      ch0_txdata_ext_1(127 downto 0) => ch0_txdata_ext_1(127 downto 0),
      ch0_txpippmen_ext_0 => ch0_txpippmen_ext_0,
      ch0_txpippmen_ext_1 => ch0_txpippmen_ext_1,
      ch0_txpippmstepsize_ext_0(4 downto 0) => ch0_txpippmstepsize_ext_0(4 downto 0),
      ch0_txpippmstepsize_ext_1(4 downto 0) => ch0_txpippmstepsize_ext_1(4 downto 0),
      ch0_txpmaresetdone_ext_0 => ch0_txpmaresetdone_ext_0,
      ch0_txpmaresetdone_ext_1 => ch0_txpmaresetdone_ext_1,
      gt_bridge_ip_0_diff_gt_ref_clock_clk_n(0) => gt_bridge_ip_0_diff_gt_ref_clock_clk_n(0),
      gt_bridge_ip_0_diff_gt_ref_clock_clk_p(0) => gt_bridge_ip_0_diff_gt_ref_clock_clk_p(0),
      gt_reset_gt_bridge_ip_0 => gt_reset_gt_bridge_ip_0,
      gt_reset_gt_bridge_ip_1 => gt_reset_gt_bridge_ip_1,
      gtpowergood => gtpowergood,
      lcpll_lock_gt_bridge_ip_0 => lcpll_lock_gt_bridge_ip_0,
      lcpll_lock_gt_bridge_ip_1 => lcpll_lock_gt_bridge_ip_1,
      link_status_gt_bridge_ip_0 => link_status_gt_bridge_ip_0,
      link_status_gt_bridge_ip_1 => link_status_gt_bridge_ip_1,
      rate_sel_gt_bridge_ip_0(3 downto 0) => rate_sel_gt_bridge_ip_0(3 downto 0),
      rate_sel_gt_bridge_ip_1(3 downto 0) => rate_sel_gt_bridge_ip_1(3 downto 0),
      refclk => refclk,
      reset_rx_datapath_in_0 => reset_rx_datapath_in_0,
      reset_rx_pll_and_datapath_in_0 => reset_rx_pll_and_datapath_in_0,
      reset_tx_datapath_in_0 => reset_tx_datapath_in_0,
      reset_tx_datapath_in_1 => reset_tx_datapath_in_1,
      reset_tx_pll_and_datapath_in_0 => reset_tx_pll_and_datapath_in_0,
      reset_tx_pll_and_datapath_in_1 => reset_tx_pll_and_datapath_in_1,
      rpll_lock_gt_bridge_ip_0 => rpll_lock_gt_bridge_ip_0,
      rpll_lock_gt_bridge_ip_1 => rpll_lock_gt_bridge_ip_1,
      rx_resetdone_out_gt_bridge_ip_0 => rx_resetdone_out_gt_bridge_ip_0,
      rx_resetdone_out_gt_bridge_ip_1 => rx_resetdone_out_gt_bridge_ip_1,
      rxusrclk_gt_bridge_ip_0 => rxusrclk_gt_bridge_ip_0,
      rxusrclk_gt_bridge_ip_1 => rxusrclk_gt_bridge_ip_1,
      tx_resetdone_out_gt_bridge_ip_0 => tx_resetdone_out_gt_bridge_ip_0,
      tx_resetdone_out_gt_bridge_ip_1 => tx_resetdone_out_gt_bridge_ip_1,
      txusrclk_gt_bridge_ip_0 => txusrclk_gt_bridge_ip_0,
      txusrclk_gt_bridge_ip_1 => txusrclk_gt_bridge_ip_1
    );
end STRUCTURE;
