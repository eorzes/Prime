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
-- CERN EP-ESE-BE, HPTD, 19 March 2025

-- This module reads the pulses from two DDMTD branches and returns the phase (as count between pulses)
-- if STATS, it returns also statistics: sum of N_AVG signed values, its range, and variance times N_AVG
-- the statistics are updated evey N_AVG*N/DIVISIONS dmtd_clk cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity phase_meas is
  generic (
    N           : integer := 100000; -- DDMTD time dilation factor, i.e. clock cycles within one beat clock period
    OUT_BITS    : integer := 28;     -- 2^N_BITS must hold max phase value (N) and statistic outputs
    AVG_BITS    : integer := 15;     -- bits of n_avg port, determines statistics occupancy
    GEN_VAR_DSP : boolean := true;   -- return variance of n_avg values
    P_DIV_A     : integer := 1;      -- N/P_DIV_A = clock cycles between pulse_a_in
    P_DIV_B     : integer := 1;  
    P_MUL_A     : integer := 1;      -- N*P_MUL_A = clock cycles between pulse_a_in
    P_MUL_B     : integer := 1;      -- must be either DIV = 1 or MUL = 1  
    DEBUG_CORES : boolean := false         
  );
  port ( 
    rst               : in  std_logic;
    dmtd_clk          : in  std_logic;
    pulse_a_in        : in  std_logic;
    pulse_b_in        : in  std_logic;
    n_avg             : in  unsigned(AVG_BITS-1 downto 0);        -- must be power of 2 for correct variance 
    new_meas_p_o      : out std_logic;
    new_sum_p_o       : out std_logic;
    a_minus_b_phase_o : out std_logic_vector(OUT_BITS-1 downto 0);  -- phase t_a - t_b, time from b to a edge
    a_minus_b_sum_o   : out std_logic_vector(OUT_BITS-1 downto 0);  -- sum[phi]
    var_o             : out std_logic_vector(OUT_BITS-1 downto 0);  -- sum[(phi-avg)^2]. standard deviation = sqrt(var_o/n_avg)
    max_o             : out std_logic_vector(OUT_BITS-1 downto 0);  -- max[phi]
    min_o             : out std_logic_vector(OUT_BITS-1 downto 0)   -- min[phi]
    );
end phase_meas;

architecture Behavioral of phase_meas is

    constant GEN_STATS : boolean := true;

    constant MUL_RATIO   : integer := integer(real(maximum(P_MUL_A, P_MUL_B))/real(minimum(P_MUL_A, P_MUL_B)));
    constant DIV_RATIO   : integer := integer(real(maximum(P_DIV_A, P_DIV_B))/real(minimum(P_DIV_A, P_DIV_B)));
    constant PULSE_RATIO : integer := DIV_RATIO * MUL_RATIO;
    constant DIVISIONS   : integer := maximum(P_DIV_A, P_DIV_B);
    constant PERIOD      : integer := integer(real(N)/real(DIVISIONS));
    constant HALF_T      : integer := PERIOD/2;
    constant OPT_DELAY   : integer := PULSE_RATIO*PERIOD - HALF_T;

    type state_t is (WAIT_FOR_LOCK, WAIT_SLOW_PULSE, START_AT_OPTIMAL, WAIT_FIRST_PULSE, COUNT_TO_SECOND_PULSE, SKIP_FAST_PULSES);
    attribute ENUM_ENCODING: string;
    attribute ENUM_ENCODING of state_t: type is "000 001 010 011 100 101";
    signal state : state_t := WAIT_FOR_LOCK;
    
    signal negative        : std_logic := '0';
    signal count           : signed(OUT_BITS-1 downto 0) := to_signed(0, OUT_BITS);
    signal a_minus_b_phase : signed(OUT_BITS-1 downto 0) := to_signed(0, OUT_BITS);
    signal b_locked        : std_logic := '0'; 
    signal save_phase      : std_logic := '0';
    
    ---- statistics ----
    type stats_state_t is (WAIT_BLOCK_AVG, COMPUTE_STATS, OVERFLOW_CHECK, OUTPUT_STATS);
    attribute ENUM_ENCODING of stats_state_t: type is "00 01 10 11";
    signal stats_state : stats_state_t := WAIT_BLOCK_AVG;
    
    constant CNT_BITS     : integer := 20;
    signal avg_cnt        : integer range 0 to (2**CNT_BITS)-1 := 0;   
    signal bit_shifts_div : integer range 0 to 31 := 1; -- AVG_BITS(N_AVG) if generic N_AVG
    
    --constant AVG_BITS  : integer := integer(ceil(log2(real(N_AVG)))); -- use this if generic N_AVG
    constant SUM_BITS : integer := OUT_BITS+AVG_BITS+1; -- for sum: 2^SUM_BITS must hold sum of max phase values (±N*n_avg)
                                                     -- for variance output: 2^OUT_BITS should hold (xi-<xi>)|max^2 * n_avg; where (xi-<xi>)|max = N/2
                                                     -- if losing informazion on resize of range and variance, these are assigned to the max value as overflow flag
    constant POW_BITS : integer := 2*SUM_BITS+2;     -- for variance: 2^POW_BITS must hold (xi|max*n_avg)^2; where xi|max = N
    
    signal q_sum : signed(SUM_BITS-1 downto 0) := (others => '0');
    signal q_sm2 : signed(POW_BITS-1 downto 0) := (others => '0');
    signal q_max : signed(OUT_BITS-1 downto 0) := (OUT_BITS-1 => '1', others => '0'); -- -2**(OUT_BITS-1)
    signal q_min : signed(OUT_BITS-1 downto 0) := (OUT_BITS-1 => '0', others => '1'); --  2**(OUT_BITS-1)-1
    
    signal q_sum_i     : signed(SUM_BITS-1 downto 0) := (others => '0');
    signal q_var_i     : signed(POW_BITS-1 downto 0) := (others => '0');
    signal q_sum_reg   : signed(OUT_BITS-1 downto 0) := (others => '0');
    signal q_var_reg   : signed(OUT_BITS-1 downto 0) := (others => '0');
    signal q_max_reg   : signed(OUT_BITS-1 downto 0) := (others => '0');
    signal q_min_reg   : signed(OUT_BITS-1 downto 0) := (others => '0');
    signal stats_rdy   : std_logic := '0';   
    signal block_ready : std_logic := '0';
    signal clear_block : std_logic := '0';
    signal cycle_cnt   : integer range 0 to N-1 := 0;
    
    constant MULICYCLE_FACTOR : integer := integer(real(N)/(8.0*real(DIVISIONS)));
    
    --dbg
    signal count_v : std_logic_vector(19 downto 0) := (others => '0');
    signal state_v : std_logic_vector(2  downto 0) := (others => '0');
    signal ph_v    : std_logic_vector(31 downto 0) := (others => '0');
    signal sum_v   : std_logic_vector(31 downto 0) := (others => '0');
    signal max_v   : std_logic_vector(31 downto 0) := (others => '0');
    signal avg_v   : std_logic_vector(31 downto 0) := (others => '0');
    signal var_v   : std_logic_vector(31 downto 0) := (others => '0');
    signal period_v  : std_logic_vector(31 downto 0) := (others => '0');
    signal pul_rat_v : std_logic_vector(31 downto 0) := (others => '0');
    signal opt_del_v : std_logic_vector(31 downto 0) := (others => '0');
        
begin
    
    process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            if rst = '1' then
                a_minus_b_phase_o <= (others => '0');
                new_meas_p_o      <= '0';
            elsif save_phase = '1' then
                a_minus_b_phase_o <= std_logic_vector(a_minus_b_phase);
                new_meas_p_o      <= '1';
            else
                new_meas_p_o      <= '0';
            end if;
        end if;
    end process;
    
    statistic_results: if GEN_STATS generate
        process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    a_minus_b_sum_o <= (others => '0');
                    var_o           <= (others => '0');
                    max_o           <= (others => '0');
                    min_o           <= (others => '0');
                    new_sum_p_o     <= '0';
                elsif stats_rdy = '1' then
                    a_minus_b_sum_o <= std_logic_vector(q_sum_reg);
                    var_o           <= std_logic_vector(q_var_reg);
                    max_o           <= std_logic_vector(q_max_reg);
                    min_o           <= std_logic_vector(q_min_reg);
                    new_sum_p_o     <= '1';
                else
                    new_sum_p_o     <= '0';
                end if;
            end if;
        end process;
    end generate statistic_results;

    FSM : process(dmtd_clk) 
        variable slow_is_a : std_logic := '0';
    begin
        if rising_edge(dmtd_clk) then
            if rst = '1' then
                state           <= WAIT_FOR_LOCK; -- use at startup or after a phase shift greater than T/2
                b_locked        <= '0';
                count           <= to_signed(0, OUT_BITS);
                a_minus_b_phase <= to_signed(0, OUT_BITS);
                save_phase      <= '0';
                slow_is_a       := '0';
            else
                save_phase <= '0';
                case(state) is 
                
                    when WAIT_FOR_LOCK =>
                        if pulse_b_in = '1' then
                            b_locked <= '1';
                        end if;
                        if (b_locked and pulse_a_in) = '1' then
                            state <= WAIT_SLOW_PULSE when PULSE_RATIO /= 1 else START_AT_OPTIMAL;
                        end if;
                        
                    when WAIT_SLOW_PULSE => 
                        slow_is_a := '1' when P_DIV_A*P_MUL_B < P_DIV_B*P_MUL_A else '0';
                        if ((pulse_a_in = '1' and slow_is_a = '1') or (pulse_b_in = '1' and slow_is_a = '0')) then
                            state <= START_AT_OPTIMAL;
                        end if;
                    
                    -- The DDMTD phase_meas module is designed to start at T/2 from a pulse (after a reset), 
                    -- this way it measures always the smallest phase (between ta-tb and tb-ta),
                    -- until the pulses lose periodicity, due to GT resets, PLL loss of locks, switch to clock/data pattern.
                    -- this design is robust to a - b pulses inversion (small phase with jitter)
                    when START_AT_OPTIMAL =>
                        if count = OPT_DELAY then
                            state <= WAIT_FIRST_PULSE;
                            count <= to_signed(0, OUT_BITS);
                        else 
                            count <= count + 1;
                        end if;

                    when WAIT_FIRST_PULSE =>
                        if (pulse_b_in and pulse_a_in) = '1' then
                            a_minus_b_phase <= to_signed(0, OUT_BITS);
                            save_phase      <= '1';
                            if PULSE_RATIO /= 1 then state <= SKIP_FAST_PULSES; end if;
                        elsif (pulse_b_in or pulse_a_in) = '1' then
                            negative <= '1' when pulse_a_in = '1' else '0';
                            count    <= to_signed(1, OUT_BITS);
                            state    <= COUNT_TO_SECOND_PULSE;
                        end if;

                    when COUNT_TO_SECOND_PULSE =>
                        if (((pulse_b_in = '1') and (negative = '1')) or ((pulse_a_in = '1') and (negative = '0'))) then
                            state <= WAIT_FIRST_PULSE when PULSE_RATIO = 1 else SKIP_FAST_PULSES;
                            a_minus_b_phase <= count when negative = '0' else -count;
                            save_phase <= '1'; -- a measurement is completed after N/DIVISIONS dmtd_clk cycles
                            count <= to_signed(0, OUT_BITS);
                        else
                            count <= count + 1;
                        end if;
                        
                    when SKIP_FAST_PULSES => 
                        if count = PULSE_RATIO-1 then
                            state <= WAIT_FIRST_PULSE;
                            count <= to_signed(0, OUT_BITS);
                        elsif ((pulse_a_in = '1' and slow_is_a = '0') or (pulse_b_in = '1' and slow_is_a = '1')) then
                            count <= count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;
    
    statistics: if GEN_STATS generate
    
        statistics_accumulation: process(dmtd_clk)
            variable phi : signed(OUT_BITS-1 downto 0);
        begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    avg_cnt <=  0;
                    q_sum   <= (others => '0');
                    q_sm2   <= (others => '0');
                    q_max   <= (OUT_BITS-1 => '1', others => '0'); -- -2**(OUT_BITS-1)  
                    q_min   <= (OUT_BITS-1 => '0', others => '1'); --  2**(OUT_BITS-1)-1
                    block_ready <= '0';
                elsif save_phase = '1' then
                    phi := a_minus_b_phase;
                    q_sum   <= q_sum + resize(phi    , SUM_BITS);
                    q_sm2   <= q_sm2 + resize(phi*phi, POW_BITS);
                    q_max   <= phi when phi > q_max else q_max;
                    q_min   <= phi when phi < q_min else q_min;
                    if avg_cnt < n_avg - 1 then
                        avg_cnt <= avg_cnt + 1;
                    else
                        avg_cnt <= 0;
                        block_ready <= '1';
                    end if;
                elsif clear_block = '1' then
                    q_sum <= (others => '0');
                    q_sm2 <= (others => '0');
                    q_max <= (OUT_BITS-1 => '1', others => '0'); -- -2**(OUT_BITS-1)  
                    q_min <= (OUT_BITS-1 => '0', others => '1'); --  2**(OUT_BITS-1)-1
                    block_ready <= '0';
                end if;
            end if;
        end process;
        
        FSM_stats_output: process(dmtd_clk) 
            variable square : signed(POW_BITS-1 downto 0);
        begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    q_sum_i     <= (others => '0');
                    q_var_i     <= (others => '0');
                    q_max_reg   <= (others => '0');
                    q_min_reg   <= (others => '0');
                    q_sum_reg   <= (others => '0');
                    q_var_reg   <= (others => '0');
                    stats_rdy   <= '0';
                    clear_block <= '0';
                    cycle_cnt   <=  0 ;
                    stats_state <= WAIT_BLOCK_AVG;
                else
                    stats_rdy   <= '0';
                    clear_block <= '0';
                    case(stats_state) is 
                    
                        when WAIT_BLOCK_AVG =>
                            if block_ready = '1' then
                                stats_state <= COMPUTE_STATS;
                            end if;
                            
                        when COMPUTE_STATS =>
                            if cycle_cnt = MULICYCLE_FACTOR - 1 then
                                square    := resize(q_sum*q_sum, POW_BITS);
                                q_max_reg <= q_max;
                                q_min_reg <= q_min;
                                q_sum_i   <= resize(q_sum, q_sum_i'length);
                                q_var_i   <= resize(q_sm2 - shift_right(square, bit_shifts_div),
                                                    q_var_i'length) when GEN_VAR_DSP else (others => '0'); -- integer division (rounded)
                                clear_block <= '1';
                                cycle_cnt   <=  0 ;
                                stats_state <= OVERFLOW_CHECK;
                            else
                                cycle_cnt <= cycle_cnt + 1;
                            end if;
                            
                        when OVERFLOW_CHECK =>
                            if cycle_cnt = MULICYCLE_FACTOR - 1 then
                                -- if not fitting OUT_BITS, flag as largest value
                                if q_sum_i(q_sum_i'left downto q_sum_reg'length) /= (q_sum_i'left downto q_sum_reg'length => '1') and 
                                   q_sum_i(q_sum_i'left downto q_sum_reg'length) /= (q_sum_i'left downto q_sum_reg'length => '0') then
                                    q_sum_reg <= (others => '1');
                                    q_sum_reg(q_sum_reg'left) <= '0';
                                else
                                    q_sum_reg <= resize(q_sum_i, q_sum_reg'length);
                                end if;
                                if q_var_i(q_var_i'left downto q_var_reg'length) /= (q_var_i'left downto q_var_reg'length => '0') then
                                    q_var_reg <= (others => '1');
                                    q_var_reg(q_var_reg'left) <= '0';
                                else
                                    q_var_reg <= resize(q_var_i, q_var_reg'length);
                                end if;
                                cycle_cnt   <= 0;
                                stats_state <= OUTPUT_STATS;
                            else
                                cycle_cnt <= cycle_cnt + 1;
                            end if;
                            
                        when OUTPUT_STATS =>
                            if cycle_cnt = MULICYCLE_FACTOR - 1 then
                                stats_rdy   <= '1';
                                cycle_cnt   <=  0 ;
                                stats_state <= WAIT_BLOCK_AVG;
                            else
                                cycle_cnt <= cycle_cnt + 1;
                            end if;
                    end case;      
                end if;
            end if;
        end process;
        
        priority_encoder: process(n_avg) begin
            bit_shifts_div <= 0; 
            for i in n_avg'range loop
                if n_avg(i) = '1' then
                    bit_shifts_div <= i;
                    exit; 
                end if;
            end loop;
        end process;
        
    end generate statistics;
    
    pm_dbg: if DEBUG_CORES generate
        state_v <= std_logic_vector(to_unsigned(state_t'POS(state), 3));
        count_v <= std_logic_vector(resize(count, count_v'length));
        ph_v    <= std_logic_vector(resize(a_minus_b_phase, 32));
        sum_v   <= std_logic_vector(resize(          q_sum, 32));          
        max_v   <= std_logic_vector(resize(      q_max_reg, 32));
        var_v   <= std_logic_vector(resize(      q_var_reg, 32));       
        avg_v   <= std_logic_vector(to_unsigned(avg_cnt, 32));  
        
        period_v  <= std_logic_vector(to_signed(PERIOD      , 32));
        pul_rat_v <= std_logic_vector(to_signed(PULSE_RATIO , 32));
        opt_del_v <= std_logic_vector(to_signed(OPT_DELAY   , 32));
    
        ila_phase_meas_i: entity work.ila_phase_meas
        port map(
            clk => dmtd_clk,
            probe0(0)  => rst,
            probe1(0)  => pulse_a_in,
            probe2(0)  => pulse_b_in,
            probe3     => state_v,
            probe4     => count_v,
            probe5(0)  => negative,
            probe6     => ph_v,
            probe7     => sum_v,      
            probe8     => avg_v,      
            probe9     => var_v,
            probe10    => max_v,
            probe11(0) => save_phase, 
            probe12(0) => stats_rdy     
        );
        
--        vio_phase_meas_i: entity work.vio_pm
--        port map(
--            clk        => dmtd_clk,
--            probe_in0  => period_v ,
--            probe_in1  => pul_rat_v,
--            probe_in2  => opt_del_v
--        ); 
     end generate pm_dbg;

end Behavioral;
