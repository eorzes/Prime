library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.gdmtd_pkg.all;
use work.arrays_pkg.all; 

package gt_pkg is

  constant GT_N    : integer := 2;
  constant DDMTD_N : integer := 0;
  constant QUAD_N  : integer := 1;
  
  constant USR_DATA : integer := 32; --32 
  constant SER_DATA : integer := 40; --40
  constant GTCTRL_W : integer :=  4; --40
  
  type from_gt_usr_logic_t is record  -- user logic flags of GT rx/tx (alignment, datacheck, txpi)
    data_valid     : std_logic;
    rx_aligned     : std_logic;
    slide_count    : std_logic_vector(8 downto 0);
    odds_count     : std_logic_vector(8 downto 0);
    lol_count      : std_logic_vector(8 downto 0);
  end record;
  type from_txpi_logic_t is record
    ali_done  : std_logic;
    step_done : std_logic;
    acc_phase : std_logic_vector(15 downto 0);
    acc_phase_pre_cal : std_logic_vector(15 downto 0);
    fifo_fill_pd      : std_logic_vector(31 downto 0);
  end record;
  type from_gt_t is record  -- from GT to user logic
    tx_outclk   : std_logic;
    tx_usrclk   : std_logic;
    rx_usrclk   : std_logic;
    rx_data     : std_logic_vector(USR_DATA-1 downto 0);
    rx_ctrl0    : std_logic_vector(GTCTRL_W-1 downto 0); -- 1 bit per data byte   
    rx_ctrl1    : std_logic_vector(GTCTRL_W-1 downto 0); -- 1 bit per data byte   
    rx_ctrl2    : std_logic_vector(GTCTRL_W-1 downto 0); -- 1 bit per data byte   
    rx_ctrl3    : std_logic_vector(GTCTRL_W-1 downto 0); -- 1 bit per data byte 
    rx_rdy      : std_logic;
    tx_rdy      : std_logic;
    tx_rdy_sys  : std_logic;
    rx_recclk   : std_logic; -- recovered clk directly from data stream (divided): doesn't go in fpga logic, has 10 times less jitter than rxoutclk
    logic       : from_gt_usr_logic_t;
    txpi        : from_txpi_logic_t;
    txbufstatus : std_logic_vector( 1 downto 0);
    bb_tx_done  : std_logic;
    pslverr_o   : std_logic;
    timeout     : std_logic;
  end record;
  type qpll_shared_t is record
    reset_from_gts : std_logic;
    lock           : std_logic;
    clk            : std_logic;
    refclk         : std_logic;
  end record;

  type gt_eq_t is record  -- rx LPM equalizer configuration values
    lpmlf : std_logic_vector(1 downto 0);
    lpmhf : std_logic_vector(1 downto 0);
    lpmos : std_logic_vector(1 downto 0);
    lpmgc : std_logic_vector(1 downto 0);
  end record;
  type to_txpi_t is record
    ctrl         : std_logic_vector(7 downto 0);
    ali_calib    : std_logic;
    fine_realign : std_logic;
    hold_rst     : std_logic;
    skip_ali     : std_logic;
    nUI          : std_logic_vector(2 downto 0);
  end record;
  type to_gt_t is record -- from the user logic or Software to GT
    tx_usrclk     : std_logic;
    tx_data       : std_logic_vector(SER_DATA-1 downto 0);
    rx_reset      : std_logic;
    tx_reset      : std_logic;
    reset_all     : std_logic;
    rx_aligner_en : std_logic;
    tx_enc_bypass : std_logic;
    rx_reset_dp   : std_logic;
    tx_reset_dp   : std_logic;
    tx_ctrl0      : std_logic_vector(GTCTRL_W-1 downto 0);
    tx_ctrl1      : std_logic_vector(GTCTRL_W-1 downto 0);
    tx_ctrl2      : std_logic_vector(GTCTRL_W-1 downto 0);
    gt_eq         : gt_eq_t;
    txpi          : to_txpi_t;
  end record;
  type tx_manual_bb is record
    txphdlyreset_int    : std_logic;
    txdlybypass_int     : std_logic;
    txphalignen_int     : std_logic;
    txdlysreset_int     : std_logic;
    txphinit_int        : std_logic;
    txphalign_int       : std_logic;
    txdlyen_int         : std_logic;
    txdlysresetdone_int : std_logic;
    txphinitdone_int    : std_logic;
    txphaligndone_int   : std_logic;
    txsyncout_int       : std_logic;
  end record;
  
  type to_gt_array_t    is array (natural range <>) of to_gt_t;
  type from_gt_array_t  is array (natural range <>) of from_gt_t;
  
  type from_txpi_logic_array_t  is array (natural range <>) of from_txpi_logic_t;
  
  subtype to_gt_array_4_t   is to_gt_array_t(0 to 3)  ;
  subtype from_gt_array_4_t is from_gt_array_t(0 to 3);
  type to_gt_matrix_t    is array (natural range <>) of to_gt_array_4_t;
  type from_gt_matrix_t  is array (natural range <>) of from_gt_array_4_t;
  
  type dmtd_hold_rst_array_t is array (natural range <>) of std_logic;
  type register_array_t      is array (natural range <>) of std_logic_vector(31 downto 0);
  
  type from_axi_t is record  -- controls from Software to FPGA
    to_gt          : to_gt_array_t(GT_N-1 downto 0);
    dmtd_hold_rst  : dmtd_hold_rst_array_t(DDMTD_N-1 downto 0);
    heater_enable  : std_logic;
    heat_ctrl      : std_logic_vector(19 downto 0);
  end record;
  
  type from_dmonitor_rxpi is record
    single : std_logic_vector(31 downto 0);
    sum    : std_logic_vector(31 downto 0);
    var    : std_logic_vector(31 downto 0);
    max    : std_logic_vector(31 downto 0);
    min    : std_logic_vector(31 downto 0);
  end record;
  type from_dmonitor_rxpi_array_t  is array (natural range <>) of from_dmonitor_rxpi;

  type to_axi_t is record  -- data and logs from FPGA to Software
    temp           : std_logic_vector(31 downto 0);
    from_gt        : from_gt_array_t(GT_N-1 downto 0);
    from_dmtds     : from_dmtd_array_t(DDMTD_N-1 downto 0);
    from_rxpi      : from_dmonitor_rxpi_array_t(GT_N-1 downto 0);
  end record;

  type gt_stat_t is record
    dmonitorout                     : std_logic_vector(31 downto 0);
    dmonitoroutclk                  : std_logic;
    dmonitoroutclk_buf              : std_logic;
    drpdo                           : std_logic_vector(15 downto 0);
    drprdy                          : std_logic;
    rxprbserr                       : std_logic;
    rxprbslocked                    : std_logic;
    rxbufstatus                     : std_logic_vector( 2 downto 0);
    txbufstatus                     : std_logic_vector( 1 downto 0);
    buffbypass_tx_done              : std_logic;
    txplllock                       : std_logic;
    rxplllock                       : std_logic;
    gtwiz_buffbypass_rx_done        : std_logic;
    gtwiz_buffbypass_rx_error       : std_logic;
    gtwiz_reset_rx_cdr_stable       : std_logic;
    gtwiz_reset_tx_done             : std_logic;
    gtwiz_reset_rx_done             : std_logic;
    txpmaresetdone                  : std_logic;
    rxpmaresetdone                  : std_logic;
    gtpowergood                     : std_logic;
    rxbyteisaligned                 : std_logic;
    rxbyterealign                   : std_logic;
  end record;

  type gt_ctrl_t is record
    rxslide                         : std_logic;
    block_dp_rst                    : std_logic;
    gtwiz_reset_all                 : std_logic;
    gtwiz_reset_tx_pll_and_datapath : std_logic;
    gtwiz_reset_rx_pll_and_datapath : std_logic;
    gtwiz_reset_tx_datapath         : std_logic;
    gtwiz_reset_rx_datapath         : std_logic;
    drpaddr                         : std_logic_vector( 9 downto 0);
    drpclk                          : std_logic;
    drpdi                           : std_logic_vector(15 downto 0);
    drpen                           : std_logic;
    drpwe                           : std_logic;
    dmonitorclk                     : std_logic;
    eyescanreset                    : std_logic;
    rxpolarity                      : std_logic;
    rxprbscntreset                  : std_logic;
    rxprbssel                       : std_logic_vector( 3 downto 0);
    txpippmen                       : std_logic;
    txpippmovrden                   : std_logic;
    txpippmpd                       : std_logic;
    txpippmsel                      : std_logic;
    txpippmstepsize                 : std_logic_vector( 4 downto 0);
    txpolarity                      : std_logic;
    txprbsforceerr                  : std_logic;
    txprbssel                       : std_logic_vector( 3 downto 0);
    loopback                        : std_logic_vector( 2 downto 0);
    rxcommadeten                    : std_logic;    
    rxmcommaalignen                 : std_logic; 
    rxpcommaalignen                 : std_logic; 
--  rxdfeagcovrden                  : std_logic;
--  rxdfelfovrden                   : std_logic;
--  rxdfelpmreset                   : std_logic;
--  rxdfeutovrden                   : std_logic;
--  rxdfevpovrden                   : std_logic;
--  rxlpmen                         : std_logic;
    rxlpmgcovrden                   : std_logic;
    rxlpmhfovrden                   : std_logic;
    rxlpmlfklovrden                 : std_logic;
    rxlpmosovrden                   : std_logic;
    rxlpmgchold                     : std_logic;
    rxlpmhfhold                     : std_logic;
    rxlpmlfklhold                   : std_logic;
    rxlpmoshold                     : std_logic;
--  rxosovrden                      : std_logic;
    gtwiz_buffbypass_rx_reset       : std_logic;
    gtwiz_buffbypass_rx_start_user  : std_logic;
    gtwiz_userclk_tx_active         : std_logic;
    gtwiz_userclk_rx_active         : std_logic;
  end record;

  constant GT_CTRL_NULL : gt_ctrl_t := (
    rxslide                         => '0',
    block_dp_rst                    => '0',
    gtwiz_reset_all                 => '0',
    gtwiz_reset_tx_pll_and_datapath => '0',
    gtwiz_reset_rx_pll_and_datapath => '0',
    gtwiz_reset_tx_datapath         => '0',
    gtwiz_reset_rx_datapath         => '0',
    drpaddr                         => (others => '0'),
    drpclk                          => '0',
    drpdi                           => (others => '0'),
    drpen                           => '0',
    drpwe                           => '0',
    dmonitorclk                     => '0',
    eyescanreset                    => '0',
    rxpolarity                      => '0',
    rxprbscntreset                  => '0',
    rxprbssel                       => (others => '0'),
    txpippmen                       => '0',
    txpippmovrden                   => '0',
    txpippmpd                       => '0',
    txpippmsel                      => '0',
    txpippmstepsize                 => (others => '0'),
    txpolarity                      => '0',
    txprbsforceerr                  => '0',
    txprbssel                       => (others => '0'),
    rxcommadeten                    => '1',
    rxmcommaalignen                 => '0', --'1'
    rxpcommaalignen                 => '0', --'1'
    loopback                        => (others => '0'),
    
    rxlpmgcovrden                   => '0',
    rxlpmhfovrden                   => '0',
    rxlpmlfklovrden                 => '0',
    rxlpmosovrden                   => '0',
    rxlpmgchold                     => '0',
    rxlpmhfhold                     => '0',
    rxlpmlfklhold                   => '0',
    rxlpmoshold                     => '0',
    
    gtwiz_buffbypass_rx_reset       => '0',
    gtwiz_buffbypass_rx_start_user  => '0',
    gtwiz_userclk_tx_active         => '0',
    gtwiz_userclk_rx_active         => '0'
  );
  
  -- apb3 interface signals 
  
  type from_apb3_t is record 
      prdata   : std_logic_vector(31 downto 0);
      pready   : std_logic;     
      pslverr  : std_logic;  
      hold_rst : std_logic;                                      
  end record;
  constant FROM_APB3_INIT : from_apb3_t := (
      prdata   => (others => '0'),
      pready   => '0',
      pslverr  => '0',
      hold_rst => '0'
  );
  type to_apb3_t is record 
      paddr     : std_logic_vector(15 downto 0); 
      penable   : std_logic;                                    
      psel      : std_logic;                     
      pwdata    : std_logic_vector(31 downto 0); 
      pwrite    : std_logic;   
      pslverr_o : std_logic;
      timeout   : std_logic;               
  end record;
  constant TO_APB3_INIT : to_apb3_t := (
      paddr     => (others => '0'),
      penable   => '0',
      psel      => '0',
      pwdata    => (others => '0'),
      pwrite    => '0',
      pslverr_o => '0',
      timeout   => '0'
  );

  -- record array definitions  
  
  type tx_manual_bb_array_t is array (natural range <>) of tx_manual_bb;
  
  type from_apb3_array_t is array (natural range <>) of from_apb3_t;
  type to_apb3_array_t is array (natural range <>) of to_apb3_t;

  type gt_ctrl_array_t is array (natural range <>) of gt_ctrl_t;
  type gt_stat_array_t is array (natural range <>) of gt_stat_t;
  
  subtype gt_ctrl_array_4_t is gt_ctrl_array_t(0 to 3);
  subtype gt_stat_array_4_t is gt_stat_array_t(0 to 3);
  type gt_ctrl_matrix_t is array (natural range <>) of gt_ctrl_array_4_t;
  type gt_stat_matrix_t is array (natural range <>) of gt_stat_array_4_t;

  type from_gt_logic_array_t is array (natural range <>) of from_gt_usr_logic_t;
  
  type QUADs_GTs_map_t is array (natural range <>) of integer_array;
  
  function or_reduce_shared_pll_rst(in_record: gt_stat_array_t; active: integer_array) return std_logic;
  
  -- data generator
  type gen_t is record 
      rst_main      : std_logic;
      rst_vio       : std_logic;
      data_std      : std_logic_vector(USR_DATA-1 downto 0); 
      ctrl          : std_logic_vector(GTCTRL_W-1 downto 0); 
      ctrl_pre      : std_logic_vector(GTCTRL_W-1 downto 0); 
      data_prbs     : std_logic_vector(USR_DATA-1 downto 0);
      data          : std_logic_vector(USR_DATA-1 downto 0);
      is_comma      : std_logic; --:= '0';
      was_comma     : std_logic; --:= '0';
      was_comma_pre : std_logic; --:= '0';
      is_m_comma    : std_logic; --:= '0';
      is_x_comma    : std_logic; --:= '0';
  end record;
  type gen_array_t is array (natural range <>) of gen_t;
  constant GEN_INIT : gen_t := (
    rst_main      => '0',
    rst_vio       => '0',
    data_std      => (others => '0'),
    ctrl          => (others => '0'),
    ctrl_pre      => (others => '0'),
    data_prbs     => (others => '0'),
    data          => (others => '0'),
    is_comma      => '0',
    was_comma     => '0',
    was_comma_pre => '0',
    is_m_comma    => '0',
    is_x_comma    => '0'
  );
  
  -- data encoding
  type enc_t is record 
      bypass        : std_logic; -- must be synced with tx_usrclk, bypass the encoder to send a clock-like pattern
      disp_out      : std_logic;  
      disp_in       : std_logic;  
      tx_data       : std_logic_vector(SER_DATA-1 downto 0); 
      fixed_seq_vio : std_logic;
      comma_fix_vio : std_logic; -- used to override the comma encoding to maintain its parity. causes parity errors
      bypass_vio    : std_logic; --:= '0'
  end record;
  type enc_array_t is array (natural range <>) of enc_t;
  constant ENC_INIT : enc_t := (
    bypass        => '0',
    disp_out      => '0',
    disp_in       => '0',
    tx_data       => (others => '0'),
    fixed_seq_vio => '0',
    comma_fix_vio => '0',
    bypass_vio    => '0'
  );
  
  -- txpi top level signals for interconnection
  type txpi_t is record 
     acc_phase         : std_logic_vector(15 downto 0);
     acc_phase_pre_cal : std_logic_vector(15 downto 0);
     first_rst_phase   : std_logic_vector(6 downto 0);
     calib_reg_phase   : std_logic_vector(6 downto 0);
     ui_align_calib    : std_logic; --:= '0';
     ali_calib_vio     : std_logic; --:= '0'; -- needs to start at '0'
     fine_realign      : std_logic; --:= '0';
     fine_realign_vio  : std_logic; --:= '0';
     step_done         : std_logic; --:= '0';
     step_done_stiky   : std_logic; --:= '0';
     aligned           : std_logic; --:= '0';
     fifo_fill_pd      : std_logic_vector(31 downto 0); 
  end record;
  type txpi_array_t is array (natural range <>) of txpi_t;
  constant TXPI_INIT : txpi_t := (
    acc_phase         => (others => '0'),
    acc_phase_pre_cal => (others => '0'),
    first_rst_phase   => (others => '0'),
    calib_reg_phase   => (others => '0'),
    ui_align_calib    => '0',
    ali_calib_vio     => '0',
    fine_realign      => '0',
    fine_realign_vio  => '0',
    step_done         => '0',
    step_done_stiky   => '0',
    aligned           => '0',
    fifo_fill_pd      => (others => '0')
  );
  
  -- comma detection
  type comma_det_parts_t is record 
     x_comma : std_logic; --:= '0';
     p_comma : std_logic; --:= '0';
     m_comma : std_logic; --:= '0';
  end record;
  type comma_det_t is record 
     rx: comma_det_parts_t;
     tx: comma_det_parts_t;
  end record;
  type comma_det_array_t is array (natural range <>) of comma_det_t;
  constant COM_PT_INIT : comma_det_parts_t := (
    x_comma => '0',
    p_comma => '0',
    m_comma => '0'
  );
  constant COM_INIT : comma_det_t := (
    rx => COM_PT_INIT,
    tx => COM_PT_INIT
  );
  
  -- Rx data check
  type rx_check_t is record 
     data              : std_logic_vector(USR_DATA-1 downto 0);
     error             : std_logic_vector(USR_DATA-1 downto 0);
     data_reg          : std_logic_vector(USR_DATA-1 downto 0);
     valid             : std_logic; --:= '0';  
     valid_comma_frame : std_logic; --:= '0';
     valid_std         : std_logic; --:= '0';
     tx_fixed_seq      : std_logic; --:= '0';
  end record;
  type rx_check_array_t is array (natural range <>) of rx_check_t;
  constant CHK_INIT : rx_check_t := (
    data              => (others => '0'),
    error             => (others => '0'),
    data_reg          => (others => '0'),
    valid             => '0',
    valid_comma_frame => '0',
    valid_std         => '0',
    tx_fixed_seq      => '0'
  );
  
  -- GT resets
  type gtrst_t is record 
     gt_reset_nolock      : std_logic; 
     block_nolock_rst     : std_logic; 
     block_ali_odd_rst    : std_logic; -- := '0';
     rst_dp_not_pll       : std_logic;
     rxreset_from_ali     : std_logic;
     rxreset_from_ali_sys : std_logic;
     rxreset_datapath     : std_logic; -- := '0'; 
     rxreset_datapath_vio : std_logic;
     rxreset_datapath_q   : std_logic; -- := '0';
     rxreset_vio          : std_logic; --:= '0';
     txreset_datapath     : std_logic; -- := '0'; 
     txreset_datapath_vio : std_logic;
     txreset_datapath_q   : std_logic; -- := '0';
     txreset_vio          : std_logic; --:= '0';
     gt_reset_all_vio     : std_logic;
     aligned_sys          : std_logic;
     rxrdy_sys            : std_logic;
     ali_en_sys           : std_logic; -- := '1';
     nolock_cnt           : integer range 0 to 1e9; --:= 0;
  end record;
  type gtrst_array_t is array (natural range <>) of gtrst_t;
  constant GTRST_INIT : gtrst_t := (
    gt_reset_nolock      => '0',
    block_nolock_rst     => '0',
    block_ali_odd_rst    => '0',
    rst_dp_not_pll       => '0',
    rxreset_from_ali     => '0',
    rxreset_from_ali_sys => '0',
    rxreset_datapath     => '0',
    rxreset_datapath_vio => '0',
    rxreset_datapath_q   => '0',
    rxreset_vio          => '0',
    txreset_datapath     => '0',
    txreset_datapath_vio => '0',
    txreset_datapath_q   => '0',
    txreset_vio          => '0',
    gt_reset_all_vio     => '0',
    aligned_sys          => '0',
    rxrdy_sys            => '0',
    ali_en_sys           => '1',
    nolock_cnt           =>  0 
  );
  
  -- rx aligner
  type rx_align_t is record 
     slide            : std_logic; --:= '0';
     vio_slide        : std_logic; --:= '0';
     vio_single_slide : std_logic; --:= '0'; 
     slide_cnt        : std_logic_vector(8 downto 0); 
     odds_cnt         : std_logic_vector(8 downto 0); 
     lol_cnt          : std_logic_vector(8 downto 0);
     aligned          : std_logic;
     avoid_odd_rst    : std_logic;
     -- rx aligner enable - ethernet addresses selection - multi Zynq (group1 [1, Tx], group2 [2, Rx] or VIO [0])
     ali_disable_vio  : std_logic; -- := '0';
     ali_en           : std_logic; -- := '1';
     ---debug from fsm aligner
     st               : std_logic_vector(2 downto 0); 
     align_cnt        : std_logic_vector(9 downto 0);
     rst_timeout      : std_logic;
  end record;
  type rx_align_array_t is array (natural range <>) of rx_align_t;
  constant ALI_INIT : rx_align_t := (
    slide            => '0',
    vio_slide        => '0',
    vio_single_slide => '0',
    slide_cnt        => (others => '0'),
    odds_cnt         => (others => '0'),
    lol_cnt          => (others => '0'),
    aligned          => '0',
    avoid_odd_rst    => '0',
    ali_disable_vio  => '0',
    ali_en           => '1',
    st               => (others => '0'),
    align_cnt        => (others => '0'),
    rst_timeout      => '0'
  );

end package gt_pkg;

package body gt_pkg is

  function or_reduce_shared_pll_rst(in_record: gt_stat_array_t; active: integer_array) return std_logic is
    variable reset : std_logic_vector(in_record'length-1 downto 0) := (others => '0');
  begin
    for i in in_record'range loop
        if active(i) > -1 then
            reset(i) := not(in_record(i).txplllock); 
        end if;
    end loop;
    return or_reduce(reset);
  end function or_reduce_shared_pll_rst;
  
end package body gt_pkg;
