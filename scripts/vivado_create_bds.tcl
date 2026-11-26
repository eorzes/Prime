########################################################################
# The Xilinx Vivado EULA does not allow the distribution of block designs
# or parts thereof. Therefore the block design information is distributed
# in the form of Tcl scripts.
#
# This Vivado Tcl script finds block design creation scripts matching a
# fixed file name pattern, and runs all found scripts to generate the
# corresponding block designs.
#
# Run from the linux shell command line of your cms-tcds2-firmware area:
#   vivado -mode batch -notrace -nolog -nojou -quiet -source scripts/vivado_create_bds.tcl
# or in the Vivado Tcl console:
#   source vivado_create_bds.tcl
########################################################################

package require cmdline

variable self_script_dir [file dirname [file normalize [info script]]]
set root_dir [file dirname $self_script_dir]
set env(TCLLIBPATH) [list $self_script_dir]
lappend ::auto_path $self_script_dir

set script_name_pattern_base "vivado_create_bd_"
set sep_line [string repeat "-" 60]

# recursive search of "script_name_pattern_base" tcl files in specified directory 
proc glob_recursive {{dir .} {filespec *} {types {b c f l p s}}} {
    set files [glob -nocomplain -types $types -dir $dir -- $filespec]
    foreach x [glob -nocomplain -types {d} -dir $dir -- *] {
        set files [concat $files \
                   [glob_recursive [file join [pwd] $x] $filespec $types]]
    }
    set filelist {}
    foreach x $files { lappend filelist [file normalize $x] }
    return $filelist
}

set parameters {
    {bd-name-pattern.arg "*" "Pattern describing which block design(s) to generate"}
}
set usage "- A script to (re)generate Xilinx block designs from stored Tcl scripts"
if { [catch {array set options [cmdline::getoptions ::argv $parameters $usage]}] } {
    puts [cmdline::usage $parameters $usage]
    exit 1
}

# find all the vivado block design creation scripts in src/bd.
set bd_name_pattern $options(bd-name-pattern)
set script_name_pattern "${script_name_pattern_base}${bd_name_pattern}.tcl"
set bd_dir [file join $root_dir src bd]
set bd_scripts [glob_recursive $bd_dir $script_name_pattern]

set plural_text [expr {[llength $bd_scripts] == 1 ? "" : "s"}]
set bd_scripts [lsort $bd_scripts]

puts "$sep_line"
puts "Found [llength $bd_scripts] matching block design creation script${plural_text}"
puts "$sep_line"

# temporarily suppress all vivado messages
set_msg_config -severity {INFO} -suppress
set_msg_config -id {BD 41-1306} -suppress
set_msg_config -id {BD 41-702} -suppress
set_msg_config -id {BD::TCL 103-2053} -suppress
#set_msg_config -severity {WARNING} -suppress

foreach script_path $bd_scripts {
	# script_path is full path to the found bd gen script
	# [file dirname $script_path] returns the directory path where the found script is
	# [file tail $script_path] returns the script name with extension 
	# [file rootname x] removes the extension 
	set script_dir [file dirname $script_path]
    set gen_script [file rootname [file tail $script_path]] 
    set bd_name [regsub "^${script_name_pattern_base}" $gen_script ""]

	puts "Processing $bd_name"

	# generate .bd from .tcl (mute puts from the BD script)
	set status [catch {source $script_path} err]
	# set full_cmd [concat $vivado_cmd $script_path]
    # set status [catch {exec {*}$full_cmd} err] 
	# exec runs the script on another thread, preventing from closing the vivado project (not accessable here)
    if { $status != 0 } {
        set err_lines [split [string map {"\r\n" "\n" "\r" "\n"} $err] "\n"]
        set real_error [expr {[lsearch -glob $err_lines "*ERROR:*"] != -1}]
        if { $real_error } {
            puts "A problem occurred while processing $bd_name:"
            foreach line $err_lines { if {[string trim $line] ne ""} { puts "  !!! $line" } }
            exit 1
        }
    }

	# clean target – keep only hdl/ and the create script (hdl/ contains the bd wrapper.vhd)
	foreach item [glob -nocomplain -dir $script_dir *] {
		set tail [file tail $item]
		if {$tail eq "hdl" || $tail eq "${gen_script}.tcl"} { continue }
		file delete -force $item
	}

	# move everything from scripts/bd/<name>/ to script_dir
	set bd_gen_dir [file join $self_script_dir bd $bd_name ]
	foreach item [glob -nocomplain -dir $bd_gen_dir *] {
		set dest [file join $script_dir [file tail $item]]
		if {[file exists $dest]} { file delete -force $dest }
		file rename $item $dest
	}

    # close and delete vivado project created by the generate script
	close_project
	set myproj_dir [file join $self_script_dir myproj]
    if {[file isdirectory $myproj_dir]} { 
		file delete -force $myproj_dir 
	}

    puts "$sep_line"
}

# restore console message config
reset_msg_config -severity {INFO} -suppress
reset_msg_config -id {BD 41-1306} -suppress
reset_msg_config -id {BD 41-702} -suppress
reset_msg_config -id {BD::TCL 103-2053} -suppress
#reset_msg_config -severity {WARNING} -suppress

# remove bd folder 
set generated_bd_dir [file join $self_script_dir bd]
file delete -force $generated_bd_dir

# remove .xil folder
set xil_dir [file join $self_script_dir ".xil"]
if {[file isdirectory $xil_dir]} { file delete -force $xil_dir }

puts "Done"
puts "$sep_line"