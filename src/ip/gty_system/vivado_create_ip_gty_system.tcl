##################################################################
# CHECK VIVADO VERSION
##################################################################

set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
  return 1
}

##################################################################
# START
##################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source vivado_create_ip_gty_system.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project gty_system gty_system -part xcvm1802-vsva2197-2MP-e-S
  set_property BOARD_PART xilinx.com:vmk180:part0:3.2 [current_project]
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:gtwiz_versal:1.0 }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# CREATE IP gty_system
##################################################################

set_property target_language VHDL [current_project]
set gty_system [create_ip -name gtwiz_versal -vendor xilinx.com -library ip -version 1.0 -module_name gty_system]

# User Parameters
set_property -dict [list \
  CONFIG.ENABLE_REG_INTERFACE {true} \
  CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {RX_BUFFER_BYPASS_MODE_LANE SINGLE RX_BUFFER_MODE 0 RX_COMMA_ALIGN_WORD 4 RX_COMMA_M_ENABLE true RX_COMMA_P_ENABLE true RX_COMMA_SHOW_REALIGN_ENABLE false RX_DATA_DECODING 8B10B RX_EQ_MODE LPM RX_LINE_RATE 9.6 RX_REFCLK_FREQUENCY 240 RX_SLIDE_MODE PCS TX_BUFFER_RESET_ON_RATE_CHANGE DISABLE TX_INT_DATA_WIDTH 40 TX_LINE_RATE 9.6 TX_OUTCLK_SOURCE TXPLLREFCLK TX_PIPM_ENABLE true TX_REFCLK_FREQUENCY 240 TX_USER_DATA_WIDTH 40} \
  CONFIG.INTF0_NO_OF_LANES {1} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_rxbufstatus) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_rxpmaresetdone) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_rxpmaresetmask) {false} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_rxslide) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txbufstatus) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txctrl0) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txctrl1) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txctrl2) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txpippmen) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txpippmstepsize) {true} \
  CONFIG.INTF0_OPTIONAL_PORTS(ch_txpmaresetdone) {true} \
  CONFIG.INTF1_GT_DIRECTION {SIMPLEX_TX} \
  CONFIG.INTF1_GT_SETTINGS(LR0_SETTINGS) {TX_BUFFER_RESET_ON_RATE_CHANGE DISABLE TX_DATA_ENCODING RAW TX_LINE_RATE 9.6 TX_PIPM_ENABLE true TX_REFCLK_FREQUENCY 240 TX_INT_DATA_WIDTH 40 TX_OUTCLK_SOURCE TXPLLREFCLK TX_USER_DATA_WIDTH 40} \
  CONFIG.INTF1_OPTIONAL_PORTS {} \
  CONFIG.NO_OF_INTERFACE {2} \
  CONFIG.NO_OF_QUADS {1} \
  CONFIG.QUAD0_CH0_DEBUG_EN {true} \
  CONFIG.QUAD0_CH0_PHYREADY_EN {true} \
  CONFIG.QUAD0_CH0_PHYSTATUS_EN {false} \
  CONFIG.QUAD0_GT_GPIO_EN {false} \
  CONFIG.QUAD0_HSCLK0_LCPLL_LOCK_EN {true} \
  CONFIG.QUAD0_HSCLK0_RPLLRESET_EN {false} \
  CONFIG.QUAD0_NO_PROT {2} \
  CONFIG.QUAD0_PROT0_LANES {1} \
  CONFIG.QUAD0_PROT0_RX1_EN {false} \
  CONFIG.QUAD0_PROT0_RX2_EN {false} \
  CONFIG.QUAD0_PROT0_RX3_EN {false} \
  CONFIG.QUAD0_PROT0_TX1_EN {false} \
  CONFIG.QUAD0_PROT0_TX2_EN {false} \
  CONFIG.QUAD0_PROT0_TX3_EN {false} \
  CONFIG.QUAD0_PROT1_TX1_EN {true} \
  CONFIG.QUAD0_PROT1_TXMSTCLK {TX1} \
] [get_ips gty_system]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $gty_system

##################################################################

