########################################################################
# Vivado Tcl script – export all .bd files under src/bd
#   → generates vivado_create_bd_<name>.tcl
########################################################################

variable self_script_dir [file dirname [file normalize [info script]]]
set root_dir [file dirname $self_script_dir]
set env(TCLLIBPATH) [list $self_script_dir]
lappend ::auto_path $self_script_dir

set sep_line [string repeat "-" 60]

# recursive glob that stops once a .bd is found in a folder
proc glob_recursive {{dir .} {filespec *} {types {b c f l p s}}} {
    set files [glob -nocomplain -types $types -dir $dir -- $filespec]
    set filelist {}
    set found_bd 0

    foreach f $files {
        set norm_f [file normalize $f]
        lappend filelist $norm_f
        if {[string match "*.bd" [file tail $norm_f]]} { set found_bd 1 }
    }

    if {$found_bd} { return $filelist }

    foreach sub [glob -nocomplain -types d -dir $dir -- *] {
        lappend filelist {*}[glob_recursive [file join $dir $sub] $filespec $types]
    }
    return $filelist
}

# find every .bd file in src/bd
set bd_dir   [file join $root_dir src bd]
set bd_files [glob_recursive $bd_dir *.bd]
set plural_text [expr {[llength $bd_files] == 1 ? "" : "s"}]
set bd_files [lsort $bd_files]

puts "$sep_line"
puts "Found [llength $bd_files] .bd file${plural_text} to export"
puts "$sep_line"

if {[llength $bd_files] == 0} {
    puts "No .bd files found. Done."
    exit 0
}

# temporarily suppress all vivado messages
set_msg_config -severity {INFO} -suppress
set_msg_config -id {BD 5-339} -suppress
#set_msg_config -severity {WARNING} -suppress

# temporary vivado project folder definition
set temp_proj_dir "./temp_bd_export"
file delete -force $temp_proj_dir

proc discard_out {cmd handle args} {
    switch -- $cmd {
        initialize { return {initialize finalize write} }
        write      { return "" }
        finalize   { return }
    }
}

# process each block design
foreach bd_path $bd_files {
    set bd_name       [file rootname [file tail $bd_path]]
    set bd_parent_dir [file dirname $bd_path]

    puts "Exporting ${bd_name} from [file tail $bd_path]"

    if {![file exists $bd_path]} {
        puts "  Skipping – file not found: $bd_path"
        continue
    }

    # read .bd content
	set bd_channel [open $bd_path r]
    set bd_content [read $bd_channel]
    close $bd_channel
    set part ""
    set board ""

	# dynamically detect part and board from the .bd file
    if {[regexp {\"device\"\s*:\s*\"([^\"]+)\"} $bd_content -> part]} {
        puts "Detected part: $part"
    } else {
        puts "WARNING: No device in .bd"
    }

    if {[regexp {\"BASE_BOARD_PART\"\s*:\s*\"([^\"]+)\"} $bd_content -> board]} {
        puts "Detected board: $board"
    } else {
        puts "No BASE_BOARD_PART in .bd, searching for .xci files in the block design subfolders"
        # look for any .xci under <bd_folder>/ip/
        set ip_root [file join $bd_parent_dir ip]
        if {[file isdirectory $ip_root]} {
            set xci_list [glob -nocomplain -tails -directory $ip_root -types f **/*.xci]
            if {[llength $xci_list] > 0} {
                set first_xci_rel [lindex $xci_list 0]
                set first_xci_abs [file join $ip_root $first_xci_rel]
                puts "First .xci found: ${first_xci_rel}"

                set xci_content [read [open $first_xci_abs r]]
                if {[regexp {\"BASE_BOARD_PART\"\s*:\s*\[\s*\{\s*\"value\"\s*:\s*\"([^\"]+)\"} $xci_content -> board]} {
                    puts "BASE_BOARD_PART from .xci: $board"
                } else {
                    puts "No BASE_BOARD_PART in $first_xci_rel"
                }
            } else {
                puts "No .xci files under $ip_root"
            }
        } else {
            puts "No 'ip' folder under $bd_parent_dir"
        }
		if {$board eq ""} {
			#set board "xilinx.com:vpk180:part0:1.1" # set here fallback for board part if no ip is found
			set board ""
		}
    }

    # create temporary project in temp_proj_dir
    set proj_dir [file join $temp_proj_dir $bd_name]
    file delete -force $proj_dir
    create_project $bd_name $proj_dir -force -part $part
    if {$board ne ""} { set_property BOARD_PART $board [current_project] }

    # add block design to project and open it (in a quiet way)
    add_files -quiet -force $bd_path
    if {[catch {open_bd_design -quiet $bd_path} err]} {
        puts "ERROR opening BD: $err"
        close_project
        file delete -force $proj_dir
        continue
    }

    # write recreation script
    set out_file [file join $bd_parent_dir "vivado_create_bd_${bd_name}.tcl"]
    if {[catch {write_bd_tcl -force $out_file} err]} {
        puts "ERROR write_bd_tcl: $err"
        close_bd_design [current_bd_design]
        close_project
        file delete -force $proj_dir
        continue
    }
	
	# inject -quiet into verbose functions
    set fh [open $out_file r]
    set content [read $fh]
    close $fh
    regsub -all {assign_bd_address } $content {assign_bd_address -quiet } content
    regsub -all -line {^(\s*)save_bd_design\s*$} $content {\1save_bd_design -quiet} content
    regsub -all {create_bd_design } $content {create_bd_design -quiet } content
    regsub -all {create_bd_cell } $content {create_bd_cell -quiet } content
    set fh [open $out_file w]
    puts -nonewline $fh $content
    close $fh

    puts "Generated: $out_file"
    close_bd_design [current_bd_design]
    close_project
    file delete -force $proj_dir
	puts "$sep_line"
}

# restore console message config
reset_msg_config -severity {INFO} -suppress
reset_msg_config -id {BD 5-339} -suppress
#reset_msg_config -severity {WARNING} -suppress

# cleanup
file delete -force $temp_proj_dir
set xil_dir [file join $self_script_dir ".xil"]
if {[file isdirectory $xil_dir]} { file delete -force $xil_dir }
file delete -force [file join $self_script_dir "dfx_runtime.txt"]

puts "Done"
puts "$sep_line"