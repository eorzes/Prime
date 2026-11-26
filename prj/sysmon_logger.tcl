set sysmon_logging 0
set sysmon_interval 1000

set project_dir [get_property DIRECTORY [current_project]]
set prj_dir [file dirname $project_dir]
set sysmon_log_file [file join $prj_dir "sysmon_log.csv"]

set sysmon [lindex [get_hw_sysmons] 0]

proc sysmon_log_once {} {
    global sysmon_logging sysmon_log_file sysmon_interval sysmon

    if {!$sysmon_logging} { return }

    refresh_hw_sysmon $sysmon

    set temp      [get_property DEVICE_TEMP  $sysmon]
    set vccaux    [get_property VCCAUX       $sysmon]
    set vccauxpmc [get_property VCCAUX_PMC   $sysmon]
    set vccpmc    [get_property VCC_PMC      $sysmon]
    set vccpsfp   [get_property VCC_PSFP     $sysmon]
    set vccpslp   [get_property VCC_PSLP     $sysmon]
    set vccsoc    [get_property VCC_SOC      $sysmon]
    set vpvn      [get_property VP_VN        $sysmon]

    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

    set fp [open $sysmon_log_file a]
    puts $fp "$timestamp,$temp,$vccaux,$vccauxpmc,$vccpmc,$vccpsfp,$vccpslp,$vccsoc,$vpvn"
    close $fp

    puts "$timestamp | TEMP=$temp | VCCAUX=$vccaux | VCCAUX_PMC=$vccauxpmc | VCC_PMC=$vccpmc | VCC_PSFP=$vccpsfp | VCC_PSLP=$vccpslp | VCC_SOC=$vccsoc | VP_VN=$vpvn"

    after $sysmon_interval sysmon_log_once
}

proc start_sysmon_logging {} {
    global sysmon_logging sysmon_log_file sysmon_interval sysmon

    if {$sysmon_logging} {
        puts "SYSMON logging is already running."
        return
    }

    set fp [open $sysmon_log_file w]
    puts $fp "timestamp,DEVICE_TEMP_C,VCCAUX_V,VCCAUX_PMC_V,VCC_PMC_V,VCC_PSFP_V,VCC_PSLP_V,VCC_SOC_V,VP_VN_V"
    close $fp

    set sysmon_logging 1

    puts "============================================================"
    puts "SYSMON logging STARTED"
    puts "File     : $sysmon_log_file"
    puts "Interval : $sysmon_interval ms"
    puts "============================================================"

    sysmon_log_once
}

proc stop_sysmon_logging {} {
    global sysmon_logging

    set sysmon_logging 0
    puts "SYSMON logging STOPPED"
}

proc sysmon_logging_status {} {
    global sysmon_logging sysmon_log_file sysmon_interval

    puts "SYSMON logging: [expr {$sysmon_logging ? "RUNNING" : "STOPPED"}]"
    puts "File     : $sysmon_log_file"
    puts "Interval : $sysmon_interval ms"
}

puts "SYSMON logger loaded."