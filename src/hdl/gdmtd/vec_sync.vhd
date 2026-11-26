
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vec_sync is
    generic (
        STAGES   : integer := 3;
		REG_IN   : boolean := false;  -- register input in the src_clk domain
		PAUSE_IN : integer := 0;      -- additional cycles to pause the input on src_clk domain
		EN_OUT   : boolean := true;   -- keep true when bits are not independent
		N_BITS   : integer := 31
    );
    port (
		src_clk        : in  std_logic;
        clk            : in  std_logic;
        async_in       : in  std_logic_vector(N_BITS-1 downto 0);
        sync_out       : out std_logic_vector(N_BITS-1 downto 0)
    );
end vec_sync;

architecture Behavioral of vec_sync is

    constant CNT_BITS     : integer := 16;
    signal pause_cnt      : unsigned(CNT_BITS-1 downto 0) := to_unsigned(0, CNT_BITS);
    
    signal async_reg_in   : std_logic_vector(N_BITS-1 downto 0) := (others => '0');
    signal async_reg_slow : std_logic_vector(N_BITS-1 downto 0) := (others => '0');
    signal sync_reg       : std_logic_vector(N_BITS-1 downto 0) := (others => '0');
    signal sync_reg2      : std_logic_vector(N_BITS-1 downto 0) := (others => '0');

begin

	reg_input: if REG_IN or PAUSE_IN > 0 generate
		process(src_clk) begin
			if rising_edge(src_clk) then
                async_reg_in <= async_in;
			end if;
		end process;
	else generate 
		async_reg_in <= async_in;
	end generate reg_input;
	
	pause_input: if PAUSE_IN > 0 generate
		process(src_clk) begin
			if rising_edge(src_clk) then
                if pause_cnt = PAUSE_IN-1 then
                    async_reg_slow <= async_reg_in;
                    pause_cnt <= to_unsigned(0, CNT_BITS);
                else
                    pause_cnt <= pause_cnt + 1;
                end if;
			end if;
		end process;
	else generate 
		async_reg_slow <= async_reg_in;
	end generate pause_input;

	sync_regs: for i in 0 to N_BITS-1 generate
		bit_sinc_inst: entity work.bit_sync
			generic map ( STAGES => STAGES )
			port map (
				clk      => clk,
				async_in => async_reg_slow(i),
				sync_out => sync_reg(i)
			);
	end generate sync_regs;
	
	reg_out: if EN_OUT generate 
        process(clk) begin
            if rising_edge(clk) then
                sync_reg2 <= sync_reg;
                if sync_reg = sync_reg2 then
                    sync_out <= sync_reg2;
                end if;
            end if;
        end process;
    else generate 
        sync_out <= sync_reg;
    end generate reg_out;

end Behavioral;