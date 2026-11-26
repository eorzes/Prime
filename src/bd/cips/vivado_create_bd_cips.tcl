
################################################################
# This is a generated script based on design: cips
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source cips_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvm1802-vsva2197-2MP-e-S
   set_property BOARD_PART xilinx.com:vmk180:part0:3.2 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name cips

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.

set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default 
  # the value is script directory path)
  set origin_dir ./bd

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."

     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -quiet -dir $str_bd_folder $design_name
} else {

  # Create regular design
  if { [catch {create_bd_design -quiet $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."

     return 1
  }
}

current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:versal_cips:3.4\
xilinx.com:ip:smartconnect:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set S00_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_ONLY} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S00_AXI_0


  # Create ports
  set aresetn_0 [ create_bd_port -dir I -type rst aresetn_0 ]
  set pl0_ref_clk [ create_bd_port -dir O -type clk pl0_ref_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI_0} \
 ] $pl0_ref_clk

  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DEVICE_INTEGRITY_MODE {Sysmon temperature voltage and external IO monitoring} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_S_AXI_LPD_DATA_WIDTH {32} \
      PS_USE_M_AXI_FPD {0} \
      PS_USE_M_AXI_LPD {0} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_S_AXI_FPD {0} \
      PS_USE_S_AXI_LPD {1} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_MEAS33 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 0}} \
      SMON_MEAS34 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX_PMC} {SUPPLY_NUM 1}} \
      SMON_MEAS56 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 2}} \
      SMON_MEAS57 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 3}} \
      SMON_MEAS58 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 4}} \
      SMON_MEAS60 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 5}} \
      SMON_MEAS61 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 1.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {1 V unipolar}} {NAME VP_VN} {SUPPLY_NUM 6}} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_0_1 [get_bd_intf_ports S00_AXI_0] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins versal_cips_0/S_AXI_LPD]

  # Create port connections
  connect_bd_net -net aresetn_0_1  [get_bd_ports aresetn_0] \
  [get_bd_pins smartconnect_0/aresetn]
  connect_bd_net -net versal_cips_0_pl0_ref_clk  [get_bd_pins versal_cips_0/pl0_ref_clk] \
  [get_bd_ports pl0_ref_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins versal_cips_0/s_axi_lpd_aclk]

  # Create address segments
  assign_bd_address -quiet -offset 0xFFA80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_0] -force
  assign_bd_address -quiet -offset 0xFFA90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_1] -force
  assign_bd_address -quiet -offset 0xFFAA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_2] -force
  assign_bd_address -quiet -offset 0xFFAB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_3] -force
  assign_bd_address -quiet -offset 0xFFAC0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_4] -force
  assign_bd_address -quiet -offset 0xFFAD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_5] -force
  assign_bd_address -quiet -offset 0xFFAE0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_6] -force
  assign_bd_address -quiet -offset 0xFFAF0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_adma_7] -force
  assign_bd_address -quiet -offset 0xFD5C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_apu_0] -force
  assign_bd_address -quiet -offset 0xF0800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_0] -force
  assign_bd_address -quiet -offset 0xF0D10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_cti] -force
  assign_bd_address -quiet -offset 0xF0D00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_dbg] -force
  assign_bd_address -quiet -offset 0xF0D30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_etm] -force
  assign_bd_address -quiet -offset 0xF0D20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a720_pmu] -force
  assign_bd_address -quiet -offset 0xF0D50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_cti] -force
  assign_bd_address -quiet -offset 0xF0D40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_dbg] -force
  assign_bd_address -quiet -offset 0xF0D70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_etm] -force
  assign_bd_address -quiet -offset 0xF0D60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_a721_pmu] -force
  assign_bd_address -quiet -offset 0xF0CA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_cti] -force
  assign_bd_address -quiet -offset 0xF0C60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_ela] -force
  assign_bd_address -quiet -offset 0xF0C30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_etf] -force
  assign_bd_address -quiet -offset 0xF0C20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_apu_fun] -force
  assign_bd_address -quiet -offset 0xF0F80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_atm] -force
  assign_bd_address -quiet -offset 0xF0FA0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_cti2a] -force
  assign_bd_address -quiet -offset 0xF0FD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_cti2d] -force
  assign_bd_address -quiet -offset 0xF0F40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2a] -force
  assign_bd_address -quiet -offset 0xF0F50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2b] -force
  assign_bd_address -quiet -offset 0xF0F60000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2c] -force
  assign_bd_address -quiet -offset 0xF0F70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_ela2d] -force
  assign_bd_address -quiet -offset 0xF0F20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_fun] -force
  assign_bd_address -quiet -offset 0xF0F00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_cpm_rom] -force
  assign_bd_address -quiet -offset 0xF0B80000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_fpd_atm] -force
  assign_bd_address -quiet -offset 0xF0B70000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_fpd_stm] -force
  assign_bd_address -quiet -offset 0xF0980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_coresight_lpd_atm] -force
  assign_bd_address -quiet -offset 0xFC000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_cpm] -force
  assign_bd_address -quiet -offset 0xFD1A0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crf_0] -force
  assign_bd_address -quiet -offset 0xFF5E0000 -range 0x00020000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crl_0] -force
  assign_bd_address -quiet -offset 0xF1260000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_crp_0] -force
  assign_bd_address -quiet -offset 0xFD360000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_afi_0] -force
  assign_bd_address -quiet -offset 0xFD380000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_afi_2] -force
  assign_bd_address -quiet -offset 0xFD5E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_cci_0] -force
  assign_bd_address -quiet -offset 0xFD700000 -range 0x00100000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_gpv_0] -force
  assign_bd_address -quiet -offset 0xFD000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_maincci_0] -force
  assign_bd_address -quiet -offset 0xFD390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slave_xmpu_0] -force
  assign_bd_address -quiet -offset 0xFD610000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slcr_0] -force
  assign_bd_address -quiet -offset 0xFD690000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_slcr_secure_0] -force
  assign_bd_address -quiet -offset 0xFD5F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_smmu_0] -force
  assign_bd_address -quiet -offset 0xFD800000 -range 0x00800000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_fpd_smmutcu_0] -force
  assign_bd_address -quiet -offset 0xFF3F0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_buffer] -force
  assign_bd_address -quiet -offset 0xFF320000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_pmc] -force
  assign_bd_address -quiet -offset 0xFF390000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_pmc_nobuf] -force
  assign_bd_address -quiet -offset 0xFF310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ipi_psm] -force
  assign_bd_address -quiet -offset 0xFF9B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_afi_0] -force
  assign_bd_address -quiet -offset 0xFF0A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_iou_secure_slcr_0] -force
  assign_bd_address -quiet -offset 0xFF080000 -range 0x00020000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_iou_slcr_0] -force
  assign_bd_address -quiet -offset 0xFF410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_slcr_0] -force
  assign_bd_address -quiet -offset 0xFF510000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_slcr_secure_0] -force
  assign_bd_address -quiet -offset 0xFF990000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_lpd_xppu_0] -force
  assign_bd_address -quiet -offset 0xFF960000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_ctrl] -force
  assign_bd_address -quiet -offset 0xFFFC0000 -range 0x00040000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_ram_0] -force
  assign_bd_address -quiet -offset 0xFF980000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_ocm_xmpu_0] -force
  assign_bd_address -quiet -offset 0xF11E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_aes] -force
  assign_bd_address -quiet -offset 0xF11F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_bbram_ctrl] -force
  assign_bd_address -quiet -offset 0xF12D0000 -range 0x00001000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_cfi_cframe_0] -force
  assign_bd_address -quiet -offset 0xF12B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_cfu_apb_0] -force
  assign_bd_address -quiet -offset 0xF11C0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_dma_0] -force
  assign_bd_address -quiet -offset 0xF11D0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_dma_1] -force
  assign_bd_address -quiet -offset 0xF1250000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_efuse_cache] -force
  assign_bd_address -quiet -offset 0xF1240000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_efuse_ctrl] -force
  assign_bd_address -quiet -offset 0xF1110000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_global_0] -force
  assign_bd_address -quiet -offset 0xF0310000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ppu1_mdm_0] -force
  assign_bd_address -quiet -offset 0xF2000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ram] -force
  assign_bd_address -quiet -offset 0xF6000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_ram_npi] -force
  assign_bd_address -quiet -offset 0xF1200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_rsa] -force
  assign_bd_address -quiet -offset 0xF12A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_rtc_0] -force
  assign_bd_address -quiet -offset 0xF1210000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_sha] -force
  assign_bd_address -quiet -offset 0xF1220000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_slave_boot] -force
  assign_bd_address -quiet -offset 0xF2100000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_slave_boot_stream] -force
  assign_bd_address -quiet -offset 0xF1270000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_sysmon_0] -force
  assign_bd_address -quiet -offset 0xF1230000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_trng] -force
  assign_bd_address -quiet -offset 0xF12F0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xmpu_0] -force
  assign_bd_address -quiet -offset 0xF1310000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xppu_0] -force
  assign_bd_address -quiet -offset 0xF1300000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_pmc_xppu_npi_0] -force
  assign_bd_address -quiet -offset 0xFFC90000 -range 0x0000F000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_psm_global_reg] -force
  assign_bd_address -quiet -offset 0xFFE90000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_1_atcm_global] -force
  assign_bd_address -quiet -offset 0xFFEB0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_1_btcm_global] -force
  assign_bd_address -quiet -offset 0xFFE00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_r5_tcm_ram_global] -force
  assign_bd_address -quiet -offset 0xFF9A0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_rpu_0] -force
  assign_bd_address -quiet -offset 0xFF130000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_scntr_0] -force
  assign_bd_address -quiet -offset 0xFF140000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs versal_cips_0/S_AXI_LPD/pspmc_0_psv_scntrs_0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design -quiet
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

