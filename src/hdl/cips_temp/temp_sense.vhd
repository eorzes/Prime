----------------------------------------------------------------------------------
-- Company: CERN - HPTD
-- Engineer: Edoardo Orzes
-- 
-- Create Date: 02/04/2026
-- Module Name: temp_sense

-- moving average filter of N_AVG samples, returns sum output (to be divided by N_AVG)

-- Revision: v1.0
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity moving_avg_filter is
    generic ( N_AVG : integer := 250; TEMP_BITS : integer := 16 );
    port (
        clk          : in  std_logic; 
        rst          : in  std_logic;
        shift_value  : in  std_logic; -- pulse when new phase ready
        temp_in      : in  std_logic_vector(TEMP_BITS-1 downto 0);
        temp_sum_out : out std_logic_vector(31 downto 0) -- ensure the sum of N_AVG is fitting in 32 bits.
    );
end moving_avg_filter;

architecture Behavioral of moving_avg_filter is

    constant AVG_BITS_REQ : integer := TEMP_BITS + integer(ceil(log2(real(N_AVG)))); -- must be less than 33
    constant AVG_BITS     : integer := AVG_BITS_REQ when AVG_BITS_REQ <= 32 else 32;
    
    type q_array_t is array(0 to N_AVG-1) of unsigned(TEMP_BITS-1 downto 0);

    signal q_array   : q_array_t := (others => (others => '0')); 
    signal sum       : unsigned(AVG_BITS-1  downto 0) := (others => '0');
    signal oldest    : unsigned(TEMP_BITS-1 downto 0) := (others => '0');

begin
        
    SISO: process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                q_array <= (others => (others => '0'));
            elsif shift_value = '1' then
                q_array(0) <= unsigned(temp_in);
                for i in 1 to N_AVG-1 loop
                    q_array(i) <= q_array(i-1);
                end loop;
            end if;
        end if;
    end process;
    oldest <= q_array(N_AVG-1);

    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                sum <= (others => '0');
            elsif shift_value = '1' then
                sum <= sum + unsigned(temp_in) - oldest; 
            end if;
        end if;
    end process;
    
    temp_sum_out <= std_logic_vector(resize(sum, 32));

end Behavioral;
