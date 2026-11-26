library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package gdmtd_pkg is

  type to_dmtd_t is record  -- ddmtd inputs
    hold_rst      : std_logic;
    dmtd_clk_p    : std_logic;
    dmtd_clk_n    : std_logic;
    beat_a_p      : std_logic;
    beat_a_n      : std_logic;
    beat_b_p      : std_logic;
    beat_b_n      : std_logic;
    first_ali     : std_logic;
    dly_reg_a     : unsigned(9 downto 0);
    dly_reg_b     : unsigned(9 downto 0);
    info_a        : std_logic_vector(39 downto 0);
    info_b        : std_logic_vector(39 downto 0);
    word_clk_a    : std_logic;
    word_clk_b    : std_logic;   
    n_avg         : unsigned(11 downto 0);
  end record;
  type to_dmtd_array_t is array (natural range <>) of to_dmtd_t;
  
  type from_dmtd_t is record  -- ddmtd outputs
    dly_reg_a   : unsigned(9 downto 0);
    dly_reg_b   : unsigned(9 downto 0);
    phase_count : std_logic_vector(31 downto 0);
    phase_avg   : std_logic_vector(31 downto 0);
    glitches    : std_logic_vector(31 downto 0);
    stdv        : std_logic_vector(31 downto 0);
    max         : std_logic_vector(31 downto 0);
    min         : std_logic_vector(31 downto 0);
    new_meas_p  : std_logic;
    new_sum_p   : std_logic;
  end record;
  type from_dmtd_array_t is array (natural range <>) of from_dmtd_t;
  
  type GDMTD_BRANCH_CONFIG_t is record  
    MODE          : integer  ; -- target type: 0 -> clock, 1 -> data targeting headers, 2 -> data targeting bits
    ALL_EDGES     : boolean  ; -- produce a pulse (for phase measurement) at every target detection, or limit to one pulse per beat period
    N_INFO        : integer  ; -- number of bits of the info_i port, relative to the data protocol
    DIVISIONS     : integer  ; -- beat period divisions: (MODE > 0) half the number of parallel bits on a word,
                               -- (MODE = 0) when the input clock period (T_in') is shorter than T_in(T_beat), set it to T_in/T_in'.
    TARGET_PERIOD : integer  ; -- (MODE > 0) number of word clock cycles in a data frame (i.e. words in a frame), if < 4, set it at 4, 
                               -- (MODE = 0) set to T_in'/Tin if T_in' > T_in, where T_in' is the input clock period and f_dmtd := g(T_in, N)       
    TARGET_VALUE  : std_logic; -- targeted sample value before edge to detect. with '1' a falling edge is detected.
    TARGET_BITS_N : integer  ; --(MODE = 1) number of equal bits (of TARGET_VALUE) to target on the header, must be unique in the header.
  end record;
  
  constant STD_CLOCK : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 0   ,
    ALL_EDGES     => true,
    N_INFO        => 1   ,
    DIVISIONS     => 1   , 
    TARGET_PERIOD => 1   ,
    TARGET_VALUE  => '1' ,
    TARGET_BITS_N => 1
    );
  constant HEADER_8B10B_40_6 : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 1   ,
    ALL_EDGES     => true,
    N_INFO        => 1   ,
    DIVISIONS     => 20  ,
    TARGET_PERIOD => 6   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 5
    );
  constant ALL_SERIAL_BITS : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 2   ,
    ALL_EDGES     => true,
    N_INFO        => 40   ,
    DIVISIONS     => 20  ,
    TARGET_PERIOD => 4   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 1
    );
  constant ONE_SERIAL_BIT : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 2   ,
    ALL_EDGES     => false,
    N_INFO        => 2   ,
    DIVISIONS     => 20  ,
    TARGET_PERIOD => 4   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 1
    );
  constant CLOCK_20X_ALL : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 0   ,
    ALL_EDGES     => true,
    N_INFO        => 1   ,
    DIVISIONS     => 20  ,
    TARGET_PERIOD => 1   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 1
    );
  constant CLOCK_20X_SINGLE : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 0   ,
    ALL_EDGES     => false,
    N_INFO        => 1   ,
    DIVISIONS     => 20  ,
    TARGET_PERIOD => 1   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 1
    );
  constant CLOCK_HALF_T : GDMTD_BRANCH_CONFIG_t := (
    MODE          => 0   ,
    ALL_EDGES     => true,
    N_INFO        => 1   ,
    DIVISIONS     => 1   , 
    TARGET_PERIOD => 2   ,
    TARGET_VALUE  => '1',
    TARGET_BITS_N => 1
    );
  

end package gdmtd_pkg;

package body gdmtd_pkg is
  
end package body gdmtd_pkg;
