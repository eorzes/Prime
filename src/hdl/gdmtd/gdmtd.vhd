-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Copyright CERN 2026.
-- This source describes Open Hardware and is licensed under the CERN-OHLW v2
-- You may redistribute and modify this documentation and make products
-- using it under the terms of the CERN-OHL-W v2 (https:/cern.ch/cern-ohl).
-- This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
-- WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
-- AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-W v2
-- for applicable conditions.
-- Source location: https://www.ohwr.org/project/wr-switch-hw
-- As per CERN-OHL-W v2 section 4.1, should You produce hardware based on
-- these sources, You must maintain the Source Location visible on the
-- external case of any product you make using this documentation.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Designed by Edoardo Orzes 
-- CERN EP-ESE-BE, HPTD, 27 March 2026

-- The Generalized DDMTD performs phase measurements both on clocks and data streams.
-- The DDMTD has 2 branches (a and b), each configured through generics to detect edges either on clocks or data signals.
-- MODE determies the target type: MODE = 0 -> clock, MODE > 0 -> data stremas.

-- THEORY:
-- The DDMTD requires an helper PLL (locked or free-running) that outputs a dmtd_clk with a freqency (f_dmtd) approacing the input one (f_in).
-- each DDMTD branch generates a beat signal by time dilating the input signal by factor N. the beat signal presents glitches due to jitter sampling. 
-- a deglitcher per branch decides the real edges from the beat signal (returning pulse signals), a counter measures phase between the pulses.
-- for clock inputs (MODE = 0), f_dmtd := g(f_in, N) = N/(N+1)*f_in, T_beat = (N+1)*T_in. large values of N imply better resolution but higher latency.
-- resolution(N) = T_in/N ; latency(N) = T_in*(N+1) = T_dmtd*N. *the latency also depends on ALL_EDGES and DIV and MUL generics.
-- for data inputs (MODE > 0) f_in is the frequency of the word clock (the transceiver parallel clock).

-- MEASURING SIGNALS WITH DIFFERENT FREQUENCIES:
-- it is possible to set the dmtd_clk as a function of T_in, while measuring clocks (or data) with periods (T_in') different than T_in 
-- as long as the periods ratio (T_in'/T_in) is defined and T_in' is either a multiple or submultiple of T_in.
-- to define the periods ratio of a branch, set DIV = T_in/T_in' (fatser) or MUL = T_in'/Tin (slower). 
-- If DIV > 1 then MUL = 1; if MUL > 1 then DIV = 1. MUL is not necessary, it can be kept at 1.
-- ALL_EDGES is set true when the input is fatert than T_in and all its edges are targeted for phase measurements.
-- Example of ALL_EDGE = true : clock input with f_in' = 4.8 GHz, f_in = 240 MHz -> 20 edges detected every beat period.
-- Example of ALL_EDGE = false: clock input with f_in' = 4.8 GHz, f_in = 240 MHz ->  1  edge detected every beat period.

-- DATA STREAM CONFIGURATIONS:
-- for data streams (MODE > 0) we distinguish 2 cases. 
-- data frame = sequence of words, a word contains PARALLEL_BITS, a word corresponds to a word_clk cycle,
-- the data frame can contain one frame header, which can be periodic, alternating or aperiodic.
-- edges are detected on time dilated bit patterns, rather than on time dilated clocks.
-- the TARGET pattern can be either a frame header, if periodic (MODE = 1) or serial bits (MODE = 2), if aperiodic headers.
-- with MODE = 2 and ALL_EDGES, every couple of bits triggers an edge detection. latency scales by 0.5/PARALLEL_BITS.
-- with MODE = 2 and not(ALL_EDGES) or with MODE = 1, an edge is detected every word (even if the header/TARGET is not every word). 

-- to create the time dilated TARGET from data stream, the GDMTD requires information from the data protocol:
-- the information is used to drive the "sample inversion" logic in target_dilation modules.
-- for MODE = 1, the header flag (TARGET) from the protocol is assigned to info_i.
-- for MODE = 2 and not ALL_EDGES, two consecutive lane bits (TARGET) from the protocol are assigned to info_i.
-- for MODE = 2 and ALL_EDGES, all parallel bits are assigned to info_i (sync to word_clk).
-- the bits to assign to info_i (MODE = 2) are the travelling serial bits, not the user bits, provided by data encoder/decoder or scrambler.

-- info_i (word_clk) and sample_i (dmtd_clk) are from different clock domains, "downsampling" and a FIFO solve the CDC within target_dilation.
-- TARGET_PERIOD is set to a minimum value of 4, to ease the alignment and solve the CDC, 
-- for MODE = 1, TARGET_PERIOD is set to the header period (if >= 4), i.e. word_clk cycles between headers (header word included). 
-- for MODE > 0, DIV is set to half the parallel bits number, two bits correspond to a priod T_in' = T_in/DIV.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.gdmtd_pkg.all;

entity gdmtd is
  generic (
    N            : integer := 100000;  -- DDMTD time dilation factor, f_dmtd := N/(N+1)*f_in, T_beat = (N+1)*T_in.                                      
    OUT_BITS     : integer := 28;      -- number of bits of output phase and statistics (2^OUT_BITS must hold max phase value (N) and statistic outputs).  
    GEN_VAR_DSP  : boolean := true;
    AVG_BITS     : integer := 12;      -- bits for n_avg input port   
    DEGLITCH_A   : boolean := true;    -- choose if to implement the "target time dilation" module (input stage + deglitcher) (it might be in another DDMTD)
    DEGLITCH_B   : boolean := true;
    MIX_IN_A     : boolean := true;    -- implement the mixer+synchronizer, should be false when using an external flip-flop (mixer)
    MIX_IN_B     : boolean := true;
    DEBUG_CORES  : boolean := false;
    BRANCH_CFG_A : GDMTD_BRANCH_CONFIG_t := STD_CLOCK; -- refer to gdmtd_pkg for details on the configuration
    BRANCH_CFG_B : GDMTD_BRANCH_CONFIG_t := STD_CLOCK
    );
  port (
    rst           : in  std_logic;  -- reset (sync to dmtd_clk)
    clk_sys       : in  std_logic;  -- clock to synchronise the outputs
    
    -- (MODE > 0) information from encoder/decoder (header flag or lane bits)
    word_clk_a    : in  std_logic;  -- data protocol parallel clock
    word_clk_b    : in  std_logic;
    info_i_a      : in  std_logic_vector(BRANCH_CFG_A.N_INFO-1 downto 0); -- sync to word_clk_a
    info_i_b      : in  std_logic_vector(BRANCH_CFG_B.N_INFO-1 downto 0); -- sync to word_clk_b
    
    -- (MODE > 0) flag/sample alignment logic
    first_ali     : in  std_logic;            -- sync to dmtd_clk
    delay_reg_i_a : in  unsigned(9 downto 0);
    delay_reg_i_b : in  unsigned(9 downto 0);
    delay_reg_o_a : out unsigned(9 downto 0);
    delay_reg_o_b : out unsigned(9 downto 0);
       
    -- DDMTD input clocks     
    dmtd_clk      : in  std_logic;  -- DDMTD clock (f_dmtd) (PLL offset clock)
    sample_i_a    : in  std_logic;  -- clock to measure (f_in) or data input 
    sample_i_b    : in  std_logic;
    
    -- DDMTD pulses, from detected edges (deglitched) in the time dilated domain (sync to dmtd_clk)
    ext_pulse_i_a : in  std_logic;  -- optional branch pulse input/output, it can be shared from/to other DDMTDs
    ext_pulse_i_b : in  std_logic;  -- tie to '0' if unused
    ext_pulse_o_a : out std_logic;  -- leave open if unused
    ext_pulse_o_b : out std_logic;
    
    -- DDMTD averaging number (sync to dmtd_clk)
    n_avg         : in  unsigned(AVG_BITS-1 downto 0);
    
    -- DDMTD phase measurement outputs (sync to clk_sys)
    new_meas_p_o  : out std_logic; -- pulse indicating a new measurement is ready
    new_sum_p_o   : out std_logic; -- pulse indicating a new sum of n_avg measurement is ready
    meas_o        : out std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');  -- signed integer phase count. reflects the phase t_a - t_b, time from b to a edge 
    meas_sum_o    : out std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');  -- sum of n_avg signed integer phase counts
    nvar_o        : out std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');  -- standared deviation of the averaged samples
    max_o         : out std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');  -- max value of the averaged samples
    min_o         : out std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');  -- min value of the averaged samples
    glitches_o    : out std_logic_vector(        31 downto 0) := (others => '0')   -- range of glitches on A:(31 downto 16) and B:(14 downto 0) edges of the meas_o result
    );
end gdmtd;

architecture Behavioral of gdmtd is

    signal pulse_a   : std_logic := '0';
    signal pulse_b   : std_logic := '0';

    signal meas_dmtd      : std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');
    signal meas_dmtd_sum  : std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');
    signal glitches_async : std_logic_vector(        31 downto 0) := (others => '0');
    signal nvar_dmtd      : std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');
    signal max_dmtd       : std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');
    signal min_dmtd       : std_logic_vector(OUT_BITS-1 downto 0) := (others => '0');
    
    signal new_meas_pulse : std_logic := '0';
    signal new_sum_pulse  : std_logic := '0';
    
    -- when MODE = 1, one pulse per word clock is produced
    constant P_DIV_A : integer := BRANCH_CFG_A.DIVISIONS when (BRANCH_CFG_A.ALL_EDGES and BRANCH_CFG_A.MODE /= 1) else 1; 
    constant P_DIV_B : integer := BRANCH_CFG_B.DIVISIONS when (BRANCH_CFG_B.ALL_EDGES and BRANCH_CFG_B.MODE /= 1) else 1;
                                                           
begin

  BRANCH_A: if DEGLITCH_A generate 
    target_dilation_a: entity work.target_time_dilation
      generic map (
        N           => N,             
        OUT_BITS    => OUT_BITS,  
        MIX_IN      => MIX_IN_A,
        CFG         => BRANCH_CFG_A,
        DEBUG_CORES => DEBUG_CORES
        )
      port map ( 
        rst         => rst,
        
        word_clk    => word_clk_a,  
        info_i      => info_i_a,  
        
        first_ali    => first_ali,  
        delay_reg_i  => delay_reg_i_a,
        delay_reg_o  => delay_reg_o_a,
           
        dmtd_clk    => dmtd_clk,  
        sample_i    => sample_i_a,  
            
        pulse_o     => pulse_a,   
        glitches_o  => glitches_async(31 downto 16)
        );
        ext_pulse_o_a <= pulse_a;
    else generate
        pulse_a <= ext_pulse_i_a;
        delay_reg_o_a <= (others => '0');
    end generate BRANCH_A;

  BRANCH_B: if DEGLITCH_B generate 
    target_dilation_b: entity work.target_time_dilation
      generic map (
        N           => N,             
        OUT_BITS    => OUT_BITS,    
        MIX_IN      => MIX_IN_B,
        CFG         => BRANCH_CFG_B,
        DEBUG_CORES => DEBUG_CORES
        )
      port map ( 
        rst         => rst,
        
        word_clk    => word_clk_b,  
        info_i      => info_i_b,  
        
        first_ali    => first_ali,  
        delay_reg_i  => delay_reg_i_b,
        delay_reg_o  => delay_reg_o_b,
           
        dmtd_clk    => dmtd_clk,  
        sample_i    => sample_i_b,  
            
        pulse_o     => pulse_b,   
        glitches_o  => glitches_async(15 downto 0)
        );
        ext_pulse_o_b <= pulse_b;
    else generate
        pulse_b <= ext_pulse_i_b;
        delay_reg_o_b <= (others => '0');
    end generate BRANCH_B;

    phase_meas: entity work.phase_meas
      generic map (
        N           => N,
        OUT_BITS    => OUT_BITS, 
        GEN_VAR_DSP => GEN_VAR_DSP,
        AVG_BITS    => AVG_BITS,
        P_DIV_A     => P_DIV_A,
        P_DIV_B     => P_DIV_B,
        P_MUL_A     => 1,
        P_MUL_B     => 1,
        DEBUG_CORES => DEBUG_CORES
      ) port map ( 
        rst               => rst,
        dmtd_clk          => dmtd_clk,
        pulse_a_in        => pulse_a,
        pulse_b_in        => pulse_b,
        n_avg             => n_avg,
        new_meas_p_o      => new_meas_pulse,
        new_sum_p_o       => new_sum_pulse,
        a_minus_b_phase_o => meas_dmtd,
        a_minus_b_sum_o   => meas_dmtd_sum,
        var_o             => nvar_dmtd,
        max_o             => max_dmtd,
        min_o             => min_dmtd
        );
     
    sync_phase: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_meas_pulse,
        async_in       => meas_dmtd, 
        sync_out       => meas_o(OUT_BITS-1 downto 0),
        sync_pulse_out => new_meas_p_o
      ); 
    sync_sum: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_sum_pulse,
        async_in       => meas_dmtd_sum, 
        sync_out       => meas_sum_o(OUT_BITS-1 downto 0),
        sync_pulse_out => new_sum_p_o
      ); 
    sync_glitches: entity work.vec_pulse_sync
      generic map ( N_BITS => 32 ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_sum_pulse,
        async_in       => glitches_async, 
        sync_out       => glitches_o,
        sync_pulse_out => open
      ); 
    sync_variance: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_sum_pulse,
        async_in       => nvar_dmtd, 
        sync_out       => nvar_o(OUT_BITS-1 downto 0),
        sync_pulse_out => open
      ); 
    sync_max: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_sum_pulse,
        async_in       => max_dmtd, 
        sync_out       => max_o(OUT_BITS-1 downto 0),
        sync_pulse_out => open
      ); 
    sync_min: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => dmtd_clk,
        async_pulse_in => new_sum_pulse,
        async_in       => min_dmtd, 
        sync_out       => min_o(OUT_BITS-1 downto 0),
        sync_pulse_out => open
      ); 

end Behavioral;
