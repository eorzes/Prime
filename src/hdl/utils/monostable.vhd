library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity monostable is
    generic (
        PULSE_WIDTH : positive := 1
    );
    port (
        rst       : in  std_logic;
        clk       : in  std_logic;
        data_in   : in  std_logic;
        pulse_out : out std_logic
    );
end monostable;

architecture Behavioral of monostable is
    signal delay       : std_logic := '0';
    signal edge_detect : std_logic;
    signal stretch_cnt : integer range 0 to PULSE_WIDTH-1 := 0;
    signal pulse_active : std_logic := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                delay <= '0';
            else
                delay <= data_in;
            end if;
        end if;
    end process;

    edge_detect <= data_in and not delay;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                stretch_cnt  <= 0;
                pulse_active <= '0';
            else
                if edge_detect = '1' then
                    stretch_cnt  <= PULSE_WIDTH - 1;
                    pulse_active <= '1';
                elsif stretch_cnt > 0 then
                    stretch_cnt  <= stretch_cnt - 1;
                    pulse_active <= '1';
                else
                    pulse_active <= '0';
                end if;
            end if;
        end if;
    end process;

    pulse_out <= pulse_active;

end Behavioral;