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

---- Designed by Edoardo Orzes 
---- CERN EP-ESE-BE, HPTD, 18 March 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.gdmtd_pkg.all;

entity target_time_dilation is
  generic (
    N           : integer := 100000;
    OUT_BITS    : integer := 20;
    MIX_IN      : boolean := true;    
    DEBUG_CORES : boolean := false;
    CFG         : GDMTD_BRANCH_CONFIG_t := STD_CLOCK
    );
  port ( 
    rst         : in   std_logic;
   
    word_clk    : in   std_logic;
    info_i      : in   std_logic_vector(CFG.N_INFO-1 downto 0);
    
    first_ali   : in   std_logic;
    delay_reg_i : in   unsigned(9 downto 0);
    delay_reg_o : out  unsigned(9 downto 0);
    
    dmtd_clk    : in   std_logic;
    sample_i    : in   std_logic;
   
    pulse_o     : out  std_logic;
    glitches_o  : out  std_logic_vector(15 downto 0)
    );
end target_time_dilation;

architecture Behavioral of target_time_dilation is

    constant PARALLEL_BITS : integer := 2*CFG.DIVISIONS;
    constant BIT_SCAN      : integer := integer(real(N)/real(PARALLEL_BITS));  -- cycles to scan one serial bit
    constant STABLE_VALUE  : integer := integer(real(1.0/4.0)*real(BIT_SCAN)); -- cycles to scan one stable value
    constant STABLE_EDGE   : integer := integer(real(1.0/3.0)*real(BIT_SCAN)); -- cycles to scan one stable edge
    constant T_MINUS_BIT   : integer := integer(real(N)*(1.0-2.0/real(PARALLEL_BITS))); -- cycles to scan one word minus one bit
    
    ------ LOGIC CONFIGURATION FOR TARGET DETECTION ------
    
    constant HEADER_SCAN    : integer := integer(real(CFG.TARGET_BITS_N-1)*real(BIT_SCAN));  -- cycles to scan a set of equal bits in the header
    constant TARGET_LENGTH  : integer := STABLE_VALUE when CFG.MODE /= 1 else HEADER_SCAN; -- cycles to scan the target before the edge to detect
    constant LOCK_THRESHOLD : integer := TARGET_LENGTH; 
    
    ------------------------------------------------------
    
    constant SHIFT_REG_INVERT_LEN  : integer := 32; -- MODE > 0, max delay for sample/info channels
    constant SHIFT_REG_SAMPLE_LEN  : integer := SHIFT_REG_INVERT_LEN/2;
    constant MAX_LOCK_TIME         : integer := N*CFG.TARGET_PERIOD;

    signal q_sync  : std_logic := '0'; -- input sample (gets synchronized if MIX_IN)
    signal q_del   : std_logic := '0'; -- MODE > 0, delayed (aligned) sample
    signal q_adj   : std_logic := '0'; -- MODE > 0, adjusted sample (inverted based on info_i logic) 
    signal q       : std_logic := '0'; -- sample ready for deglitcher
    signal q_buf   : std_logic := '0'; -- registered sample, only for glitch window count (statistics).
    
    type ali_state_t is (CHECK_LOCK, SHIFT, ALIGNED);
    attribute ENUM_ENCODING: string;
    attribute ENUM_ENCODING of ali_state_t: type is "00 01 10";
    signal ali_state : ali_state_t := CHECK_LOCK;
    
    signal shift_reg_invert     : std_logic_vector(SHIFT_REG_INVERT_LEN-1 downto 0) := (others => '0');
    signal shift_reg_sample     : std_logic_vector(SHIFT_REG_SAMPLE_LEN-1 downto 0) := (others => '0');
    signal shift_reg_invert_sel : unsigned(delay_reg_i'length-1 downto 0) := (others => '0');
    signal locked               : std_logic := '0';
    signal count_locked         : integer range 0 to (2**OUT_BITS)-1 := 0;
    
    signal count               : integer range 0 to (2**OUT_BITS)-1 := 0;
    signal count_tp_wordclk    : integer range 0 to 31 := 0;
    signal count_tp_dmtdclk    : integer range 0 to 31 := 0;
    signal counter_tp_top      : integer range 0 to 31 := CFG.TARGET_PERIOD-1;
    signal enable_q            : std_logic;
   
    signal pulse        : std_logic := '0';
    signal invert_async : std_logic := '0';
    signal invert       : std_logic := '0';
    signal invert_del   : std_logic := '0';
    signal scanned_bit  : integer range 0 to PARALLEL_BITS-1 := 0; 
    signal scanned_b_v  : std_logic_vector(14 downto 0);
    
    type state_t is (WAIT_TARGET, DEGLITCH_EDGE, WAIT_NEXT_WORD, REGISTER_EDGE);
    attribute ENUM_ENCODING of state_t: type is "00 01 10 11";
    signal state : state_t := WAIT_TARGET;
    
    signal count_valid_edge        : integer range 0 to (2**OUT_BITS)-1 := 0;
    signal start_glitch_window     : std_logic := '0';      
    signal count_free              : integer range 0 to (2**OUT_BITS)-1 := 0;
    signal count_glitches_running  : integer range 0 to (2**OUT_BITS)-1 := 0;
    signal count_glitches          : integer range 0 to (2**OUT_BITS)-1 := 0;
    signal glitches_reg            : std_logic_vector(15 downto 0) := (others => '0');
    
    signal start_target_counter : std_logic := '0';
    signal invert_logic         : std_logic := '0';
    
    ---- Debug
    signal shift_reg_v : std_logic_vector( 9 downto 0) := (others => '0');
    signal count_v     : std_logic_vector(19 downto 0) := (others => '0');
    signal count_s_v   : std_logic_vector(19 downto 0) := (others => '0');
    signal state_v     : std_logic_vector( 1 downto 0) := (others => '0');
    signal glitch_vL   : std_logic_vector( 9 downto 0) := (others => '0');
    signal glitchR_v   : std_logic_vector( 9 downto 0) := (others => '0');
    signal manual_vio  : std_logic_vector( 9 downto 0) := (others => '0');
    ----
        
begin

    ------ LOGIC CONFIGURATION FOR DATA STREAMS (MODE > 0) ------

    -- the target counter is free-running by default, counting modulo TARGET_PERIOD.
    -- it is used to downsample the info_i, for the control of the sample inversion logic.
    -- configure it as needed, depending on the data protocol. Leave it at '0' for MODE = 0 (clocks)
    start_target_counter <= '1' when (CFG.MODE = 1 and info_i(0) = '1') else '0'; -- here if MODE = 1, aligns to m_comma
    
    -- set invert_logic to control the sample inversion based on info_i. Not needed for MODE = 0 (clocks)
    -- here if MODE = 2, I create a clock-like time-dilated patter, 
    -- here if MODE = 1, I invert the sample when it is an m_comma (info_i(0) = '1') to get a time-dilated p_comma
    invert_logic <= '1' when (CFG.MODE = 2 and info_i(scanned_bit) = scanned_b_v(0)) or (CFG.MODE = 1 and info_i(0) = '1') else '0';
    scanned_b_v  <= std_logic_vector(to_unsigned(scanned_bit, scanned_b_v'length));
    
    -------------------------------------------------------------

    pulse_o <= pulse;
    
    MIXER: if MIX_IN generate
        bit_sync_input: entity work.bit_sync
            port map (
                clk      => dmtd_clk,
                async_in => sample_i, -- sampling (mixing) of DDMTD input signal
                sync_out => q_sync
            ); 
    else generate
        q_sync <= sample_i; -- avoid sampling and synchronizing if flip-flop is external, set input delay in .xdc
    end generate MIXER;
        
    GEN_CLOCK_INPUT_STAGE: if CFG.MODE = 0 and CFG.TARGET_PERIOD = 1 generate
        q <= q_sync;
    end generate GEN_CLOCK_INPUT_STAGE;
    
    GEN_DATA_INPUT_STAGE: if CFG.MODE > 0 generate 
    
        slow_down_invert: process(word_clk) begin
            if rising_edge(word_clk) then
                if count_tp_wordclk = CFG.TARGET_PERIOD-1 then
                    invert_async <= invert_logic;
                end if;
            end if;
        end process;
    
        bit_sync_invert: entity work.bit_sync
            port map (
                clk      => dmtd_clk,        
                async_in => invert_async,
                sync_out => invert   
            ); 
    
        shift_reg_delay_samples: process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                shift_reg_sample(0) <= q_sync;
                for i in 1 to SHIFT_REG_SAMPLE_LEN - 1 loop
                    shift_reg_sample(i) <= shift_reg_sample(i - 1);
                end loop;
            end if;
        end process;
        q_del      <= shift_reg_sample(SHIFT_REG_SAMPLE_LEN - 1);
        shift_reg_delay_invert: process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                shift_reg_invert(0) <= invert;
                for i in 1 to SHIFT_REG_INVERT_LEN - 1 loop
                    shift_reg_invert(i) <= shift_reg_invert(i - 1);
                end loop;
            end if;
        end process;
        invert_del <= shift_reg_invert(to_integer(unsigned(shift_reg_invert_sel)));
        
        invert_sample: q_adj <= not(q_del) when invert_del = '1' else q_del; 
        
        word_clk_counter_mod_tp: process(word_clk) begin
            if rising_edge(word_clk) then
                if rst = '1' then
                    count_tp_wordclk <= 0;
                else
                    if count_tp_wordclk = CFG.TARGET_PERIOD-1 or start_target_counter = '1' then
                        count_tp_wordclk <= 0; 
                    else
                        count_tp_wordclk <= count_tp_wordclk + 1; 
                    end if;
                end if;
            end if;
        end process;
        
    end generate GEN_DATA_INPUT_STAGE;
    
    downsampling: if CFG.MODE > 0 or CFG.TARGET_PERIOD > 1 generate
    
        target_filter_enable: enable_q <= '1' when count_tp_dmtdclk = counter_tp_top else '0';
        target_filter: process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    q <= '0';
                else
                    if enable_q = '1' then
                        q <= q_adj when CFG.MODE > 0 else q_sync;
                    end if;
                end if;
            end if;
        end process;
        
        -- downsampling explanation:
        -- after the target edge detection, the scanning is moved back by one word (count_tp_dmtdclk up to counter_tp_top), 
        -- this way the scanning occurs always on the targeted word.
        -- an edge detection pulse is generated every N samples. Without this intervention, it would take N*TARGET_PERIOD samples.
        dmtd_clk_counter_mod_tp: process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    count_tp_dmtdclk <= 0;
                else
                    if count_tp_dmtdclk = CFG.TARGET_PERIOD-1 then
                        count_tp_dmtdclk <= 0; 
                    else
                        count_tp_dmtdclk <= count_tp_dmtdclk + 1; 
                    end if;
                end if;
            end if;
        end process;
        
    end generate downsampling;
    
    deglitcher_state_machine: process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            if rst = '1' then
                count <=  0 ;
                pulse <= '0';
                counter_tp_top <= CFG.TARGET_PERIOD-1;
                scanned_bit <= 0;
                state <= WAIT_TARGET;
            else
                case(state) is
                
                    when WAIT_TARGET =>
                        pulse <= '0';
                        if count = TARGET_LENGTH - 1 then
                            count <= 0;
                            state <= DEGLITCH_EDGE;
                        elsif q = CFG.TARGET_VALUE then
                            count <= count + 1;
                        else
                            count <= 0;
                        end if;

                    when DEGLITCH_EDGE =>
                        pulse <= '0';
                        if count = STABLE_EDGE - 1 then
                            count <= 0;
                            state <= REGISTER_EDGE;
                        elsif q = not(CFG.TARGET_VALUE) then
                            count <= count + 1;
                            if count = 0 then
                                scanned_bit <= scanned_bit + 1 when scanned_bit < PARALLEL_BITS-1 else 0;
                            end if;
                        end if;

                    when REGISTER_EDGE =>
                        pulse <= '1';
                        -- with MODE > 0, the ddmtd scanning hast to me limited to one word clock period, 
                        -- or the alignment with info_i is lost for N*TARGET_PERIOD-1 cycles and latency increases by TARGET_PERIOD
                        if (CFG.MODE > 0 and not(CFG.MODE = 2 and CFG.ALL_EDGES and scanned_bit < PARALLEL_BITS-1)) 
                           or (CFG.MODE = 0 and CFG.TARGET_PERIOD > 1) then 
                            counter_tp_top <= counter_tp_top-1 when counter_tp_top > 0 else CFG.TARGET_PERIOD-1;
                        end if;
                        scanned_bit <= (scanned_bit + 1) when (CFG.ALL_EDGES and scanned_bit < PARALLEL_BITS-1) else 0;
                        state <= WAIT_TARGET when CFG.ALL_EDGES else WAIT_NEXT_WORD;
                        
                    when WAIT_NEXT_WORD =>
                        pulse <= '0';
                        if count = T_MINUS_BIT - 1 then
                            count <= 0;
                            state <= WAIT_TARGET;
                        else
                            count <= count + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;
    
    -- at startup, control the delay (shift_reg_*_sel) until check_lock = '1'
    locked <= '1' when count = LOCK_THRESHOLD-1 else '0';
    startup_alignment_FSM: if CFG.MODE > 0 generate 
        process(dmtd_clk) begin
            if rising_edge(dmtd_clk) then
                if rst = '1' then
                    count_locked <= 0;
                    ali_state <= CHECK_LOCK when first_ali = '1' else ALIGNED;
                    if first_ali = '1' then
                        shift_reg_invert_sel <= (others => '0');
                    end if;
                else
                    case(ali_state) is
                    
                        when CHECK_LOCK =>
                            if locked = '1' then
                                shift_reg_invert_sel <= shift_reg_invert_sel + 1;
                                count_locked <= 0;
                                ali_state <= ALIGNED;
                            elsif count_locked = MAX_LOCK_TIME-1 then
                                count_locked <= 0;
                                ali_state <= SHIFT;
                            else
                                count_locked <= count_locked + 1;
                            end if;
                            
                        when SHIFT =>
                            if shift_reg_invert_sel = SHIFT_REG_INVERT_LEN-1 then
                                shift_reg_invert_sel <= (others => '0');
                            else
                                shift_reg_invert_sel <= shift_reg_invert_sel + 1;
                            end if;
                            ali_state <= CHECK_LOCK;
                            
                        when ALIGNED =>
                            if first_ali = '0' then
                                shift_reg_invert_sel <= delay_reg_i + unsigned(manual_vio);
                            else
                                delay_reg_o <= shift_reg_invert_sel;
                            end if;
                            -- alignemnt depends only on routing length
                            -- it is performed only once
                            
                    end case;
                end if;
            end if;
        end process;
    else generate 
        delay_reg_o <= (others => '0');
        shift_reg_invert_sel <= (others => '0');
    end generate startup_alignment_FSM;
    
    -- optional process to check the period of the pulses (should be around N)
    count_between_pulses: process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            if rst = '1' then
                count_valid_edge <= 0;
            else
                if pulse = '1' then
                    count_valid_edge <= 0;
                else
                    count_valid_edge <= count_valid_edge + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- optional process to measure the range of glitches on the detected edge (statistics)
    -- wide range of glitches provides natural dithering for accurate measurements
    glitch_count_helper: process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            q_buf <= '0' when rst = '1' else q;
        end if;
    end process;
    glitch_window_counter: process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            if state = DEGLITCH_EDGE then
                if start_glitch_window = '1' then
                    count_free <= count_free + 1;
                end if;
                if q = not(q_buf) then
                    start_glitch_window <= '1';
                    count_glitches_running <= count_free;
                end if;
                if count_free - count_glitches_running > STABLE_VALUE - 1 then
                    count_glitches <= count_glitches_running;
                end if;
            else
                start_glitch_window <= '0';
                count_free <= 0;
            end if;
        end if;
    end process;
    glitches_reg <= std_logic_vector(to_unsigned(count_glitches, 16));
    pre_sync_vector: process(dmtd_clk) begin
        if rising_edge(dmtd_clk) then
            glitches_o <= glitches_reg;
        end if;
    end process;
      
--    deg_debug_cores: if DEBUG_CORES generate
--    ---- debug ----
    shift_reg_v <= std_logic_vector(shift_reg_invert_sel);
    count_v     <= std_logic_vector(to_unsigned(count, 20));
    count_s_v   <= std_logic_vector(to_unsigned(count_valid_edge, 20));
    state_v     <= std_logic_vector(to_unsigned(state_t'POS(state), 2));
    glitch_vL   <= std_logic_vector(to_unsigned(count_glitches, 10));
    glitchR_v   <= std_logic_vector(to_unsigned(count_glitches_running, 10));
    
--    vio_dmtd: entity work.vio_dd
--        port map(
--            clk           => dmtd_clk,
--            probe_in0(0)  => locked,
--            probe_in1     => shift_reg_v,
--            probe_out0    => manual_vio
--        ); 
    
--    ila_dmtd: entity work.ila_dbg
--        port map(
--            clk           => dmtd_clk,
--            probe0(0)     => q,--count_v,         -- deglitcher counter (for pattern recognition)  
--            probe1        => count_s_v,       -- count between pulses (N when locked)    
----            probe2        => glitch_vL,       -- glitch counter                                
----            probe3        => glitchR_v,       -- glitch running counter  
--            probe2        => scanned_b_v,
--            probe3(0)     => pulse                
----            probe4        => state_v,         -- deglitcher FSM state                          
----            probe5(0)     => rst,             -- external reset                                
----            probe6(0)     => invert,          -- sample inversion command from info flag    
----            probe7(0)     => invert_del,      -- sample inversion command, aligned to data sample                   
----            probe8(0)     => enable_q,        -- target filter FF enable     
----            probe9(0)     => q_ad,           -- sample after inversion     
----            probe10(0)    => q                -- sample after target filter  
----            probe11(0)    => pulse            -- output pulse of edge detection              
--        );
--     end generate deg_debug_cores;
  
end Behavioral;