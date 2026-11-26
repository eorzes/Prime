----------------------------------------------------------------------------------
-- Company: CERN - HPTD
-- Engineer: Edoardo Orzes
-- 
-- Create Date: 30/07/2025
-- Module Name: fsm_aligner

--  FSM automated byte aliner for manual alinment mode, using bit slide of GTH/Y transceiver.
--  The comma that is searched is k28.5 (x"BC"); expected to be in the least significant byte on the 4 bytes word, when aligned.
--  The FSM sends rxresets to maintain a fixed (even) parity in the number of bit slides - to achieve determinism among relocks.

-- Revision: v2.0
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity fsm_aligner is
  generic (
    CYCLES_WITHIN_FRAME         : integer := 6;  -- 6 rxusrclk cycles is the default window for searching for comma in SEARCH state before going to SLIDE or ALIGNED state.
    ERRORS_THRESHOLD_TO_REALIGN : integer := 16; -- 16 consecutive errors is the default threshold that triggers to SLIDE state from the ALIGNED state.
    ALIGN_THRESHOLD_TO_ALIGNED  : integer := 6;  -- 6 consecutive commas in the right position is the default threshold to set the byteAligned flag to 1.
    USER_WIDTH                  : integer := 32;
    CYCLES_BETWEEN_SLIDES       : integer := 33
  ); 
  port( 
    clk             : in  std_logic;
    rst             : in  std_logic;
    en              : in  std_logic;
    rxdata          : in  std_logic_vector(USER_WIDTH-1 downto 0);
    ctrl            : in  std_logic;   -- control for special symbols in 8b10b
    allow_odd_rst   : in  std_logic;
    rxSlide         : out std_logic;                       -- output for the transceiver's bitslide
    slideCount      : out std_logic_vector(8 downto 0); 
    oddsCount       : out std_logic_vector(8 downto 0);
    byteAligned     : out std_logic;
    rxreset_out     : out std_logic; -- connect to gtwizard_rx_reset_datapath
    lolCount        : out std_logic_vector(8 downto 0);
    -- debug for ILA
    st   : out std_logic_vector(2  downto 0); 
    aliC : out std_logic_vector(9 downto 0);
    r_t  : out std_logic
  );
end fsm_aligner;

architecture Behavioral of fsm_aligner is

    constant CYCLES_TO_WAIT_BETWEEN_SLIDES : integer := 35;      -- minimum time between assertions of rxslide is 32 rxusrclk cycles
    constant TDLOCK                        : integer := 10; --10e6 + 2300000; -- TDLOCK (CDR to data max time for LPM equaliser) is the time to wait after the reset before clk is in place
    
    signal rst_also_oddC : std_logic;
    
    -- COUNTERS --
    signal count       : integer range 0 to 50      := 0; -- > CYCLES_TO_WAIT_BETWEEN_SLIDES
    signal count_s     : integer range 0 to 1000    := 0; -- > 4*CYCLES_WITHIN_FRAME
    signal n_slide     : integer range 0 to 511     := 0; -- > 9 bits
    signal count_r     : integer range 0 to 50e6     := 0; -- > TDLOCK
    signal errorCount  : integer range 0 to 1000    := 0; -- > ERRORS_THRESHOLD_TO_REALIGN
    signal alignCount  : integer range 0 to 1000    := 0; -- > ALIGN_THRESHOLD_TO_ALIGNED
    signal n_odds      : integer range 0 to 511     := 0; -- > 9 bits 
    signal n_lol       : integer range 0 to 511     := 0; -- > 9 bits 
    signal rst_timeout : std_logic := '0';
    signal lolcount_en : std_logic := '0';
    signal lolstop     : std_logic := '0';
    signal wasAligned  : std_logic := '1';
    signal rxreset     : std_logic := '0';
    
    signal n_slide_v   : std_logic_vector(8 downto 0) := (others => '0'); -- > 9 bits
    signal byte_ali    : std_logic := '0';
    
    -- FSM STATES --
    type state_t is (START, SEARCH, SLIDE, RESET, ALIGNED);
    attribute ENUM_ENCODING: string;
    attribute ENUM_ENCODING of state_t: type is "000 001 010 011 100";
    signal state     : state_t := START;
    signal intState  : integer := 0;
    
begin

    intState <= state_t'POS(state);
    st   <= std_logic_vector(to_unsigned(intState, 3));
    aliC <= std_logic_vector(to_unsigned(alignCount, 10));
    r_t  <= rst_timeout;

    byteAligned <= byte_ali;
    slideCount  <= n_slide_v;
    n_slide_v   <= std_logic_vector(to_unsigned(n_slide, 9));
    oddsCount   <= std_logic_vector(to_unsigned(n_odds,  9));
    lolCount    <= std_logic_vector(to_unsigned(n_lol,   9));
                
    LOL : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' or lolcount_en = '0' then
                n_lol <= 0;
                lolstop <= '0';
            else
                if byte_ali = '0' and lolstop = '0' then
                    if n_lol < 510 then
                        n_lol <= n_lol + 1;
                        lolstop <= '1';
                    end if;
                end if;
                if byte_ali = '1' then
                    lolstop <= '0';
                end if;
            end if;
        end if;
     end process LOL;

    FSM : process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= START;
                if wasAligned = '1' then
                    n_odds <= 0; -- has to maintain the count among aligner_odd_rst
                    wasAligned <= '0';
                end if;
                count <= 0;
                count_r <= 0;
                n_slide <= 0;
                errorCount <= 0;
                alignCount <= 0;
                rst_timeout <= '0';
                lolcount_en <= '0';
            else
                if en = '1' then 
                    case(state) is 
                        when START =>
                            if count_r = TDLOCK-1 then    
                                count_r <= 0;
                                state <= SEARCH;
                            else 
                                count_r <= count_r + 1;
                            end if;
                        
                        when SEARCH => 
                            rst_timeout <= '0';
                            if count_s = CYCLES_BETWEEN_SLIDES-1 then
                                rst_timeout <= '1';
                                state <= SLIDE;
                            end if;
                            if ctrl = '1' and rxdata(7 downto 0) = x"BC" then
                                rst_timeout <= '1';
                                if alignCount = ALIGN_THRESHOLD_TO_ALIGNED-1 then
                                    --if allow_odd_rst = '1' and n_slide_v(0) = '1' then
                                    if allow_odd_rst = '1' and n_slide /= 0 then
                                        state <= RESET;  -- if slide count is odd is needed to reset again until it's even
                                        n_odds <= n_odds + 1 when n_odds < 510 else n_odds;
                                    else
                                        state <= ALIGNED;
                                        alignCount <= 0;
                                    end if;
                                else
                                    alignCount <= alignCount + 1;
                                end if;
                            end if;
                            
                        when RESET =>
                            rst_timeout <= '1';
                            --rst_timeout <= '0';
                            --state <= START;
                            
                        when SLIDE =>
                            rst_timeout <= '0';
                            if count = CYCLES_TO_WAIT_BETWEEN_SLIDES-1 then  
                                count <= 0;
                                state <= SEARCH;
                            else 
                                count <= count + 1;
                            end if;
                            if count = 2 then 
                                n_slide <= n_slide + 1 when n_slide < 510 else n_slide;
                            end if;
                            
                        when ALIGNED => 
                            rst_timeout <= '0';
                            if count_s > 2*CYCLES_WITHIN_FRAME then -- no comma detected
                                rst_timeout <= '1';
                                errorCount <= errorCount + 2;
                            end if;
                            if ctrl = '1' then
                                rst_timeout <= '1';
                                if rxdata(7 downto 0) = x"BC" then
                                    if errorCount > 0 then
                                        errorCount <= errorCount - 1;
                                    end if;
                                    if byte_ali = '0' then
                                        alignCount <= alignCount + 1;
                                    end if;
                                else 
                                    errorCount <= errorCount + 1;
                                end if;
                            end if;
                            if errorCount = ERRORS_THRESHOLD_TO_REALIGN-1 then
                                rst_timeout <= '1';
                                errorCount <= 0;
                                n_slide <= 0;
                                alignCount <= 0;
                                n_odds <= 0; -- alignment lost not due to aligner_odd_rst
                                state <= SLIDE;
                            end if;
                            if byte_ali = '1' then
                                lolcount_en <= '1';  -- maintained at 1 after fist successful alignemnt
                                wasAligned <= '1';
                            end if;
                            
                    end case;
                end if;
            end if;
        end if;
    end process;
        
    FSM_outputs: process(state, count, alignCount) begin
     
        rxSlide <= '0';
        rxreset <= '0';     
        byte_ali <= '0';
        
        case(state) is
            when START => 
            
            when SEARCH => 
                
            when RESET => 
                rxreset <= '1'; 

            when SLIDE => 
                if count = 1 or count = 2 then
                    rxSlide <= '1';
                end if;
                
            when ALIGNED =>
                if alignCount = ALIGN_THRESHOLD_TO_ALIGNED-1 then
                    byte_ali <= '1';
                end if;
                
        end case;
    end process;
    
    comma_time_out: process(clk) begin
        if rising_edge(clk) then
            if rst_timeout = '1' or rst = '1' then
                count_s <= 0;
            else
                if en = '1' and (state = SEARCH or state = ALIGNED) then 
                    count_s <= count_s + 1;
                end if;
            end if;
        end if;
    end process;
    
   reset_pulse: entity work.monostable
    generic map ( PULSE_WIDTH => 10 ) -- GT requires rxreset_out sync to sys_clk_gt (60MHz)
    port map (
      rst       => rst,
      clk       => clk,
      data_in   => rxreset,
      pulse_out => rxreset_out
    );

end Behavioral;
