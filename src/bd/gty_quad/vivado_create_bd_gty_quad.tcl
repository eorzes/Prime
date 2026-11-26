
################################################################
# This is a generated script based on design: gty_quad
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
# source gty_quad_script.tcl

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
set design_name gty_quad

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
xilinx.com:ip:gt_bridge_ip:1.1\
xilinx.com:ip:gt_quad_base:1.1\
xilinx.com:ip:bufg_gt:1.0\
xilinx.com:ip:util_reduced_logic:2.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:util_ds_buf:2.2\
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
  set gt_bridge_ip_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 gt_bridge_ip_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {240000000} \
   ] $gt_bridge_ip_0_diff_gt_ref_clock

  set GT_Serial [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial ]

  set APB3_INTF_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:apb_rtl:1.0 APB3_INTF_0 ]


  # Create ports
  set apb3clk_quad [ create_bd_port -dir I -type clk -freq_hz 125000000 apb3clk_quad ]
  set gt_reset_gt_bridge_ip_0 [ create_bd_port -dir I gt_reset_gt_bridge_ip_0 ]
  set link_status_gt_bridge_ip_0 [ create_bd_port -dir O link_status_gt_bridge_ip_0 ]
  set txusrclk_gt_bridge_ip_0 [ create_bd_port -dir O txusrclk_gt_bridge_ip_0 ]
  set rxusrclk_gt_bridge_ip_0 [ create_bd_port -dir O rxusrclk_gt_bridge_ip_0 ]
  set rpll_lock_gt_bridge_ip_0 [ create_bd_port -dir O rpll_lock_gt_bridge_ip_0 ]
  set lcpll_lock_gt_bridge_ip_0 [ create_bd_port -dir O lcpll_lock_gt_bridge_ip_0 ]
  set tx_resetdone_out_gt_bridge_ip_0 [ create_bd_port -dir O tx_resetdone_out_gt_bridge_ip_0 ]
  set rx_resetdone_out_gt_bridge_ip_0 [ create_bd_port -dir O rx_resetdone_out_gt_bridge_ip_0 ]
  set rate_sel_gt_bridge_ip_0 [ create_bd_port -dir I -from 3 -to 0 rate_sel_gt_bridge_ip_0 ]
  set apb3clk_gt_bridge_ip_0 [ create_bd_port -dir I -type clk -freq_hz 125000000 apb3clk_gt_bridge_ip_0 ]
  set reset_rx_pll_and_datapath_in_0 [ create_bd_port -dir I reset_rx_pll_and_datapath_in_0 ]
  set reset_rx_datapath_in_0 [ create_bd_port -dir I reset_rx_datapath_in_0 ]
  set reset_tx_pll_and_datapath_in_0 [ create_bd_port -dir I reset_tx_pll_and_datapath_in_0 ]
  set reset_tx_datapath_in_0 [ create_bd_port -dir I reset_tx_datapath_in_0 ]
  set ch0_rxdata_ext_0 [ create_bd_port -dir O -from 127 -to 0 ch0_rxdata_ext_0 ]
  set ch0_txdata_ext_0 [ create_bd_port -dir I -from 127 -to 0 ch0_txdata_ext_0 ]
  set ch0_rxctrl0_ext_0 [ create_bd_port -dir O -from 15 -to 0 ch0_rxctrl0_ext_0 ]
  set ch0_rxctrl1_ext_0 [ create_bd_port -dir O -from 15 -to 0 ch0_rxctrl1_ext_0 ]
  set ch0_rxctrl2_ext_0 [ create_bd_port -dir O -from 7 -to 0 ch0_rxctrl2_ext_0 ]
  set ch0_rxctrl3_ext_0 [ create_bd_port -dir O -from 7 -to 0 ch0_rxctrl3_ext_0 ]
  set ch0_txctrl0_ext_0 [ create_bd_port -dir I -from 15 -to 0 ch0_txctrl0_ext_0 ]
  set ch0_txctrl1_ext_0 [ create_bd_port -dir I -from 15 -to 0 ch0_txctrl1_ext_0 ]
  set ch0_txctrl2_ext_0 [ create_bd_port -dir I -from 7 -to 0 ch0_txctrl2_ext_0 ]
  set ch0_rxcommadet_ext_0 [ create_bd_port -dir O ch0_rxcommadet_ext_0 ]
  set ch0_rxbyteisaligned_ext_0 [ create_bd_port -dir O ch0_rxbyteisaligned_ext_0 ]
  set ch0_rxbyterealign_ext_0 [ create_bd_port -dir O ch0_rxbyterealign_ext_0 ]
  set gt_reset_gt_bridge_ip_1 [ create_bd_port -dir I gt_reset_gt_bridge_ip_1 ]
  set link_status_gt_bridge_ip_1 [ create_bd_port -dir O link_status_gt_bridge_ip_1 ]
  set txusrclk_gt_bridge_ip_1 [ create_bd_port -dir O txusrclk_gt_bridge_ip_1 ]
  set rxusrclk_gt_bridge_ip_1 [ create_bd_port -dir O rxusrclk_gt_bridge_ip_1 ]
  set rpll_lock_gt_bridge_ip_1 [ create_bd_port -dir O rpll_lock_gt_bridge_ip_1 ]
  set lcpll_lock_gt_bridge_ip_1 [ create_bd_port -dir O lcpll_lock_gt_bridge_ip_1 ]
  set tx_resetdone_out_gt_bridge_ip_1 [ create_bd_port -dir O tx_resetdone_out_gt_bridge_ip_1 ]
  set rx_resetdone_out_gt_bridge_ip_1 [ create_bd_port -dir O rx_resetdone_out_gt_bridge_ip_1 ]
  set rate_sel_gt_bridge_ip_1 [ create_bd_port -dir I -from 3 -to 0 rate_sel_gt_bridge_ip_1 ]
  set apb3clk_gt_bridge_ip_1 [ create_bd_port -dir I -type clk -freq_hz 125000000 apb3clk_gt_bridge_ip_1 ]
  set reset_tx_pll_and_datapath_in_1 [ create_bd_port -dir I reset_tx_pll_and_datapath_in_1 ]
  set reset_tx_datapath_in_1 [ create_bd_port -dir I reset_tx_datapath_in_1 ]
  set ch0_txdata_ext_1 [ create_bd_port -dir I -from 127 -to 0 ch0_txdata_ext_1 ]
  set gtpowergood [ create_bd_port -dir O gtpowergood ]
  set refclk [ create_bd_port -dir O -type gt_usrclk refclk ]
  set ch0_txpippmen_ext_0 [ create_bd_port -dir I ch0_txpippmen_ext_0 ]
  set ch0_txbufstatus_ext_0 [ create_bd_port -dir O -from 1 -to 0 ch0_txbufstatus_ext_0 ]
  set ch0_txpippmstepsize_ext_0 [ create_bd_port -dir I -from 4 -to 0 ch0_txpippmstepsize_ext_0 ]
  set ch0_txpmaresetdone_ext_0 [ create_bd_port -dir O ch0_txpmaresetdone_ext_0 ]
  set ch0_rxpmaresetdone_ext_0 [ create_bd_port -dir O ch0_rxpmaresetdone_ext_0 ]
  set ch0_rxbufstatus_ext_0 [ create_bd_port -dir O -from 2 -to 0 ch0_rxbufstatus_ext_0 ]
  set ch0_rxslide_ext_0 [ create_bd_port -dir I ch0_rxslide_ext_0 ]
  set ch0_txpippmen_ext_1 [ create_bd_port -dir I ch0_txpippmen_ext_1 ]
  set ch0_txbufstatus_ext_1 [ create_bd_port -dir O -from 1 -to 0 ch0_txbufstatus_ext_1 ]
  set ch0_txpippmstepsize_ext_1 [ create_bd_port -dir I -from 4 -to 0 ch0_txpippmstepsize_ext_1 ]
  set ch0_txpmaresetdone_ext_1 [ create_bd_port -dir O ch0_txpmaresetdone_ext_1 ]
  set ch0_txctrl0_ext_1 [ create_bd_port -dir I -from 15 -to 0 ch0_txctrl0_ext_1 ]
  set ch0_txctrl1_ext_1 [ create_bd_port -dir I -from 15 -to 0 ch0_txctrl1_ext_1 ]
  set ch0_txctrl2_ext_1 [ create_bd_port -dir I -from 7 -to 0 ch0_txctrl2_ext_1 ]

  # Create instance: gt_bridge_ip_0, and set properties
  set gt_bridge_ip_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:gt_bridge_ip:1.1 gt_bridge_ip_0 ]
  set_property -dict [list \
    CONFIG.BYPASS_MODE {true} \
    CONFIG.IP_LR0_SETTINGS {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ TX_HD_EN 0 RX_HD_EN 0 RX_GRAY_BYP true TX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true TX_PRECODE_BYP\
true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION DUPLEX TX_LINE_RATE 9.6 TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 240 TX_ACTUAL_REFCLK_FREQUENCY\
240.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE\
Fast_Sync TX_PIPM_ENABLE true TX_OUTCLK_SOURCE TXPLLREFCLK TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 240.000010 TX_DIFF_SWING_EMPH_MODE CUSTOM TX_64B66B_SCRAMBLER false\
TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A RX_LINE_RATE 9.6 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 240 RX_ACTUAL_REFCLK_FREQUENCY 240.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false\
RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 8B10B RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 40 RX_BUFFER_MODE 0 RX_OUTCLK_SOURCE RXPROGDIVCLK RXPROGDIV_FREQ_ENABLE true RXPROGDIV_FREQ_SOURCE\
LCPLL RXPROGDIV_FREQ_VAL 240.000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE LPM RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET\
0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 4 RX_COMMA_SHOW_REALIGN_ENABLE false PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE false RX_COMMA_P_ENABLE\
true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE PCS RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW\
1 RX_CB_MAX_LEVEL 1 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false RX_CB_MASK_0_2\
false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0\
false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2 false RX_CB_MASK_1_3\
false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_VAL\
00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000\
RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false\
RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2\
00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 5.7588482 RX_JTOL_LF_SLOPE\
-20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE SINGLE RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE\
DISABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0 } \
    CONFIG.IP_NO_OF_LANES {1} \
  ] $gt_bridge_ip_0


  # Create instance: gt_bridge_ip_1, and set properties
  set gt_bridge_ip_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:gt_bridge_ip:1.1 gt_bridge_ip_1 ]
  set_property -dict [list \
    CONFIG.BYPASS_MODE {true} \
    CONFIG.IP_GT_DIRECTION {SIMPLEX_TX} \
    CONFIG.IP_LR0_SETTINGS {PRESET None RX_PAM_SEL NRZ TX_PAM_SEL NRZ TX_HD_EN 0 RX_HD_EN 0 RX_GRAY_BYP true TX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true TX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true TX_PRECODE_BYP\
true RX_PRECODE_LITTLEENDIAN false TX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None GT_TYPE GTY GT_DIRECTION SIMPLEX_TX TX_LINE_RATE 9.6 TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 240 TX_ACTUAL_REFCLK_FREQUENCY\
240.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE\
Fast_Sync TX_PIPM_ENABLE true TX_OUTCLK_SOURCE TXPLLREFCLK TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 240.000010 TX_DIFF_SWING_EMPH_MODE CUSTOM TX_64B66B_SCRAMBLER false\
TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A RX_LINE_RATE 10.3125 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 156.25 RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD\
false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 0 RX_OUTCLK_SOURCE RXPROGDIVCLK RXPROGDIV_FREQ_ENABLE true RXPROGDIV_FREQ_SOURCE\
LCPLL RXPROGDIV_FREQ_VAL 322.266 RXRECCLK_FREQ_ENABLE true RXRECCLK_FREQ_VAL 644.531 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE\
800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false TX_LANE_DESKEW_HDMI_ENABLE\
false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ\
0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1\
false RX_CB_MASK_0_2 false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0\
00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2\
false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT\
0 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1\
00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3\
false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2\
00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 6.1862627 RX_JTOL_LF_SLOPE\
-20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE TX_BUFFER_RESET_ON_RATE_CHANGE\
DISABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0 } \
    CONFIG.IP_NO_OF_TX_LANES {1} \
  ] $gt_bridge_ip_1


  # Create instance: gt_quad_base, and set properties
  set gt_quad_base [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:gt_quad_base:1.1 gt_quad_base ]
  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY {125.0} \
    CONFIG.BYPASS_DRC_58G {false} \
    CONFIG.CHANNEL_ORDERING {/gt_quad_base/TX0_GT_IP_Interface gty_quad_gt_bridge_ip_0_2./gt_bridge_ip_0/GT_TX0.0 /gt_quad_base/TX1_GT_IP_Interface gty_quad_gt_bridge_ip_1_0./gt_bridge_ip_1/GT_TX0.0 /gt_quad_base/RX0_GT_IP_Interface\
gty_quad_gt_bridge_ip_0_2./gt_bridge_ip_0/GT_RX0.0} \
    CONFIG.GT_TYPE {GTY} \
    CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {PROT0 {RX0 TX0} unconnected {RX1 RX2 RX3 TX2 TX3} PROT1 TX1} GT_TYPE GTY REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }} \
    CONFIG.PROT0_ENABLE {true} \
    CONFIG.PROT0_GT_DIRECTION {DUPLEX} \
    CONFIG.PROT0_LR0_SETTINGS {RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CB_K 00000000 RX_CB_DISP 00000000 RX_CC_MASK 00000000 RX_CC_K\
00000000 RX_CC_DISP 00000000 GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 9.6 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 240 TX_ACTUAL_REFCLK_FREQUENCY 240.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH\
40 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE true TX_OUTCLK_SOURCE TXPLLREFCLK TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 240.000010 TX_DIFF_SWING_EMPH_MODE\
CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE DISABLE PRESET None RX_PAM_SEL NRZ RX_HD_EN\
0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 9.6 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 240 RX_ACTUAL_REFCLK_FREQUENCY\
240.000000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 8B10B RX_USER_DATA_WIDTH 32 RX_INT_DATA_WIDTH 40 RX_BUFFER_MODE 0 RX_OUTCLK_SOURCE\
RXPROGDIVCLK RXPROGDIV_FREQ_ENABLE true RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 240.000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE LPM RX_COUPLING AC RX_TERMINATION\
PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD 4 RX_COMMA_SHOW_REALIGN_ENABLE\
false PCIE_ENABLE false RX_COMMA_P_ENABLE true RX_COMMA_M_ENABLE true RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 1111111111 RX_SLIDE_MODE PCS RX_SSC_PPM\
0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1\
false RX_CB_DISP_0_1 false RX_CB_MASK_0_2 false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0\
false RX_CB_VAL_1_0 00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2\
false RX_CB_DISP_1_2 false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE\
ENABLE RX_CC_REPEAT_WAIT 0 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0 false RX_CC_DISP_0_0 false\
RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3 false RX_CC_VAL_0_3\
00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1 false RX_CC_DISP_1_1\
false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ 250 PCIE_USERCLK_FREQ\
250 RX_JTOL_FC 5.7588482 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE SINGLE RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE RX_BUFFER_RESET_ON_RATE_CHANGE\
ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET K28.5 RX_COMMA_VALID_ONLY 0 GT_TYPE GTY} \
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
    CONFIG.PROT0_RX_MASTERCLK_SRC {RX0} \
    CONFIG.PROT0_TX_MASTERCLK_SRC {TX0} \
    CONFIG.PROT1_ENABLE {true} \
    CONFIG.PROT1_GT_DIRECTION {SIMPLEX_TX} \
    CONFIG.PROT1_LR0_SETTINGS {PRESET None RX_PAM_SEL NRZ RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET None RX_LINE_RATE 10.3125\
RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY 156.25 RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING RAW RX_USER_DATA_WIDTH\
32 RX_INT_DATA_WIDTH 32 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 322.265625 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL\
0 INS_LOSS_NYQ 20 RX_EQ_MODE AUTO RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC\
false OOB_ENABLE false RX_COMMA_ALIGN_WORD 1 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL\
1010000011 RX_COMMA_MASK 0000000000 RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000\
RX_CB_K 00000000 RX_CB_DISP 00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false\
RX_CB_MASK_0_2 false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0\
00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2\
false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT\
0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0\
false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3\
false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1\
false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ\
250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 6.1862627 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE\
RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0 GT_DIRECTION SIMPLEX_TX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP\
true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 9.6 TX_PLL_TYPE LCPLL TX_REFCLK_FREQUENCY 240 TX_ACTUAL_REFCLK_FREQUENCY 240.000000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0\
TX_REFCLK_SOURCE R0 TX_DATA_ENCODING RAW TX_USER_DATA_WIDTH 40 TX_INT_DATA_WIDTH 40 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE true TX_OUTCLK_SOURCE TXPLLREFCLK TXPROGDIV_FREQ_ENABLE\
false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 240.000010 TX_DIFF_SWING_EMPH_MODE CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE\
false TX_BUFFER_RESET_ON_RATE_CHANGE DISABLE GT_TYPE GTY} \
    CONFIG.PROT1_LR10_SETTINGS {NA NA} \
    CONFIG.PROT1_LR11_SETTINGS {NA NA} \
    CONFIG.PROT1_LR12_SETTINGS {NA NA} \
    CONFIG.PROT1_LR13_SETTINGS {NA NA} \
    CONFIG.PROT1_LR14_SETTINGS {NA NA} \
    CONFIG.PROT1_LR15_SETTINGS {NA NA} \
    CONFIG.PROT1_LR1_SETTINGS {NA NA} \
    CONFIG.PROT1_LR2_SETTINGS {NA NA} \
    CONFIG.PROT1_LR3_SETTINGS {NA NA} \
    CONFIG.PROT1_LR4_SETTINGS {NA NA} \
    CONFIG.PROT1_LR5_SETTINGS {NA NA} \
    CONFIG.PROT1_LR6_SETTINGS {NA NA} \
    CONFIG.PROT1_LR7_SETTINGS {NA NA} \
    CONFIG.PROT1_LR8_SETTINGS {NA NA} \
    CONFIG.PROT1_LR9_SETTINGS {NA NA} \
    CONFIG.PROT1_NO_OF_LANES {1} \
    CONFIG.PROT1_NO_OF_RX_LANES {1} \
    CONFIG.PROT1_NO_OF_TX_LANES {1} \
    CONFIG.PROT1_RX_MASTERCLK_SRC {None} \
    CONFIG.PROT1_TX_MASTERCLK_SRC {TX1} \
    CONFIG.PROT_OUTCLK_VALUES {CH0_RXOUTCLK 240 CH0_TXOUTCLK 240 CH1_RXOUTCLK 390.625 CH1_TXOUTCLK 240 CH2_RXOUTCLK 390.625 CH2_TXOUTCLK 390.625 CH3_RXOUTCLK 390.625 CH3_TXOUTCLK 390.625} \
    CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base {/gt_quad_base gty_quad_gt_bridge_ip_0_2.IP_CH0,gty_quad_gt_bridge_ip_1_0.IP_CH0,undef,undef MSTRCLK 1,1,0,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base\
{/gt_quad_base gty_quad_gt_bridge_ip_0_2.IP_CH0,undef,undef,undef MSTRCLK 1,0,0,0 IS_CURRENT_QUAD 1}}} \
    CONFIG.REFCLK_LIST {{/gt_bridge_ip_0_diff_gt_ref_clock_clk_p[0]}} \
    CONFIG.REFCLK_STRING {HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_PROT1_R0_240_MHz_unique1} \
    CONFIG.REG_CONF_INTF {APB3_INTF} \
    CONFIG.RX0_LANE_SEL {PROT0} \
    CONFIG.RX1_LANE_SEL {unconnected} \
    CONFIG.RX2_LANE_SEL {unconnected} \
    CONFIG.RX3_LANE_SEL {unconnected} \
    CONFIG.TX0_LANE_SEL {PROT0} \
    CONFIG.TX1_LANE_SEL {PROT1} \
    CONFIG.TX2_LANE_SEL {unconnected} \
    CONFIG.TX3_LANE_SEL {unconnected} \
  ] $gt_quad_base

  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY.VALUE_MODE {auto} \
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
    CONFIG.PROT0_RX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.PROT0_TX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.PROT1_ENABLE.VALUE_MODE {auto} \
    CONFIG.PROT1_GT_DIRECTION.VALUE_MODE {auto} \
    CONFIG.PROT1_LR0_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR10_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR11_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR12_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR13_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR14_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR15_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR1_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR2_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR3_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR4_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR5_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR6_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR7_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR8_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_LR9_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT1_NO_OF_LANES.VALUE_MODE {auto} \
    CONFIG.PROT1_NO_OF_RX_LANES.VALUE_MODE {auto} \
    CONFIG.PROT1_NO_OF_TX_LANES.VALUE_MODE {auto} \
    CONFIG.PROT1_RX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.PROT1_TX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.QUAD_USAGE.VALUE_MODE {auto} \
    CONFIG.REG_CONF_INTF.VALUE_MODE {auto} \
    CONFIG.RX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX3_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX3_LANE_SEL.VALUE_MODE {auto} \
  ] $gt_quad_base


  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_1 ]

  # Create instance: urlp, and set properties
  set urlp [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 urlp ]
  set_property CONFIG.C_SIZE {1} $urlp


  # Create instance: xlcp, and set properties
  set xlcp [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlcp ]
  set_property CONFIG.NUM_PORTS {1} $xlcp


  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf


  # Create instance: bufg_gt_2, and set properties
  set bufg_gt_2 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_2 ]

  # Create instance: urlp_1, and set properties
  set urlp_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:util_reduced_logic:2.0 urlp_1 ]
  set_property CONFIG.C_SIZE {1} $urlp_1


  # Create instance: xlcp_1, and set properties
  set xlcp_1 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlcp_1 ]
  set_property CONFIG.NUM_PORTS {1} $xlcp_1


  # Create instance: bufg_gt_0, and set properties
  set bufg_gt_0 [ create_bd_cell -quiet -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net APB3_INTF_0_1 [get_bd_intf_ports APB3_INTF_0] [get_bd_intf_pins gt_quad_base/APB3_INTF]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_RX0 [get_bd_intf_pins gt_bridge_ip_0/GT_RX0] [get_bd_intf_pins gt_quad_base/RX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_GT_TX0 [get_bd_intf_pins gt_bridge_ip_0/GT_TX0] [get_bd_intf_pins gt_quad_base/TX0_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_bridge_ip_0_diff_gt_ref_clock_1 [get_bd_intf_pins util_ds_buf/CLK_IN_D] [get_bd_intf_ports gt_bridge_ip_0_diff_gt_ref_clock]
  connect_bd_intf_net -intf_net gt_bridge_ip_1_GT_TX0 [get_bd_intf_pins gt_bridge_ip_1/GT_TX0] [get_bd_intf_pins gt_quad_base/TX1_GT_IP_Interface]
  connect_bd_intf_net -intf_net gt_quad_base_GT_Serial [get_bd_intf_pins gt_quad_base/GT_Serial] [get_bd_intf_ports GT_Serial]

  # Create port connections
  connect_bd_net -net apb3clk_gt_bridge_ip_0_1  [get_bd_ports apb3clk_gt_bridge_ip_0] \
  [get_bd_pins gt_bridge_ip_0/apb3clk]
  connect_bd_net -net apb3clk_gt_bridge_ip_1_1  [get_bd_ports apb3clk_gt_bridge_ip_1] \
  [get_bd_pins gt_bridge_ip_1/apb3clk]
  connect_bd_net -net apb3clk_quad_1  [get_bd_ports apb3clk_quad] \
  [get_bd_pins gt_quad_base/apb3clk]
  connect_bd_net -net bufg_gt_0_usrclk  [get_bd_pins bufg_gt_0/usrclk] \
  [get_bd_ports refclk]
  connect_bd_net -net bufg_gt_1_usrclk  [get_bd_pins bufg_gt_1/usrclk] \
  [get_bd_pins gt_bridge_ip_0/gt_txusrclk] \
  [get_bd_pins gt_quad_base/ch0_txusrclk]
  connect_bd_net -net bufg_gt_2_usrclk  [get_bd_pins bufg_gt_2/usrclk] \
  [get_bd_pins gt_bridge_ip_1/gt_txusrclk] \
  [get_bd_pins gt_quad_base/ch1_txusrclk]
  connect_bd_net -net bufg_gt_usrclk  [get_bd_pins bufg_gt/usrclk] \
  [get_bd_pins gt_bridge_ip_0/gt_rxusrclk] \
  [get_bd_pins gt_quad_base/ch0_rxusrclk]
  connect_bd_net -net ch0_rxslide_ext_0_1  [get_bd_ports ch0_rxslide_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_rxslide_ext]
  connect_bd_net -net ch0_txctrl0_ext_0_1  [get_bd_ports ch0_txctrl0_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txctrl0_ext]
  connect_bd_net -net ch0_txctrl0_ext_1  [get_bd_ports ch0_txctrl0_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txctrl0_ext]
  connect_bd_net -net ch0_txctrl1_ext_0_1  [get_bd_ports ch0_txctrl1_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txctrl1_ext]
  connect_bd_net -net ch0_txctrl1_ext_1  [get_bd_ports ch0_txctrl1_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txctrl1_ext]
  connect_bd_net -net ch0_txctrl2_ext_0_1  [get_bd_ports ch0_txctrl2_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txctrl2_ext]
  connect_bd_net -net ch0_txctrl2_ext_1  [get_bd_ports ch0_txctrl2_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txctrl2_ext]
  connect_bd_net -net ch0_txdata_ext_0_1  [get_bd_ports ch0_txdata_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txdata_ext]
  connect_bd_net -net ch0_txdata_ext_1  [get_bd_ports ch0_txdata_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txdata_ext]
  connect_bd_net -net ch0_txpippmen_ext_0_1  [get_bd_ports ch0_txpippmen_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txpippmen_ext]
  connect_bd_net -net ch0_txpippmen_ext_1_1  [get_bd_ports ch0_txpippmen_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txpippmen_ext]
  connect_bd_net -net ch0_txpippmstepsize_ext_0_1  [get_bd_ports ch0_txpippmstepsize_ext_0] \
  [get_bd_pins gt_bridge_ip_0/ch0_txpippmstepsize_ext]
  connect_bd_net -net ch0_txpippmstepsize_ext_1_1  [get_bd_ports ch0_txpippmstepsize_ext_1] \
  [get_bd_pins gt_bridge_ip_1/ch0_txpippmstepsize_ext]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxbufstatus_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxbufstatus_ext] \
  [get_bd_ports ch0_rxbufstatus_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxbyteisaligned_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxbyteisaligned_ext] \
  [get_bd_ports ch0_rxbyteisaligned_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxbyterealign_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxbyterealign_ext] \
  [get_bd_ports ch0_rxbyterealign_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxcommadet_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxcommadet_ext] \
  [get_bd_ports ch0_rxcommadet_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxctrl0_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxctrl0_ext] \
  [get_bd_ports ch0_rxctrl0_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxctrl1_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxctrl1_ext] \
  [get_bd_ports ch0_rxctrl1_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxctrl2_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxctrl2_ext] \
  [get_bd_ports ch0_rxctrl2_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxctrl3_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxctrl3_ext] \
  [get_bd_ports ch0_rxctrl3_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxdata_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxdata_ext] \
  [get_bd_ports ch0_rxdata_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_rxpmaresetdone_ext  [get_bd_pins gt_bridge_ip_0/ch0_rxpmaresetdone_ext] \
  [get_bd_ports ch0_rxpmaresetdone_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_txbufstatus_ext  [get_bd_pins gt_bridge_ip_0/ch0_txbufstatus_ext] \
  [get_bd_ports ch0_txbufstatus_ext_0]
  connect_bd_net -net gt_bridge_ip_0_ch0_txpmaresetdone_ext  [get_bd_pins gt_bridge_ip_0/ch0_txpmaresetdone_ext] \
  [get_bd_ports ch0_txpmaresetdone_ext_0]
  connect_bd_net -net gt_bridge_ip_0_lcpll_lock_out  [get_bd_pins gt_bridge_ip_0/lcpll_lock_out] \
  [get_bd_ports lcpll_lock_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_link_status_out  [get_bd_pins gt_bridge_ip_0/link_status_out] \
  [get_bd_ports link_status_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_rpll_lock_out  [get_bd_pins gt_bridge_ip_0/rpll_lock_out] \
  [get_bd_ports rpll_lock_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_rx_resetdone_out  [get_bd_pins gt_bridge_ip_0/rx_resetdone_out] \
  [get_bd_ports rx_resetdone_out_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_rxusrclk_out  [get_bd_pins gt_bridge_ip_0/rxusrclk_out] \
  [get_bd_ports rxusrclk_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_tx_resetdone_out  [get_bd_pins gt_bridge_ip_0/tx_resetdone_out] \
  [get_bd_ports tx_resetdone_out_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_0_txusrclk_out  [get_bd_pins gt_bridge_ip_0/txusrclk_out] \
  [get_bd_ports txusrclk_gt_bridge_ip_0]
  connect_bd_net -net gt_bridge_ip_1_ch0_txbufstatus_ext  [get_bd_pins gt_bridge_ip_1/ch0_txbufstatus_ext] \
  [get_bd_ports ch0_txbufstatus_ext_1]
  connect_bd_net -net gt_bridge_ip_1_ch0_txpmaresetdone_ext  [get_bd_pins gt_bridge_ip_1/ch0_txpmaresetdone_ext] \
  [get_bd_ports ch0_txpmaresetdone_ext_1]
  connect_bd_net -net gt_bridge_ip_1_lcpll_lock_out  [get_bd_pins gt_bridge_ip_1/lcpll_lock_out] \
  [get_bd_ports lcpll_lock_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_link_status_out  [get_bd_pins gt_bridge_ip_1/link_status_out] \
  [get_bd_ports link_status_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_rpll_lock_out  [get_bd_pins gt_bridge_ip_1/rpll_lock_out] \
  [get_bd_ports rpll_lock_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_rx_resetdone_out  [get_bd_pins gt_bridge_ip_1/rx_resetdone_out] \
  [get_bd_ports rx_resetdone_out_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_rxusrclk_out  [get_bd_pins gt_bridge_ip_1/rxusrclk_out] \
  [get_bd_ports rxusrclk_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_tx_resetdone_out  [get_bd_pins gt_bridge_ip_1/tx_resetdone_out] \
  [get_bd_ports tx_resetdone_out_gt_bridge_ip_1]
  connect_bd_net -net gt_bridge_ip_1_txusrclk_out  [get_bd_pins gt_bridge_ip_1/txusrclk_out] \
  [get_bd_ports txusrclk_gt_bridge_ip_1]
  connect_bd_net -net gt_quad_base_ch0_rxoutclk  [get_bd_pins gt_quad_base/ch0_rxoutclk] \
  [get_bd_pins bufg_gt/outclk]
  connect_bd_net -net gt_quad_base_ch0_txoutclk  [get_bd_pins gt_quad_base/ch0_txoutclk] \
  [get_bd_pins bufg_gt_1/outclk]
  connect_bd_net -net gt_quad_base_ch1_txoutclk  [get_bd_pins gt_quad_base/ch1_txoutclk] \
  [get_bd_pins bufg_gt_2/outclk]
  connect_bd_net -net gt_quad_base_gtpowergood  [get_bd_pins gt_quad_base/gtpowergood] \
  [get_bd_pins xlcp_1/In0] \
  [get_bd_pins xlcp/In0]
  connect_bd_net -net gt_quad_base_hsclk0_lcplllock  [get_bd_pins gt_quad_base/hsclk0_lcplllock] \
  [get_bd_pins gt_bridge_ip_0/gt_lcpll_lock] \
  [get_bd_pins gt_bridge_ip_1/gt_lcpll_lock]
  connect_bd_net -net gt_reset_gt_bridge_ip_0_1  [get_bd_ports gt_reset_gt_bridge_ip_0] \
  [get_bd_pins gt_bridge_ip_0/gtreset_in]
  connect_bd_net -net gt_reset_gt_bridge_ip_1_1  [get_bd_ports gt_reset_gt_bridge_ip_1] \
  [get_bd_pins gt_bridge_ip_1/gtreset_in]
  connect_bd_net -net rate_sel_gt_bridge_ip_0_1  [get_bd_ports rate_sel_gt_bridge_ip_0] \
  [get_bd_pins gt_bridge_ip_0/rate_sel]
  connect_bd_net -net rate_sel_gt_bridge_ip_1_1  [get_bd_ports rate_sel_gt_bridge_ip_1] \
  [get_bd_pins gt_bridge_ip_1/rate_sel]
  connect_bd_net -net reset_rx_datapath_in_1  [get_bd_ports reset_rx_datapath_in_0] \
  [get_bd_pins gt_bridge_ip_0/reset_rx_datapath_in]
  connect_bd_net -net reset_rx_pll_and_datapath_in_1  [get_bd_ports reset_rx_pll_and_datapath_in_0] \
  [get_bd_pins gt_bridge_ip_0/reset_rx_pll_and_datapath_in]
  connect_bd_net -net reset_tx_datapath_in_0_1  [get_bd_ports reset_tx_datapath_in_1] \
  [get_bd_pins gt_bridge_ip_1/reset_tx_datapath_in]
  connect_bd_net -net reset_tx_datapath_in_1  [get_bd_ports reset_tx_datapath_in_0] \
  [get_bd_pins gt_bridge_ip_0/reset_tx_datapath_in]
  connect_bd_net -net reset_tx_pll_and_datapath_in_0_1  [get_bd_ports reset_tx_pll_and_datapath_in_1] \
  [get_bd_pins gt_bridge_ip_1/reset_tx_pll_and_datapath_in]
  connect_bd_net -net reset_tx_pll_and_datapath_in_1  [get_bd_ports reset_tx_pll_and_datapath_in_0] \
  [get_bd_pins gt_bridge_ip_0/reset_tx_pll_and_datapath_in]
  connect_bd_net -net urlp_1_Res  [get_bd_pins urlp_1/Res] \
  [get_bd_pins gt_bridge_ip_1/gtpowergood]
  connect_bd_net -net urlp_Res  [get_bd_pins urlp/Res] \
  [get_bd_ports gtpowergood] \
  [get_bd_pins gt_bridge_ip_0/gtpowergood]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2  [get_bd_pins util_ds_buf/IBUF_DS_ODIV2] \
  [get_bd_pins bufg_gt_0/outclk]
  connect_bd_net -net util_ds_buf_IBUF_OUT  [get_bd_pins util_ds_buf/IBUF_OUT] \
  [get_bd_pins gt_quad_base/GT_REFCLK0]
  connect_bd_net -net xlcp_1_dout  [get_bd_pins xlcp_1/dout] \
  [get_bd_pins urlp_1/Op1]
  connect_bd_net -net xlcp_dout  [get_bd_pins xlcp/dout] \
  [get_bd_pins urlp/Op1]

  # Create address segments
  assign_bd_address -quiet -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces APB3_INTF_0] [get_bd_addr_segs gt_quad_base/APB3_INTF/Reg] -force


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

