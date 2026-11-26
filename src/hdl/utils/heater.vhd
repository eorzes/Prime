library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
--use ieee.math_real.all;
library unisim;
use unisim.vcomponents.all;

entity heater_wrap is
    generic (
		N_DEVICES   : integer := 10;  --40
		BLOCK_SCALE : integer := 3    -- total heaters = N_DEVICES * BLOCK_SCALE * NUM_UNITS
    );
    port (
--        clk  : in std_logic; -- the faster, the hotter
		rdy  : in std_logic;  -- turn on and off the heater, async
		ctrl : in std_logic_vector(19 downto 0) -- how many devices to turn on
    );
end heater_wrap;

architecture Behavioral of heater_wrap is

--    constant STARTUP_TIME_S : real := 120.0; -- seconds
--    constant CLK_FREQ_HZ    : real := 500_000_000.0;
--    constant STARTUP_CNT    : integer := integer(STARTUP_TIME_S * CLK_FREQ_HZ / real(N_DEVICES));
    
--    signal heater_clk   : std_logic;
--	signal rdy_sync     : std_logic := '0';
	signal enables      : std_logic_vector(N_DEVICES-1 downto 0) := (others => '0');
	
--	signal counter      : integer range 0 to STARTUP_CNT-1 := 0;
--	signal device_en    : std_logic_vector(N_DEVICES-1 downto 0) := (others => '0');
--	signal slow_enable  : std_logic := '0';
--	signal slow_disable : std_logic := '0';
	

begin 

--   bit_synch_rdy_to_heat: entity work.synch
--    port map (
--      clk               => clk,
--      clk_start         => '0',
--      data_asynch_in    => (0 => rdy),
--      data_synch_out(0) => rdy_sync
--    ); 

--   BUFGCE_inst : BUFGCE
--       generic map (
--          CE_TYPE    => "SYNC",
--          SIM_DEVICE => "ULTRASCALE_PLUS" 
--       )
--       port map (
--          O  => heater_clk,   
--          CE => rdy_sync,   
--          I  => clk          
--       );
    
    ENABLES_GEN : for i in 0 to N_DEVICES-1 generate
        enables(i) <= '1' when unsigned(ctrl) > i else '0';
    end generate;

	DEVICES_GEN: for i in 0 to N_DEVICES-1 generate
	   BLOCKS_GEN: for j in 0 to BLOCK_SCALE-1 generate
          u_tile : entity work.heater_tile_0
              port map (
                  heater_clk => '0', --heater_clk,
                  enable     => enables(i) and rdy
              );
       end generate;
    end generate;
    
--    slow_enable  <= '1' when (rdy_sync = '1' and device_en /= (device_en'range => '1')) else '0';
--    slow_disable <= '1' when (rdy_sync = '0' and device_en /= (device_en'range => '0')) else '0';
--    process(clk) begin
--        if rising_edge(clk) then
--            if slow_enable = '1' or slow_disable = '1' then
--                counter <= counter + 1;
--                if counter = STARTUP_CNT-1 then
--                    counter <= 0;
--                    if slow_enable = '1' then
--                        device_en <= device_en(N_DEVICES-2 downto 0) & '1';
--                    else
--                        device_en <= device_en(N_DEVICES-2 downto 0) & '0';
--                    end if;
--                end if;
--            end if;
--        end if;
--    end process;
    
    
end Behavioral;
