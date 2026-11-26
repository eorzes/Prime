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
# source vivado_create_ip_ila_temp.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project ila_temp ila_temp -part xcvm1802-vsva2197-2MP-e-S
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
  set list_check_ips { xilinx.com:ip:axis_ila:1.3 }
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
# CREATE IP ila_temp
##################################################################

set_property target_language VHDL [current_project]
set ila_temp [create_ip -name axis_ila -vendor xilinx.com -library ip -version 1.3 -module_name ila_temp]

# User Parameters
set_property -dict [list \
  CONFIG.C_DATA_DEPTH {1024} \
  CONFIG.C_NUM_OF_PROBES {3} \
  CONFIG.C_PROBE0_WIDTH {16} \
  CONFIG.C_PROBE11_WIDTH {1} \
  CONFIG.C_PROBE13_WIDTH {1} \
  CONFIG.C_PROBE14_WIDTH {1} \
  CONFIG.C_PROBE16_WIDTH {1} \
  CONFIG.C_PROBE19_WIDTH {1} \
  CONFIG.C_PROBE1_WIDTH {1} \
  CONFIG.C_PROBE2_WIDTH {1} \
  CONFIG.C_PROBE3_WIDTH {1} \
  CONFIG.C_PROBE4_WIDTH {1} \
  CONFIG.C_PROBE7_WIDTH {1} \
  CONFIG.C_PROBE8_WIDTH {1} \
  CONFIG.C_PROBE9_WIDTH {1} \
  CONFIG.C_SLOT_0_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_0_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_0_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_0_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_0_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_0_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_10_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_10_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_10_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_10_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_10_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_10_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_11_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_11_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_11_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_11_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_11_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_11_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_12_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_12_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_12_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_12_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_12_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_12_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_13_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_13_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_13_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_13_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_13_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_13_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_14_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_14_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_14_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_14_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_14_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_14_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_15_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_15_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_15_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_15_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_15_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_15_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_1_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_1_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_1_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_1_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_1_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_1_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_2_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_2_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_2_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_2_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_2_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_2_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_3_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_3_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_3_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_3_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_3_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_3_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_4_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_4_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_4_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_4_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_4_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_4_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_5_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_5_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_5_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_5_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_5_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_5_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_6_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_6_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_6_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_6_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_6_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_6_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_7_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_7_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_7_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_7_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_7_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_7_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_8_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_8_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_8_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_8_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_8_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_8_AXI_WUSER_WIDTH {1} \
  CONFIG.C_SLOT_9_AXI_ARUSER_WIDTH {1} \
  CONFIG.C_SLOT_9_AXI_AWUSER_WIDTH {1} \
  CONFIG.C_SLOT_9_AXI_BUSER_WIDTH {1} \
  CONFIG.C_SLOT_9_AXI_ID_WIDTH {32} \
  CONFIG.C_SLOT_9_AXI_RUSER_WIDTH {1} \
  CONFIG.C_SLOT_9_AXI_WUSER_WIDTH {1} \
] [get_ips ila_temp]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $ila_temp

##################################################################

