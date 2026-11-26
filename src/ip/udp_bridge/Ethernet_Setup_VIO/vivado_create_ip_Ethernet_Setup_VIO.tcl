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
# source vivado_create_ip_Ethernet_Setup_VIO.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project Ethernet_Setup_VIO Ethernet_Setup_VIO -part xcvm1802-vsva2197-2MP-e-S
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
  set list_check_ips { xilinx.com:ip:axis_vio:1.0 }
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
# CREATE IP Ethernet_Setup_VIO
##################################################################

set_property target_language VHDL [current_project]
set Ethernet_Setup_VIO [create_ip -name axis_vio -vendor xilinx.com -library ip -version 1.0 -module_name Ethernet_Setup_VIO]

# User Parameters
set_property -dict [list \
  CONFIG.C_NUM_PROBE_IN {0} \
  CONFIG.C_NUM_PROBE_OUT {6} \
  CONFIG.C_PROBE_OUT0_INIT_VAL {0x543210543210} \
  CONFIG.C_PROBE_OUT0_WIDTH {48} \
  CONFIG.C_PROBE_OUT1_INIT_VAL {0x0A010002} \
  CONFIG.C_PROBE_OUT1_WIDTH {32} \
  CONFIG.C_PROBE_OUT2_INIT_VAL {0x13EE} \
  CONFIG.C_PROBE_OUT2_WIDTH {16} \
  CONFIG.C_PROBE_OUT3_INIT_VAL {0x40a6b7b50bf4} \
  CONFIG.C_PROBE_OUT3_WIDTH {48} \
  CONFIG.C_PROBE_OUT4_INIT_VAL {0x0A000001} \
  CONFIG.C_PROBE_OUT4_WIDTH {32} \
  CONFIG.C_PROBE_OUT5_INIT_VAL {0x17d6} \
  CONFIG.C_PROBE_OUT5_WIDTH {16} \
] [get_ips Ethernet_Setup_VIO]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $Ethernet_Setup_VIO

##################################################################

