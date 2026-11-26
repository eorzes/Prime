--
-- Designed by Edoardo Orzes 
-- CERN EP-ESE-BE, HPTD, 4 August 2026
--
-- Computes the averaging of data_i, performs decimation to relax statistics timing
-- If GEN_VAR_DSP, it computes n times variance ( sum[(xi-<x>)^2] ). standard deviation = sqrt(n*variance / n)
-- It computes the max and min. usign both max and min allows to get the range from a set of averages, same for variance.
--
-- IMPORTANT: for the variance to work (GEN_VAR_DSP) it requires timing constraints:
--
-- set_multicycle_path -setup -end -from [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] \
--                                 -to   [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] RELAX
-- set_multicycle_path -hold  -end -from [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] \
--                                 -to   [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] RELAX-1
--
-- the "average" string should be the instance name of this module, and to be unique in the project
-- use the appropriate RELAX value must be smaller than MULICYCLE_FACTOR and larger than enouth cycles to complete the DSP paths)
-- for the variance to work (GEN_VAR_DSP), n_avg must be a power of 2 
-- to minimise latency, set GEN_VAR_DSP = False or consider MULTY_CYCLE generic

-- MULTY_CYCLE generic overrides automatic DSP latency (MULICYCLE_DEFAULT):
-- values larger than MULICYCLE_DEFAULT stall sample acquisition while statistics are computed. 
-- The acquired samples are no longer uniformly spaced in time.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity average is
  generic (
    IN_BITS     : integer := 7;
    OUT_BITS    : integer := 32;     -- 2^N_BITS must hold max phase value (N) and statistic outputs
    AVG_BITS    : integer := 15;     -- bits of n_avg port, determines statistics occupancy
    DECIMATION  : integer := 30;     -- for uniformly spaced samples between blocks: minimum 5 when GEN_VAR_DSP else 3 (see SYNC_GEN & FSM_stats_output). 
                                     -- use DECIMATION to slow down the sample retrieval, to relax timing for variance computation.
    MULTY_CYCLE : integer := -1;     -- leave at -1 (default) unless DECIMATION < 5 or RELAX >= MULICYCLE_DEFAULT
	SYNC_IN     : boolean := true;   -- synchronize input from src_clk to clk
	CIRCULAR    : boolean := true;   -- handle wrap around with sign adjustment, then requires post processing MOD period on avg (avg = sum/n_avg)
	GEN_VAR_DSP : boolean := true;   -- generate variance logic
	DEBUG_CORES : boolean := false
  );
  port ( 
    rst          : in  std_logic;
    src_clk      : in  std_logic; -- data_i clock
    clk          : in  std_logic; -- clk
	clk_sys      : in  std_logic; -- to sync the outputs
    data_i       : in  std_logic_vector(IN_BITS-1 downto 0);
    n_avg        : in  unsigned(AVG_BITS-1 downto 0);        -- must be power of 2 for correct division (like 512*32)
    new_meas_p_o : out std_logic;                            
	new_sum_p_o  : out std_logic;                            
	meas_o       : out std_logic_vector(OUT_BITS-1 downto 0);
	sum_o        : out std_logic_vector(OUT_BITS-1 downto 0);
	var_o        : out std_logic_vector(OUT_BITS-1 downto 0);
	max_o        : out std_logic_vector(OUT_BITS-1 downto 0);
	min_o        : out std_logic_vector(OUT_BITS-1 downto 0) 
    );
end average;

architecture Behavioral of average is

    constant CHECK_OVF : boolean := true;
	
	signal data_sync  : std_logic_vector(IN_BITS-1 downto 0);
	signal data_slow  : signed(IN_BITS-1 downto 0);
	
	signal adjust_sign: std_logic := '0';
	signal stored_sign: std_logic := '0';
	
	signal new_meas_p : std_logic;                            
	signal new_sum_p  : std_logic;                            
	signal meas       : std_logic_vector(OUT_BITS-1 downto 0);
	signal sum        : std_logic_vector(OUT_BITS-1 downto 0);
	signal var        : std_logic_vector(OUT_BITS-1 downto 0);
	signal max        : std_logic_vector(OUT_BITS-1 downto 0); 
	signal min        : std_logic_vector(OUT_BITS-1 downto 0); 
    
	constant CNT_BITS      : integer := 20;
    signal count           : signed(CNT_BITS-1 downto 0) := to_signed(0, CNT_BITS);
    signal save_phase      : std_logic := '0';
    
    ---- statistics ----
    type stats_state_t is (WAIT_BLOCK_AVG, COMPUTE_STATS, WAIT_STATS, OVERFLOW_CHECK);
    attribute ENUM_ENCODING: string;
    attribute ENUM_ENCODING of stats_state_t: type is "00 01 10 11";
    signal stats_state : stats_state_t := WAIT_BLOCK_AVG;
    
    signal avg_cnt        : integer range 0 to (2**CNT_BITS)-1 := 0;   
    signal bit_shifts_div : integer range 0 to 31 := 1; -- AVG_BITS(N_AVG) if generic N_AVG
    
    --constant AVG_BITS  : integer := integer(ceil(log2(real(N_AVG)))); -- use this if generic N_AVG
    constant EXTRA_BITS : integer := 0 when not CIRCULAR else 2;
    constant DATA_BITS  : integer := IN_BITS+EXTRA_BITS;
    constant SUM_BITS   : integer := DATA_BITS+AVG_BITS+1; -- for sum: 2^SUM_BITS must hold sum of max phase values (±N*n_avg)
                                                           -- for variance output: 2^OUT_BITS should hold (xi-<xi>)|max^2 * n_avg; where (xi-<xi>)|max = N/2
                                                           -- if losing informazion on resize of range and variance, these are assigned to the max value as overflow flag
    constant POW_BITS : integer := 2*SUM_BITS+2;           -- for variance: 2^POW_BITS must hold (xi|max*n_avg)^2; where xi|max = N
    
    type statistics is record     
        sum : signed(SUM_BITS-1 downto 0); 
        var : signed(POW_BITS-1 downto 0); 
        max : signed(DATA_BITS-1 downto 0);
        min : signed(DATA_BITS-1 downto 0);
    end record;
    constant stats_init : statistics := (
        sum => (others => '0'),
        var => (others => '0'),
        max => (DATA_BITS-1 => '1', others => '0'), -- -2**(DATA_BITS-1)   
        min => (DATA_BITS-1 => '0', others => '1')  --  2**(DATA_BITS-1)-1 
    );

    signal q_run : statistics := stats_init;
    signal q_end : statistics := stats_init;
    
    signal block_ready : std_logic := '0';
    signal clear_block : std_logic := '0';
    signal stats_busy  : std_logic := '0'; -- only required for MULTY_CYCLE > -1
    signal cycle_cnt   : integer   :=  0 ;
    
    constant MULICYCLE_DEFAULT : integer := maximum(1, integer(real(DECIMATION-3)/2.0)) when GEN_VAR_DSP else 1;
    constant MULICYCLE_FACTOR  : integer := maximum(1, MULTY_CYCLE) when MULTY_CYCLE > -1 else MULICYCLE_DEFAULT;
    
    -- keep name of q_* signals for relax constraints
    attribute KEEP : string;
    attribute KEEP of q_run : signal is "TRUE";
    attribute KEEP of q_end : signal is "TRUE";
    
    --dbg
    signal count_v : std_logic_vector(19 downto 0) := (others => '0');
    signal state_v : std_logic_vector(2  downto 0) := (others => '0');
    signal ph_v    : std_logic_vector(31 downto 0) := (others => '0');
    signal sm2_v   : std_logic_vector(97 downto 0) := (others => '0');
    signal bsd_v   : std_logic_vector(15 downto 0) := (others => '0');
    signal vrr_v   : std_logic_vector(31 downto 0) := (others => '0');
    signal var_v   : std_logic_vector(97 downto 0) := (others => '0');
    signal mf_v : std_logic_vector(31 downto 0) := (others => '0');
    signal pb_v : std_logic_vector(31 downto 0) := (others => '0');
    signal mb_v : std_logic_vector(31 downto 0) := (others => '0');
        
begin

    SYNC_GEN: if SYNC_IN generate
        sync_data_i: entity work.vec_sync
            generic map ( N_BITS => IN_BITS, PAUSE_IN => 4 ) 
            port map (
                src_clk  => src_clk,
                clk      => clk,
                async_in => data_i,   
                sync_out => data_sync
            );
    else generate
        data_sync <= data_i;
    end generate SYNC_GEN;
    
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                meas       <= (others => '0');
                new_meas_p <= '0';
            elsif save_phase = '1' then
                meas       <= std_logic_vector(resize(signed(data_sync), OUT_BITS));
                new_meas_p <= '1';
            else
                new_meas_p <= '0';
            end if;
        end if;
    end process;
    
    get_sample: process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                count      <= to_signed(0, CNT_BITS);
                data_slow  <= to_signed(0, IN_BITS);
                save_phase <= '0';
            elsif count = DECIMATION-1 and stats_busy = '0' then
                count      <= to_signed(0, CNT_BITS);
                data_slow  <= signed(data_sync);
                save_phase <= '1';
            else
                if count /= DECIMATION-1 then
                    count <= count + 1;
                end if;
                save_phase <= '0';
            end if;
        end if;
    end process;
    
    modulo_in: if CIRCULAR generate
        process(data_slow, avg_cnt, stored_sign) begin
            adjust_sign <= '0';
            if avg_cnt > 0 and data_slow(IN_BITS-1) /= data_slow(IN_BITS-2) then
                if data_slow(IN_BITS-1) /= stored_sign then
                    adjust_sign <= '1';
                end if;
            end if;
        end process;
        process(clk) begin
            if rising_edge(clk) then
                if avg_cnt = 0 then
                    stored_sign <= data_slow(IN_BITS-1); 
                end if;
            end if;
        end process;
    else generate
        adjust_sign <= '0';
    end generate modulo_in;
    
    statistics_accumulation: process(clk)
        variable d : signed(DATA_BITS-1 downto 0); -- using extra bits for wrap-around adjustments
        constant two_to_IN_BITS : signed(DATA_BITS-1 downto 0) := signed'("01" & (IN_BITS-1 downto 0 => '0'));
    begin
        if rising_edge(clk) then
            if rst = '1' then
                avg_cnt <=  0;
                d     := to_signed(0, DATA_BITS);
                q_run <= stats_init;
                block_ready <= '0';
            elsif save_phase = '1' then
                if adjust_sign = '1' then
                    if data_slow(IN_BITS-1) = '1' then
                        -- negative, but stored positive: +2**(IN_BITS)
                        d := resize(data_slow, DATA_BITS) + two_to_IN_BITS; 
                    else
                        -- positive, but stored negative: -2**(IN_BITS)
                        d := resize(data_slow, DATA_BITS) - two_to_IN_BITS; 
                    end if;
                else 
                    d := resize(data_slow, DATA_BITS);
                end if;
                q_run.sum   <= q_run.sum + resize(d  , SUM_BITS);
                q_run.var   <= q_run.var + resize(d*d, POW_BITS);
                q_run.max   <= d when d > q_run.max else q_run.max;
                q_run.min   <= d when d < q_run.min else q_run.min;
                if avg_cnt = to_integer(n_avg) - 1 then
                    avg_cnt <= 0;
                    block_ready <= '1';
                else
                    avg_cnt <= avg_cnt + 1;
                end if;
            elsif clear_block = '1' then
                q_run <= stats_init;
                block_ready <= '0';
            end if;
        end if;
    end process;
    
    stats_busy <= '0' when stats_state = WAIT_BLOCK_AVG else '1';
    
    FSM_stats_output: process(clk) 
        variable square : signed(POW_BITS-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                new_sum_p   <= '0';
                sum <= (others => '0');
                var <= (others => '0');
                max <= (others => '0');
                min <= (others => '0');
                
                q_end       <= stats_init;
                clear_block <= '0';
                cycle_cnt   <=  0 ;
                stats_state <= WAIT_BLOCK_AVG;
            else
                clear_block <= '0';
                new_sum_p   <= '0';
                case(stats_state) is 
                
                    -- 1 clock cycle ( + DECIMATION * n_avg clock cycles from the start of statistics_accumulation)
                    when WAIT_BLOCK_AVG =>
                        if block_ready = '1' then
                            if GEN_VAR_DSP then
                                stats_state <= COMPUTE_STATS;
                            elsif not CHECK_OVF then
                                max <= std_logic_vector(resize(q_run.max, OUT_BITS));
                                min <= std_logic_vector(resize(q_run.min, OUT_BITS));
                                sum <= std_logic_vector(resize(q_run.sum, OUT_BITS));
                                var <= std_logic_vector(resize(q_run.var, OUT_BITS));
                                new_sum_p <= '1';
                                clear_block <= '1';
                            else
                                q_end.max <= q_run.max;
                                q_end.min <= q_run.min;
                                q_end.sum <= q_run.sum;
                                q_end.var <= (others => '0');
                                clear_block <= '1';
                                stats_state <= OVERFLOW_CHECK;
                            end if;
                        end if;
                        
                    -- wait for product to be computed (d*d in statistics_accumulation)
                    -- MULICYCLE_FACTOR clock cycles 
                    when COMPUTE_STATS =>
                        if cycle_cnt = MULICYCLE_FACTOR - 1 then
                            square    := resize(q_run.sum*q_run.sum, POW_BITS);
                            q_end.max <= q_run.max;
                            q_end.min <= q_run.min;
                            q_end.sum <= q_run.sum;
                            q_end.var <= q_run.var - shift_right(square, bit_shifts_div) when GEN_VAR_DSP else (others => '0'); -- integer division (rounded)
                            cycle_cnt   <=  0 ;
                            stats_state <= WAIT_STATS;
                        else
                            cycle_cnt <= cycle_cnt + 1;
                        end if;
                    
                    -- wait for product to be computed (q_sum*q_sum in COMPUTE_STATS)
                    -- MULICYCLE_FACTOR clock cycles 
                    when WAIT_STATS => 
                       if cycle_cnt = MULICYCLE_FACTOR - 1 then
                            clear_block <= '1';
                            cycle_cnt   <=  0 ;
                            stats_state <= OVERFLOW_CHECK;
                        else
                            cycle_cnt <= cycle_cnt + 1;
                        end if;
                    
                    -- 1 clock cycle
                    -- total cycles for clear_block execution: SC = 2 x MULICYCLE_FACTOR + 2
                    -- for uniformly spaced samples (not relying on stats_busy), SC must extinguish before the next block: DECIMATION > SC
                    when OVERFLOW_CHECK =>
                        -- if not fitting OUT_BITS, flag as largest value
                        if SUM_BITS > OUT_BITS then
                            if q_end.sum(q_end.sum'left downto OUT_BITS) /= (q_end.sum'left downto OUT_BITS => '1') and 
                               q_end.sum(q_end.sum'left downto OUT_BITS) /= (q_end.sum'left downto OUT_BITS => '0') then
                                sum <= (others => '1');
                                sum(sum'left) <= '0';
                            else
                                sum <= std_logic_vector(resize(q_end.sum, OUT_BITS));
                            end if;
                        else
                            sum <= std_logic_vector(resize(q_end.sum, OUT_BITS));
                        end if;
                        if POW_BITS > OUT_BITS then
                            if q_end.var(q_end.var'left downto OUT_BITS) /= (q_end.var'left downto OUT_BITS => '0') then
                                var <= (others => '1');
                                var(var'left) <= '0';
                            else
                                var <= std_logic_vector(resize(q_end.var, OUT_BITS));
                            end if;
                        else
                            var <= std_logic_vector(resize(q_end.var, OUT_BITS));
                        end if;
                        max <= std_logic_vector(resize(q_end.max, OUT_BITS));
                        min <= std_logic_vector(resize(q_end.min, OUT_BITS));
                        new_sum_p <= '1';
                        stats_state <= WAIT_BLOCK_AVG;
                        
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
    
    sync_sum: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => clk,
        async_pulse_in => new_sum_p,
        async_in       => sum, 
        sync_out       => sum_o,
        sync_pulse_out => new_sum_p_o
      ); 
    sync_var: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => clk,
        async_pulse_in => new_sum_p,
        async_in       => var, 
        sync_out       => var_o,
        sync_pulse_out => open
      ); 
    sync_max: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => clk,
        async_pulse_in => new_sum_p,
        async_in       => max, 
        sync_out       => max_o,
        sync_pulse_out => open
      ); 
    sync_min: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => clk,
        async_pulse_in => new_sum_p,
        async_in       => min, 
        sync_out       => min_o,
        sync_pulse_out => open
      ); 
    
    sync_meas: entity work.vec_pulse_sync
      generic map ( N_BITS => OUT_BITS ) 
      port map (
        clk            => clk_sys,
        src_clk        => clk,
        async_pulse_in => new_meas_p,
        async_in       => meas, 
        sync_out       => meas_o,
        sync_pulse_out => new_meas_p_o
      );
      
--    pm_dbg: if DEBUG_CORES generate
--        state_v <= std_logic_vector(to_unsigned(stats_state_t'POS(stats_state), 3));
--        count_v <= std_logic_vector(resize(count, count_v'length));
--        ph_v    <= std_logic_vector(resize(     q_run.sum          , 32));
--        sm2_v   <= std_logic_vector(resize(     q_run.var          , 98));          
--        bsd_v   <= std_logic_vector(to_unsigned(bit_shifts_div , 16));
--        vrr_v   <= std_logic_vector(resize(     var                , 32));       
--        var_v   <= std_logic_vector(resize(     q_end.var          , 98));  
        
--        mf_v <= std_logic_vector(to_signed(MULICYCLE_FACTOR, 32));
--        mb_v <= std_logic_vector(to_signed(SUM_BITS, 32));
--        pb_v <= std_logic_vector(to_signed(POW_BITS, 32));
    
--        ila_dmon_var_i: entity work.ila_dmon_var
--        port map(
--            clk        => clk,
--            probe0(0)  => stats_rdy  ,
--            probe1(0)  => block_ready,
--            probe2(0)  => clear_block,
--            probe3(0)  => save_phase ,
--            probe4     => state_v    ,
--            probe5     => count_v    ,
--            probe6     => ph_v       ,
--            probe7     => sm2_v      ,
--            probe8     => bsd_v      ,
--            probe9     => vrr_v      ,
--            probe10    => var_v  
--        );
        
--        vio_phase_meas_i: entity work.vio_pm
--        port map(
--            clk        => clk,
--            probe_in0  => mf_v,
--            probe_in1  => mb_v,
--            probe_in2  => pb_v
--        ); 
--     end generate pm_dbg;

end Behavioral;
