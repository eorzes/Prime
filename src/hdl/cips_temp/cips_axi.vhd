----------------------------------------------------------------------------------
-- Company: CERN - HPTD
-- Engineer: Edoardo Orzes
-- 
-- Create Date: 02/04/2026
-- Module Name: temp_sense

-- Instantiates a block design with the CIPS (Control, Interfaces and Processing System) and an AXI4LITE bridge,
-- CIPS is configured to connect the PS PMC (Processing System - Platform Management Controller) to the PL (Programmable Logic).
-- a state machine (in versal_sysmon_temp_reader) reads temperature via AXI, 
-- a moving average filter of N_AVG samples takes 10s to produce the averaged output.

-- Versal Adaptive SoC Register Reference (AM012): PMC_SYSMON_CSR Module Register Summary
-- DEVICE_TEMP absolute address: 0x00F1271030 (PMC_SYSMON_CSR)

-- Revision: v1.0
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cips_axi_temp is
    port(
        clk          : in  std_logic;
        rstn         : in  std_logic;
        temp_sum_out : out std_logic_vector(31 downto 0) -- accurate after 10 seconds from startup - to be divided by N_AVG
    );
end cips_axi_temp;

architecture Behavioral of cips_axi_temp is

    constant SYSMON_CLK_FREQ : integer := 333*10**6;
    constant N_AVG           : integer := 200;
    constant READ_INTERVALS  : integer := (SYSMON_CLK_FREQ/N_AVG) * 10; -- sets a 10s average window

    signal PL_cips_out_clk : std_logic;
    signal temp_pulse      : std_logic;  
    signal temp            : std_logic_vector(15 downto 0);                      
    signal temp_error      : std_logic;  
    signal temp_sum_async  : std_logic_vector(31 downto 0);
    signal rstn_sync       : std_logic;
                                                      
    signal m_axi_araddr    : std_logic_vector(31 downto 0);
    signal m_axi_arvalid   : std_logic;                    
    signal m_axi_arready   : std_logic;                    
    signal m_axi_rdata     : std_logic_vector(31 downto 0);
    signal m_axi_rresp     : std_logic_vector(1 downto 0); 
    signal m_axi_rvalid    : std_logic;                    
    signal m_axi_rready    : std_logic;    

begin

    CIPS_inst: entity work.cips_wrapper
        port map (
            S00_AXI_0_araddr  => m_axi_araddr,
            S00_AXI_0_arprot  => (others => '0'),
            S00_AXI_0_arvalid => m_axi_arvalid,
            S00_AXI_0_arready => m_axi_arready,
            S00_AXI_0_rdata   => m_axi_rdata,
            S00_AXI_0_rresp   => m_axi_rresp,
            S00_AXI_0_rvalid  => m_axi_rvalid,
            S00_AXI_0_rready  => m_axi_rready,
            aresetn_0         => rstn,
            pl0_ref_clk       => PL_cips_out_clk -- 333 MHz
        );
    
    axi_to_temp: entity work.versal_sysmon_temp_reader
        generic map ( C_READ_INTERVAL_CYC => READ_INTERVALS ) -- 333M/200 * 10 -> 200 measures in 10s window
        port map (
            clk             => PL_cips_out_clk,
            rst_n           => rstn_sync,
                        
            temp_pulse      => temp_pulse,
            temp_raw        => temp,
            error           => temp_error,
    
            m_axi_araddr    => m_axi_araddr ,
            m_axi_arvalid   => m_axi_arvalid,
            m_axi_arready   => m_axi_arready,
            m_axi_rdata     => m_axi_rdata  ,
            m_axi_rresp     => m_axi_rresp  ,
            m_axi_rvalid    => m_axi_rvalid ,
            m_axi_rready    => m_axi_rready 
         );
     
     moving_avg: entity work.moving_avg_filter
        generic map ( N_AVG => N_AVG, TEMP_BITS => 16 )
        port map (
            clk          => PL_cips_out_clk,
            rst          => '0',
            shift_value  => temp_pulse,
            temp_in      => temp,
            temp_sum_out => temp_sum_async
        );
        
     bus_synch: entity work.synch
      generic map ( NBITS => 32, CLK_IN => true ) 
      port map (
        clk            => clk,
        clk_start      => PL_cips_out_clk,
        data_asynch_in => temp_sum_async, 
        data_synch_out => temp_sum_out
      ); 
      
     bit_synch: entity work.synch
      port map (
        clk               => PL_cips_out_clk,
        clk_start         => '0',
        data_asynch_in(0) => rstn, 
        data_synch_out(0) => rstn_sync
      ); 
     
     ila_temp_i: entity work.ila_temp
        port map(
          clk       => PL_cips_out_clk,
          probe0    => temp,
          probe1(0) => temp_pulse,
          probe2(0) => temp_error
      ); 

end Behavioral;
