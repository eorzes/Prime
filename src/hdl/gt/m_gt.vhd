library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.gt_pkg.all;
use work.arrays_pkg.all; 

library unisim;
use unisim.vcomponents.all;

entity m_gt is
  generic (
    ACTIVE_CHs   : integer_array := (0, -1, -1, -1);
    N_CH         : positive:=4;
    MTX          : positive range 0 to 3:= 0;
    rx_rdy_delay : integer := 10; --64 * 1024 * 1024 - 1;
    tx_rdy_delay : integer := 10; --64 * 1024 * 1024 - 1;
    SIM_DEVICE   : string  := "VERSAL_PREMIUM"
  );
  port(
    clk_sys     : in  std_logic;
    gt_refclk   : in  std_logic;
    gt_rx_p     : in  std_logic_vector(0 to N_CH-1);
    gt_rx_n     : in  std_logic_vector(0 to N_CH-1);
    gt_tx_p     : out std_logic_vector(0 to N_CH-1);
    gt_tx_n     : out std_logic_vector(0 to N_CH-1);
    gt_ctrl_i   : in  gt_ctrl_array_t (0 to N_CH-1);
    gt_stat_o   : out gt_stat_array_t (0 to N_CH-1);
    gt_i        : in  to_gt_array_t   (0 to N_CH-1);
    gt_o        : out from_gt_array_t (0 to N_CH-1);
    txpi_done   : in  std_logic_vector(0 to N_CH-1)
  );
end m_gt;

architecture rtl of m_gt is
  
  signal gt_stat              : gt_stat_array_t( 0 to 3);
  
  signal gt_out               : from_gt_array_t(0 to 3);
  signal gt_stat_drp          : gt_stat_array_t(0 to 3);
  signal from_apb3            : from_apb3_t := FROM_APB3_INIT;
  signal to_apb3              : to_apb3_t   := TO_APB3_INIT;
  
  signal tx_bb                : tx_manual_bb_array_t(0 to N_CH-1);
  signal txsync               : std_logic_vector(0 to N_CH-1); 
                                               
  signal shared_pll_was_rst   : std_logic := '0';
  signal shared_pll_was_rst_p : std_logic := '0';
  signal shared_pll_rst_stiky : std_logic_vector(0 to N_CH-1) := (others => '0');
  signal rst_dp_shared_pll    : std_logic_vector(0 to N_CH-1) := (others => '0');
                                             
  signal txoutclk             : std_logic_vector(0 to N_CH-1);    
  signal txusrclk             : std_logic_vector(0 to N_CH-1);    
  signal txusrclk_m           : std_logic;      
                                                
  signal rxoutclk             : std_logic_vector(0 to N_CH-1);    
  signal rxusrclk             : std_logic_vector(0 to N_CH-1);     
  
  signal tx_data              : array_nb(0 to N_CH-1)(19 downto 0); --39  
  
  signal rxresetdone_o        : std_logic_vector(0 to N_CH-1);    
  signal txresetdone_o        : std_logic_vector(0 to N_CH-1);  
  signal rxresetdone_usrclk   : std_logic_vector(0 to N_CH-1);
  signal txresetdone_usrclk   : std_logic_vector(0 to N_CH-1); 
  
  signal dmon_cnt_dbg : unsigned(4 downto 0) := (others => '0');
  
  signal addr_i          : std_logic_vector(15 downto 0);
  signal write_i         : std_logic;
  signal start_i         : std_logic;
  signal wdata_i         : std_logic_vector(31 downto 0);
  signal rdata_o         : std_logic_vector(31 downto 0);
  signal busy_o          : std_logic;
  signal done_o          : std_logic;
  signal slverr_o        : std_logic;
  signal timeout_error_o : std_logic;
  
  signal vio_apb3paddr   : std_logic_vector(15 downto 0);
  signal vio_apb3psel    : std_logic;
  signal vio_apb3penable : std_logic;
  signal vio_apb3pwrite  : std_logic;
  signal vio_apb3pwdata  : std_logic_vector(31 downto 0);
  
  signal to_apb3_drp     : to_apb3_t := TO_APB3_INIT;

  signal vio_sel         : std_logic;

begin

  gt_o <= gt_out;
  gt_stat_o <= gt_stat;
    
  shared_pll_was_rst <= or_reduce_shared_pll_rst(gt_stat, ACTIVE_CHs);
  pll_was_rst_pulse: entity work.monostable
    port map (
        rst       => '0',
        clk       => clk_sys,
        data_in   => shared_pll_was_rst,
        pulse_out => shared_pll_was_rst_p
  );
  datapaths_reset: for i in 0 to 3 generate 
      process(clk_sys) begin
        if rising_edge(clk_sys) then 
            if shared_pll_was_rst_p = '1' then 
                shared_pll_rst_stiky(i) <= '1';
            end if;
            rst_dp_shared_pll(i) <= '1' when (gt_ctrl_i(i).block_dp_rst = '0' and shared_pll_rst_stiky(i) = '1' and gt_stat(i).txplllock = '1') else '0';
            if shared_pll_rst_stiky(i) = '1' and gt_stat(i).txplllock = '1' then
                shared_pll_rst_stiky(i) <= '0';
            end if;
        end if;
      end process;
  end generate datapaths_reset;
--  ila_dp_rst: entity work.ila_pe
--    port map(
--      clk       => clk_sys,
--      probe0(0) => shared_pll_was_rst_p,
--      probe1(0) => shared_pll_rst_stiky(0),
--      probe2(0) => shared_pll_rst_stiky(1),
--      probe3(0) => gt_stat(0).txplllock,
--      probe4(0) => shared_pll_was_rst,
--      probe5(0) => rst_dp_shared_pll(0),
--      probe6(0) => rst_dp_shared_pll(1)
--  ); 
    
    drp_to_apb3_map_inst: entity work.drp_to_apb3_map
      generic map( ACTIVE_CHs => ACTIVE_CHs )
      port map( 
          clk_i       => clk_sys,
          from_gt_i   => gt_out,
          to_gt_i     => gt_i,
          gt_ctrl_i   => gt_ctrl_i,
          gt_stat_o   => gt_stat_drp,
          from_apb3_i => from_apb3,
          to_apb3_o   => to_apb3_drp
      );
    drp_apb3_int: for i in 0 to 3 generate
        gt_stat(i).drpdo    <= gt_stat_drp(i).drpdo ;
        gt_stat(i).drprdy   <= gt_stat_drp(i).drprdy;
        gt_out(i).pslverr_o <= to_apb3.pslverr_o;
        gt_out(i).timeout   <= to_apb3.timeout  ;
    end generate drp_apb3_int;
    
        u_apb3 : entity work.apb3_controller
      generic map (
        ADDR_WIDTH     => 16,
        DATA_WIDTH     => 32,
        TIMEOUT_CYCLES => 1000
      )
      port map (
        clk             => clk_sys,
        rst             => not vio_sel,

        addr_i          => addr_i,
        write_i         => write_i,
        start_i         => start_i,
        wdata_i         => wdata_i,
        rdata_o         => rdata_o,
        busy_o          => busy_o,
        done_o          => done_o,
        slverr_o        => slverr_o,
        timeout_error_o => timeout_error_o,

        apb3paddr       => vio_apb3paddr,
        apb3psel        => vio_apb3psel,
        apb3penable     => vio_apb3penable,
        apb3pwrite      => vio_apb3pwrite,
        apb3pwdata      => vio_apb3pwdata,
        apb3prdata      => from_apb3.prdata,
        apb3pready      => from_apb3.pready,
        apb3pslverr     => from_apb3.pslverr
      );
      
  process(txpi_done)
    variable v : std_logic;
  begin
    v := '1';
    for i in 0 to N_CH-1 loop
      if ACTIVE_CHs(i) > -1 and txpi_done(i) = '0' then
        v := '0';
      end if;
    end loop;
    vio_sel <= v;
  end process;

  -- router: DRP master until alignment done, then VIO master
  to_apb3.paddr     <= vio_apb3paddr   when vio_sel = '1' else to_apb3_drp.paddr;
  to_apb3.psel      <= vio_apb3psel    when vio_sel = '1' else to_apb3_drp.psel;
  to_apb3.penable   <= vio_apb3penable when vio_sel = '1' else to_apb3_drp.penable;
  to_apb3.pwrite    <= vio_apb3pwrite  when vio_sel = '1' else to_apb3_drp.pwrite;
  to_apb3.pwdata    <= vio_apb3pwdata  when vio_sel = '1' else to_apb3_drp.pwdata;
  to_apb3.pslverr_o <= slverr_o        when vio_sel = '1' else to_apb3_drp.pslverr_o;
  to_apb3.timeout   <= timeout_error_o when vio_sel = '1' else to_apb3_drp.timeout;
      
   u_vio : entity work.vio_apb3
    port map (
      clk           => clk_sys,
      probe_out0    => addr_i,
      probe_out1(0) => write_i,
      probe_out2(0) => start_i,
      probe_out3    => wdata_i,
      probe_in0     => rdata_o,
      probe_in1(0)  => busy_o,
      probe_in2(0)  => done_o,
      probe_in3(0)  => slverr_o,
      probe_in4(0)  => timeout_error_o
    );

  ---------------------------
  -- clock scheme
  ---------------------------
  
  tx_usrclk_bufg_gt : bufg_gt
    generic map ( SIM_DEVICE => SIM_DEVICE )
    port map( 
      i       => txoutclk(MTX),
      o       => txusrclk_m,
      ce      => '1',     
      cemask  => '0',     
      clr     => '0',         
      clrmask => '0',     
      div     => "000"   
    );
    
  rx_usrclk_bufg_gt : bufg_gt 
    generic map ( SIM_DEVICE => SIM_DEVICE )
    port map( 
      i       => rxoutclk(0),
      o       => rxusrclk(0),
      ce      => '1',     
      cemask  => '0',     
      clr     => '0',     
      clrmask => '0',     
      div     => "000"   
    );
    
  ch: for i in 0 to N_CH-1 generate
  active_ch: if ACTIVE_CHs(i) > -1 generate
  
    txusrclk(i) <= txusrclk_m;
  
--    rx_usrclk_bufg_gt : bufg_gt 
--      generic map ( SIM_DEVICE => SIM_DEVICE )
--      port map( 
--        i       => rxoutclk(i),
--        o       => rxusrclk(i),
--        ce      => '1',     
--        cemask  => '0',     
--        clr     => '0',     
--        clrmask => '0',     
--        div     => "000"   
--       );
    
      cdc_resetdone_rx : entity work.cdc_bit
        port map(clk => rxusrclk(i), i => rxresetdone_o(i), o => rxresetdone_usrclk(i));
      cdc_resetdone_tx : entity work.cdc_bit         
        port map(clk => txusrclk(i), i => txresetdone_o(i), o => txresetdone_usrclk(i));
    
      -----------------------------
      p_rxrdy : process(rxusrclk(i))
        -----------------------------
        variable cnt : integer range 0 to rx_rdy_delay;
      begin
        if rising_edge(rxusrclk(i)) then
          if rxresetdone_usrclk(i) = '0' then
            gt_out(i).rx_rdy <= '0';
            cnt   := 0;
          elsif cnt = rx_rdy_delay then
            gt_out(i).rx_rdy <= '1';
          else
            gt_out(i).rx_rdy <= '0';
            cnt   := cnt + 1;
          end if;
        end if;
      end process;
    
      -----------------------------
      p_txrdy : process(txusrclk(i))
        -----------------------------
        variable cnt : integer range 0 to tx_rdy_delay;
      begin
        if rising_edge(txusrclk(i)) then
          if txresetdone_usrclk(i) = '0' then
            gt_out(i).tx_rdy <= '0';
            cnt   := 0;
          elsif cnt = tx_rdy_delay then
            gt_out(i).tx_rdy <= '1';
          else
            gt_out(i).tx_rdy <= '0';
            cnt   := cnt + 1;
          end if;
        end if;
      end process;
      
      bit_synch_tx_rdy: entity work.bit_sync
        port map (
            clk      => clk_sys,
            async_in => gt_out(i).tx_rdy,  
            sync_out => gt_out(i).tx_rdy_sys     
        ); 
    
      -----------------------------
      -- IO mapping
      -----------------------------
    
      gt_stat(i).gtwiz_reset_rx_done <= rxresetdone_o(i);
      gt_stat(i).gtwiz_reset_tx_done <= txresetdone_o(i);
    
      gt_out(i).rx_usrclk <= rxusrclk(i);
      gt_out(i).tx_usrclk <= txusrclk(i);
    
      gt_stat(i).gtwiz_buffbypass_rx_done  <= '1'; -- Versal GTYe5 hack
      gt_stat(i).gtwiz_buffbypass_rx_error <= '0' when gt_stat(i).rxbufstatus = "000" else '1';
                
  end generate active_ch;
  end generate ch;
  
  dmonitorclk_bufg_gt : bufg_gt 
      generic map ( SIM_DEVICE => SIM_DEVICE )
      port map( 
        i       => gt_stat(0).dmonitoroutclk,
        o       => gt_stat(0).dmonitoroutclk_buf,
        ce      => '1',     
        cemask  => '0',     
        clr     => '0',     
        clrmask => '0',     
        div     => "000"   
       );
       
   ila_rxpi_dmon: entity work.ila_rxpi
    port map(
      clk    => gt_stat(0).dmonitoroutclk_buf,
      probe0 => gt_stat(0).dmonitorout,
      probe1 => std_logic_vector(dmon_cnt_dbg)
    ); 
    
  process(gt_stat(0).dmonitoroutclk_buf) begin
      if rising_edge(gt_stat(0).dmonitoroutclk_buf) then
        if dmon_cnt_dbg = 31 then
            dmon_cnt_dbg <= to_unsigned(0, 5);
        else
            dmon_cnt_dbg <= dmon_cnt_dbg + 1;
        end if;
      end if;
  end process;
  
  gt_stat(0).rxplllock   <= gt_stat(0).txplllock;
  gt_stat(1).rxplllock   <= gt_stat(0).txplllock;
  gt_stat(1).gtpowergood <= gt_stat(0).gtpowergood;  -- see next item
      
  -----------------------------
  quad_inst : entity work.gty_system
  -----------------------------
    port map(      
        gtpowergood                        => gt_stat(0).gtpowergood,
        gtwiz_freerun_clk                  => clk_sys,
        QUAD0_GTREFCLK0                    => gt_refclk,
        QUAD0_apb3presetn                  => '1',
        QUAD0_apb3paddr                    => to_apb3.paddr,
        QUAD0_apb3penable                  => to_apb3.penable,
        QUAD0_apb3prdata                   => from_apb3.prdata,
        QUAD0_apb3psel                     => to_apb3.psel,
        QUAD0_apb3pslverr                  => from_apb3.pslverr,
        QUAD0_apb3pready                   => from_apb3.pready,
        QUAD0_apb3pwdata                   => to_apb3.pwdata,
        QUAD0_apb3pwrite                   => to_apb3.pwrite,

        QUAD0_TX0_outclk                   => txoutclk(0),
        QUAD0_TX1_outclk                   => txoutclk(1),
        QUAD0_RX0_outclk                   => rxoutclk(0),
        QUAD0_TX0_usrclk                   => txusrclk(0),
        QUAD0_TX1_usrclk                   => txusrclk(1),
        QUAD0_RX0_usrclk                   => rxusrclk(0),

        QUAD0_rxp(0)                       => gt_rx_p(0),
        QUAD0_rxp(3 downto 1)              => "000",
        QUAD0_rxn(0)                       => gt_rx_n(0),
        QUAD0_rxn(3 downto 1)              => "000",
        QUAD0_txp(0)                       => gt_tx_p(0),
        QUAD0_txp(1)                       => gt_tx_p(1),
        QUAD0_txp(3 downto 2)              => open,
        QUAD0_txn(0)                       => gt_tx_n(0),
        QUAD0_txn(1)                       => gt_tx_n(1),
        QUAD0_txn(3 downto 2)              => open,

        QUAD0_ch0_phyready                 => open,
        QUAD0_ch0_phyesmadaptsave          => '0',
        QUAD0_ch0_clkrsvd0                 => '0',
        QUAD0_ch0_clkrsvd1                 => '0',
        QUAD0_ch0_iloresetmask             => '0',
        QUAD0_ch0_loopback                 => (others => '0'),
        QUAD0_ch0_dmonfiforeset            => '0',
        QUAD0_ch0_pcsrsvdin                => (others => '0'),
        QUAD0_ch0_gtrsvd                   => (others => '0'),
        QUAD0_ch0_pcsrsvdout               => open,
        QUAD0_ch0_pinrsvdas                => open,
        QUAD0_ch0_resetexception           => open,
        QUAD0_ch0_hsdppcsreset             => '0',
        QUAD0_ch0_tstin                    => (others => '0'),
        QUAD0_hsclk0_lcplllock             => gt_stat(0).txplllock,
        QUAD0_ch0_dmonitorout              => gt_stat(0).dmonitorout,
        QUAD0_ch0_dmonitoroutclk           => gt_stat(0).dmonitoroutclk,
        QUAD0_ch0_dmonitorclk              => gt_stat(0).dmonitoroutclk_buf,

        INTF0_TX0_ch_txdata(39 downto 0)   => gt_i(0).tx_data(39 downto 0),
        INTF0_TX0_ch_txdata(127 downto 40) => (others => '0'),
        INTF0_TX0_ch_txbufstatus           => gt_stat(0).txbufstatus,
        INTF0_TX0_ch_txpmaresetdone(0)     => gt_stat(0).txpmaresetdone, 
        INTF0_TX0_ch_txrate                => (others => '0'),
        INTF0_TX0_ch_txpippmen(0)          => gt_ctrl_i(0).txpippmen,
        INTF0_TX0_ch_txctrl0(3 downto 0)   => gt_i(0).tx_ctrl0,
        INTF0_TX0_ch_txctrl0(15 downto 4)  => (others => '0'),
        INTF0_TX0_ch_txctrl1(3 downto 0)   => gt_i(0).tx_ctrl1,
        INTF0_TX0_ch_txctrl1(15 downto 4)  => (others => '0'),
        INTF0_TX0_ch_txctrl2(3 downto 0)   => gt_i(0).tx_ctrl2,
        INTF0_TX0_ch_txctrl2(7 downto 4)   => (others => '0'),
        INTF0_TX0_ch_txpippmstepsize       => gt_ctrl_i(0).txpippmstepsize,

        INTF0_RX0_ch_rxbufstatus           => gt_stat(0).rxbufstatus,
        INTF0_RX0_ch_rxpmaresetdone(0)     => gt_stat(0).rxpmaresetdone,
        INTF0_RX0_ch_rxrate                => (others => '0'),
        INTF0_RX0_ch_rxdata(31 downto 0)   => gt_out(0).rx_data(31 downto 0),
        INTF0_RX0_ch_rxdata(127 downto 32) => open,
        INTF0_RX0_ch_rxcommadet(0)         => open,
        INTF0_RX0_ch_rxbyteisaligned(0)    => gt_stat(0).rxbyteisaligned,
        INTF0_RX0_ch_rxbyterealign(0)      => gt_stat(0).rxbyterealign,
        INTF0_RX0_ch_rxctrl0(3 downto 0)   => gt_out(0).rx_ctrl0,
        INTF0_RX0_ch_rxctrl0(15 downto 4)  => open,
        INTF0_RX0_ch_rxctrl1(3 downto 0)   => gt_out(0).rx_ctrl1,
        INTF0_RX0_ch_rxctrl1(15 downto 4)  => open,
        INTF0_RX0_ch_rxctrl2(3 downto 0)   => gt_out(0).rx_ctrl2,
        INTF0_RX0_ch_rxctrl2(7 downto 4)   => open,
        INTF0_RX0_ch_rxctrl3(3 downto 0)   => gt_out(0).rx_ctrl3,
        INTF0_RX0_ch_rxctrl3(7 downto 4)   => open,
        INTF0_RX0_ch_rxslide(0)            => gt_ctrl_i(0).rxslide,

        INTF1_TX0_ch_txdata(39 downto 0)   => gt_i(1).tx_data(39 downto 0),
        INTF1_TX0_ch_txdata(127 downto 40) => (others => '0'),
        INTF1_TX0_ch_txbufstatus           => gt_stat(1).txbufstatus,
        INTF1_TX0_ch_txpmaresetdone(0)     => gt_stat(1).txpmaresetdone,
        INTF1_TX0_ch_txrate                => (others => '0'),
        INTF1_TX0_ch_txpippmen(0)          => gt_ctrl_i(1).txpippmen,
        INTF1_TX0_ch_txctrl0(3 downto 0)   => gt_i(1).tx_ctrl0,
        INTF1_TX0_ch_txctrl0(15 downto 4)  => (others => '0'),
        INTF1_TX0_ch_txctrl1(3 downto 0)   => gt_i(1).tx_ctrl1,
        INTF1_TX0_ch_txctrl1(15 downto 4)  => (others => '0'),
        INTF1_TX0_ch_txctrl2(3 downto 0)   => gt_i(1).tx_ctrl2,
        INTF1_TX0_ch_txctrl2(7 downto 4)   => (others => '0'),
        INTF1_TX0_ch_txpippmstepsize       => gt_ctrl_i(1).txpippmstepsize,

        INTF0_TX_clr_out                   => open,
        INTF0_TX_clrb_leaf_out             => open,
        INTF0_RX_clr_out                   => open,
        INTF0_RX_clrb_leaf_out             => open,
        INTF0_rst_all_in                   => gt_ctrl_i(0).gtwiz_reset_all,
        INTF0_rst_tx_pll_and_datapath_in   => gt_ctrl_i(0).gtwiz_reset_tx_pll_and_datapath,
        INTF0_rst_tx_datapath_in           => gt_ctrl_i(0).gtwiz_reset_tx_datapath or rst_dp_shared_pll(0),
        INTF0_rst_tx_done_out              => txresetdone_o(0),
        INTF0_rst_rx_pll_and_datapath_in   => gt_ctrl_i(0).gtwiz_reset_rx_pll_and_datapath,
        INTF0_rst_rx_datapath_in           => gt_ctrl_i(0).gtwiz_reset_rx_datapath or rst_dp_shared_pll(0),
        INTF0_rst_rx_done_out              => rxresetdone_o(0),

        INTF1_TX_clr_out                   => open,
        INTF1_TX_clrb_leaf_out             => open,
        INTF1_rst_all_in                   => gt_ctrl_i(1).gtwiz_reset_all,
        INTF1_rst_tx_pll_and_datapath_in   => gt_ctrl_i(1).gtwiz_reset_tx_pll_and_datapath,
        INTF1_rst_tx_datapath_in           => gt_ctrl_i(1).gtwiz_reset_tx_datapath or rst_dp_shared_pll(1),
        INTF1_rst_tx_done_out              => txresetdone_o(1)
    );

end rtl;
