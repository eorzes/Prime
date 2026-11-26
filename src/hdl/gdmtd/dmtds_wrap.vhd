library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;
use work.gdmtd_pkg.all;
use work.arrays_pkg.all; 

entity dmtds_wrap is
    generic ( GDMTD_N : integer := 2 );
    port ( 
        clk_sys   : in  std_logic;
        dmtds_in  : in  to_dmtd_array_t(GDMTD_N-1 downto 0);
        dmtds_out : out from_dmtd_array_t(GDMTD_N-1 downto 0)
    );
end dmtds_wrap;

architecture Behavioral of dmtds_wrap is

    constant OUT_BITS : integer := 28;

    signal beat_a       : std_logic_vector(GDMTD_N-1 downto 0);
    signal beat_b       : std_logic_vector(GDMTD_N-1 downto 0);
    signal dmtd_clk_in  : std_logic;
    signal dmtd_clk     : std_logic_vector(GDMTD_N-1 downto 0);
    signal ext_pulse_a  : std_logic_vector(GDMTD_N-1 downto 0);
    signal ext_pulse_b  : std_logic_vector(GDMTD_N-1 downto 0);
                                           
    signal dmtd_rst     : std_logic_vector(GDMTD_N-1 downto 0) := (others => '0');
    
    signal first_ali    : std_logic_vector(GDMTD_N-1 downto 0) := (others => '0');
    signal rst_ali      : std_logic_vector(GDMTD_N-1 downto 0) := (others => '0');
    signal dly_reg_i_a  : array_u_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    signal dly_reg_i_b  : array_u_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    signal dly_reg_o_a  : array_u_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    signal dly_reg_o_b  : array_u_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    
    -- dbg
    signal dly_reg_i_a_v : array_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    signal dly_reg_i_b_v : array_nb(GDMTD_N-1 downto 0)(9 downto 0) := (others => (others => '0'));
    signal cnt_p_phi     : integer_array(GDMTD_N-1 downto 0) := (others => 0);
    signal cnt_p_sum     : integer_array(GDMTD_N-1 downto 0) := (others => 0);
    signal cnt_p_phi_v   : array_nb(GDMTD_N-1 downto 0)(31 downto 0) := (others => (others => '0'));
    signal cnt_p_sum_v   : array_nb(GDMTD_N-1 downto 0)(31 downto 0) := (others => (others => '0'));

begin

--  fanout_buf_0a_inst: entity work.gt_buf
--    port map(
--      i     => dmtds_in(0).beat_a_p,  
--      ib    => dmtds_in(0).beat_a_n,
--      clk_o => beat_a(0)     
--    );
--  fanout_buf_0b_inst: entity work.gt_buf
--    port map(
--      i     => dmtds_in(0).beat_b_p,  
--      ib    => dmtds_in(0).beat_b_n,
--      clk_o => beat_b(0)              
--    );
--  fanout_buf_0a_inst: ibufds
--    port map(
--      i  => dmtds_in(0).beat_a_p,  
--      ib => dmtds_in(0).beat_a_n,
--      o  => beat_a(0)     
--    );
--  fanout_buf_0b_inst: ibufds
--    port map(
--      i  => dmtds_in(0).beat_b_p,  
--      ib => dmtds_in(0).beat_b_n,
--      o  => beat_b(0)              
--    );
--  fanout_buf_1a_inst: ibufds
--    port map(
--      i  => dmtds_in(1).beat_a_p,  
--      ib => dmtds_in(1).beat_a_n,
--      o  => beat_a(1)     
--    );
--    beat_a(1) <= '0';
--  fanout_buf_1b_inst: ibufds
--    port map(
--      i  => dmtds_in(1).beat_b_p,  
--      ib => dmtds_in(1).beat_b_n,
--      o  => beat_b(1)     
--    );
--    beat_b(1) <= '0';
--  fanout_buf_2a_inst: ibufds
--    port map(
--      i  => dmtds_in(2).beat_a_p,  
--      ib => dmtds_in(2).beat_a_n,
--      o  => beat_a(2)     
--    );
--    beat_a(2) <= '0';
--   fanout_buf_2b_inst: ibufds
--    port map(
--      i  => dmtds_in(2).beat_b_p,  
--      ib => dmtds_in(2).beat_b_n,
--      o  => beat_b(2)     
--    );

  beat_a(1) <= beat_b(2);
  beat_b(1) <= beat_a(0);

--  fanout_buf_3a_inst: ibufds
--    port map(
--      i  => dmtds_in(3).beat_a_p,  
--      ib => dmtds_in(3).beat_a_n,
--      o  => beat_a(3)     
--    );
--   fanout_buf_3b_inst: ibufds
--    port map(
--      i  => dmtds_in(3).beat_b_p,  
--      ib => dmtds_in(3).beat_b_n,
--      o  => beat_b(3)     
--    );
    
--    beat_a(4) <= beat_b(5);
--    beat_b(4) <= beat_a(3);
    
--  fanout_buf_5a_inst: ibufds
--    port map(
--      i  => dmtds_in(5).beat_a_p,  
--      ib => dmtds_in(5).beat_a_n,
--      o  => beat_a(5)     
--    );
--   fanout_buf_5b_inst: ibufds
--    port map(
--      i  => dmtds_in(5).beat_b_p,  
--      ib => dmtds_in(5).beat_b_n,
--      o  => beat_b(5)     
--    );

  resets: for i in 0 to GDMTD_N-1 generate
    bit_synch_dmtd: entity work.bit_sync
    port map (
        clk      => dmtd_clk(i),
        async_in => dmtds_in(i).hold_rst,
        sync_out => dmtd_rst(i)   
    );  
  end generate resets;
  
--  dmtdclk_buf_inst: entity work.gt_buf
--    port map(
--      i     => dmtds_in(0).dmtd_clk_p,  
--      ib    => dmtds_in(0).dmtd_clk_n,
--      clk_o => dmtd_clk_in     -- Only way to use a GT Ref as a GPIO: GBTCLK pins -> IBUFGTE4.odiv2 -> BUFG_GT -> logic
--    );
  dmtdclk_buf_inst: ibufds
    port map(
      i     => dmtds_in(0).dmtd_clk_p,  
      ib    => dmtds_in(0).dmtd_clk_n,
      o     => dmtd_clk_in   
    );
   dmtd_clk(0) <= dmtd_clk_in;
   dmtd_clk(1) <= dmtd_clk_in;
   dmtd_clk(2) <= dmtd_clk_in;
   dmtd_clk(3) <= dmtd_clk_in;
   dmtd_clk(4) <= dmtd_clk_in;
   dmtd_clk(5) <= dmtd_clk_in;

--ali_regs: for i in 0 to GDMTD_N-1 generate
--    process(dmtd_clk(i)) begin
--        if rising_edge(dmtd_clk(i)) then
--            if first_ali(i) = '1' then
--                dly_reg_i_a(i) <= dly_reg_o_a(i); 
--                dly_reg_i_b(i) <= dly_reg_o_b(i); 
--            end if;
--        end if;
--    end process;
--    dly_reg_i_a_v(i) <= std_logic_vector(dly_reg_i_a(i));
--    dly_reg_i_b_v(i) <= std_logic_vector(dly_reg_i_b(i));
--    vio_gen_g : if i>2 generate 
--        vio_delay: entity work.vio_dly
--            port map(
--                clk           => dmtd_clk(i),
--                probe_out0(0) => first_ali(i),
--                probe_in0     => dly_reg_i_a_v(i),
--                probe_in1     => dly_reg_i_b_v(i)
--            ); 
--     end generate vio_gen_g;
--  end generate ali_regs;
  
--  pulse_check: for i in 0 to GDMTD_N-1 generate
--      ila_pulses: entity work.ila_gd_p
--            port map(
--                clk       => clk_sys,
--                probe0(0) => dmtds_out(i).new_meas_p,
--                probe1(0) => dmtds_out(i).new_sum_p,
--                probe2    => dmtds_out(i).phase_count(OUT_BITS-1 downto 0),
--                probe3    => dmtds_out(i).phase_avg(OUT_BITS-1 downto 0),
--                probe4    => cnt_p_phi_v(i),
--                probe5    => cnt_p_sum_v(i)
--            ); 
--       process(clk_sys) begin
--        if rising_edge(clk_sys) then
--            if dmtds_out(i).new_meas_p = '1' then
--                cnt_p_phi(i) <= 0;
--            else
--                cnt_p_phi(i) <= cnt_p_phi(i) + 1;
--            end if;
--            if dmtds_out(i).new_sum_p = '1' then
--                cnt_p_sum(i) <= 0;
--            else
--                cnt_p_sum(i) <= cnt_p_sum(i) + 1;
--            end if;
--        end if;
--       end process;
--       cnt_p_phi_v(i) <= std_logic_vector(to_unsigned(cnt_p_phi(i), 32));
--       cnt_p_sum_v(i) <= std_logic_vector(to_unsigned(cnt_p_sum(i), 32)); 
--   end generate pulse_check;

   ddmtd0_inst: entity work.gdmtd
    generic map (
        N            => 100000,        
        OUT_BITS     => OUT_BITS, 
        GEN_VAR_DSP  => true,
        AVG_BITS     => 12, 
        DEGLITCH_A   => true,     
        DEGLITCH_B   => true,
        MIX_IN_A     => true,     
        MIX_IN_B     => true,
        DEBUG_CORES  => false,
        BRANCH_CFG_A => STD_CLOCK,        
        BRANCH_CFG_B => STD_CLOCK 
    ) port map (
        rst           => dmtd_rst(0),
        clk_sys       => clk_sys,
                     
        word_clk_a    => '0',
        word_clk_b    => '0',
        info_i_a(0)   => '0', 
        info_i_b(0)   => '0',
                 
        first_ali     => '0',
        delay_reg_i_a => "0000000000",
        delay_reg_i_b => "0000000000",
        delay_reg_o_a => open,
        delay_reg_o_b => open,
                    
        dmtd_clk      => dmtd_clk(0),
        sample_i_a    => dmtds_in(0).beat_a_p,
        sample_i_b    => dmtds_in(0).beat_b_p,
                    
        ext_pulse_i_a => '0',
        ext_pulse_i_b => '0',
        ext_pulse_o_a => ext_pulse_a(0),
        ext_pulse_o_b => ext_pulse_b(0),
                    
        n_avg         => dmtds_in(0).n_avg,
                    
        new_meas_p_o  => open,
        new_sum_p_o   => open,
        meas_o        => dmtds_out(0).phase_count(OUT_BITS-1 downto 0),
        meas_sum_o    => dmtds_out(0).phase_avg(OUT_BITS-1 downto 0),  
        nvar_o        => dmtds_out(0).stdv(OUT_BITS-1 downto 0),       
        max_o         => dmtds_out(0).max(OUT_BITS-1 downto 0),  
        min_o         => dmtds_out(0).min(OUT_BITS-1 downto 0),      
        glitches_o    => dmtds_out(0).glitches   
    );
        ext_pulse_a(1) <= ext_pulse_b(2);
        ext_pulse_b(1) <= ext_pulse_a(0);
        
   ddmtd1_inst: entity work.gdmtd
    generic map (
        N            => 100000,        
        OUT_BITS     => OUT_BITS, 
        GEN_VAR_DSP  => true,
        AVG_BITS     => 12, 
        DEGLITCH_A   => false,     
        DEGLITCH_B   => false,
        MIX_IN_A     => true,     
        MIX_IN_B     => true,
        DEBUG_CORES  => false,
        BRANCH_CFG_A => STD_CLOCK,        
        BRANCH_CFG_B => STD_CLOCK 
    ) port map (
        rst           => dmtd_rst(1),
        clk_sys       => clk_sys,
                     
        word_clk_a    => '0',
        word_clk_b    => '0',
        info_i_a(0)   => '0', 
        info_i_b(0)   => '0',
                 
        first_ali     => '0',
        delay_reg_i_a => "0000000000",
        delay_reg_i_b => "0000000000",
        delay_reg_o_a => open,
        delay_reg_o_b => open,
                    
        dmtd_clk      => dmtd_clk(1),
        sample_i_a    => dmtds_in(1).beat_a_p,
        sample_i_b    => dmtds_in(1).beat_b_p,
                    
        ext_pulse_i_a => ext_pulse_a(1),
        ext_pulse_i_b => ext_pulse_b(1),
        ext_pulse_o_a => open,
        ext_pulse_o_b => open,
                    
        n_avg         => dmtds_in(1).n_avg,
                    
        new_meas_p_o  => open,
        new_sum_p_o   => open,
        meas_o        => dmtds_out(1).phase_count(OUT_BITS-1 downto 0),
        meas_sum_o    => dmtds_out(1).phase_avg(OUT_BITS-1 downto 0),  
        nvar_o        => dmtds_out(1).stdv(OUT_BITS-1 downto 0),       
        max_o         => dmtds_out(1).max(OUT_BITS-1 downto 0),  
        min_o         => dmtds_out(1).min(OUT_BITS-1 downto 0),      
        glitches_o    => dmtds_out(1).glitches   
    );
    
--   ddmtd2_inst: entity work.gdmtd
--    generic map (
--        N            => 100000,        
--        OUT_BITS     => OUT_BITS, 
--        GEN_VAR_DSP  => true,
--        AVG_BITS     => 12, 
--        DEGLITCH_A   => true,     
--        DEGLITCH_B   => true,
--        MIX_IN_A     => true,     
--        MIX_IN_B     => true,
--        DEBUG_CORES  => false,
--        BRANCH_CFG_A => STD_CLOCK,        
--        BRANCH_CFG_B => STD_CLOCK 
--    ) port map (
--        rst           => dmtd_rst(2),
--        clk_sys       => clk_sys,
                     
--        word_clk_a    => '0',
--        word_clk_b    => '0',
--        info_i_a(0)   => '0', 
--        info_i_b(0)   => '0',
                 
--        first_ali     => '0',
--        delay_reg_i_a => "0000000000",
--        delay_reg_i_b => "0000000000",
--        delay_reg_o_a => open,
--        delay_reg_o_b => open,
                    
--        dmtd_clk      => dmtd_clk(2),
--        sample_i_a    => dmtds_in(2).beat_a_p,
--        sample_i_b    => dmtds_in(2).beat_b_p,
                    
--        ext_pulse_i_a => '0',
--        ext_pulse_i_b => '0',
--        ext_pulse_o_a => ext_pulse_a(2),
--        ext_pulse_o_b => ext_pulse_b(2),
                    
--        n_avg         => dmtds_in(2).n_avg,
                    
--        new_meas_p_o  => open,
--        new_sum_p_o   => open,
--        meas_o        => dmtds_out(2).phase_count(OUT_BITS-1 downto 0),
--        meas_sum_o    => dmtds_out(2).phase_avg(OUT_BITS-1 downto 0),  
--        nvar_o        => dmtds_out(2).stdv(OUT_BITS-1 downto 0),       
--        max_o         => dmtds_out(2).max(OUT_BITS-1 downto 0),  
--        min_o         => dmtds_out(2).min(OUT_BITS-1 downto 0),      
--        glitches_o    => dmtds_out(2).glitches   
--    );
        
--   ddmtd3_inst: entity work.gdmtd
--    generic map (
--        N            => 100000,        
--        OUT_BITS     => OUT_BITS, 
--        GEN_VAR_DSP  => true,
--        AVG_BITS     => 12, 
--        DEGLITCH_A   => true,     
--        DEGLITCH_B   => true,
--        MIX_IN_A     => false,     
--        MIX_IN_B     => false,
--        DEBUG_CORES  => false,
--        BRANCH_CFG_A => HEADER_8B10B_40_6,        
--        BRANCH_CFG_B => HEADER_8B10B_40_6 
--    ) port map (
--        rst           => dmtd_rst(3),
--        clk_sys       => clk_sys,
                     
--        word_clk_a    => dmtds_in(3).word_clk_a,
--        word_clk_b    => dmtds_in(3).word_clk_b,
--        info_i_a(0)   => dmtds_in(3).info_a(0), 
--        info_i_b(0)   => dmtds_in(3).info_b(0),
                 
--        first_ali     => first_ali(3),
--        delay_reg_i_a => dly_reg_i_a(3),
--        delay_reg_i_b => dly_reg_i_b(3),
--        delay_reg_o_a => dly_reg_o_a(3),
--        delay_reg_o_b => dly_reg_o_b(3),
                    
--        dmtd_clk      => dmtd_clk(3),
--        sample_i_a    => beat_a(3),
--        sample_i_b    => beat_b(3),
                    
--        ext_pulse_i_a => '0',
--        ext_pulse_i_b => '0',
--        ext_pulse_o_a => ext_pulse_a(3),
--        ext_pulse_o_b => ext_pulse_b(3),
                    
--        n_avg         => dmtds_in(3).n_avg,
                    
--        new_meas_p_o  => open,
--        new_sum_p_o   => open,
--        meas_o        => dmtds_out(3).phase_count(OUT_BITS-1 downto 0),
--        meas_sum_o    => dmtds_out(3).phase_avg(OUT_BITS-1 downto 0),  
--        nvar_o        => dmtds_out(3).stdv(OUT_BITS-1 downto 0),       
--        max_o         => dmtds_out(3).max(OUT_BITS-1 downto 0),  
--        min_o         => dmtds_out(3).min(OUT_BITS-1 downto 0),      
--        glitches_o    => dmtds_out(3).glitches   
--    );
    
--    ext_pulse_a(4) <= ext_pulse_b(5);
--    ext_pulse_b(4) <= ext_pulse_a(3);
    
--   ddmtd4_inst: entity work.gdmtd
--    generic map (
--        N            => 100000,        
--        OUT_BITS     => OUT_BITS, 
--        GEN_VAR_DSP  => true,
--        AVG_BITS     => 12, 
--        DEGLITCH_A   => false,     
--        DEGLITCH_B   => false,
--        MIX_IN_A     => false,     
--        MIX_IN_B     => false,
--        DEBUG_CORES  => false,
--        BRANCH_CFG_A => HEADER_8B10B_40_6,        
--        BRANCH_CFG_B => HEADER_8B10B_40_6 
--    ) port map (
--        rst           => dmtd_rst(4),
--        clk_sys       => clk_sys,
                     
--        word_clk_a    => dmtds_in(4).word_clk_a,
--        word_clk_b    => dmtds_in(4).word_clk_b,
--        info_i_a(0)   => dmtds_in(4).info_a(0), 
--        info_i_b(0)   => dmtds_in(4).info_b(0),
                 
--        first_ali     => first_ali(4),
--        delay_reg_i_a => dly_reg_i_a(4),
--        delay_reg_i_b => dly_reg_i_b(4),
--        delay_reg_o_a => dly_reg_o_a(4),
--        delay_reg_o_b => dly_reg_o_b(4),
                    
--        dmtd_clk      => dmtd_clk(4),
--        sample_i_a    => beat_a(4),
--        sample_i_b    => beat_b(4),
                    
--        ext_pulse_i_a => ext_pulse_a(4),
--        ext_pulse_i_b => ext_pulse_b(4),
--        ext_pulse_o_a => open,
--        ext_pulse_o_b => open,
                    
--        n_avg         => dmtds_in(4).n_avg,
                    
--        new_meas_p_o  => open,
--        new_sum_p_o   => open,
--        meas_o        => dmtds_out(4).phase_count(OUT_BITS-1 downto 0),
--        meas_sum_o    => dmtds_out(4).phase_avg(OUT_BITS-1 downto 0),  
--        nvar_o        => dmtds_out(4).stdv(OUT_BITS-1 downto 0),       
--        max_o         => dmtds_out(4).max(OUT_BITS-1 downto 0),  
--        min_o         => dmtds_out(4).min(OUT_BITS-1 downto 0),      
--        glitches_o    => dmtds_out(4).glitches   
--    );
    
--   ddmtd5_inst: entity work.gdmtd
--    generic map (
--        N            => 100000,        
--        OUT_BITS     => OUT_BITS, 
--        GEN_VAR_DSP  => true,
--        AVG_BITS     => 12, 
--        DEGLITCH_A   => true,     
--        DEGLITCH_B   => true,
--        MIX_IN_A     => false,     
--        MIX_IN_B     => false,
--        DEBUG_CORES  => false,
--        BRANCH_CFG_A => HEADER_8B10B_40_6,        
--        BRANCH_CFG_B => HEADER_8B10B_40_6 
--    ) port map (
--        rst           => dmtd_rst(5),
--        clk_sys       => clk_sys,
                     
--        word_clk_a    => dmtds_in(5).word_clk_a,
--        word_clk_b    => dmtds_in(5).word_clk_b,
--        info_i_a(0)   => dmtds_in(5).info_a(0), 
--        info_i_b(0)   => dmtds_in(5).info_b(0),
                 
--        first_ali     => first_ali(5),
--        delay_reg_i_a => dly_reg_i_a(5),
--        delay_reg_i_b => dly_reg_i_b(5),
--        delay_reg_o_a => dly_reg_o_a(5),
--        delay_reg_o_b => dly_reg_o_b(5),
                    
--        dmtd_clk      => dmtd_clk(5),
--        sample_i_a    => beat_a(5),
--        sample_i_b    => beat_b(5),
                    
--        ext_pulse_i_a => '0',
--        ext_pulse_i_b => '0',
--        ext_pulse_o_a => ext_pulse_a(5),
--        ext_pulse_o_b => ext_pulse_b(5),
                    
--        n_avg         => dmtds_in(5).n_avg,
                    
--        new_meas_p_o  => open,
--        new_sum_p_o   => open,
--        meas_o        => dmtds_out(5).phase_count(OUT_BITS-1 downto 0),
--        meas_sum_o    => dmtds_out(5).phase_avg(OUT_BITS-1 downto 0),  
--        nvar_o        => dmtds_out(5).stdv(OUT_BITS-1 downto 0),       
--        max_o         => dmtds_out(5).max(OUT_BITS-1 downto 0),  
--        min_o         => dmtds_out(5).min(OUT_BITS-1 downto 0),      
--        glitches_o    => dmtds_out(5).glitches   
--    );

    
end Behavioral;
