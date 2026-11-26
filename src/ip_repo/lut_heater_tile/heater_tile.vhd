----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Markus Happe, Christian Plessl 
-- 
-- Create Date:    12:49:15 04/24/2012 
-- Design Name: 
-- Module Name:    lut_oscilator - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--  modified by Edoardo Orzes, 26/2/2026, CERN, EP-ESE-BE, HPTD
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity heater_tile is
    generic (
        NUM_UNITS : integer := 256
    );
    port (
	    heater_clk : in std_logic; -- not used
        enable     : in std_logic  
    );
end heater_tile;

architecture Behavioral of heater_tile is

    attribute KEEP_HIERARCHY : string;
    attribute KEEP_HIERARCHY of Behavioral : architecture is "YES";

    signal lut_sig : std_logic_vector(NUM_UNITS-1 downto 0);
	
	attribute KEEP : string;
	attribute KEEP of Behavioral: architecture is "true";
	attribute KEEP of lut_sig : signal is "true";

    attribute DONT_TOUCH : string;
    attribute DONT_TOUCH of lut_sig : signal is "TRUE";
	
	attribute ALLOW_COMBINATORIAL_LOOPS : string;
	attribute ALLOW_COMBINATORIAL_LOOPS of lut_sig : signal is "TRUE";
    
begin

    GEN_UNITS: for i in 0 to NUM_UNITS-1 generate
        lut_inst : LUT6
			generic map (INIT => X"4444444444444444") -- Specify LUT Contents
			port map ( 	
				I0 => lut_sig(i), 
				I1 => enable, 
				I2 => lut_sig(i),
				I3 => lut_sig(i),
				I4 => lut_sig(i),
				I5 => lut_sig(i),
				O  => lut_sig(i)
			);
    end generate;
    
end Behavioral;
