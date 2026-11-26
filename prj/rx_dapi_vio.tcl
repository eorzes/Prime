# RX DAPI / DA bypass check via VIO APB3 (Hardware Manager)
# AM002: "RX DAPI and RX DAPI Bypass Dividers"
#   https://docs.amd.com/r/en-US/am002-versal-gty-transceivers/RX-Interface
#
# Usage (same VIO path as rxpi_dmon_vio.tcl):
#   source rxpi_dmon_vio.tcl
#   source rx_dapi_vio.tcl
#   rxpi_dmon_init hw_vio_5
#   rx_dapi_read
#
# Documented in AM002 Ports and Attributes for that section:
#   RX_DA_BYP      CH0_PIPE_CTRL_CFG7  0x0CA4  [15]
#                  0 = DAPI used (built-in /2), 1 = DAPI bypassed
#   RXOUTCLKCTL    CH0_PIPE_CTRL_CFG7  0x0CA4  [14:12]  (same register)
#   RX_DA_REFCLK_SEL CH0_DA_CFG        0x0C5C  [3]
#
# Named in AM002 prose but NO bit field / address published:
#   RX DA DIV            (use wizard default when RX_DA_BYP=0)
#   RX DAPI BYPASS DIV   (use wizard default when RX_DA_BYP=1)
# The script dumps CH0_DA_CFG and CH0_PIPE_CTRL_CFG7 so those bits
# can be inspected even though AM002 does not name them.

if {[info procs rxpi_dmon_read_reg] eq ""} {
  error "source rxpi_dmon_vio.tcl first (needs rxpi_dmon_read_reg / rxpi_dmon_init)"
}

namespace eval ::rx_dapi {
  variable ADDR_PIPE_CTRL_CFG7 0x0CA4
  variable ADDR_PIPE_CTRL_CFG8 0x0CA5
  variable ADDR_DA_CFG         0x0C5C
  variable ADDR_PIPE_CTRL_CFG3 0x0CA0
  variable ADDR_PHALIGN_CFG0   0x0C91
  variable ADDR_PHALIGN_CFG1   0x0C92
  variable ADDR_PHALIGN_CFG5   0x0C96
  variable ADDR_RX_PCS_CFG2    0x0C67
}

proc rx_dapi::_rxoutclkctl_str {v} {
  switch -- $v {
    1 { return "RXOUTPCSCLK" }
    2 { return "RXPHYCLK" }
    3 { return "RXREFCLKPMA" }
    5 { return "RXPROGDIVCLK" }
    6 { return "CH*_TXOUTCLK" }
    default { return "reserved/unknown" }
  }
}

proc rx_dapi::_rxout_div_str {v} {
  switch -- $v {
    0 { return "/1" }
    1 { return "/2" }
    2 { return "/4" }
    3 { return "/8" }
    4 { return "/16" }
    default { return "reserved" }
  }
}

proc rx_dapi_read {} {
  rx_phalign_read
}

proc rx_dapi::_sync_mode_str {v} {
  switch -- $v {
    0 { return "slave / single-lane" }
    1 { return "initial master" }
    2 { return "maintenance master" }
    default { return "reserved" }
  }
}

proc rx_dapi::_chain_mode_str {v} {
  switch -- $v {
    0 { return "unused (single-lane)" }
    1 { return "top lane of multi-lane block" }
    2 { return "bottom lane of multi-lane block" }
    3 { return "middle lane(s) of multi-lane block" }
    default { return "reserved" }
  }
}

proc rx_dapi::_cmn_mode_str {v} {
  switch -- $v {
    0 { return "common clock disabled / async gearbox" }
    1 { return "TX initial master common clock" }
    2 { return "RX initial master common clock" }
    3 { return "reserved" }
    default { return "reserved" }
  }
}

# AM002 RX Buffer Bypass attributes (phase + delay alignment)
# https://docs.amd.com/r/en-US/am002-versal-gty-transceivers/RX-Buffer-Bypass
proc rx_phalign_read {} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }

  set cfg0 0
  set cfg1 0
  set cfg5 0
  set pcs2 0
  set cfg7 0
  set cfg8 0
  set dacfg 0
  set cfg3 0
  set ok0 1
  set ok1 1
  set ok5 1
  set okp 1
  set ok7 1
  set ok8 1
  set okda 1
  set ok3 1

  if {[catch {set cfg0 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PHALIGN_CFG0]} err]} {
    set ok0 0
    puts "CH0_RX_PHALIGN_CFG0 @0x0C91 READ FAIL: $err"
  }
  if {[catch {set cfg1 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PHALIGN_CFG1]} err]} {
    set ok1 0
    puts "CH0_RX_PHALIGN_CFG1 @0x0C92 READ FAIL: $err"
  }
  if {[catch {set cfg5 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PHALIGN_CFG5]} err]} {
    set ok5 0
    puts "CH0_RX_PHALIGN_CFG5 @0x0C96 READ FAIL: $err"
  }
  if {[catch {set pcs2 [rxpi_dmon_read_reg $::rx_dapi::ADDR_RX_PCS_CFG2]} err]} {
    set okp 0
    puts "CH0_RX_PCS_CFG2     @0x0C67 READ FAIL: $err"
  }
  if {[catch {set cfg7 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PIPE_CTRL_CFG7]} err]} {
    set ok7 0
    puts "CH0_PIPE_CTRL_CFG7  @0x0CA4 READ FAIL: $err"
  }
  if {[catch {set cfg8 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PIPE_CTRL_CFG8]} err]} {
    set ok8 0
    puts "CH0_PIPE_CTRL_CFG8  @0x0CA5 READ FAIL: $err"
  }
  if {[catch {set dacfg [rxpi_dmon_read_reg $::rx_dapi::ADDR_DA_CFG]} err]} {
    set okda 0
    puts "CH0_DA_CFG          @0x0C5C READ FAIL: $err"
  }
  if {[catch {set cfg3 [rxpi_dmon_read_reg $::rx_dapi::ADDR_PIPE_CTRL_CFG3]} err]} {
    set ok3 0
    puts "CH0_PIPE_CTRL_CFG3  @0x0CA0 READ FAIL: $err"
  }

  puts "============================================================"
  puts "RX buffer-bypass / DAPI / progdiv (AM002, CH0)"
  puts "============================================================"

  if {$ok0} {
    set dly   [expr {($cfg0 >> 31) & 0x1}]
    set ph    [expr {($cfg0 >> 30) & 0x1}]
    set smode [expr {($cfg0 >> 16) & 0x3}]
    set multi [expr {($cfg0 >> 15) & 0x1}]
    set byp   [expr {($cfg0 >> 14) & 0x1}]
    puts [format "CH0_RX_PHALIGN_CFG0 @0x0C91 = 0x%08X" $cfg0]
    puts [format "  DLY_ALIGN_EN      [31]    = %d    %s" $dly [expr {$dly ? "delay align ON" : "delay align OFF"}]]
    puts [format "  PH_ALIGN_EN       [30]    = %d    %s" $ph  [expr {$ph  ? "phase align ON" : "phase align OFF"}]]
    puts [format "  SYNC_MODE         [17:16] = %d    %s" $smode [rx_dapi::_sync_mode_str $smode]]
    puts [format "  SYNC_MULTI_LANE   [15]    = %d    %s" $multi [expr {$multi ? "multi-lane" : "single-lane"}]]
    puts [format "  RXBUF_BYPASS_MODE [14]    = %d    %s" $byp [expr {$byp ? "buffer BYPASSED" : "buffer IN USE"}]]
  }

  if {$ok7} {
    set da_byp   [expr {($cfg7 >> 15) & 0x1}]
    set rxoutctl [expr {($cfg7 >> 12) & 0x7}]
    puts [format "CH0_PIPE_CTRL_CFG7  @0x0CA4 = 0x%08X" $cfg7]
    puts [format "  RX_DA_BYP         [15]    = %d    %s" $da_byp \
        [expr {$da_byp ? "DAPI BYPASSED" : "DAPI in RXOUTCLK path"}]]
    puts [format "  RXOUTCLKCTL       [14:12] = %d    %s" $rxoutctl [rx_dapi::_rxoutclkctl_str $rxoutctl]]
  }

  if {$ok8} {
    set psel [expr {($cfg8 >> 10) & 0x3FF}]
    puts [format "CH0_PIPE_CTRL_CFG8  @0x0CA5 = 0x%08X" $cfg8]
    puts [format "  RXPROGDIVSEL      [19:10] = 0x%03X  /%s" $psel [rx_dapi::_progdiv_str $psel]]
  }

  if {$okda} {
    set refsel [expr {($dacfg >> 3) & 0x1}]
    puts [format "CH0_DA_CFG          @0x0C5C = 0x%08X" $dacfg]
    puts [format "  RX_DA_REFCLK_SEL  [3]     = %d    %s" $refsel \
        [expr {$refsel ? "LCPLL refclk" : "RPLL refclk"}]]
  }

  if {$ok3} {
    set rdiv [expr {($cfg3 >> 26) & 0x7}]
    puts [format "CH0_PIPE_CTRL_CFG3  @0x0CA0 = 0x%08X" $cfg3]
    puts [format "  RXOUT_DIV         [28:26] = %d    %s  (serial D, not PROGDIV)" \
        $rdiv [rx_dapi::_rxout_div_str $rdiv]]
  }

  if {$ok1} {
    set chain [expr {($cfg1 >> 2) & 0x3}]
    set agbox [expr {($cfg1 >> 1) & 0x1}]
    puts [format "CH0_RX_PHALIGN_CFG1 @0x0C92 = 0x%08X" $cfg1]
    puts [format "  CHAIN_MODE           [3:2] = %d    %s" $chain [rx_dapi::_chain_mode_str $chain]]
    puts [format "  ASYNC_GBOX_PHALIGN_EN [1] = %d    %s" $agbox \
        [expr {$agbox ? "async gearbox phalign ON" : "async gearbox phalign OFF"}]]
    puts "  (AM002 attribute table: CHAIN_MODE[3:2], ASYNC_GBOX[1]; some use-mode lists write [2:1]/[0])"
  }

  if {$ok5} {
    set cmn [expr {($cfg5 >> 26) & 0x3}]
    puts [format "CH0_RX_PHALIGN_CFG5 @0x0C96 = 0x%08X" $cfg5]
    puts [format "  CMN_FAB_CLK_PHALIGN_MODE [27:26] = %d    %s" $cmn [rx_dapi::_cmn_mode_str $cmn]]
  }

  if {$okp} {
    set pbuf [expr {($pcs2 >> 30) & 0x1}]
    puts [format "CH0_RX_PCS_CFG2     @0x0C67 = 0x%08X" $pcs2]
    puts [format "  RX_PHASE_BUFFER_USE [30]   = %d    %s" $pbuf \
        [expr {$pbuf ? "RX phase buffer control ON" : "RX phase buffer control OFF"}]]
  }

  puts "------------------------------------------------------------"
  puts "AM002 single-lane auto buffer bypass reference:"
  puts "  DLY_ALIGN_EN=1  PH_ALIGN_EN=1  SYNC_MODE=0  SYNC_MULTI_LANE=0"
  puts "  RXBUF_BYPASS_MODE=1  CHAIN_MODE=0  ASYNC_GBOX_PHALIGN_EN=0"
  puts "  RXOUTCLKCTL=RXPHYCLK(2) or RXPROGDIVCLK(5)"
  puts "============================================================"

  return [list $cfg0 $cfg1 $cfg5 $pcs2 $cfg7 $cfg8 $dacfg $cfg3]
}

# RMW CH0_RX_PHALIGN_CFG0 (0x0C91)
#   DLY_ALIGN_EN [31]  PH_ALIGN_EN [30]
proc rx_dapi::_phalign0_rmw {mask_clear mask_set label} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  set addr $::rx_dapi::ADDR_PHALIGN_CFG0
  set old [rxpi_dmon_read_reg $addr]
  set new [expr {($old & ~$mask_clear) | $mask_set}]
  puts [format "%s" $label]
  puts [format "  CH0_RX_PHALIGN_CFG0 0x%08X -> 0x%08X" $old $new]
  rxpi_dmon_write_reg $addr $new
  set rd [rxpi_dmon_read_reg $addr]
  set dly [expr {($rd >> 31) & 0x1}]
  set ph  [expr {($rd >> 30) & 0x1}]
  puts [format "  readback 0x%08X  DLY_ALIGN_EN=%d  PH_ALIGN_EN=%d" $rd $dly $ph]
  return $rd
}

proc rx_ph_align_disable {} {
  # PH_ALIGN_EN [30] = 0
  rx_dapi::_phalign0_rmw 0x40000000 0x00000000 "Disable RX phase aligner (PH_ALIGN_EN=0)"
}

proc rx_dly_align_disable {} {
  # DLY_ALIGN_EN [31] = 0
  rx_dapi::_phalign0_rmw 0x80000000 0x00000000 "Disable RX delay aligner (DLY_ALIGN_EN=0)"
}

proc rx_ph_align_enable {} {
  # PH_ALIGN_EN [30] = 1
  rx_dapi::_phalign0_rmw 0x40000000 0x40000000 "Enable RX phase aligner (PH_ALIGN_EN=1)"
}

proc rx_dly_align_enable {} {
  # DLY_ALIGN_EN [31] = 1
  rx_dapi::_phalign0_rmw 0x80000000 0x80000000 "Enable RX delay aligner (DLY_ALIGN_EN=1)"
}

# RMW CH0_PIPE_CTRL_CFG7 (0x0CA4)
#   RX_DA_BYP [15]  0 = DAPI in RXOUTCLK path, 1 = DAPI bypassed
# Leaves DLY_ALIGN_EN / PH_ALIGN_EN untouched.
proc rx_dapi::_pipe7_rmw {mask_clear mask_set label} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  set addr $::rx_dapi::ADDR_PIPE_CTRL_CFG7
  set old [rxpi_dmon_read_reg $addr]
  set new [expr {($old & ~$mask_clear) | $mask_set}]
  puts [format "%s" $label]
  puts [format "  CH0_PIPE_CTRL_CFG7 0x%08X -> 0x%08X" $old $new]
  rxpi_dmon_write_reg $addr $new
  set rd [rxpi_dmon_read_reg $addr]
  set byp [expr {($rd >> 15) & 0x1}]
  set ctl [expr {($rd >> 12) & 0x7}]
  puts [format "  readback 0x%08X  RX_DA_BYP=%d  RXOUTCLKCTL=%d (%s)" \
      $rd $byp $ctl [rx_dapi::_rxoutclkctl_str $ctl]]
  return $rd
}

proc rx_dly_align_bypass {} {
  rx_dapi::_pipe7_rmw 0x00008000 0x00008000 \
      "Bypass RX DAPI (RX_DA_BYP=1), DLY_ALIGN_EN unchanged"
}

proc rx_dly_align_unbypass {} {
  rx_dapi::_pipe7_rmw 0x00008000 0x00000000 \
      "Use RX DAPI (RX_DA_BYP=0), DLY_ALIGN_EN unchanged"
}

# AM002 CH0_PIPE_CTRL_CFG8 0x0CA5 RXPROGDIVSEL[19:10]
# 10'b1001011000 /4     10'b1001111000 /5     10'b1110011000 /5.5
# 10'b0001011000 /8     10'b0001111000 /10    10'b0001000000 /16
# 10'b1100011000 /16.5  10'b0001100000 /20    10'b0001000010 /32
# 10'b0100011000 /33    10'b0001100010 /40
proc rx_dapi::_progdiv_code {div} {
  set d [string trim $div]
  set d [string map {/ "" X x} $d]
  switch -- $d {
    4     { return 0x258 }
    5     { return 0x278 }
    5.5   { return 0x398 }
    8     { return 0x058 }
    10    { return 0x078 }
    16    { return 0x040 }
    16.5  { return 0x318 }
    20    { return 0x060 }
    32    { return 0x042 }
    33    { return 0x118 }
    40    { return 0x062 }
    default {
      error "RXPROGDIVSEL: '$div' not in AM002 list 4 5 5.5 8 10 16 16.5 20 32 33 40"
    }
  }
}

proc rx_dapi::_progdiv_str {code} {
  set code [expr {$code & 0x3FF}]
  switch -- $code {
    600 { return 4 }
    632 { return 5 }
    920 { return 5.5 }
    88  { return 8 }
    120 { return 10 }
    64  { return 16 }
    792 { return 16.5 }
    96  { return 20 }
    66  { return 32 }
    280 { return 33 }
    98  { return 40 }
    default { return "unknown(0x[format %03X $code])" }
  }
}

proc rx_progdiv_set {div} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  set addr $::rx_dapi::ADDR_PIPE_CTRL_CFG8
  set code [rx_dapi::_progdiv_code $div]
  set old [rxpi_dmon_read_reg $addr]
  set new [expr {($old & ~0x000FFC00) | (($code & 0x3FF) << 10)}]
  puts [format "RXPROGDIVSEL -> /%s  code=0x%03X" $div $code]
  puts [format "  CH0_PIPE_CTRL_CFG8 0x%08X -> 0x%08X" $old $new]
  rxpi_dmon_write_reg $addr $new
  set rd [rxpi_dmon_read_reg $addr]
  set got [expr {($rd >> 10) & 0x3FF}]
  puts [format "  readback 0x%08X  RXPROGDIVSEL=/%s" $rd [rx_dapi::_progdiv_str $got]]
  return $rd
}

# CH0 RXPHDLYRESET / RXSYNCDONE on the same vio_apb3
# VHDL: probe_out4=rxphdlypd  probe_out5=rxphdlyreset
#       probe_in5=rxphdlyresetdone  probe_in6=rxsyncdone
namespace eval ::rx_dapi {
  variable p_pd ""
  variable p_rst ""
  variable p_rstdone ""
  variable p_sync ""
}

proc rx_dapi::_phdly_first {pats} {
  foreach pat $pats {
    if {![catch {set p [rxpi_dmon::_find_probe $pat]}]} { return $p }
  }
  error "None of these probes found: $pats"
}

proc rx_dapi::_phdly_bind {} {
  if {$::rxpi_dmon::vio eq ""} { rxpi_dmon_init }
  if {$::rx_dapi::p_rst ne ""} { return }
  set ::rx_dapi::p_pd      [rx_dapi::_phdly_first {rxphdlypd probe_out4}]
  set ::rx_dapi::p_rst     [rx_dapi::_phdly_first {rxphdlyreset probe_out5}]
  set ::rx_dapi::p_rstdone [rx_dapi::_phdly_first {rxphdlyresetdone probe_in5}]
  set ::rx_dapi::p_sync    [rx_dapi::_phdly_first {rxsyncdone probe_in6}]
  foreach p [list $::rx_dapi::p_pd $::rx_dapi::p_rst $::rx_dapi::p_rstdone $::rx_dapi::p_sync] {
    catch { set_property OUTPUT_VALUE_RADIX BIN $p }
    catch { set_property INPUT_VALUE_RADIX  BIN $p }
  }
  puts "  rxphdlypd        [get_property NAME $::rx_dapi::p_pd]"
  puts "  rxphdlyreset     [get_property NAME $::rx_dapi::p_rst]"
  puts "  rxphdlyresetdone [get_property NAME $::rx_dapi::p_rstdone]"
  puts "  rxsyncdone       [get_property NAME $::rx_dapi::p_sync]"
}

proc rx_phdly_status {} {
  rx_dapi::_phdly_bind
  refresh_hw_vio $::rxpi_dmon::vio
  set pd  [rxpi_dmon::_bit [get_property OUTPUT_VALUE $::rx_dapi::p_pd]]
  set rst [rxpi_dmon::_bit [get_property OUTPUT_VALUE $::rx_dapi::p_rst]]
  set rdn [rxpi_dmon::_bit [get_property INPUT_VALUE  $::rx_dapi::p_rstdone]]
  set syn [rxpi_dmon::_bit [get_property INPUT_VALUE  $::rx_dapi::p_sync]]
  puts [format "RXPHDLYPD=%d  RXPHDLYRESET=%d  RXPHDLYRESETDONE=%d  RXSYNCDONE=%d" $pd $rst $rdn $syn]
  return $syn
}

# Pulse RXPHDLYRESET (assert then release). Forces RXPHDLYPD=0.
# Returns RXSYNCDONE (1=align finished, 0=timeout).
proc rx_phdly_reset {{wait_ms 2000}} {
  rx_dapi::_phdly_bind
  set vio $::rxpi_dmon::vio

  set_property OUTPUT_VALUE 0 $::rx_dapi::p_pd
  set_property OUTPUT_VALUE 0 $::rx_dapi::p_rst
  commit_hw_vio $vio
  after 20

  puts "RXPHDLYRESET 0 -> 1"
  set_property OUTPUT_VALUE 1 $::rx_dapi::p_rst
  commit_hw_vio $vio
  after 50

  puts "RXPHDLYRESET 1 -> 0  (start auto align)"
  set_property OUTPUT_VALUE 0 $::rx_dapi::p_rst
  commit_hw_vio $vio

  set t0 [clock milliseconds]
  set syn 0
  set rdn 0
  set dt 0
  while {1} {
    refresh_hw_vio $vio
    set rdn [rxpi_dmon::_bit [get_property INPUT_VALUE $::rx_dapi::p_rstdone]]
    set syn [rxpi_dmon::_bit [get_property INPUT_VALUE $::rx_dapi::p_sync]]
    set dt [expr {[clock milliseconds] - $t0}]
    if {$syn} { break }
    if {$dt >= $wait_ms} { break }
    after 50
  }
  puts [format "waited %d ms  RXPHDLYRESETDONE=%d  RXSYNCDONE=%d" $dt $rdn $syn]
  return $syn
}

puts "Loaded rx_dapi_vio.tcl"
puts "  rx_dapi_read / rx_phalign_read - one dump: phalign + DAPI + RXPROGDIVSEL"
puts "  rx_ph_align_disable    - PH_ALIGN_EN=0"
puts "  rx_dly_align_disable   - DLY_ALIGN_EN=0"
puts "  rx_ph_align_enable     - PH_ALIGN_EN=1"
puts "  rx_dly_align_enable    - DLY_ALIGN_EN=1"
puts "  rx_dly_align_bypass    - RX_DA_BYP=1 (DAPI out of RXOUTCLK path)"
puts "  rx_dly_align_unbypass  - RX_DA_BYP=0 (DAPI in path)"
puts "  rx_phdly_reset         - pulse RXPHDLYRESET, return RXSYNCDONE"
puts "  rx_phdly_status        - print PD/RESET/RESETDONE/SYNCDONE"
puts "  rx_progdiv_set <div>   - RMW RXPROGDIVSEL (4 5 5.5 8 10 16 16.5 20 32 33 40)"
