----------------------------------------------------------------------------------
-- Company: CERN - HPTD
-- Engineer: Edoardo Orzes
-- 
-- Last edit: 6/10/2026

-- This is a general project for timing studies on GTH / GTY transceivers
-- It allows to instantiate a generic number of lanes and DMTDs

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.gt_pkg.all;
use work.gdmtd_pkg.all;
use work.arrays_pkg.all; 

library unisim;
use unisim.vcomponents.all;

entity m_top is
  port(
    clk_freerun_p   : in  std_logic;  -- system clock (freerun)
    clk_freerun_n   : in  std_logic;

    -- GT lanes
    gt_refclk_p : in  std_logic_vector(QUAD_N-1 downto 0);  -- reference clock (240 MHz)
    gt_refclk_n : in  std_logic_vector(QUAD_N-1 downto 0);
    gt_rx_p     : in  std_logic_vector(  GT_N-1 downto 0);
    gt_rx_n     : in  std_logic_vector(  GT_N-1 downto 0);
    gt_tx_p     : out std_logic_vector(  GT_N-1 downto 0);
    gt_tx_n     : out std_logic_vector(  GT_N-1 downto 0);
    
    -- I/O Clocking
    rxUserClk_p   : out std_logic;  -- 240MHz RxUsrClk of GT0 (for Jitter Cleaner)
    rxUserClk_n   : out std_logic;

--    ddmtdclk_in_p  : in std_logic;  -- 239.997...MHz LVDS DDMTD helper clock from jitter cleaner
--    ddmtdclk_in_n  : in std_logic;

--    beat_DRx_p : in std_logic; -- beat0_p
--    beat_DRx_n : in std_logic; -- beat0_n
--    beat_DTx_p : in std_logic; -- beat1_p
--    beat_DTx_n : in std_logic; -- beat1_n
--    beat_URx_p : in std_logic; -- beat2_p
--    beat_URx_n : in std_logic; -- beat2_n
--    beat_UTx_p : in std_logic; -- beat3_p
--    beat_UTx_n : in std_logic; -- beat3_n

    -- phase shifter out
--    ps_clk_o   : out std_logic;
--    ps_s_o     : out std_logic;
--    ps_le_o    : out std_logic;
--    ps_oe_o    : out std_logic;
    
    -- Zynq SFP enables
--    SFP1_enable : out std_logic;
--    SFP2_enable : out std_logic;
    
    -- Versal Prime SFP enables
    SFP0_enable : out std_logic;
    SFP1_enable : out std_logic;
    
    -- UDP Interface for controlling the FPGA from the computer with AXI-Ethernet
    eth_gtrefclk_p : in std_logic; -- 156.25MHz
    eth_gtrefclk_n : in std_logic;
    
    -- Ethernet SFP lane
    txn_eth_sfp : out std_logic;
    txp_eth_sfp : out std_logic;
    rxn_eth_sfp : in  std_logic;
    rxp_eth_sfp : in  std_logic;
    -- IIC
    sda : inout std_logic;
    scl : inout std_logic
  );
end m_top;

architecture rtl of m_top is

  -- choose number of GTs and QUADs 
  constant GT_N    : integer := GT_N;    -- to be set in gt_pkg
  constant QUAD_N  : integer := QUAD_N;  -- to be set in gt_pkg
  constant DDMTD_N : integer := DDMTD_N; -- to be set in gt_pkg
  
  constant USR_DATA : integer := USR_DATA; -- to be set in gt_pkg
  constant SER_DATA : integer := SER_DATA; -- to be set in gt_pkg
  
  -- GT array signals are mapped into QUADs channels by QUADs_GTs_map: (QUAD_index => (CH0, CH1, CH2, CH3)), in CHn set the GT index from GT_N arrays, -1 for unused channel
  constant QUADs_GTs_map : QUADs_GTs_map_t(0 to QUAD_N-1)(0 to 3) := (0 => (0,1,-1,-1));
  constant QUADs_BUF_map : integer_array(  0 to QUAD_N-1)         := (0 =>  0);          -- BUFG_GT dest (quad id) => BUFG_GT source (quad id)
  constant QUADs_MTXs    : integer_array(  0 to QUAD_N-1)         := (0 =>  0);          -- each QUAD has a GT which shares txusrclk (0 to 3)
  
  constant SIM_DEVICE    : string := "VERSAL_PRIME";
  
  -- system clocks
  signal clk_sys_free_buf : std_logic;
  signal clk_sys_125      : std_logic;
  signal clk_sys_gt       : std_logic;
  signal clk_sys_rdy      : std_logic;
  signal clk_sys_rdy_sync : std_logic;

  -- GT arrays
  signal gt_ctrl   : gt_ctrl_array_t(GT_N-1 downto 0) := (others => GT_CTRL_NULL);
  signal gt_stat   : gt_stat_array_t(GT_N-1 downto 0);
  signal to_gt     : to_gt_array_t(GT_N-1 downto 0);
  signal from_gt   : from_gt_array_t(GT_N-1 downto 0);

  -- AXI records
  signal from_axi : from_axi_t;
  signal to_axi   : to_axi_t;

  -- controls arrays
  
  -- data generator
  signal data_gen              : gen_array_t(GT_N-1 downto 0);
  signal shared_gen_rst        : std_logic;
  signal shared_gen_data_std   : std_logic_vector(USR_DATA-1 downto 0); 
  signal shared_gen_ctrl       : std_logic_vector( 3 downto 0);
  signal shared_data_prbs      : std_logic_vector(USR_DATA-1 downto 0);

  -- comma_detection
  signal comma_det: comma_det_array_t(GT_N-1 downto 0) := (others => COM_INIT);

  -- data encoding
  signal encoder   : enc_array_t(GT_N-1 downto 0) := (others => ENC_INIT);
  constant COMMA   : std_logic_vector(7 downto 0) := x"BC"; 
  constant P_COMMA : std_logic_vector(9 downto 0) := "0101111100"; -- defined in transceiver wizard > comma encoding
  constant M_COMMA : std_logic_vector(9 downto 0) := "1010000011"; -- defined in transceiver wizard > comma encoding

  -- txpi
  signal txpi : txpi_array_t(GT_N-1 downto 0) := (others => TXPI_INIT);

  -- rx data check
  signal rx_check : rx_check_array_t(GT_N-1 downto 0) := (others => CHK_INIT);

  -- GT resets
  signal gt_resets : gtrst_array_t(GT_N-1 downto 0) := (others => GTRST_INIT);
  signal block_dp_rst : std_logic_vector(0 to QUAD_N-1):= (others => '0');
  
  -- rx alignment logic
  signal rx_aligner : rx_align_array_t(GT_N-1 downto 0) := (others => ALI_INIT);

  -- clocks
  signal reset_clk_sys  : std_logic; -- resets GT and AXI through mmcm lock
  signal qpll_refclk    : std_logic;
  signal refclk         : std_logic;
  signal rxUserClk      : std_logic;
  signal recclk40       : std_logic;
  signal clk_heater     : std_logic;
  signal axi_rx_clk     : std_logic_vector(GT_N-1 downto 0) := (others => '0');
  signal axi_tx_clk     : std_logic_vector(GT_N-1 downto 0) := (others => '0');
  signal eth_gt_sys_clk : std_logic;
  signal clk_pcs_pma    : std_logic;
  signal pcspmaclk_lock : std_logic;

  -- temperature log and control
  signal temperature   : std_logic_vector(31 downto 0);
  signal heater_enable : std_logic;
  signal heater_en_vio : std_logic;
  
  --DDMTDs
  signal to_dmtds : to_dmtd_array_t(DDMTD_N-1 downto 0);
  
  --Ethernet
  signal eth_addr_sel : std_logic_vector(2 downto 0) := "000";

  ---debug
  signal refclk_freq : std_logic_vector(7 downto 0);
  signal txpi_done   : std_logic_vector(GT_N-1 downto 0) := (others => '0');
    
begin

  -- Versal prime SFP
  SFP0_enable <= '1'; -- SFP on the right (when FMCs are on the right)
  SFP1_enable <= '0'; 

  gt_signals: for i in 0 to GT_N-1 generate
  
      rx_aligner(i).ali_en <= not(rx_aligner(i).ali_disable_vio) and from_axi.to_gt(i).rx_aligner_en;
    
      gt_ctrl(i).gtwiz_reset_rx_datapath         <= gt_resets(i).rxreset_datapath_vio or from_axi.to_gt(i).rx_reset_dp or (gt_resets(i).rxreset_from_ali_sys and gt_resets(i).rst_dp_not_pll); 
      gt_ctrl(i).gtwiz_reset_rx_pll_and_datapath <= gt_resets(i).rxreset_vio or from_axi.to_gt(i).rx_reset or gt_resets(i).gt_reset_nolock or (gt_resets(i).rxreset_from_ali_sys and not(gt_resets(i).rst_dp_not_pll));
      
      gt_ctrl(i).gtwiz_reset_tx_datapath         <= gt_resets(i).txreset_datapath_vio or from_axi.to_gt(i).tx_reset_dp; 
      gt_ctrl(i).gtwiz_reset_tx_pll_and_datapath <= gt_resets(i).txreset_vio or from_axi.to_gt(i).tx_reset;
      
      gt_ctrl(i).gtwiz_reset_all <= not(clk_sys_rdy_sync) or gt_resets(i).gt_reset_all_vio or from_axi.to_gt(i).reset_all;
      
      gt_ctrl(i).rxslide <= rx_aligner(i).slide or rx_aligner(i).vio_single_slide;
      
--      gt_ctrl(i).txpippmen <= '0';
--      gt_ctrl(i).txpippmstepsize <= (others => '0');
      
      to_gt(i).txpi <= from_axi.to_gt(i).txpi;
      --to_axi.from_gt(i).txpi <= from_gt(i).txpi; -- txpi signals assigned to axi below tx_phase_aligner
      
      to_axi.from_gt(i).bb_tx_done        <= gt_stat(i).buffbypass_tx_done;
      to_axi.from_gt(i).txbufstatus       <= gt_stat(i).txbufstatus;
      to_axi.from_gt(i).pslverr_o         <= from_gt(i).pslverr_o;
      to_axi.from_gt(i).timeout           <= from_gt(i).timeout; 
      
      to_axi.from_gt(i).logic.data_valid  <= rx_check(i).valid;       -- from data checker (based on test sequence sent by data generator)
      to_axi.from_gt(i).logic.rx_aligned  <= rx_aligner(i).aligned;  -- from FSM_Aligner (should remain true when valid is false due to switching to illegal clock-like pattern)
      to_axi.from_gt(i).logic.slide_count <= rx_aligner(i).slide_cnt;  -- from FSM_Aligner: count of bit slide used to frame align with the 8b10b comma x"BC"
      to_axi.from_gt(i).logic.odds_count  <= rx_aligner(i).odds_cnt;   -- from FSM_Aligner: count of resets sent by FSM_Aligner to have an even number of slideCount
      to_axi.from_gt(i).logic.lol_count   <= rx_aligner(i).lol_cnt;    -- from FSM_Aligner: count of lost of alignment registered by the rx aligner FSM   
      to_axi.temp                         <= temperature; -- Die temperature from BandGap SYSMON sensor, averaged over 250 values eavenly spread in a 10s window
      
      -- Rx GT Equalizer configuration
      gt_ctrl(i).rxlpmgchold     <= from_axi.to_gt(i).gt_eq.lpmgc(1); --axi_gpio_ctrl_async(11)
      gt_ctrl(i).rxlpmgcovrden   <= from_axi.to_gt(i).gt_eq.lpmgc(0); --axi_gpio_ctrl_async(10)
      gt_ctrl(i).rxlpmhfhold     <= from_axi.to_gt(i).gt_eq.lpmhf(1); --axi_gpio_ctrl_async( 9)
      gt_ctrl(i).rxlpmhfovrden   <= from_axi.to_gt(i).gt_eq.lpmhf(0); --axi_gpio_ctrl_async( 8)
      gt_ctrl(i).rxlpmlfklhold   <= from_axi.to_gt(i).gt_eq.lpmlf(1); --axi_gpio_ctrl_async( 7)
      gt_ctrl(i).rxlpmlfklovrden <= from_axi.to_gt(i).gt_eq.lpmlf(0); --axi_gpio_ctrl_async( 6)
      gt_ctrl(i).rxlpmoshold     <= from_axi.to_gt(i).gt_eq.lpmos(1); --axi_gpio_ctrl_async( 5)
      gt_ctrl(i).rxlpmosovrden   <= from_axi.to_gt(i).gt_eq.lpmos(0); --axi_gpio_ctrl_async( 4)
      -- 
  end generate gt_signals;
  
  sys_clk_inst: entity work.clk_buf
    port map (
      i  => clk_freerun_p,  
      ib => clk_freerun_n,  
      o  => clk_sys_free_buf
    );
  sys_clks_gen_inst : entity work.sys_clks_gen
   port map ( 
    clk_out_125     => clk_sys_125,
    clk_out_gt      => clk_sys_gt,
    clk_out_pcs_pma => clk_pcs_pma,    
--    clk_out_heater  => clk_heater,
    reset           => '0',
    locked          => clk_sys_rdy,
    clk_in_200      => clk_sys_free_buf
   );
   bit_synch_rdy_to_gtsys: entity work.bit_sync
    port map (
        clk      => clk_sys_gt,
        async_in => clk_sys_rdy,  
        sync_out => clk_sys_rdy_sync     
    ); 
  bit_synch_rdy_to_pcspma: entity work.bit_sync
    port map (
        clk      => clk_pcs_pma,
        async_in => clk_sys_rdy,  
        sync_out => pcspmaclk_lock     
    ); 
  
------------------------------------------------------------------------
----- Main GT - Tx data generator & 8b10b encoder & data checker & rx aligner
------------------------------------------------------------------------   
  
  gt_data_handlers: for i in 0 to GT_N-1 generate
  
       -- data generator
      gen_inst: entity work.data_generator
        generic map ( USER_W => USR_DATA )
        port map(
          rst_i   => data_gen(i).rst_main, 
          clk_i   => from_gt(i).tx_usrclk,
          data_o  => data_gen(i).data_std,
          ctrl_o  => data_gen(i).ctrl
        );
          
      data_gen(i).is_comma <= '1' when data_gen(i).ctrl = "0001" else '0';
      data_gen(i).data <= data_gen(i).data_std when encoder(i).fixed_seq_vio = '1' else (data_gen(i).data_prbs(USR_DATA-1 downto 8) & COMMA when data_gen(i).was_comma = '1' else data_gen(i).data_prbs);
      PRBS_module_core_31_gen : entity work.axis_prbs
        generic map ( NBITS => USR_DATA )
        port map (
            reset        => data_gen(i).rst_main,
            clock        => from_gt(i).tx_usrclk,
            s_prbs_tdata => (others => '0'),
            s_prbs_tvalid => '1',
            s_prbs_tready => open,
            m_prbs_tdata  => data_gen(i).data_prbs, -- one cycle delay
            m_prbs_tvalid => open,
            m_prbs_tready => not(data_gen(i).is_comma)
        );
            data_gen(i).rst_main <= not(from_gt(i).tx_rdy) or data_gen(i).rst_vio;
  
      enc_inst: entity work.multibyte_enc8b10b
        generic map ( NBR => 4 ) --2
        port map(
          clk_i         => from_gt(i).tx_usrclk,
          --ctrl_i        => data_gen(i).ctrl(1 downto 0) when encoder(i).fixed_seq_vio = '1' else data_gen(i).ctrl_pre(1 downto 0), -- about comma encoding
          ctrl_i        => data_gen(i).ctrl(3 downto 0) when encoder(i).fixed_seq_vio = '1' else data_gen(i).ctrl_pre(3 downto 0), -- about comma encoding
          data_i        => data_gen(i).data,
          rundp_o       => encoder(i).disp_out,
          rundp_i       => encoder(i).disp_in,
          bypass_en_i   => encoder(i).bypass,
          bypass_data_i => x"FFFFF00000", --x"FFC00", 
          data_o        => encoder(i).tx_data
        );
          encoder(i).disp_in <= encoder(i).disp_out;
          encoder(i).bypass  <= encoder(i).bypass_vio or from_axi.to_gt(i).tx_enc_bypass;
      
      pre_comma_reg: process(from_gt(i).tx_usrclk) begin
          if rising_edge(from_gt(i).tx_usrclk) then
              data_gen(i).was_comma     <= data_gen(i).is_comma;
              data_gen(i).was_comma_pre <= data_gen(i).was_comma;
              data_gen(i).ctrl_pre      <= data_gen(i).ctrl;
          end if;
      end process;
      to_gt(i).tx_data <= encoder(i).tx_data(SER_DATA-1 downto 10) & P_COMMA when (encoder(i).comma_fix_vio = '1' and data_gen(i).was_comma_pre = '1' and encoder(i).bypass = '0' and encoder(i).fixed_seq_vio = '0') else encoder(i).tx_data;
      data_gen(i).is_m_comma <= '1' when  to_gt(i).tx_data(9 downto 0) = M_COMMA else '0';
      data_gen(i).is_x_comma <= '1' when (to_gt(i).tx_data(9 downto 0) = P_COMMA or data_gen(i).is_m_comma = '1') else '0';
      
      check_inst: entity work.data_checker
        generic map ( USER_W => USR_DATA )
        port map(
          rst_i     => not(rx_aligner(i).aligned),
          clk_i     => from_gt(i).rx_usrclk,
          comDet    => comma_det(i).rx.p_comma or comma_det(i).rx.m_comma, --from_gt(0).rx_ctrl2(0),
          aligned   => rx_aligner(i).aligned,  
          data_in   => from_gt(i).rx_data,
          valid     => rx_check(i).valid_std,
          data_gen  => rx_check(i).data
        );
      PRBS_module_core_31_check : entity work.axis_prbs
        generic map (
            CHK_MODE => 1,
            NBITS    => USR_DATA
        ) port map (
            reset         => not(rx_aligner(i).aligned),
            clock         => from_gt(i).rx_usrclk,
            s_prbs_tdata  => from_gt(i).rx_data,
            s_prbs_tvalid => not(comma_det(i).rx.x_comma),
            s_prbs_tready => open,
            m_prbs_tdata  => rx_check(i).error,
            m_prbs_tvalid => open,
            m_prbs_tready => '1'
        );
      reg_rx_data: process(from_gt(i).rx_usrclk) begin
        if rising_edge(from_gt(i).rx_usrclk) then
            rx_check(i).data_reg <= from_gt(i).rx_data;
        end if;
      end process;
      rx_check(i).valid_comma_frame <= '1' when from_gt(i).rx_data = (rx_check(i).data_reg(USR_DATA-1 downto 8) & COMMA) else '0';
      rx_check(i).valid <= rx_check(i).valid_std when rx_check(i).tx_fixed_seq = '1' else (not(or_reduce(rx_check(i).error)) when comma_det(i).rx.x_comma = '0' else rx_check(i).valid_comma_frame);
      
      comma_det(i).rx.x_comma <= from_gt(i).rx_ctrl0(0) and ('1' when from_gt(i).rx_data(7 downto 0) = COMMA else '0');
      comma_det(i).rx.m_comma <= from_gt(i).rx_ctrl2(0);
      comma_det(i).rx.p_comma <= not(comma_det(i).rx.m_comma) and comma_det(i).rx.x_comma;
      
      fsm_aligner_inst: entity work.fsm_aligner
       generic map ( USER_WIDTH => USR_DATA )
       port map(
         clk             => from_gt(i).rx_usrclk,
         rst             => not(from_gt(i).rx_rdy),
         en              => rx_aligner(i).ali_en, -- en default to 0, on Rx FPGA has to be manually set to 1 from switch or VIO.
         rxdata          => from_gt(i).rx_data,
         ctrl            => comma_det(i).rx.p_comma or comma_det(i).rx.m_comma, --from_gt(i).rx_ctrl2,
         allow_odd_rst   => not(rx_aligner(i).avoid_odd_rst),
         rxSlide         => rx_aligner(i).slide,
         slideCount      => rx_aligner(i).slide_cnt,
         oddsCount       => rx_aligner(i).odds_cnt,
         byteAligned     => rx_aligner(i).aligned,  
         rxreset_out     => gt_resets(i).rxreset_from_ali,
         lolCount        => rx_aligner(i).lol_cnt,
         -- debug purpose
         st   => rx_aligner(i).st,
         aliC => rx_aligner(i).align_cnt,
         r_t  => rx_aligner(i).rst_timeout
       );
     
     bit_synch1_rx_to_sys: entity work.bit_sync
        port map ( clk => clk_sys_gt, async_in => gt_resets(i).rxreset_from_ali, sync_out => gt_resets(i).rxreset_from_ali_sys ); 
     bit_synch2_rx_to_sys: entity work.bit_sync
        port map ( clk => clk_sys_gt, async_in => rx_aligner(i).aligned, sync_out => gt_resets(i).aligned_sys ); 
     bit_synch3_rx_to_sys: entity work.bit_sync
        port map ( clk => clk_sys_gt, async_in => from_gt(i).rx_rdy, sync_out => gt_resets(i).rxrdy_sys ); 
     bit_synch4_rx_to_sys: entity work.bit_sync
        port map ( clk => clk_sys_gt, async_in => rx_aligner(i).ali_en, sync_out => gt_resets(i).ali_en_sys ); 
        
      -- If the Main GT Rx does not start or if it does not align, then after 8 seconds the GT is reset.
      GT_reset: process(clk_sys_gt) begin
        if rising_edge(clk_sys_gt) then
            if (gt_resets(i).rxrdy_sys = '0' or gt_resets(i).aligned_sys = '0') and gt_resets(i).ali_en_sys = '1' then
                gt_resets(i).nolock_cnt <= gt_resets(i).nolock_cnt + 1;
            elsif gt_resets(i).aligned_sys = '1' then
                gt_resets(i).nolock_cnt <= 0;
            end if;
        end if;
      end process;
      gt_resets(i).gt_reset_nolock <= '1' when (gt_resets(i).block_nolock_rst = '0' and gt_resets(i).nolock_cnt = 1e9) else '0';
  
  end generate gt_data_handlers;

  quads_inst: entity work.quads_chs_map 
    generic map ( QUADs_GTs_map => QUADs_GTs_map, QUADs_N => QUAD_N, GTs_N => GT_N, QUADs_BUF_map => QUADs_BUF_map, MTX => QUADs_MTXs, SIM_DEVICE => SIM_DEVICE ) 
    port map(
      clk_sys     => clk_sys_gt,
      gt_refclk_p => gt_refclk_p,
      gt_refclk_n => gt_refclk_n,
      gt_rx_p     => gt_rx_p,   
      gt_rx_n     => gt_rx_n, 
      gt_tx_p     => gt_tx_p,   
      gt_tx_n     => gt_tx_n, 
      gt_ctrl_i   => gt_ctrl, 
      gt_stat_o   => gt_stat, 
      gt_i        => to_gt,   
      gt_o        => from_gt,
      refclk_o    => refclk,
      txpi_done_i => txpi_done
    );
    
  drpclks: for i in 0 to GT_N-1 generate
      gt_ctrl(i).drpclk <= clk_sys_gt;
  end generate drpclks;
  
  bit_sync_tx_to_sys_gen: for i in 0 to GT_N-1 generate
      to_axi.from_gt(i).tx_rdy     <= from_gt(i).tx_rdy_sys;
      to_axi.from_gt(i).tx_rdy_sys <= from_gt(i).tx_rdy_sys;
  end generate bit_sync_tx_to_sys_gen;
  
  txpi_done_map: for i in 0 to GT_N-1 generate
      bit_synch_txpi_done: entity work.bit_sync
        port map ( clk => clk_sys_gt, async_in => txpi(i).aligned, sync_out => txpi_done(i) ); 
  end generate txpi_done_map;

------------------------------------------------------------------------
----- I/O Clocking
------------------------------------------------------------------------

  rxuserclk_d_oddr_inst: entity work.oddr
    port map(
      clk_in  => from_gt(0).rx_usrclk,
      clk_out => rxUserClk
    );
  obufds_inst : obufds
    port map (
      O  => rxUserClk_p, 
      OB => rxUserClk_n,
      I  => rxUserClk 
    );

------------------------------------------------------------------------
----- Tx Phase Aligner
------------------------------------------------------------------------

  txpi_gen: for i in 0 to GT_N-1 generate
  
  tx_aligner_inst: entity work.tx_phase_aligner
   generic map (
      -- User choice of DRP control or port control
      -- Recommended nowadays to use in DRP control as a strange behaviour was observed using the port in PI code stepping mode
      g_DRP_NPORT_CTRL        => true,  --! Uses DRP control of port control for the transmitter PI
      g_DRP_ADDR_TXPI_PPM_CFG => ("010011010")  --! Check the transceiver user guide of your device for this address               
    ) port map (
      --==============================================================================
      --! User control/monitor ports - clk_sys
      --==============================================================================    
      -- Clock / reset                                                       
      clk_sys_i => clk_sys_gt,           --! system clock input
      reset_i   => not(from_gt(i).tx_rdy_sys) or to_gt(i).txpi.hold_rst, --! active high sync. reset (recommended to keep reset_i=1 while transceiver reset initialization is being performed)

      -- Top level interface                                                 
      tx_aligned_o => txpi(i).aligned,  --! Use it as a reset for the user transmitter logic

      -- Config (for different flavours)
      tx_pi_phase_calib_i   => txpi(i).first_rst_phase, --! previous calibrated tx pi phase (tx_pi_phase_o after first reset calibration)
      tx_ui_align_calib_i   => txpi(i).ui_align_calib, --! align with previous calibrated tx pi phase
      tx_fifo_fill_pd_max_i => x"00040000",  --! phase detector accumulated max output, sets precision of phase detector
                                             --! this is supposedly a static signal, this block shall be reset whenever this signal changes
                                             --! the time for each phase detection after a clear is given by tx_fifo_fill_pd_max_i * PERIOD_clk_txusr_i
      tx_fine_realign_i     => txpi(i).fine_realign,  --! A rising edge will cause the Tx to perform a fine realignment to the half-response

      -- It is only valid to re-shift clock once aligned (tx_aligned_o = '1') 
      ps_strobe_i     => to_gt(i).txpi.ctrl(0), --! pulse synchronous to clk_sys_i to activate a shift in the phase (only captured rising edge, so a signal larger than a pulse is also fine)
      ps_inc_ndec_i   => to_gt(i).txpi.ctrl(5),  --! 1 increments phase by phase_step_i units, 0 decrements phase by phase_step_i units
      ps_phase_step_i => to_gt(i).txpi.ctrl(4 downto 1), --! number of units to shift the phase of the receiver clock (see Xilinx transceiver User Guide to convert units in time)       
      ps_done_o       => txpi(i).step_done,  --! pulse synchronous to clk_sys_i to indicate a phase shift was performed

      -- Tx PI phase value
      tx_pi_phase_o => txpi(i).acc_phase(6 downto 0),  --! phase shift accumulated
      tx_pi_phase_pre_cal_o => txpi(i).acc_phase_pre_cal(6 downto 0),  --! phase shift accumulated before UI alignment

      -- Tx fifo fill level phase detector                                   
      tx_fifo_fill_pd_o => txpi(i).fifo_fill_pd, --! phase detector output, when aligned this value should be close to (0x2_0000)

      --==============================================================================
      --! MGT ports - tx_usrclk
      --==============================================================================
      clk_txusr_i          => from_gt(i).tx_usrclk,  --! txusr2clk                
      -- Tx fifo fill level - see Xilinx transceiver User Guide for more information      
      tx_fifo_fill_level_i => gt_stat(i).txbufstatus(0),  --! connect to txbufstatus[0]

      -- Transmitter PI ports - see Xilinx transceiver User Guide for more information
      -- obs1: all txpi ports shall be connected to the transceiver even when using this block in DRP-mode                
      txpippmen_o       => gt_ctrl(i).txpippmen,  --! enable tx phase interpolator controller
      txpippmovrden_o   => gt_ctrl(i).txpippmovrden,  --! enable DRP control of tx phase interpolator
      txpippmsel_o      => gt_ctrl(i).txpippmsel,  --! set to 1 when using tx pi ppm controler
      txpippmpd_o       => gt_ctrl(i).txpippmpd,  --! power down transmitter phase interpolator 
      txpippmstepsize_o => gt_ctrl(i).txpippmstepsize,  --! sets step size and direction of phase shift with port control PI code stepping mode

      -- DRP interface - see Xilinx transceiver User Guide for more information
      -- obs2: connect clk_sys_i to drpclk
      -- obs3: if using this block in port-mode, DRP output can be left floating and input connected to '0'               
      drpaddr_o => gt_ctrl(i).drpaddr(8 downto 0),  --! For devices with a 10-bit DRP address interface, connect MSB to '0'
      drpen_o   => gt_ctrl(i).drpen,         --! DRP enable transaction
      drpdi_o   => gt_ctrl(i).drpdi,  --! DRP data write
      drprdy_i  => gt_stat(i).drprdy,          --! DRP finished transaction
      drpdo_i   => gt_stat(i).drpdo,  --! DRP data read; not used nowadays, write only interface
      drpwe_o   => gt_ctrl(i).drpwe      --! DRP write enable
    );
    --gt_ctrl(1).drpclk <= clk_sys_gt; already connected, cpll requires it
    txpi(i).ui_align_calib <= to_gt(i).txpi.ali_calib; --or vio_txpi_ali_calib; -- if '0' does calib (first reset), if '1' uses that calibration to UI align (most precise way).
    txpi(i).fine_realign   <= to_gt(i).txpi.fine_realign; --or vio_txpi_fine_realign;
    
    to_axi.from_gt(i).txpi.acc_phase <= txpi(i).acc_phase;
    to_axi.from_gt(i).txpi.step_done <= txpi(i).step_done_stiky;
    to_axi.from_gt(i).txpi.ali_done  <= txpi(i).aligned;
    
    to_axi.from_gt(i).txpi.acc_phase_pre_cal <= txpi(i).acc_phase_pre_cal;
    to_axi.from_gt(i).txpi.fifo_fill_pd      <= txpi(i).fifo_fill_pd;
    
  process(clk_sys_gt) begin
    if rising_edge(clk_sys_gt) then
        if txpi(i).ui_align_calib = '0' then
            txpi(i).first_rst_phase <= txpi(i).acc_phase(6 downto 0);
        end if;
    end if;
  end process;
  
  process(clk_sys_gt) begin
    if rising_edge(clk_sys_gt) then
        if txpi(i).step_done = '1' then
            txpi(i).step_done_stiky <= '1';
        elsif to_gt(i).txpi.ctrl(0) = '0' or from_gt(i).tx_rdy_sys = '0' or to_gt(i).txpi.hold_rst = '1' then
            txpi(i).step_done_stiky <= '0';
        end if;
    end if;
  end process;
  
--    ila_drp_inst: entity work.ila_drp
--    port map(
--      clk           => clk_sys_gt,
--      probe0(0)     => gt_ctrl(i).txpippmen,
--      probe1        => gt_ctrl(i).drpaddr(8 downto 0),
--      probe2(0)     => gt_ctrl(i).drpen,        
--      probe3        => gt_ctrl(i).drpdi,  
--      probe4        => gt_stat(i).drpdo, 
--      probe5(0)     => gt_stat(i).drprdy,
--      probe6(0)     => gt_ctrl(i).drpwe,
--      probe7(0)     => gt_ctrl(i).txpippmovrden, 
--      probe8(0)     => gt_ctrl(i).txpippmsel, 
--      probe9(0)     => gt_ctrl(i).txpippmpd,
--      probe10       => gt_ctrl(i).txpippmstepsize,
--      probe11       => gt_stat(i).txbufstatus
--  );   
  
  end generate txpi_gen;
  
------------------------------------------------------------------------
----- DDMTD Phase measuremet(s)
------------------------------------------------------------------------

--    to_dmtds(0).hold_rst      <= from_axi.dmtd_hold_rst(0);              
--    to_dmtds(0).dmtd_clk_p    <= ddmtdclk_in_p;                          
--    to_dmtds(0).dmtd_clk_n    <= ddmtdclk_in_n;                          
--    to_dmtds(0).beat_a_p      <= from_gt(0).rx_usrclk;                             
--    to_dmtds(0).beat_b_p      <= from_gt(0).tx_usrclk;                  
--    to_dmtds(0).n_avg         <= to_unsigned(512, 12);
    
--    to_dmtds(1).hold_rst      <= from_axi.dmtd_hold_rst(1);                          
----    to_dmtds(1).beat_a_p      <= from_gt(0).rx_usrclk;                             
----    to_dmtds(1).beat_b_p      <= from_gt(1).tx_usrclk;                  
--    to_dmtds(1).n_avg         <= to_unsigned(512, 12);
    
--    to_dmtds(2).hold_rst      <= from_axi.dmtd_hold_rst(2);                      
--    to_dmtds(2).beat_a_p      <= from_gt(1).rx_usrclk;                             
--    to_dmtds(2).beat_b_p      <= from_gt(1).tx_usrclk;                  
--    to_dmtds(2).n_avg         <= to_unsigned(512, 12);
    
--    to_dmtds(3).hold_rst      <= from_axi.dmtd_hold_rst(3);                          
--    to_dmtds(3).beat_a_p      <= beat_DRx_p;
--    to_dmtds(3).beat_a_n      <= beat_DRx_n;  
--    to_dmtds(3).beat_b_p      <= beat_UTx_p;
--    to_dmtds(3).beat_b_n      <= beat_UTx_n;     
--    to_dmtds(3).word_clk_a    <= from_gt(0).rx_usrclk;           
--    to_dmtds(3).info_a(0)     <= comma_det(0).rx.m_comma;
--    to_dmtds(3).word_clk_b    <= from_gt(0).tx_usrclk;           
--    to_dmtds(3).info_b(0)     <= data_gen(0).is_m_comma;       
--    to_dmtds(3).n_avg         <= to_unsigned(512, 12);
    
--    to_dmtds(4).hold_rst      <= from_axi.dmtd_hold_rst(4);                          
----    to_dmtds(4).beat_a_p      <= beat_DRx_p;
----    to_dmtds(4).beat_a_n      <= beat_DRx_n;  
----    to_dmtds(4).beat_b_p      <= beat_UTx_p;
----    to_dmtds(4).beat_b_n      <= beat_UTx_n;     
----    to_dmtds(4).word_clk_a    <= from_gt(0).rx_usrclk;           
----    to_dmtds(4).info_a(0)     <= comma_det(0).rx.m_comma;
----    to_dmtds(4).word_clk_b    <= from_gt(0).tx_usrclk;           
----    to_dmtds(4).info_b(0)     <= data_gen(0).is_m_comma;       
--    to_dmtds(4).n_avg         <= to_unsigned(512, 12);
    
--    to_dmtds(5).hold_rst      <= from_axi.dmtd_hold_rst(5);                          
--    to_dmtds(5).beat_a_p      <= beat_URx_p;
--    to_dmtds(5).beat_a_n      <= beat_URx_n;  
--    to_dmtds(5).beat_b_p      <= beat_DTx_p;
--    to_dmtds(5).beat_b_n      <= beat_DTx_n;     
--    to_dmtds(5).word_clk_a    <= from_gt(1).rx_usrclk;           
--    to_dmtds(5).info_a(0)     <= comma_det(1).rx.m_comma;
--    to_dmtds(5).word_clk_b    <= from_gt(1).tx_usrclk;           
--    to_dmtds(5).info_b(0)     <= data_gen(1).is_m_comma;       
--    to_dmtds(5).n_avg         <= to_unsigned(512, 12);
           
--   DDMTDs_wrap : entity work.dmtds_wrap
--    generic map ( GDMTD_N => DDMTD_N) 
--    port map ( 
--      clk_sys   => clk_sys_125,
--      dmtds_in  => to_dmtds,
--      dmtds_out => to_axi.from_dmtds
--    );
   
   avg_dmonitors : for i in 0 to GT_N-1 generate
     dmonitor_average: entity work.average
      generic map (
        IN_BITS     => 7,
        OUT_BITS    => 32,
        AVG_BITS    => 15,
        DECIMATION  => 30,
        SYNC_IN     => false
      ) port map ( 
        rst          => '0',
        src_clk      => '0', --gt_stat(i).dmonitoroutclk_buf,
        clk          => gt_stat(i).dmonitoroutclk_buf, --from_gt(i).rx_usrclk,
        clk_sys      => clk_sys_125,
        data_i       => gt_stat(i).dmonitorout(6 downto 0),
        n_avg        => to_unsigned(512*32, 15),
        new_meas_p_o => open,
        new_sum_p_o  => open,
        meas_o       => to_axi.from_rxpi(i).single(31 downto 0),
        sum_o        => to_axi.from_rxpi(i).sum,
        var_o        => to_axi.from_rxpi(i).var,
        max_o        => to_axi.from_rxpi(i).max,
        min_o        => to_axi.from_rxpi(i).min
      );
    end generate;
    
--   ila_rxpi_dmon: entity work.ila_rxpi
--    port map(
--      clk    => gt_stat(0).dmonitoroutclk_buf,
--      probe0 => gt_stat(0).dmonitorout
--    );  
    
------------------------------------------------------------------------
----- Phase Shifter Controller
------------------------------------------------------------------------

--   phase_shifter_controller: entity work.pe44820_ctrl
--    port map ( 
--      clk_i  => clk_sys_125,
--      rst_i  => '0',
--      ctrl_i => from_axi.pe_ctrl,
--      clk_o  => ps_clk_o,
--      s_o    => ps_s_o,
--      le_o   => ps_le_o
--    );
    
  
------------------------------------------------------------------------
----- AXI - Ethernet Interface
------------------------------------------------------------------------
    
   axi_gt_clks_gen : for i in 0 to GT_N-1 generate
      axi_rx_clk(i) <= from_gt(i).rx_usrclk;
      axi_tx_clk(i) <= from_gt(i).tx_usrclk;
   end generate axi_gt_clks_gen;
   
   AXI_inst: entity work.AXI_interface
    generic map( GT_N => GT_N, DDMTD_N => DDMTD_N )
    port map( 
      -- Ethernet lane
      eth_gtrefclk_p => eth_gtrefclk_p,
      eth_gtrefclk_n => eth_gtrefclk_n,
      txn_eth_sfp => txn_eth_sfp,
      txp_eth_sfp => txp_eth_sfp,
      rxn_eth_sfp => rxn_eth_sfp,
      rxp_eth_sfp => rxp_eth_sfp,
      -- Virtex PHY
--      phy_resetb  => open,--phy_resetb,
--      phy_mdio    => open,--phy_mdio,
--      phy_mdc     => open,--phy_mdc,
      -- Versal QUAD clock
      apb3clk_quad => eth_gt_sys_clk,
      -- Ethernet addresses selection
      eth_addr_sel => eth_addr_sel,
      -- IIC
      sda => sda,
      scl => scl,
      -- data and clocks
      clk_sys     => clk_sys_125,
      clk_sys_gt  => clk_sys_gt,
      clk_pcs_pma => clk_pcs_pma,
      clk_lock    => pcspmaclk_lock,
      rxusrclk    => axi_rx_clk, --from_gt(1).rx_usrclk & from_gt(0).rx_usrclk,
      txusrclk    => axi_tx_clk, --from_gt(1).tx_usrclk & from_gt(0).tx_usrclk,
      to_axi      => to_axi,
      from_axi    => from_axi
    );
    eth_gt_sys_clk <= clk_sys_gt;
    
    
------------------------------------------------------------------------
----- Heater 
------------------------------------------------------------------------
    
  heater_inst: entity work.heater_wrap
    generic map (
		N_DEVICES   => 40,
		BLOCK_SCALE => 3
    ) port map (
		rdy  => clk_sys_rdy, -- async
		ctrl => from_axi.heat_ctrl
    );
    
------------------------------------------------------------------------
----- CIPS & Temperature
------------------------------------------------------------------------ 

    cips_temp_inst: entity work.cips_axi_temp
     port map (
        clk          => clk_sys_125,
        rstn         => clk_sys_rdy,
        temp_sum_out => temperature  -- valid after 10s from startup
    );
    
------------------------------------------------------------------------
----- Debug cores and other debug circuitry
------------------------------------------------------------------------ 
  
dbg_gen: for i in 0 to GT_N-1 generate

  ila_tx_inst_0: entity work.ila_1
    port map(
      clk           => from_gt(i).tx_usrclk,
      probe0        => data_gen(i).data,
      probe1        => to_gt(i).tx_data,
      probe2(0)     => encoder(i).bypass
  );   

--  ila_rx_inst: entity work.ila_0
--    port map(
--      clk           => from_gt(i).rx_usrclk,
--      probe0        => from_gt(i).rx_data,
--      probe1        => from_gt(i).rx_ctrl0, -- rxbyte is a K character
--      probe2(0)     => gt_resets(i).rxreset_from_ali,
--      probe3(0)     => rx_check(i).valid,
--      probe4        => rx_check(i).data,
--      probe5(0)     => rx_aligner(i).aligned, 
--      probe6(0)     => gt_ctrl(i).rxslide,
--      probe7        => from_gt(i).rx_ctrl2,
--      probe8        => rx_aligner(i).slide_cnt,
--      probe9        => rx_aligner(i).st,
--      probe10(0)    => comma_det(i).rx.x_comma,
--      probe11       => rx_aligner(i).odds_cnt,
--      probe12(0)    => rx_check(i).valid_comma_frame,
--      probe13       => rx_aligner(i).align_cnt,
--      probe14       => rx_aligner(i).lol_cnt,
--      probe15(0)    => rx_aligner(i).ali_en,
--      probe16       => rx_check(i).error,
--      probe17(0)    => comma_det(i).rx.p_comma,
--      probe18(0)    => comma_det(i).rx.m_comma,
--      probe19       => rx_check(i).data_reg
--  );
    
  vio_sys_inst: entity work.vio_0
    port map(
      clk           => clk_sys_gt,  
      probe_in0     => refclk_freq,
      probe_in1(0)  => gt_stat(i).gtpowergood,                    
      probe_in2(0)  => gt_stat(i).txplllock,                      
      probe_in3(0)  => gt_stat(i).txpmaresetdone,                 
      probe_in4(0)  => gt_stat(i).rxpmaresetdone,                 
      probe_in5(0)  => gt_ctrl(i).gtwiz_reset_tx_datapath,        
      probe_in6(0)  => gt_ctrl(i).gtwiz_reset_rx_datapath,        
      probe_in7(0)  => gt_ctrl(i).gtwiz_reset_tx_pll_and_datapath,
      probe_in8(0)  => gt_ctrl(i).gtwiz_reset_rx_pll_and_datapath,
      probe_in9(0)  => gt_ctrl(i).gtwiz_reset_all,                
      probe_in10(0) => clk_sys_rdy_sync,                          
      probe_out0(0) => gt_resets(i).rxreset_vio,
      probe_out1(0) => gt_resets(i).txreset_vio,
      probe_out2(0) => gt_resets(i).rxreset_datapath_vio,
      probe_out3(0) => gt_resets(i).txreset_datapath_vio,
      probe_out4(0) => gt_resets(i).gt_reset_all_vio,
      probe_out5(0) => gt_resets(i).block_nolock_rst,  -- '1' to ignore the reset from a 7 seconds counter that checks if GT is locked
      probe_out6(0) => gt_resets(i).block_ali_odd_rst, -- '1' to ignore the reset from the Rx word aligner logic (to reset on odd bit slips)
      probe_out7(0) => gt_ctrl(i).block_dp_rst,        -- '1' to reset the datapsths of GTs in a QUAD when one GT in that quad is reset, non used in Versal (resets are shared in a QUAD)
      probe_out8(0) => gt_resets(i).rst_dp_not_pll,    -- '1' to reset only the datapath from the Rx word aligner logic
      probe_out9(0) => open 
    );
    bit_synch_sys_to_rx: entity work.bit_sync
        port map ( clk => from_gt(i).rx_usrclk, async_in => gt_resets(i).block_ali_odd_rst, sync_out => rx_aligner(i).avoid_odd_rst ); 
        
--    rx_aligner(i).avoid_odd_rst       <= '1';

--    gt_resets(i).rxreset_vio          <= '0';
--    gt_resets(i).txreset_vio          <= '0';
--    gt_resets(i).rxreset_datapath_vio <= '0';
--    gt_resets(i).txreset_datapath_vio <= '0';
--    gt_resets(i).gt_reset_all_vio     <= '0';
--    gt_resets(i).block_nolock_rst     <= '1';
--    gt_resets(i).block_ali_odd_rst    <= '1';
--    gt_ctrl(i).block_dp_rst           <= '1';
--    gt_resets(i).rst_dp_not_pll       <= '1';
    
  vio_tx_inst: entity work.vio_1
    port map(
      clk           => from_gt(i).tx_usrclk,
      probe_in0(0)  => data_gen(i).rst_main, 
      probe_in1(0)  => from_gt(i).tx_rdy,    
      probe_in2(0)  => encoder(i).bypass,    
      probe_out0(0) => data_gen(i).rst_vio,      -- '1' to reset the data generator for the Tx data stream
      probe_out1(0) => encoder(i).bypass_vio,    -- '1' to bypass the external 8b10b encoder (of Tx) to send a clock patter for oscilloscope phase measurements
      probe_out2(0) => encoder(i).comma_fix_vio, -- '1' to send to Tx a modified data where the 8b10b commas are overridden by a constant comma (this breaks 8b10b encoding)
      probe_out3(0) => encoder(i).fixed_seq_vio  -- '1' to Tx a periodic data pattern (which produces constant commas) instead of PRBS pattern (PRBS pattern is properly modified with 8b10b commas)
    );  

--    data_gen(i).rst_vio      <= '0';
--    encoder(i).bypass_vio    <= '0';
--    encoder(i).comma_fix_vio <= '0';
--    encoder(i).fixed_seq_vio <= '0';

--   vio_rx_inst: entity work.vio_1
--    port map(
--      clk           => from_gt(i).rx_usrclk,
--      probe_in0(0)  => from_gt(i).rx_rdy,
--      probe_in1(0)  => rx_aligner(i).ali_en,   
--      probe_in2(0)  => rx_aligner(i).avoid_odd_rst,   
--      probe_out0(0) => rx_aligner(i).ali_disable_vio,
--      probe_out1(0) => rx_aligner(i).vio_slide,
--      probe_out2(0) => rx_check(i).tx_fixed_seq,
--      probe_out3(0) => open
--    );
--    rx_aligner(i).ali_disable_vio <= '1'; -- disables the fsm_aligner_inst (Rx word aligner logic), Rx are active in the QUAD but not used
    
  end generate dbg_gen;
  
--   vio_rx_0_inst: entity work.vio_1
--    port map(
--      clk           => from_gt(0).rx_usrclk,
--      probe_in0(0)  => from_gt(0).rx_rdy,
--      probe_in1(0)  => rx_aligner(0).ali_en,   
--      probe_in2(0)  => rx_aligner(0).avoid_odd_rst,   
--      probe_out0(0) => rx_aligner(0).ali_disable_vio,
--      probe_out1(0) => rx_aligner(0).vio_slide,
--      probe_out2(0) => rx_check(0).tx_fixed_seq,
--      probe_out3(0) => open
--    );

    rx_aligner(0).ali_disable_vio <= '0';
    rx_aligner(0).vio_slide       <= '0';
    rx_check(0).tx_fixed_seq      <= '0';

    rx_aligner(1).ali_disable_vio <= '1'; -- disables the fsm_aligner_inst (Rx word aligner logic), Rx are active in the QUAD but not used
    
   ila_rx0_0_inst: entity work.ila_0
    port map(
      clk           => from_gt(0).rx_usrclk,
      probe0        => from_gt(0).rx_data,
      probe1        => from_gt(0).rx_ctrl0, -- rxbyte is a K character
      probe2(0)     => gt_resets(0).rxreset_from_ali,
      probe3(0)     => rx_check(0).valid,
      probe4        => rx_check(0).data,
      probe5(0)     => rx_aligner(0).aligned, 
      probe6(0)     => gt_ctrl(0).rxslide,
      probe7        => from_gt(0).rx_ctrl2,
      probe8        => rx_aligner(0).slide_cnt,
      probe9        => rx_aligner(0).st,
      probe10(0)    => comma_det(0).rx.x_comma,
      probe11       => rx_aligner(0).odds_cnt,
      probe12(0)    => rx_check(0).valid_comma_frame,
      probe13       => rx_aligner(0).align_cnt,
      probe14       => rx_aligner(0).lol_cnt,
      probe15(0)    => rx_aligner(0).ali_en,
      probe16       => rx_check(0).error,
      probe17(0)    => comma_det(0).rx.p_comma,
      probe18(0)    => comma_det(0).rx.m_comma,
      probe19       => rx_check(0).data_reg
  );
  
  freq_meas_ref : entity work.clock_monitor_full
    port map (
      clk_ref         => clk_sys_gt, -- The reference clock
      clk_monitored   => refclk, -- The clock to measure
      measured_period => refclk_freq
    );

  mono_gen: for i in 0 to GT_N-1 generate
      mono_inst: entity work.monostable
        port map (
          rst       => '0',
          clk       => from_gt(i).rx_usrclk,
          data_in   => rx_aligner(i).vio_slide,
          pulse_out => rx_aligner(i).vio_single_slide
        );
  end generate mono_gen;
        
end architecture;

