
################################################################
# This is a generated script based on design: PCS_PMA_gt
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
# source PCS_PMA_gt_script.tcl

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
set design_name PCS_PMA_gt

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
xilinx.com:ip:gig_ethernet_pcs_pma:17.0\
xilinx.com:ip:gt_quad_base:1.1\
xilinx.com:ip:bufg_gt:1.0\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:xlconstant:1.1\
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
  set gig_ethernet_pcs_pma_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gig_ethernet_pcs_pma_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $gig_ethernet_pcs_pma_0_diff_gt_ref_clock

  set GT_Serial [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial ]

  set gmii_pcs_pma_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:gmii_rtl:1.0 gmii_pcs_pma_0 ]


  # Create ports
  set apb3clk_quad [ create_bd_port -dir I -type clk -freq_hz 125000000 apb3clk_quad ]
  set rxuserclk2 [ create_bd_port -dir O -type clk rxuserclk2 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {62500000} \
 ] $rxuserclk2
  set rxuserclk [ create_bd_port -dir O -type clk rxuserclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {62500000} \
 ] $rxuserclk
  set userclk2 [ create_bd_port -dir O -type clk userclk2 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
 ] $userclk2
  set userclk [ create_bd_port -dir O -type clk userclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {62500000} \
 ] $userclk
  set independent_clock_bufg_0 [ create_bd_port -dir I -type clk -freq_hz 62500000 independent_clock_bufg_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_TOLERANCE_HZ {1000000} \
 ] $independent_clock_bufg_0
  set pma_reset_0 [ create_bd_port -dir I -type rst pma_reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $pma_reset_0
  set mmcm_locked_0 [ create_bd_port -dir I mmcm_locked_0 ]
  set reset_0 [ create_bd_port -dir I -type rst reset_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset_0
  set signal_detect_0 [ create_bd_port -dir I signal_detect_0 ]
  set gmii_isolate_0 [ create_bd_port -dir O gmii_isolate_0 ]
  set mmcm_reset_0 [ create_bd_port -dir O mmcm_reset_0 ]
  set status_vector_0 [ create_bd_port -dir O -from 15 -to 0 status_vector_0 ]
  set resetdone_0 [ create_bd_port -dir O resetdone_0 ]
  set rxpcommaalignen_out_0 [ create_bd_port -dir O rxpcommaalignen_out_0 ]
  set rxmcommaalignen_out_0 [ create_bd_port -dir O rxmcommaalignen_out_0 ]
  set configuration_vector_0 [ create_bd_port -dir I -from 4 -to 0 configuration_vector_0 ]
  set gtpowergood [ create_bd_port -dir O gtpowergood ]

  # Create instance: gig_ethernet_pcs_pma_0, and set properties
  set gig_ethernet_pcs_pma_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:gig_ethernet_pcs_pma:17.0 gig_ethernet_pcs_pma_0 ]
  set_property -dict [list \
    CONFIG.Auto_Negotiation {false} \
    CONFIG.DrpClkRate {62.5} \
    CONFIG.IS_GT_WIZ_OLD {1} \
    CONFIG.Management_Interface {false} \
    CONFIG.RefClkRate {156.25} \
  ] $gig_ethernet_pcs_pma_0


  # Create instance: gt_quad_base, and set properties
  set gt_quad_base [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:gt_quad_base:1.1 gt_quad_base ]
  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY {125} \
    CONFIG.CHANNEL_ORDERING {/gt_quad_base/TX2_GT_IP_Interface PCS_PMA_gt_gig_ethernet_pcs_pma_0_0_0./gig_ethernet_pcs_pma_0/gt_tx_interface.0 /gt_quad_base/RX2_GT_IP_Interface PCS_PMA_gt_gig_ethernet_pcs_pma_0_0_0./gig_ethernet_pcs_pma_0/gt_rx_interface.0}\
\
    CONFIG.GT_TYPE {GTY} \
    CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {unconnected {RX0 RX1 RX3 TX0 TX1 TX3} PROT0 {RX2 TX2}} GT_TYPE GTY REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }} \
    CONFIG.PROT0_ENABLE {true} \
    CONFIG.PROT0_GT_DIRECTION {DUPLEX} \
    CONFIG.PROT0_LR0_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 1.25 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 156.25 TX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 8B10B TX_USER_DATA_WIDTH 16 TX_INT_DATA_WIDTH\
20 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXPROGDIVCLK TXPROGDIV_FREQ_ENABLE true TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 125.000 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE PRESET GTY-Ethernet_1G RX_PAM_SEL NRZ\
RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET Ethernet_1G XPU_MODE 0 RX_LINE_RATE 1.25 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 156.25\
RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 8B10B RX_USER_DATA_WIDTH 16 RX_INT_DATA_WIDTH 20 RX_BUFFER_MODE\
1 RX_OUTCLK_SOURCE RXPROGDIVCLK RXPROGDIV_FREQ_ENABLE true RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 62.500 RXRECCLK_FREQ_ENABLE true RXRECCLK_FREQ_VAL 500.000 INS_LOSS_NYQ 14 RX_EQ_MODE LPM RX_COUPLING\
AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 200 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD\
2 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 1111111111\
RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000\
RX_CB_K 00000000 RX_CB_DISP 00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false\
RX_CB_MASK_0_2 false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0\
00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2\
false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 2 RX_CC_LEN_SEQ 2 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT\
0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000001011010100101111000000000000000000000000010100000010111100 RX_CC_K 00010001 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 10111100 RX_CC_K_0_0\
true RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 01010000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3\
false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 10111100 RX_CC_K_1_0 true RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 10110101 RX_CC_K_1_1\
false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ\
250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 0.74985 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE\
RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0 GT_TYPE GTY} \
    CONFIG.PROT0_LR10_SETTINGS {NA NA} \
    CONFIG.PROT0_LR11_SETTINGS {NA NA} \
    CONFIG.PROT0_LR12_SETTINGS {NA NA} \
    CONFIG.PROT0_LR13_SETTINGS {NA NA} \
    CONFIG.PROT0_LR14_SETTINGS {NA NA} \
    CONFIG.PROT0_LR15_SETTINGS {NA NA} \
    CONFIG.PROT0_LR1_SETTINGS {NA NA} \
    CONFIG.PROT0_LR2_SETTINGS {NA NA} \
    CONFIG.PROT0_LR3_SETTINGS {NA NA} \
    CONFIG.PROT0_LR4_SETTINGS {NA NA} \
    CONFIG.PROT0_LR5_SETTINGS {NA NA} \
    CONFIG.PROT0_LR6_SETTINGS {NA NA} \
    CONFIG.PROT0_LR7_SETTINGS {NA NA} \
    CONFIG.PROT0_LR8_SETTINGS {NA NA} \
    CONFIG.PROT0_LR9_SETTINGS {NA NA} \
    CONFIG.PROT0_NO_OF_LANES {1} \
    CONFIG.PROT0_RX_MASTERCLK_SRC {RX2} \
    CONFIG.PROT0_TX_MASTERCLK_SRC {TX2} \
    CONFIG.PROT_OUTCLK_VALUES {CH0_RXOUTCLK 390.625 CH0_TXOUTCLK 390.625 CH1_RXOUTCLK 390.625 CH1_TXOUTCLK 390.625 CH2_RXOUTCLK 62.5 CH2_TXOUTCLK 125 CH3_RXOUTCLK 390.625 CH3_TXOUTCLK 390.625} \
    CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base {/gt_quad_base undef,undef,PCS_PMA_gt_gig_ethernet_pcs_pma_0_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base\
{/gt_quad_base undef,undef,PCS_PMA_gt_gig_ethernet_pcs_pma_0_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}}} \
    CONFIG.REFCLK_LIST {{/gig_ethernet_pcs_pma_0_diff_gt_ref_clock_clk_p[0]}} \
    CONFIG.REFCLK_STRING {HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_156.25_MHz_unique1} \
    CONFIG.RX0_LANE_SEL {unconnected} \
    CONFIG.RX1_LANE_SEL {unconnected} \
    CONFIG.RX2_LANE_SEL {PROT0} \
    CONFIG.RX3_LANE_SEL {unconnected} \
    CONFIG.TX0_LANE_SEL {unconnected} \
    CONFIG.TX1_LANE_SEL {unconnected} \
    CONFIG.TX2_LANE_SEL {PROT0} \
    CONFIG.TX3_LANE_SEL {unconnected} \
  ] $gt_quad_base

  set_property -dict [list \
    CONFIG.CHANNEL_ORDERING.VALUE_MODE {auto} \
    CONFIG.GT_TYPE.VALUE_MODE {auto} \
    CONFIG.PROT0_ENABLE.VALUE_MODE {auto} \
    CONFIG.PROT0_GT_DIRECTION.VALUE_MODE {auto} \
    CONFIG.PROT0_LR0_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR10_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR11_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR12_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR13_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR14_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR15_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR1_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR2_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR3_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR4_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR5_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR6_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR7_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR8_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR9_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_NO_OF_LANES.VALUE_MODE {auto} \
    CONFIG.QUAD_USAGE.VALUE_MODE {auto} \
    CONFIG.RX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX3_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX3_LANE_SEL.VALUE_MODE {auto} \
  ] $gt_quad_base


  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt ]
  set_property CONFIG.FREQ_HZ {62500000} $bufg_gt


  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_1 ]
  set_property CONFIG.FREQ_HZ {125000000} $bufg_gt_1


  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf


  # Create instance: bufg_gt_0, and set properties
  set bufg_gt_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_0 ]
  set_property CONFIG.FREQ_HZ {62500000.0} $bufg_gt_0


  # Create instance: bufg_gt_2, and set properties
  set bufg_gt_2 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_2 ]
  set_property CONFIG.FREQ_HZ {62500000} $bufg_gt_2


  # Create instance: xlconstant, and set properties
  set xlconstant [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant ]
  set_property CONFIG.CONST_WIDTH {3} $xlconstant


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_1


  # Create interface connections
  connect_bd_intf_net -intf_net gig_ethernet_pcs_pma_0_diff_gt_ref_clock_1 [get_bd_intf_pins util_ds_buf/CLK_IN_D] [get_bd_intf_ports gig_ethernet_pcs_pma_0_diff_gt_ref_clock]
  connect_bd_intf_net -intf_net gig_ethernet_pcs_pma_0_gt_rx_interface [get_bd_intf_pins gig_ethernet_pcs_pma_0/gt_rx_interface] [get_bd_intf_pins gt_quad_base/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gig_ethernet_pcs_pma_0_gt_tx_interface [get_bd_intf_pins gig_ethernet_pcs_pma_0/gt_tx_interface] [get_bd_intf_pins gt_quad_base/TX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net gmii_pcs_pma_0_1 [get_bd_intf_ports gmii_pcs_pma_0] [get_bd_intf_pins gig_ethernet_pcs_pma_0/gmii_pcs_pma]
  connect_bd_intf_net -intf_net gt_quad_base_GT_Serial [get_bd_intf_pins gt_quad_base/GT_Serial] [get_bd_intf_ports GT_Serial]

  # Create port connections
  connect_bd_net -net apb3clk_quad_1  [get_bd_ports apb3clk_quad] \
  [get_bd_pins gt_quad_base/apb3clk]
  connect_bd_net -net bufg_gt_0_usrclk  [get_bd_pins bufg_gt_0/usrclk] \
  [get_bd_pins gig_ethernet_pcs_pma_0/userclk] \
  [get_bd_pins gt_quad_base/ch2_txusrclk] \
  [get_bd_pins gt_quad_base/ch2_rxusrclk] \
  [get_bd_ports userclk]
  connect_bd_net -net bufg_gt_1_usrclk  [get_bd_pins bufg_gt_1/usrclk] \
  [get_bd_ports userclk2] \
  [get_bd_pins gig_ethernet_pcs_pma_0/userclk2]
  connect_bd_net -net bufg_gt_2_usrclk  [get_bd_pins bufg_gt_2/usrclk] \
  [get_bd_ports rxuserclk2] \
  [get_bd_pins gig_ethernet_pcs_pma_0/rxuserclk2]
  connect_bd_net -net bufg_gt_usrclk  [get_bd_pins bufg_gt/usrclk] \
  [get_bd_ports rxuserclk] \
  [get_bd_pins gig_ethernet_pcs_pma_0/rxuserclk]
  connect_bd_net -net configuration_vector_0_1  [get_bd_ports configuration_vector_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/configuration_vector]
  connect_bd_net -net gig_ethernet_pcs_pma_0_gmii_isolate  [get_bd_pins gig_ethernet_pcs_pma_0/gmii_isolate] \
  [get_bd_ports gmii_isolate_0]
  connect_bd_net -net gig_ethernet_pcs_pma_0_mmcm_reset  [get_bd_pins gig_ethernet_pcs_pma_0/mmcm_reset] \
  [get_bd_ports mmcm_reset_0]
  connect_bd_net -net gig_ethernet_pcs_pma_0_resetdone  [get_bd_pins gig_ethernet_pcs_pma_0/resetdone] \
  [get_bd_ports resetdone_0]
  connect_bd_net -net gig_ethernet_pcs_pma_0_rxmcommaalignen_out  [get_bd_pins gig_ethernet_pcs_pma_0/rxmcommaalignen_out] \
  [get_bd_ports rxmcommaalignen_out_0]
  connect_bd_net -net gig_ethernet_pcs_pma_0_rxpcommaalignen_out  [get_bd_pins gig_ethernet_pcs_pma_0/rxpcommaalignen_out] \
  [get_bd_ports rxpcommaalignen_out_0]
  connect_bd_net -net gig_ethernet_pcs_pma_0_status_vector  [get_bd_pins gig_ethernet_pcs_pma_0/status_vector] \
  [get_bd_ports status_vector_0]
  connect_bd_net -net gt_quad_base_ch2_rxoutclk  [get_bd_pins gt_quad_base/ch2_rxoutclk] \
  [get_bd_pins bufg_gt/outclk] \
  [get_bd_pins bufg_gt_2/outclk]
  connect_bd_net -net gt_quad_base_ch2_rxprogdivresetdone  [get_bd_pins gt_quad_base/ch2_rxprogdivresetdone] \
  [get_bd_pins gig_ethernet_pcs_pma_0/gtwiz_reset_rx_done_in]
  connect_bd_net -net gt_quad_base_ch2_txoutclk  [get_bd_pins gt_quad_base/ch2_txoutclk] \
  [get_bd_pins bufg_gt_0/outclk] \
  [get_bd_pins bufg_gt_1/outclk]
  connect_bd_net -net gt_quad_base_ch2_txprogdivresetdone  [get_bd_pins gt_quad_base/ch2_txprogdivresetdone] \
  [get_bd_pins gig_ethernet_pcs_pma_0/gtwiz_reset_tx_done_in]
  connect_bd_net -net gt_quad_base_gtpowergood  [get_bd_pins gt_quad_base/gtpowergood] \
  [get_bd_ports gtpowergood] \
  [get_bd_pins gig_ethernet_pcs_pma_0/gtpowergood_in]
  connect_bd_net -net independent_clock_bufg_0_1  [get_bd_ports independent_clock_bufg_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/independent_clock_bufg]
  connect_bd_net -net mmcm_locked_0_1  [get_bd_ports mmcm_locked_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/mmcm_locked]
  connect_bd_net -net pma_reset_0_1  [get_bd_ports pma_reset_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/pma_reset]
  connect_bd_net -net reset_0_1  [get_bd_ports reset_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/reset]
  connect_bd_net -net signal_detect_0_1  [get_bd_ports signal_detect_0] \
  [get_bd_pins gig_ethernet_pcs_pma_0/signal_detect]
  connect_bd_net -net util_ds_buf_IBUF_OUT  [get_bd_pins util_ds_buf/IBUF_OUT] \
  [get_bd_pins gt_quad_base/GT_REFCLK0]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins bufg_gt/gt_bufgtce] \
  [get_bd_pins bufg_gt/gt_bufgtcemask] \
  [get_bd_pins bufg_gt/gt_bufgtclrmask] \
  [get_bd_pins bufg_gt_0/gt_bufgtce] \
  [get_bd_pins bufg_gt_0/gt_bufgtcemask] \
  [get_bd_pins bufg_gt_0/gt_bufgtclrmask] \
  [get_bd_pins bufg_gt_1/gt_bufgtce] \
  [get_bd_pins bufg_gt_1/gt_bufgtcemask] \
  [get_bd_pins bufg_gt_1/gt_bufgtclrmask] \
  [get_bd_pins bufg_gt_2/gt_bufgtce] \
  [get_bd_pins bufg_gt_2/gt_bufgtcemask] \
  [get_bd_pins bufg_gt_2/gt_bufgtclrmask]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins bufg_gt/gt_bufgtclr] \
  [get_bd_pins bufg_gt_0/gt_bufgtclr] \
  [get_bd_pins bufg_gt_1/gt_bufgtclr] \
  [get_bd_pins bufg_gt_2/gt_bufgtclr]
  connect_bd_net -net xlconstant_dout  [get_bd_pins xlconstant/dout] \
  [get_bd_pins bufg_gt_0/gt_bufgtdiv]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design -quiet
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


