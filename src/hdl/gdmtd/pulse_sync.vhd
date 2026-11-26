
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_sync is
    generic (
        STAGES : integer := 3
    );
    port (
		src_clk  : in  std_logic;
        clk      : in  std_logic;
        async_in : in  std_logic;
        sync_out : out std_logic
    );
end pulse_sync;

architecture Behavioral of pulse_sync is

    signal ext_async_pulse : std_logic := '0';
	signal ext_sync_pulse  : std_logic := '0';
	
	signal async_del   : std_logic := '0';
	signal toggle_src  : std_logic := '0';
	signal toggle_sync : std_logic := '0';
	signal toggle_del  : std_logic := '0';

begin

	toggle_async: process(src_clk) begin
        if rising_edge(src_clk) then
            async_del <= async_in;
            if async_in = '1' and async_del = '0' then
                toggle_src <= not toggle_src;
            end if;
        end if;
    end process;

	bit_sync_inst: entity work.bit_sync
		generic map ( STAGES => STAGES )
		port map (
			clk      => clk,
			async_in => toggle_src,
			sync_out => toggle_sync
		);
		
	any_edge_detect: process(clk) begin
        if rising_edge(clk) then
            toggle_del <= toggle_sync;
        end if;
    end process;
    
    sync_out <= toggle_sync xor toggle_del;

end Behavioral;
