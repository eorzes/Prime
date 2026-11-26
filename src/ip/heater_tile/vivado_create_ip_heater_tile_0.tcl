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
# source vivado_create_ip_heater_tile_0.tcl
# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project heater_tile_0 heater_tile_0 -part xcvm1802-vsva2197-2MP-e-S
  set_property BOARD_PART xilinx.com:vmk180:part0:3.2 [current_project]
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

##################################################################
# CHECK IPs
##################################################################


set ip_repo_d [file dirname [file normalize [info script]]]
while {![file isdirectory [file join $ip_repo_d ip_repo]] && $ip_repo_d ne [file dirname $ip_repo_d]} {
    set ip_repo_d [file dirname $ip_repo_d]
}
set_property IP_REPO_PATHS [lsort -unique [concat [get_property IP_REPO_PATHS [current_fileset]] [list [file join $ip_repo_d ip_repo]]]] [current_fileset]
update_ip_catalog

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { eorzes:user:heater_tile:1.0 }
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
# CREATE IP heater_tile_0
##################################################################

set_property target_language VHDL [current_project]
set heater_tile_0 [create_ip -name heater_tile -vendor eorzes -library user -version 1.0 -module_name heater_tile_0]

# User Parameters
set_property CONFIG.NUM_UNITS {240} [get_ips heater_tile_0]

# Runtime Parameters
set_property -dict { 
  GENERATE_SYNTH_CHECKPOINT {1}
} $heater_tile_0

##################################################################

