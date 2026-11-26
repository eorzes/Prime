########################################################################
# Vivado Tcl script – export all .xci files under src/ip
#   → generates vivado_create_ip_<name>.tcl
########################################################################

variable self_script_dir [file dirname [file normalize [info script]]]
set root_dir [file dirname $self_script_dir]
set env(TCLLIBPATH) [list $self_script_dir]
lappend ::auto_path $self_script_dir

set sep_line [string repeat "-" 60]

# recursive glob that stops once a .xci is found in a folder
proc glob_recursive {{dir .} {filespec *} {types {b c f l p s}}} {
    set files [glob -nocomplain -types $types -dir $dir -- $filespec]
    set filelist {}
    set found_ip 0

    foreach f $files {
        set norm_f [file normalize $f]
        lappend filelist $norm_f
        if {[string match "*.xci" [file tail $norm_f]]} { set found_ip 1 }
    }

    if {$found_ip} { return $filelist }

    foreach sub [glob -nocomplain -types d -dir $dir -- *] {
		if {[string equal -nocase [file tail $sub] "ip_repo"]} {continue}
        lappend filelist {*}[glob_recursive [file join $dir $sub] $filespec $types]
    }
    return $filelist
}

# extract a parameter from JSON .xci file
proc extract_xci_parameter {content param_name} {
	set pattern [format {\"%s\"\s*:\s*\[\s*\{\s*\"value\"\s*:\s*\"([^\"]+)\"} $param_name]

    if {[regexp $pattern $content -> parameter]} {
        return $parameter
    } else {
		puts "Warning: ${param_name} not found"
        return ""
    }
}

# if the IP definition lives inside ip_repo (assume yes if the lookup fails)
proc ip_uses_repo {ip_name repo_dir} {
    if {[catch {get_property REPOSITORY [get_ipdefs -all -vlnv [get_property IPDEF [get_ips $ip_name]]]} repo]} { return 1 }
    return [string match -nocase "[file normalize $repo_dir]*" [file normalize $repo]]
}
set ip_repo_header {
set ip_repo_d [file dirname [file normalize [info script]]]
while {![file isdirectory [file join $ip_repo_d ip_repo]] && $ip_repo_d ne [file dirname $ip_repo_d]} {
    set ip_repo_d [file dirname $ip_repo_d]
}
set_property IP_REPO_PATHS [lsort -unique [concat [get_property IP_REPO_PATHS [current_fileset]] [list [file join $ip_repo_d ip_repo]]]] [current_fileset]
update_ip_catalog
}

# find every .xci file in src/ip
set ip_dir   [file join $root_dir src ip]
set ip_files [glob_recursive $ip_dir *.xci]
set plural_text [expr {[llength $ip_files] == 1 ? "" : "s"}]
set ip_files [lsort $ip_files]

puts "$sep_line"
puts "Found [llength $ip_files] .xci file${plural_text} to export"
puts "$sep_line"

if {[llength $ip_files] == 0} {
    puts "No .xci files found. Done."
    exit 0
}

# temporarily suppress all vivado messages
set_msg_config -severity {INFO} -suppress
set_msg_config -id {Vivado 12-13650} -suppress
#set_msg_config -severity {WARNING} -suppress

# temporary vivado project folder definition
set temp_proj_dir [file join $self_script_dir "temp_ip_export"]
file delete -force $temp_proj_dir

# process each ip
foreach ip_path $ip_files {
    set ip_name       [file rootname [file tail $ip_path]]
    set ip_parent_dir [file dirname $ip_path]

    puts "Exporting ${ip_name} from [file tail $ip_path]"

    if {![file exists $ip_path]} {
        puts "Skipping – file not found: $ip_path"
        continue
    }

    # read .xci content
    set ip_channel [open $ip_path r]
    set ip_content [read $ip_channel]
    close $ip_channel
    set part ""
    set board ""
	
	if {[string index [string trimleft $ip_content] 0] eq "<"} {
		puts "Skipping XML-format XCI: [file tail $ip_path]"
		continue
	}

    # dynamically detect part and board from the .xci file
	set device         [extract_xci_parameter $ip_content "DEVICE"]
	set package        [extract_xci_parameter $ip_content "PACKAGE"]
	set speedgrade     [extract_xci_parameter $ip_content "SPEEDGRADE"]
	set silicon_rev    [extract_xci_parameter $ip_content "SILICON_REVISION"]   ;# e.g. "es1", "production"
	set temp_grade     [string tolower [extract_xci_parameter $ip_content "TEMPERATURE_GRADE"]]  ;# e.g. E
	set static_power   [extract_xci_parameter $ip_content "STATIC_POWER"]      ;# e.g. S, L

	set part "${device}-${package}${speedgrade}"
	if {$silicon_rev  != ""} { append part "-$silicon_rev" }
	if {$temp_grade   != ""} { append part "-$temp_grade"  }
	if {$static_power != ""} { append part "-$static_power"}

    set board [extract_xci_parameter $ip_content "BASE_BOARD_PART"]
    if {$board == ""} { set board "none" }

    # create temporary project in temp_proj_dir
    set proj_dir [file join $temp_proj_dir $ip_name]
    file delete -force $proj_dir
    create_project $ip_name $proj_dir -force -part $part
    if {$board ne ""} { set_property BOARD_PART $board [current_project] }
	
	puts "set board: ${board}"
	puts "set part : ${part}"
	
	# add ip_repo to project
	set ip_repo_dir [file normalize [file join $root_dir src ip_repo]]
	set_property IP_REPO_PATHS [list $ip_repo_dir] [current_fileset]
	update_ip_catalog -rebuild
	puts "Custom IP repository registered: $ip_repo_dir"

    # add ip to project
    add_files -force $ip_path
    set ip_obj [get_ips -quiet $ip_name]
    if {$ip_obj eq "" || [get_property IS_LOCKED $ip_obj] || [get_property UPGRADE_VERSIONS $ip_obj] ne ""} {
        puts "Skipping ${ip_name}: not up-to-date"
		puts "$sep_line"
        close_project
        file delete -force $proj_dir
        continue
    }
    puts "Added ${ip_name}.xci to project"

    # write recreation script
    set out_file [file join $ip_parent_dir "vivado_create_ip_${ip_name}.tcl"]
    if {[catch {write_ip_tcl -force [get_ips $ip_name] $out_file} err]} {
        puts "ERROR write_ip_tcl: $err"
        close_project
        file delete -force $proj_dir
        continue
    }
	
	# add ip_repo to exported tcl if necessary
	if {[ip_uses_repo $ip_name $ip_repo_dir]} {
        set fh [open $out_file r]; set body [read $fh]; close $fh
        set lines [split $body "\n"]
        set idx [lsearch -regexp $lines {^\s*set bCheckIPs\s}]
        if {$idx < 0} { set idx [lsearch -regexp $lines {^\s*create_ip\s}] }
        set fh [open $out_file w]
        puts -nonewline $fh [join [linsert $lines $idx $ip_repo_header] "\n"]
        close $fh
        puts "ip_repo reference added to [file tail $out_file]"
    }

    puts "Generated: $out_file"
    close_project
    file delete -force $proj_dir
	puts "$sep_line"
}

# restore console message config
reset_msg_config -severity {INFO} -suppress
reset_msg_config -id {Vivado 12-13650} -suppress
#reset_msg_config -severity {WARNING} -suppress

# cleanup
file delete -force $temp_proj_dir
set xil_dir [file join $self_script_dir ".xil"]
if {[file isdirectory $xil_dir]} { file delete -force $xil_dir }
file delete -force [file join $self_script_dir "dfx_runtime.txt"]

puts "Done"
puts "$sep_line"