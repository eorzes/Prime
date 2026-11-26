library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.gt_pkg.all;
use work.arrays_pkg.all; 

library unisim;
use unisim.vcomponents.all;

entity gt_wrapper is
  generic (
    ACTIVE_CHs  : integer_array := (0, -1, -1, -1);
    N_CH        : positive:=4
  );
  port(
    clk_sys     : in  std_logic;
    gt_rx_p     : in  std_logic_vector(0 to N_CH-1);
    gt_rx_n     : in  std_logic_vector(0 to N_CH-1);
    gt_tx_p     : out std_logic_vector(0 to N_CH-1);
    gt_tx_n     : out std_logic_vector(0 to N_CH-1);
    gt_ctrl     : in  gt_ctrl_array_t (0 to N_CH-1);
    gt_stat     : out gt_stat_array_t (0 to N_CH-1);
    gt_i        : in  to_gt_array_t   (0 to N_CH-1);
    gt_o        : out from_gt_array_t (0 to N_CH-1);
    
    to_apb3     : in  to_apb3_t;
    from_apb3   : out from_apb3_t;
    
    reset_dp_shared : in std_logic_vector(0 to N_CH-1); 
    
    pll_refclk_i  : in  std_logic;
    rxusrclk_o    : out std_logic_vector(0 to N_CH-1); 
    txusrclk_o    : out std_logic_vector(0 to N_CH-1);
    rxresetdone_o : out std_logic_vector(0 to N_CH-1);  
    txresetdone_o : out std_logic_vector(0 to N_CH-1) 
    
  );
end gt_wrapper;

architecture rtl of gt_wrapper is     

    signal rxusrclk_int : std_logic_vector(0 to N_CH-1);

begin

  rxusrclk_o <= rxusrclk_int;

  -----------------------------
  quad_inst : entity work.gty_quad_wrapper
      -----------------------------
    port map(       
        APB3_INTF_0_paddr               => to_apb3.paddr     ,   
        APB3_INTF_0_penable             => to_apb3.penable   ,  
        APB3_INTF_0_prdata              => from_apb3.prdata  ,
        APB3_INTF_0_pready              => from_apb3.pready  ,
        APB3_INTF_0_psel                => to_apb3.psel      ,  
        APB3_INTF_0_pslverr             => from_apb3.pslverr ,
        APB3_INTF_0_pwdata              => to_apb3.pwdata    ,  
        APB3_INTF_0_pwrite              => to_apb3.pwrite    ,    
        GT_REFCLK0_0                    => pll_refclk_i      ,
        GT_Serial_grx_n(0)              => gt_rx_n(0), 
        GT_Serial_grx_n(3 downto 1)     => "000",      
        GT_Serial_grx_p(0)              => gt_rx_p(0), 
        GT_Serial_grx_p(3 downto 1)     => "000",      
        GT_Serial_gtx_n(0)              => gt_tx_n(0),
        GT_Serial_gtx_n(1)              => gt_tx_n(1), 
        GT_Serial_gtx_n(3 downto 2)     => open,       
        GT_Serial_gtx_p(0)              => gt_tx_p(0), 
        GT_Serial_gtx_p(1)              => gt_tx_p(1), 
        GT_Serial_gtx_p(3 downto 2)     => open,       
        apb3clk_gt_bridge_ip_0          => clk_sys,
        apb3clk_gt_bridge_ip_1          => clk_sys,
        apb3clk_quad                    => clk_sys,
        
        ch0_rxbufstatus_ext_0           => gt_stat(0).rxbufstatus,
        ch0_rxbyteisaligned_ext         => gt_stat(0).rxbyteisaligned,
        ch0_rxbyterealign_ext           => gt_stat(0).rxbyterealign,
        ch0_rxcommadet_ext              => open,
        ch0_rxctrl0_ext(3 downto 0)     => gt_o(0).rx_ctrl0,
        ch0_rxctrl0_ext(15 downto 4)    => open,
        ch0_rxctrl1_ext(3 downto 0)     => gt_o(0).rx_ctrl1,
        ch0_rxctrl1_ext(15 downto 4)    => open,
        ch0_rxctrl2_ext(3 downto 0)     => gt_o(0).rx_ctrl2,
        ch0_rxctrl2_ext(7 downto 4)     => open,
        ch0_rxctrl3_ext(3 downto 0)     => gt_o(0).rx_ctrl3,
        ch0_rxctrl3_ext(7 downto 4)     => open,
        ch0_rxdata_ext(31 downto 0)     => gt_o(0).rx_data(31 downto 0),
        ch0_rxdata_ext(127 downto 32)   => open,
        ch0_rxslide_ext_0               => gt_ctrl(0).rxslide,
        
        ch0_txbufstatus_ext_0           => gt_stat(0).txbufstatus,
        ch0_txbufstatus_ext_1           => gt_stat(1).txbufstatus,
        
        ch0_txctrl0_ext(3 downto 0)     => gt_i(0).tx_ctrl0,
        ch0_txctrl0_ext(15 downto 4)    => (others => '0'),
        ch0_txctrl0_ext_0(3 downto 0)   => gt_i(1).tx_ctrl0,
        ch0_txctrl0_ext_0(15 downto 4)  => (others => '0'),
        ch0_txctrl1_ext(3 downto 0)     => gt_i(0).tx_ctrl1,
        ch0_txctrl1_ext(15 downto 4)    => (others => '0'),
        ch0_txctrl1_ext_0(3 downto 0)   => gt_i(1).tx_ctrl1,
        ch0_txctrl1_ext_0(15 downto 4)  => (others => '0'),
        ch0_txctrl2_ext(3 downto 0)     => gt_i(0).tx_ctrl2,
        ch0_txctrl2_ext(7 downto 4)     => (others => '0'),
        ch0_txctrl2_ext_0(3 downto 0)   => gt_i(1).tx_ctrl2,
        ch0_txctrl2_ext_0(7 downto 4)   => (others => '0'),
        ch0_txdata_ext(39 downto 0)     => gt_i(0).tx_data(39 downto 0),
        ch0_txdata_ext(127 downto 40)   => (others => '0'),
        ch0_txdata_ext_0(39 downto 0)   => gt_i(1).tx_data(39 downto 0),
        ch0_txdata_ext_0(127 downto 40) => (others => '0'),
        
        ch0_txpippmen_ext_0             => gt_ctrl(0).txpippmen,
        ch0_txpippmen_ext_1             => gt_ctrl(1).txpippmen,
        ch0_txpippmstepsize_ext_0       => gt_ctrl(0).txpippmstepsize,
        ch0_txpippmstepsize_ext_1       => gt_ctrl(1).txpippmstepsize,
        ch0_txpmaresetdone_ext_0        => gt_stat(0).txpmaresetdone,
        ch0_txpmaresetdone_ext_1        => gt_stat(1).txpmaresetdone,
        
        gt_reset_gt_bridge_ip_0         => gt_ctrl(0).gtwiz_reset_all,
        gt_reset_gt_bridge_ip_1         => gt_ctrl(1).gtwiz_reset_all,
        gtpowergood                     => gt_stat(0).gtpowergood,
        lcpll_lock_gt_bridge_ip_0       => gt_stat(0).txplllock,
        lcpll_lock_gt_bridge_ip_1       => gt_stat(1).txplllock,
        link_status_gt_bridge_ip_0      => open,
        link_status_gt_bridge_ip_1      => open,
        
        rate_sel_gt_bridge_ip_0         => (others => '0'), -- TODO : LPM (0) / DFE (1) -- use LPM only  
        rate_sel_gt_bridge_ip_1         => (others => '0'), -- TODO : LPM (0) / DFE (1) -- use LPM only  
        
        reset_rx_datapath_in            => gt_ctrl(0).gtwiz_reset_rx_datapath or reset_dp_shared(0), 
        reset_rx_pll_and_datapath_in    => gt_ctrl(0).gtwiz_reset_rx_pll_and_datapath,                 
        reset_tx_datapath_in            => gt_ctrl(0).gtwiz_reset_tx_datapath or reset_dp_shared(0),
        reset_tx_datapath_in_0          => gt_ctrl(1).gtwiz_reset_tx_datapath or reset_dp_shared(1),                
        reset_tx_pll_and_datapath_in    => gt_ctrl(0).gtwiz_reset_tx_pll_and_datapath,  
        reset_tx_pll_and_datapath_in_0  => gt_ctrl(1).gtwiz_reset_tx_pll_and_datapath,  
        
        rpll_lock_gt_bridge_ip_0        => open,
        rpll_lock_gt_bridge_ip_1        => open,
        rx_resetdone_out_gt_bridge_ip_0 => rxresetdone_o(0),
        rx_resetdone_out_gt_bridge_ip_1 => rxresetdone_o(1),
        rxusrclk_gt_bridge_ip_0         => rxusrclk_int(0),
        rxusrclk_gt_bridge_ip_1         => rxusrclk_int(1),
        tx_resetdone_out_gt_bridge_ip_0 => txresetdone_o(0),
        tx_resetdone_out_gt_bridge_ip_1 => txresetdone_o(1),
        txusrclk_gt_bridge_ip_0         => txusrclk_o(0),
        txusrclk_gt_bridge_ip_1         => txusrclk_o(1),
        
        ch0_dmonitorclk_0               => rxusrclk_int(0),
        ch0_dmonitoroutclk_0            => gt_stat(0).dmonitoroutclk,
        ch0_dmonitorout_0               => gt_stat(0).dmonitorout
    );

end rtl;
