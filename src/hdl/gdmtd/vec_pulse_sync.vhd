
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vec_pulse_sync is
    generic (
        STAGES : integer := 3;
		REG_IN : boolean := false;  -- register input in the src_clk domain
		N_BITS : integer := 31
    );
    port (
		src_clk        : in  std_logic; -- source clock, mandatory for pulse sync
        clk            : in  std_logic; -- destination clock
        async_pulse_in : in  std_logic;
        async_in       : in  std_logic_vector(N_BITS-1 downto 0);
        sync_out       : out std_logic_vector(N_BITS-1 downto 0);
        sync_pulse_out : out std_logic
    );
end vec_pulse_sync;

architecture Behavioral of vec_pulse_sync is

    signal async_reg_in : std_logic_vector(N_BITS-1 downto 0) := (others => '0');
    signal sync_reg     : std_logic_vector(N_BITS-1 downto 0) := (others => '0');
    
    signal sync_pulse   : std_logic := '0';

begin

	reg_input: if REG_IN generate
		process(src_clk) begin
			if rising_edge(src_clk) then
				async_reg_in <= async_in;
			end if;
		end process;
	else generate 
		async_reg_in <= async_in;
	end generate reg_input;

	sync_regs: for i in 0 to N_BITS-1 generate
		bit_sync_inst: entity work.bit_sync
			generic map ( STAGES => STAGES )
			port map (
				clk      => clk,
				async_in => async_reg_in(i),
				sync_out => sync_reg(i)
			);
	end generate sync_regs;
	
	bit_sync_pulse: entity work.pulse_sync
	   generic map ( STAGES => STAGES )
       port map (
         clk      => clk,
         src_clk  => src_clk,
         async_in => async_pulse_in, 
         sync_out => sync_pulse
       ); 
	
	reg_out: process(clk) begin
        if rising_edge(clk) then
            if sync_pulse = '1' then
                sync_out       <= sync_reg;
                sync_pulse_out <= '1';
            else
                sync_pulse_out <= '0';
            end if;
        end if;
    end process;

end Behavioral;