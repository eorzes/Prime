library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.gt_pkg.all;
use work.arrays_pkg.all; 

library unisim;
use unisim.vcomponents.all;

entity drp_to_apb3_map is
  generic (
    ACTIVE_CHs : integer_array(0 to 3) := (0, -1, -1, -1) -- array index is the channel in the QUAD, value is the GT index, -1 is unused channel
  );
  port(
    clk_i          : in  std_logic;
    from_gt_i      : in  from_gt_array_t(0 to 3);
    to_gt_i        : in  to_gt_array_t(0 to 3);
    gt_ctrl_i      : in  gt_ctrl_array_t(0 to 3);
    gt_stat_o      : out gt_stat_array_t(0 to 3);
    from_apb3_i    : in  from_apb3_t;
    to_apb3_o      : out to_apb3_t
  );
end drp_to_apb3_map;

architecture Behavioral of drp_to_apb3_map is

    signal reset   : std_logic_vector(0 to 3) := (others => '0');
    signal rst_and : std_logic;
    
    signal drpaddr : array_nb(0 to 3)(8 downto 0);            
    signal drpen   : std_logic_vector(0 to 3);
    signal drpdi   : array_nb(0 to 3)(15 downto 0);           
    signal drpdo   : array_nb(0 to 3)(15 downto 0); 
    signal drprdy  : std_logic_vector(0 to 3);
    signal drpwe   : std_logic_vector(0 to 3);
    
    signal txpippmovrden : std_logic_vector(0 to 3);
    signal txpippmsel    : std_logic_vector(0 to 3);
    signal txpippmpd     : std_logic_vector(0 to 3);
    
    -- get_property CH0_TX_PIPPM_CFG [get_cells -hier -filter {NAME =~ quads_inst/quad_inst/quad_inst/gty_quad_i/gt_quad_base/inst/quad_inst}]
    -- default value: 32'h02000002 = "00000010000000000000000000000010"  
    -- must be set with attribute (one per channel):
    -- DRP  use: set_property CH0_TX_PIPPM_CFG 32'h0200000A [get_cells -hier -filter {NAME =~ quads_inst/quad_inst/quad_inst/gty_quad_i/gt_quad_base/inst/quad_inst}]
    -- PORT use: set_property CH0_TX_PIPPM_CFG 32'h02000002 [get_cells -hier -filter {NAME =~ quads_inst/quad_inst/quad_inst/gty_quad_i/gt_quad_base/inst/quad_inst}]
    constant CH_TX_PIPPM_CFG : std_logic_vector(31 downto 0) := "00000010000000000000000000001010"; -- DRP use
  --constant CH_TX_PIPPM_CFG : std_logic_vector(31 downto 0) := "00000010000000000000000000000010"; -- PORT use
    
    signal to_apb3_out : to_apb3_t;
    signal apb3_start_val : array_nb(0 to 3)(31 downto 0) := (others => (others => '0'));
    
begin

    rst_and   <= and_reduce(reset);
    to_apb3_o <= to_apb3_out;

    CHs_flatmap: for i in 0 to 3 generate
        CH_signals: if ACTIVE_CHs(i) > -1 generate 
            reset(i)            <= not(from_gt_i(i).tx_rdy_sys) or to_gt_i(i).txpi.hold_rst;
            drpaddr(i)          <= gt_ctrl_i(i).drpaddr(8 downto 0) ;
            drpen(i)            <= gt_ctrl_i(i).drpen               ;
            drpdi(i)            <= gt_ctrl_i(i).drpdi               ;
            drpwe(i)            <= gt_ctrl_i(i).drpwe               ;
            gt_stat_o(i).drpdo  <= drpdo(i)                         ;
            gt_stat_o(i).drprdy <= drprdy(i)                        ;
            txpippmovrden(i)    <= gt_ctrl_i(i).txpippmovrden       ;
            txpippmsel(i)       <= gt_ctrl_i(i).txpippmsel          ;
            txpippmpd(i)        <= gt_ctrl_i(i).txpippmpd           ; 
            
            apb3_start_val(i)    <= CH_TX_PIPPM_CFG                 ;
--            apb3_start_val(i)(3) <= txpippmovrden(i)                ;
--            apb3_start_val(i)(1) <= txpippmsel(i)                   ;   
--            apb3_start_val(i)(0) <= txpippmpd(i)                    ;    
            
        end generate CH_signals;
    end generate CHs_flatmap; 

    drp_to_apb3: entity work.drp_to_apb3_bridge
        generic map ( CHANNEL_EN => ACTIVE_CHs )                                                                                                                                                                                               
        port map(                                                                                                                                                                                                 
            clk            => clk_i,                                                                                                                                                                                    
            rst            => rst_and,
            rst_ch         => reset,
                                                                                                                                      
            drpen          => drpen  ,                                                                                                                                                         
            drpwe          => drpwe  ,                                                                                                                                                                
            drpaddr        => drpaddr,                                                                                                                                                                  
            drpdi          => drpdi  ,     
            drpdo          => drpdo  ,                                                                                                                                                                
            drprdy         => drprdy ,                                                                                                         
                                                                                                                                                                                           
            apb3paddr      => to_apb3_out.paddr  ,                                                                                                                                                              
            apb3psel       => to_apb3_out.psel   ,                                                      
            apb3penable    => to_apb3_out.penable,                                                                                                                                                            
            apb3pwrite     => to_apb3_out.pwrite ,                                                                                                                                                                 
            apb3pwdata     => to_apb3_out.pwdata ,                                                       
            apb3prdata     => from_apb3_i.prdata ,                                                                                                                                                           
            apb3pready     => from_apb3_i.pready ,
            apb3pslverr    => from_apb3_i.pslverr,
            
            apb3_start_val => apb3_start_val,
            
            apb3pslverr_o  => to_apb3_out.pslverr_o,
            timeout_error  => to_apb3_out.timeout                                                                                                             
        );  
        
--    ila_apb3: entity work.ila_apb3_drp
--        port map(
--          clk          => clk_i,
--          probe0(0)    => rst_and,
--          probe1(0)    => txpippmovrden(0),
--          probe2(0)    => txpippmsel(0)     , 
--          probe3(0)    => txpippmpd(0)        , 
--          probe4       => to_apb3_out.paddr    ,
--          probe5(0)    => to_apb3_out.penable  ,
--          probe6       => from_apb3_i.prdata ,
--          probe7(0)    => from_apb3_i.pready ,
--          probe8(0)    => to_apb3_out.psel     ,
--          probe9(0)    => from_apb3_i.pslverr,
--          probe10      => to_apb3_out.pwdata   ,
--          probe11(0)   => to_apb3_out.pwrite
--      );   
        
end Behavioral;
