----------------------------------------------------------------------------------
-- Company: CERN - HPTD
-- Engineer: Edoardo Orzes
-- 
-- Create Date: 19/11/2025 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;


entity synch is
  generic (
    NBITS  : integer := 1;
    CLK_IN : boolean := false;
    HARD   : boolean := false;
    GRAY   : boolean := false -- ATTENTION: use only if a single bit changes at a time!!! requires CLK_IN, keeps bits correlation 
  ); 
  port(
    clk            : in  std_logic;
    clk_start      : in  std_logic; -- required if CLK_IN
    data_asynch_in : in  std_logic_vector(NBITS-1 downto 0); -- if 1 bit, connect as data_asynch_in => (0 => signal )
    data_synch_out : out std_logic_vector(NBITS-1 downto 0)  -- if 1 bit, connect as data_synch_out(0) => signal 
  );
end synch;

architecture Behavioral of synch is
    
begin

    gen: if GRAY and NBITS > 1 generate
        xpm_cdc_array_single_inst : xpm_cdc_gray
               generic map (
                 DEST_SYNC_FF => 4,          -- DECIMAL; range: 2-10
                 REG_OUTPUT => 0,            -- DECIMAL; 0=disable registered output, 1=enable registered output
                 WIDTH => NBITS                  -- DECIMAL; range: 2-32
                 ) port map (
                 dest_out_bin => data_synch_out, -- WIDTH-bit output: Binary input bus (src_in_bin) synchronized to
                                             -- destination clock domain. This output is combinatorial unless REG_OUTPUT
                                             -- is set to 1.
                 dest_clk => clk,         -- 1-bit input: Destination clock.
                 src_clk => clk_start,           -- 1-bit input: Source clock.
                 src_in_bin => data_asynch_in      -- WIDTH-bit input: Binary input bus that will be synchronized to the
                                             -- destination clock domain.
               );
    elsif NBITS > 1 generate
        xpm_cdc_array_single_inst : xpm_cdc_array_single
            generic map (
              DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
              SRC_INPUT_REG => CLK_IN,  -- DECIMAL; 0=do not register input, 1=register input
              WIDTH => NBITS           -- DECIMAL; range: 1-1024
            ) port map (
              dest_out => data_synch_out, -- WIDTH-bit output: src_in synchronized to the destination clock domain. This
                                    -- output is registered.
              dest_clk => clk, -- 1-bit input: Clock signal for the destination clock domain.
              src_clk => clk_start,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
              src_in => data_asynch_in      -- WIDTH-bit input: Input single-bit array to be synchronized to destination clock
                                    -- domain. It is assumed that each bit of the array is unrelated to the others.
                                    -- This is reflected in the constraints applied to this macro. To transfer a binary
                                    -- value losslessly across the two clock domains, use the XPM_CDC_GRAY macro
                                    -- instead.
            );
    elsif HARD generate 
        HARD_SYNC_inst : HARD_SYNC
           generic map (
              LATENCY => 2            -- 2-3
           )
           port map (
              DOUT => data_synch_out(0),  -- 1-bit output: Data
              CLK => clk,                 -- 1-bit input: Clock
              DIN => data_asynch_in(0)    -- 1-bit input: Data
           );
      else generate
        xpm_cdc_single_inst : xpm_cdc_single
           generic map (
              DEST_SYNC_FF => 4,   -- DECIMAL; range: 2-10
              SRC_INPUT_REG => CLK_IN   -- DECIMAL; 0=do not register input, 1=register input
           )
           port map (
              dest_out => data_synch_out(0), -- 1-bit output: src_in synchronized to the destination clock domain. This output
                                    -- is registered.
              dest_clk => clk, -- 1-bit input: Clock signal for the destination clock domain.
              src_clk => clk_start,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
              src_in => data_asynch_in(0)      -- 1-bit input: Input signal to be synchronized to dest_clk domain.
           );
    end generate gen;
     
  

end Behavioral;