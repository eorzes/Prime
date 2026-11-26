
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_sync is
    generic (
        STAGES : integer := 3
    );
    port (
        clk      : in  std_logic;
        async_in : in  std_logic;
        sync_out : out std_logic
    );
end bit_sync;

architecture Behavioral of bit_sync is

    signal sync_reg : std_logic_vector(STAGES-1 downto 0) := (others => '0');

    -- this still requires a false path to avoid timing violations report
    attribute ASYNC_REG : boolean;
    attribute ASYNC_REG of sync_reg : signal is true;

begin

    xpm_cdc_single_inst : xpm_cdc_single
       generic map (
          DEST_SYNC_FF => STAGES,   
          SRC_INPUT_REG => false  
       )
       port map (
          dest_out => sync_out,
          dest_clk => clk, 
          src_clk  => '0',   
          src_in   => async_in     
       );

--    process(clk) begin
--        if rising_edge(clk) then
--            sync_reg(0) <= async_in;
--            for i in 1 to STAGES-1 loop
--                sync_reg(i) <= sync_reg(i-1);
--            end loop;
--        end if;
--    end process;
--    sync_out <= sync_reg(STAGES-1);

end Behavioral;