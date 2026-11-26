################################
####  Pinout
################################

#### System Clock
set_property PACKAGE_PIN AW27 [get_ports clk_freerun_p]   ;#LPDDR4_SMA_CLK2_P
set_property IOSTANDARD DIFF_LVSTL_11 [get_ports clk_freerun_*]

#### Transceivers
set_property PACKAGE_PIN M15 [get_ports gt_refclk_p] ;# FMCP1_GBTCLK0_M2C_C_P

#set_property PACKAGE_PIN AB2 [get_ports gt_rx_p[0] ] ;# FMCP1_DP0_M2C_P
                                                           
#set_property PACKAGE_PIN AA4 [get_ports gt_rx_p[1] ] ;# FMCP1_DP1_M2C_P

set_property PACKAGE_PIN AB2 [get_ports gt_rx_p[0] ] ;# FMCP1_DP0_M2C_P
set_property PACKAGE_PIN AB1 [get_ports gt_rx_n[0] ] ;# FMCP1_DP0_M2C_N
set_property PACKAGE_PIN AB7 [get_ports gt_tx_p[0] ] ;# FMCP1_DP0_C2M_P
set_property PACKAGE_PIN AB6 [get_ports gt_tx_n[0] ] ;# FMCP1_DP0_C2M_N
                                                           
set_property PACKAGE_PIN AA4 [get_ports gt_rx_p[1] ] ;# FMCP1_DP1_M2C_P
set_property PACKAGE_PIN AA3 [get_ports gt_rx_n[1] ] ;# FMCP1_DP1_M2C_N
set_property PACKAGE_PIN AA9 [get_ports gt_tx_p[1] ] ;# FMCP1_DP1_C2M_P
set_property PACKAGE_PIN AA8 [get_ports gt_tx_n[1] ] ;# FMCP1_DP1_C2M_N

#### DDMTD inputs
#set_property PACKAGE_PIN AV23  [get_ports ddmtdclk_in_p] ;# FMCP1_CLK0_M2C_P
#set_property IOSTANDARD LVDS15 [get_ports ddmtdclk_in_*]

#set_property PACKAGE_PIN AW24 [get_ports beat_DRx_p] ;# FMCP1_LA02_p
#set_property PACKAGE_PIN BE19 [get_ports beat_DTx_p] ;# FMCP1_LA21_p
                                               
##set_property PACKAGE_PIN AY22 [get_ports beat_URx_p] ;# FMCP1_LA15_p
#set_property PACKAGE_PIN BC25 [get_ports beat_UTx_p] ;# FMCP1_LA07_p 

#set_property IOSTANDARD    LVDS15    [get_ports beat_D*];
#set_property DC_BIAS       DC_BIAS_1 [get_ports beat_D*];
#set_property DIFF_TERM_ADV TERM_100  [get_ports beat_D*];

#set_property IOSTANDARD    LVDS15    [get_ports beat_U*];
#set_property DC_BIAS       DC_BIAS_1 [get_ports beat_U*];
#set_property DIFF_TERM_ADV TERM_100  [get_ports beat_U*];

### DC_BIAS provides an internal bias to both P and N pins used as an input in scenarios where 
### an AC coupled differential signal needs to be re-biased such that the LVDS15 receiver 
### specifications are met. The DC_BIAS feature creates a bias through an equivalent 
### voltage divider network to the bank's VCCO. The DC_BIAS attribute can be added to the XDC:
### set_property DC_BIAS DC_BIAS_0|DC_BIAS_1|DC_BIAS_2|DC_BIAS_3 [get_ports port_name]
### The DC_BIAS_1 setting provides the equivalent to 192 ? at 20% VCCO. In a 1.5V bank, 
### the combination of DIFF_TERM_ADV and DC_BIAS_1 provide an appropriate termination and bias
### for an AC coupled LVDS link without the need for bias or termination components on the PCB.

#### HPC1 - RxUsrClk
#set_property PACKAGE_PIN AP19  [get_ports rxUserClk_p];# FMCP1_CLK1_M2C_P #### Red HTG_FMC_SMA CLK_IN
#set_property PACKAGE_PIN AP18  [get_ports rxUserClk_n];# FMCP1_CLK1_M2C_N 
set_property PACKAGE_PIN BD23  [get_ports rxUserClk_p];# FMCP1_LA00_CC_P
set_property IOSTANDARD LVDS15 [get_ports rxUserClk_*]

#### Ethernet (lower zSFP)
set_property PACKAGE_PIN L40 [get_ports eth_gtrefclk_n] ;# ZSFP_SI570_CLK_C_N

set_property PACKAGE_PIN K46 [get_ports rxp_eth_sfp] ;# SFP0_RX_P

#### IIC (for ethernet module, no connection required)
set_property PACKAGE_PIN BD22 [get_ports sda] ;#FMCP1_LA01_CC_N
set_property PACKAGE_PIN BC23 [get_ports scl] ;#FMCP1_LA01_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports sda]
set_property IOSTANDARD LVCMOS15 [get_ports scl]

#### SFP enable (for Ethernet)
set_property PACKAGE_PIN G21 [get_ports SFP0_enable] ;# SFP0_TX_DISABLE_B (SFP on the right, when FMCs are on the right)
set_property IOSTANDARD LVCMOS33 [get_ports SFP0_enable]
set_property PACKAGE_PIN H21 [get_ports SFP1_enable] ;# SFP1_TX_DISABLE_B
set_property IOSTANDARD LVCMOS33 [get_ports SFP1_enable]

################################
####  GT Attributes
################################

### quads_inst/quad_inst[0].mgt/quad_inst/inst/intf_quad_map_inst/quad_top_inst/gt_quad_base_0_inst/inst
### *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*

### to distinguish commas, set RX_DEC_PCOMMA_DET to 0, RX_DEC_MCOMMA_DET to 1, so that CH*_RXCTRL2 is 1 only for m_comma, 
### then combine CH*_RXCTRL0 (for k characters) with rxdata to detect p_comma
### get_property CH0_RX_PCS_CFG2 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
### 32'h0005C100
set_property CH0_RX_PCS_CFG2 32'h00054100 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
set_property CH1_RX_PCS_CFG2 32'h00054100 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]

### disable auto alignment on commas with RX_PCOMMA_ALIGNEN = 0, RX_MCOMMA_ALIGNEN = 0
###get_property CH0_RX_PCS_CFG0 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
##32'hE835F0AF
set_property CH0_RX_PCS_CFG0 32'hE835F0A9 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
#set_property CH1_RX_PCS_CFG0 32'hE835F0A9 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]

### RxPI DMONITOR readings
#get_property CH0_MONITOR_CFG    32'h00000000 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
#get_property CH0_ADAPT_GEN_CFG2 32'h87FFFFFF [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
#get_property CH0_RX_CDR_CFG0    32'hAC050042 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
#get_property CTRL_RSV_CFG0      32'h00007818 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]

### RxPI DMONITOR settings
set_property CH0_MONITOR_CFG    32'h00000001 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
set_property CH0_ADAPT_GEN_CFG2 32'h97FFFFFF [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
set_property CH0_RX_CDR_CFG0    32'hAC050042 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
set_property CTRL_RSV_CFG0      32'h00007819 [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]

### DRP use for TxPI
set_property CH0_TX_PIPPM_CFG   32'h0200000A [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]
set_property CH1_TX_PIPPM_CFG   32'h0200000A [get_cells -hier -filter {NAME =~ *quads_inst/quad_inst*gt_quad_base*inst/quad_inst*}]

################################
####  PBlocks
################################

create_pblock pblock_heater0
add_cells_to_pblock [get_pblocks pblock_heater0] [get_cells -hierarchical -filter {NAME =~ heater_inst/*BLOCKS_GEN[0]*}]
resize_pblock [get_pblocks pblock_heater0] -add {CLOCKREGION_X1Y4:CLOCKREGION_X2Y4}
create_pblock pblock_heater1
add_cells_to_pblock [get_pblocks pblock_heater1] [get_cells -hierarchical -filter {NAME =~ heater_inst/*BLOCKS_GEN[1]*}]
resize_pblock [get_pblocks pblock_heater1] -add {CLOCKREGION_X8Y4:CLOCKREGION_X9Y4}
create_pblock pblock_heater2
add_cells_to_pblock [get_pblocks pblock_heater2] [get_cells -hierarchical -filter {NAME =~ heater_inst/*BLOCKS_GEN[2]*}]
resize_pblock [get_pblocks pblock_heater2] -add {CLOCKREGION_X1Y1:CLOCKREGION_X2Y1}
#create_pblock pblock_heater3
#add_cells_to_pblock [get_pblocks pblock_heater3] [get_cells -hierarchical -filter {NAME =~ heater_inst/*BLOCKS_GEN[3]*}]
#resize_pblock [get_pblocks pblock_heater3] -add {CLOCKREGION_X8Y1:CLOCKREGION_X9Y1}

#create_pblock pblock_logic
##add_cells_to_pblock [get_pblocks pblock_logic] [get_cells -hier -filter {NAME =~ "AXI_inst/*" && NAME !~ "AXI_inst/*PCS_PMA*"}]
#add_cells_to_pblock [get_pblocks pblock_logic] [get_cells -hier -filter {NAME =~ "vio_*"}]
#add_cells_to_pblock [get_pblocks pblock_logic] [get_cells -hier -filter {NAME =~ "ila_*"}]
##add_cells_to_pblock [get_pblocks pblock_logic] [get_cells -hier -filter {NAME =~ "temp_sense*"}]
#resize_pblock [get_pblocks pblock_logic] -add {CLOCKREGION_X0Y3:CLOCKREGION_X6Y1}
#set_property IS_SOFT TRUE [get_pblocks pblock_logic]

################################
####  Clocks
################################

create_clock -period 5.00000 -name clk_freerun -add [get_ports clk_freerun_p]

#create_clock -period 16.6666 -name gt_refclk -add [get_ports gt_refclk_p]
create_clock -period 4.1666 -name gt_refclk -add [get_ports gt_refclk_p]

create_clock -period 6.40000 -name eth_gtrefclk -add [get_ports eth_gtrefclk_p]

#create_clock -period 16.6667 -name ddmtdclk -add [get_ports ddmtdclk_in_p]
#create_clock -period 4.1667 -name ddmtdclk -add [get_ports ddmtdclk_in_p]

create_clock -period 4.16667 -name dmonitorclk -add [get_pins -hier -filter {NAME =~ *quad_inst*dmon*bufg*O}]

#connect_debug_port dbg_hub/clk [get_nets clk_sys_125]
#set_property C_CLK_INPUT_FREQ_HZ 125000000 [get_debug_cores dbg_hub]

### PSLink DDMTD input delays
### PLL to FMCP_HSPC_CLK0_M2C_P = 282ps
### PLL to FF = 258ps, FFctq = 200/350ps, FFq to FMCP_HSPC_LA* = 125/162ps
### max delay = (258ps + 350ps + 162ps) - 282ps = 488ps (+20ps margin = 508ps)
### min delay = (258ps + 200ps + 125ps) - 282ps = 301ps (-20ps margin = 281ps)
#set_input_delay -clock ddmtdclk -max 0.508 [get_ports beat_*]
#set_input_delay -clock ddmtdclk -min 0.281 [get_ports beat_*] -add_delay

#set_multicycle_path -setup -end -from [get_cells -hier -filter {NAME =~ *phase_meas*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *phase_meas*)}] \
#                                -to   [get_cells -hier -filter {NAME =~ *phase_meas*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *phase_meas*)}] 100
#set_multicycle_path -hold  -end -from [get_cells -hier -filter {NAME =~ *phase_meas*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *phase_meas*)}] \
#                                -to   [get_cells -hier -filter {NAME =~ *phase_meas*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *phase_meas*)}] 99
                                
set_multicycle_path -setup -end -from [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] \
                                -to   [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] 10
set_multicycle_path -hold  -end -from [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] \
                                -to   [get_cells -hier -filter {NAME =~ *average*q_* || (LIB_CELL =~ *DSP48* && NAME =~ *average*)}] 9

################################
####  Clock Domain Crossings
################################

#### A false path stops the routing optimization
#### A clock group stops only the timing optimization, but hides design errors

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ *clk_out_gt}]] \
                               -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ quads_inst/*QUAD*_TX*_outclk*}]]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_200]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks gt_refclk]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks eth_gtrefclk]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ gt_inst/rxoutclk_out[*]}]]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ gt_inst/txoutclk_out[*]}]]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ gt1_inst/ch[0].*/rxoutclk_out[0]}]]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets -hier -filter {NAME =~ gt1_inst/ch[0].*/txoutclk_out[0]}]]

### freq meas module false path
set_false_path -from [get_pins -hier -filter {NAME =~ *freq_meas*/*divider_counter_reg[3]/C}] -to [get_pins -hier -filter {NAME =~ *freq_meas*/*divided_clk_sync_reg[0]/D}]

### heater false paths, to avoid multiple hours long implementation
#set_false_path -from [get_clocks -of_objects [get_nets -of_objects [get_pins *heater_inst*/*BUFGCE_inst/O]]]
#set_false_path -to [get_pins *heater_inst*/*BUFGCE_inst/CE]






