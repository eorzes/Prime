--------------------------------------------------------------------------------
-- Type definition for the Register Space
--------------------------------------------------------------------------------
--
-- Francesco Martina @ 2023
-- v1.0
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package reg_space_pack is
    -- register space type (to be passed to the other modules)
    type reg_space_t is array (natural range <>) of std_logic_vector;
end reg_space_pack;