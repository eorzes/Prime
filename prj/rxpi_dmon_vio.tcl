# RxPI DMONITOR control via vio_apb3_master (Hardware Manager)
# Usage (hw already open, device programmed, VIO owning the APB3 bus):
#   source rxpi_dmon_vio.tcl
#   rxpi_dmon_read
#   rxpi_dmon_write

namespace eval ::rxpi_dmon {
  variable vio ""
  variable p_addr ""
  variable p_write ""
  variable p_start ""
  variable p_wdata ""
  variable p_rdata ""
  variable p_busy ""
  variable p_done ""
  variable p_slverr ""
  variable p_timeout

  # addresses from Versal GTYP CDR PI / DMON sequence
  variable ADDR_RX_CDR_CFG1    0x0C2F
  variable ADDR_MONITOR_CFG    0x0CBA
  variable ADDR_ADAPT_GEN_CFG2 0x0C3C
  variable ADDR_RX_CDR_CFG0    0x0C2E
  variable ADDR_CTRL_RSV_CFG0  0x0C03

  # full 32-bit targets from the provided set_property list
  variable EXP_MONITOR_CFG    0x00000001
  variable EXP_ADAPT_GEN_CFG2 0x97FFFFFF
  variable EXP_RX_CDR_CFG0    0xAC050042
  variable EXP_CTRL_RSV_CFG0  0x00007819
}

proc rxpi_dmon::_probe_names {vio} {
  set names {}
  foreach p [get_hw_probes -of_objects $vio -quiet] {
    lappend names [get_property NAME $p]
  }
  return $names
}

proc rxpi_dmon::_find_probe {pat} {
  set vio $::rxpi_dmon::vio
  set hits {}
  foreach p [get_hw_probes -of_objects $vio -quiet] {
    set n [get_property NAME $p]
    if {[string match *$pat $n]} {
      lappend hits $p
    }
  }
  if {[llength $hits] == 0} {
    set hits [get_hw_probes *$pat* -quiet]
  }
  if {[llength $hits] == 0} {
    error "VIO probe matching '$pat' not found on [get_property NAME $vio]"
  }
  return [lindex $hits 0]
}

# dump every VIO and its probes (run this if init fails)
proc rxpi_dmon_list {} {
  set vios [get_hw_vios]
  puts "Found [llength $vios] VIO(s)"
  foreach v $vios {
    puts "------------------------------------------------------------"
    puts "VIO [get_property NAME $v]  cell=[get_property CELL_NAME $v]"
    foreach p [get_hw_probes -of_objects $v -quiet] {
      set dir "?"
      catch { set dir [get_property DIRECTION $p] }
      set w "?"
      catch { set w [get_property WIDTH $p] }
      puts [format "  %-6s w=%-3s %s" $dir $w [get_property NAME $p]]
    }
  }
}

proc rxpi_dmon::_vio_looks_apb3 {v} {
  set names [join [rxpi_dmon::_probe_names $v] " "]
  if {[string match *addr_i* $names] && [string match *start_i* $names]} { return 1 }
  if {[string match *vio_apb3* $names]} { return 1 }
  if {[string match *probe_out0* $names] && [string match *probe_out3* $names] && [string match *probe_in0* $names]} {
    # system VIO also has probe_out*, require 16-bit addr + 32-bit data
    set has16 0
    set has32 0
    foreach p [get_hw_probes -of_objects $v -quiet] {
      set n [get_property NAME $p]
      set w 0
      catch { set w [get_property WIDTH $p] }
      if {[string match *probe_out0 $n] && $w == 16} { set has16 1 }
      if {[string match *probe_out3 $n] && $w == 32} { set has32 1 }
    }
    if {$has16 && $has32} { return 1 }
  }
  return 0
}

proc rxpi_dmon_init {{which "hw_vio_5"}} {
  set vios [get_hw_vios]
  if {[llength $vios] == 0} {
    error "No hw_vio found. Open Hardware Manager and program the device first."
  }

  set pick ""
  if {$which ne ""} {
    set pick [lindex [get_hw_vios -quiet $which] 0]
    if {$pick eq ""} { set pick [lindex [get_hw_vios -quiet *$which*] 0] }
    if {$pick eq ""} { error "VIO '$which' not found. Have: $vios" }
  }
  if {$pick eq ""} {
    foreach v $vios {
      set n [get_property NAME $v]
      set c ""
      catch { set c [get_property CELL_NAME $v] }
      if {[string match *vio_apb3_master* $n] || [string match *vio_apb3_master* $c] || [string match *u_vio* $c]} {
        set pick $v
        break
      }
      if {[rxpi_dmon::_vio_looks_apb3 $v]} {
        set pick $v
        break
      }
    }
  }

  if {$pick eq ""} {
    puts "ERROR: APB3 VIO not found. hw_vio_1 is the reset/status VIO, not vio_apb3_master."
    puts "The APB3 VIO is missing from the debug hub (not in bitstream, or clock/debug core not running)."
    rxpi_dmon_list
    error "Instantiate vio_apb3_master, connect its clk to clk_sys, rebuild, and re-program."
  }

  set ::rxpi_dmon::vio $pick
  puts "Using VIO: [get_property NAME $pick]"

  # accept either generated names or the VHDL net names
  set addr_pats   {addr_i probe_out0}
  set write_pats  {write_i probe_out1}
  set start_pats  {start_i probe_out2}
  set wdata_pats  {wdata_i probe_out3}
  set rdata_pats  {rdata_o probe_in0}
  set busy_pats   {busy_o probe_in1}
  set done_pats   {done_o probe_in2}
  set slverr_pats {slverr_o probe_in3}
  set tmo_pats    {timeout_error_o probe_in4}

  proc rxpi_dmon::_first_pat {pats} {
    foreach pat $pats {
      if {![catch {set p [rxpi_dmon::_find_probe $pat]}]} { return $p }
    }
    error "None of these probes found: $pats"
  }

  set ::rxpi_dmon::p_addr    [rxpi_dmon::_first_pat $addr_pats]
  set ::rxpi_dmon::p_write   [rxpi_dmon::_first_pat $write_pats]
  set ::rxpi_dmon::p_start   [rxpi_dmon::_first_pat $start_pats]
  set ::rxpi_dmon::p_wdata   [rxpi_dmon::_first_pat $wdata_pats]
  set ::rxpi_dmon::p_rdata   [rxpi_dmon::_first_pat $rdata_pats]
  set ::rxpi_dmon::p_busy    [rxpi_dmon::_first_pat $busy_pats]
  set ::rxpi_dmon::p_done    [rxpi_dmon::_first_pat $done_pats]
  set ::rxpi_dmon::p_slverr  [rxpi_dmon::_first_pat $slverr_pats]
  set ::rxpi_dmon::p_timeout [rxpi_dmon::_first_pat $tmo_pats]

  foreach p [list \
      $::rxpi_dmon::p_addr $::rxpi_dmon::p_wdata $::rxpi_dmon::p_rdata] {
    catch { set_property OUTPUT_VALUE_RADIX HEX $p }
    catch { set_property INPUT_VALUE_RADIX  HEX $p }
  }
  foreach p [list \
      $::rxpi_dmon::p_write $::rxpi_dmon::p_start \
      $::rxpi_dmon::p_busy $::rxpi_dmon::p_done \
      $::rxpi_dmon::p_slverr $::rxpi_dmon::p_timeout] {
    catch { set_property OUTPUT_VALUE_RADIX BIN $p }
    catch { set_property INPUT_VALUE_RADIX  BIN $p }
  }
}

proc rxpi_dmon::_bit {val} {
  # INPUT_VALUE may be "1", "0", "0b1", "0b0"
  set s [string trim $val]
  if {[string match 0b* $s]} {
    set s [string range $s 2 end]
  }
  if {$s eq "" || $s eq "0"} { return 0 }
  return 1
}

proc rxpi_dmon::_hex {val} {
  set s [string trim $val]
  set s [string map {_ ""} $s]
  if {$s eq "" || [string equal -nocase $s 0x] || [string equal -nocase $s 0b]} {
    return 0
  }
  set sl [string tolower $s]
  if {[string match 0b* $sl]} {
    set bits [string range $sl 2 end]
    if {$bits eq ""} { return 0 }
    set bits [string map {" " ""} $bits]
    set acc 0
    foreach c [split $bits {}] {
      if {$c ne "0" && $c ne "1"} { error "cannot parse binary value '$val'" }
      set acc [expr {$acc * 2 + $c}]
    }
    return $acc
  }
  if {[string match 0x* $sl]} {
    set digits [string range $sl 2 end]
  } else {
    set digits $sl
  }
  set digits [string map {" " ""} $digits]
  if {$digits eq "" || ![regexp {^[0-9a-f]+$} $digits]} {
    error "cannot parse hex value '$val'"
  }
  if {[scan $digits %x parsed] != 1} {
    error "cannot parse hex value '$val'"
  }
  return $parsed
}

proc rxpi_dmon::_wait_idle {{timeout_ms 200}} {
  set vio $::rxpi_dmon::vio
  for {set i 0} {$i < $timeout_ms} {incr i} {
    refresh_hw_vio $vio
    if {![rxpi_dmon::_bit [get_property INPUT_VALUE $::rxpi_dmon::p_busy]]} {
      return
    }
    after 1
  }
  error "APB3 timeout waiting for busy=0 (slverr=[get_property INPUT_VALUE $::rxpi_dmon::p_slverr] timeout=[get_property INPUT_VALUE $::rxpi_dmon::p_timeout])"
}

proc rxpi_dmon::_start_pulse {} {
  set vio $::rxpi_dmon::vio
  set p $::rxpi_dmon::p_start
  set_property OUTPUT_VALUE 0 $p
  commit_hw_vio $vio
  set_property OUTPUT_VALUE 1 $p
  commit_hw_vio $vio
  set_property OUTPUT_VALUE 0 $p
  commit_hw_vio $vio
}

proc rxpi_dmon_write_reg {addr data} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  set vio $::rxpi_dmon::vio
  rxpi_dmon::_wait_idle
  set_property OUTPUT_VALUE [format %04X $addr] $::rxpi_dmon::p_addr
  set_property OUTPUT_VALUE [format %08X $data] $::rxpi_dmon::p_wdata
  set_property OUTPUT_VALUE 1                   $::rxpi_dmon::p_write
  commit_hw_vio $vio
  rxpi_dmon::_start_pulse
  rxpi_dmon::_wait_idle
  refresh_hw_vio $vio
  if {[rxpi_dmon::_bit [get_property INPUT_VALUE $::rxpi_dmon::p_slverr]]} {
    error [format "APB3 slverr on write 0x%04X" $addr]
  }
}

proc rxpi_dmon_read_reg {addr} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  set vio $::rxpi_dmon::vio
  rxpi_dmon::_wait_idle
  set_property OUTPUT_VALUE [format %04X $addr] $::rxpi_dmon::p_addr
  set_property OUTPUT_VALUE 0                   $::rxpi_dmon::p_write
  commit_hw_vio $vio
  rxpi_dmon::_start_pulse
  rxpi_dmon::_wait_idle
  refresh_hw_vio $vio
  if {[rxpi_dmon::_bit [get_property INPUT_VALUE $::rxpi_dmon::p_slverr]]} {
    error [format "APB3 slverr on read 0x%04X" $addr]
  }
  return [rxpi_dmon::_hex [get_property INPUT_VALUE $::rxpi_dmon::p_rdata]]
}

proc rxpi_dmon::_yn {ok} {
  if {$ok} { return "OK" } else { return "MISMATCH" }
}

# ---------------------------------------------------------------------------
# 1) read + compare against the attached DMON sequence
# ---------------------------------------------------------------------------
proc rxpi_dmon_read {} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }

  set cdr1  [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_RX_CDR_CFG1]
  set mon   [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_MONITOR_CFG]
  set adapt [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_ADAPT_GEN_CFG2]
  set cdr0  [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_RX_CDR_CFG0]
  set rsv   [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_CTRL_RSV_CFG0]

  set pi_ddr_mode [expr {($cdr1  >> 8)  & 0x1}]
  set dmon_en_mon [expr {$mon           & 0x1}]
  set aptsel      [expr {($adapt >> 27) & 0x3}]
  set testen      [expr {($cdr0  >> 1)  & 0x1}]
  set dmon_en_rsv [expr {$rsv           & 0x1}]

  set ok_cdr1  [expr {$pi_ddr_mode == 1}]
  set ok_mon   [expr {$dmon_en_mon == 1}]
  set ok_adapt [expr {$aptsel      == 2}]
  set ok_cdr0  [expr {$testen      == 1}]
  set ok_rsv   [expr {$dmon_en_rsv == 1}]

  puts "============================================================"
  puts "RxPI DMONITOR register check (via VIO APB3)"
  puts "============================================================"
  puts [format "CH0_RX_CDR_CFG1    @0x0C2F = 0x%08X   PI_DDR_MODE[8]=%d  (req 1)     %s" \
      $cdr1 $pi_ddr_mode [rxpi_dmon::_yn $ok_cdr1]]
  puts [format "CH0_MONITOR_CFG    @0x0CBA = 0x%08X   DMON_EN[0]=%d     (req 1)     %s" \
      $mon $dmon_en_mon [rxpi_dmon::_yn $ok_mon]]
  puts [format "                   expected full 0x%08X                 %s" \
      $::rxpi_dmon::EXP_MONITOR_CFG [rxpi_dmon::_yn [expr {$mon == $::rxpi_dmon::EXP_MONITOR_CFG}]]]
  puts [format "CH0_ADAPT_GEN_CFG2 @0x0C3C = 0x%08X   APTSEL[28:27]=0x%X (req 0x2)  %s" \
      $adapt $aptsel [rxpi_dmon::_yn $ok_adapt]]
  puts [format "                   expected full 0x%08X                 %s" \
      $::rxpi_dmon::EXP_ADAPT_GEN_CFG2 [rxpi_dmon::_yn [expr {$adapt == $::rxpi_dmon::EXP_ADAPT_GEN_CFG2}]]]
  puts [format "CH0_RX_CDR_CFG0    @0x0C2E = 0x%08X   TESTEN[1]=%d      (req 1)     %s" \
      $cdr0 $testen [rxpi_dmon::_yn $ok_cdr0]]
  puts [format "                   expected full 0x%08X                 %s" \
      $::rxpi_dmon::EXP_RX_CDR_CFG0 [rxpi_dmon::_yn [expr {$cdr0 == $::rxpi_dmon::EXP_RX_CDR_CFG0}]]]
  puts [format "CTRL_RSV_CFG0      @0x0C03 = 0x%08X   DMON_EN[0]=%d     (req 1)     %s" \
      $rsv $dmon_en_rsv [rxpi_dmon::_yn $ok_rsv]]
  puts [format "                   expected full 0x%08X                 %s" \
      $::rxpi_dmon::EXP_CTRL_RSV_CFG0 [rxpi_dmon::_yn [expr {$rsv == $::rxpi_dmon::EXP_CTRL_RSV_CFG0}]]]
  puts "------------------------------------------------------------"
  if {$ok_cdr1 && $ok_mon && $ok_adapt && $ok_cdr0 && $ok_rsv} {
    puts "RESULT: all required bit-fields MATCH"
  } else {
    puts "RESULT: one or more required bit-fields DO NOT MATCH"
  }
  puts "============================================================"

  return [list $cdr1 $mon $adapt $cdr0 $rsv]
}

# ---------------------------------------------------------------------------
# 2) write required bit-fields (RMW, then verify)
# ---------------------------------------------------------------------------
proc rxpi_dmon_write {} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }

  puts "Writing RxPI DMONITOR enable sequence..."

  # CH0_MONITOR_CFG[0] = 1
  set mon [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_MONITOR_CFG]
  set mon_w [expr {$mon | 0x00000001}]
  rxpi_dmon_write_reg $::rxpi_dmon::ADDR_MONITOR_CFG $mon_w
  puts [format "  CH0_MONITOR_CFG    0x%08X -> 0x%08X" $mon $mon_w]

  # CH0_ADAPT_GEN_CFG2[28:27] = 0x2
  set adapt [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_ADAPT_GEN_CFG2]
  set adapt_w [expr {($adapt & ~0x18000000) | 0x10000000}]
  rxpi_dmon_write_reg $::rxpi_dmon::ADDR_ADAPT_GEN_CFG2 $adapt_w
  puts [format "  CH0_ADAPT_GEN_CFG2 0x%08X -> 0x%08X" $adapt $adapt_w]

  # CH0_RX_CDR_CFG0[1] = 1
  set cdr0 [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_RX_CDR_CFG0]
  set cdr0_w [expr {$cdr0 | 0x00000002}]
  rxpi_dmon_write_reg $::rxpi_dmon::ADDR_RX_CDR_CFG0 $cdr0_w
  puts [format "  CH0_RX_CDR_CFG0    0x%08X -> 0x%08X" $cdr0 $cdr0_w]

  # CTRL_RSV_CFG0[0] = 1
  set rsv [rxpi_dmon_read_reg $::rxpi_dmon::ADDR_CTRL_RSV_CFG0]
  set rsv_w [expr {$rsv | 0x00000001}]
  rxpi_dmon_write_reg $::rxpi_dmon::ADDR_CTRL_RSV_CFG0 $rsv_w
  puts [format "  CTRL_RSV_CFG0      0x%08X -> 0x%08X" $rsv $rsv_w]

  puts "Write done. Re-reading..."
  rxpi_dmon_read
}

puts "Loaded rxpi_dmon_vio.tcl"
puts "  rxpi_dmon_read   - print registers and match/mismatch"
puts "  rxpi_dmon_write  - RMW required DMON bits, then re-read"
