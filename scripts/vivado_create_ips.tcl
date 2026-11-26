########################################################################
# The Xilinx Vivado EULA does not allow the distribution of block designs
# or parts thereof. Therefore the block design information is distributed
# in the form of Tcl scripts.
#
# This Vivado Tcl script finds ip cores creation scripts matching a
# fixed file name pattern, and runs all found scripts to generate the
# corresponding ip cores.
#
# Run from the linux shell command line of your cms-tcds2-firmware area:
#   vivado -mode batch -notrace -nolog -nojou -quiet -source scripts/vivado_create_ips.tcl
# or in the Vivado Tcl console:
#   source vivado_create_ips.tcl
########################################################################

package require cmdline

variable self_script_dir [file dirname [file normalize [info script]]]
set root_dir [file dirname $self_script_dir]
set env(TCLLIBPATH) [list $self_script_dir]
lappend ::auto_path $self_script_dir

set script_name_pattern_base "vivado_create_ip_"
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
    {ip-name-pattern.arg "*" "Pattern describing which ip(s) to generate"}
}
set usage "- A script to (re)generate Xilinx ip cores from stored Tcl scripts"
if { [catch {array set options [cmdline::getoptions ::argv $parameters $usage]}] } {
    puts [cmdline::usage $parameters $usage]
    exit 1
}

# find all the vivado ip cores creation scripts in src/ip.
set ip_name_pattern $options(ip-name-pattern)
set script_name_pattern "${script_name_pattern_base}${ip_name_pattern}.tcl"
set ip_dir [file join $root_dir src ip]
set ip_scripts [glob_recursive $ip_dir $script_name_pattern]

set plural_text [expr {[llength $ip_scripts] == 1 ? "" : "s"}]
set ip_scripts [lsort $ip_scripts]

puts "$sep_line"
puts "Found [llength $ip_scripts] matching block design creation script${plural_text}"
puts "$sep_line"

# temporarily suppress all vivado messages
set_msg_config -severity {INFO} -suppress
#set_msg_config -severity {WARNING} -suppress

foreach script_path $ip_scripts {
	# script_path is full path to the found ip gen script
	# [file dirname $script_path] returns the directory path where the found script is
	# [file tail $script_path] returns the script name with extension 
	# [file rootname x] removes the extension 
	set script_dir [file dirname $script_path]
    set gen_script [file rootname [file tail $script_path]] 
    set ip_name [regsub "^${script_name_pattern_base}" $gen_script ""]
	
    puts "Processing $ip_name"

	# generate .xci from .tcl
	set status [catch {source $script_path} err] 
	# set full_cmd [concat $vivado_cmd $script_path]
    # set status [catch {exec {*}$full_cmd} err] 
	# exec runs the script on another thread, preventing from closing the vivado project (not accessable here)
    if { $status != 0 } {
        set err_lines [split [string map {"\r\n" "\n" "\r" "\n"} $err] "\n"]
        set real_error [expr {[lsearch -glob $err_lines "*ERROR:*"] != -1}]
        if { $real_error } {
            puts "A problem occurred while processing $ip_name:"
            foreach line $err_lines { if {[string trim $line] ne ""} { puts "  !!! $line" } }
            exit 1
        }
    }

	# clean target directory – keep only the create script
	foreach item [glob -nocomplain -dir $script_dir *] {
		set tail [file tail $item]
		if {$tail eq "${gen_script}.tcl"} { continue }
		file delete -force $item
	}

	# move <name>.xci from scripts/<name>/<name>.srcs/sources_1/ip/<name>/ to script_dir/
	set myproj_dir [file join $self_script_dir $ip_name]
	set ip_gen_dir [file join $myproj_dir "${ip_name}.srcs" sources_1 ip $ip_name ]
	set xci_source [file join $ip_gen_dir "${ip_name}.xci"]
	set xci_dest   [file join $script_dir "${ip_name}.xci"]
	if {[file exists $xci_dest]} { file delete -force $xci_dest }
	file rename $xci_source $xci_dest
	
	# close and delete vivado project created by the generate script
	close_project
    if {[file isdirectory $myproj_dir]} { file delete -force $myproj_dir }
	
	# modify the .xci to set gen_directory and OUTPUTDIR to "."
	if {[file exists $xci_dest]} {
		set fp [open $xci_dest r]
		set content [read $fp]
		close $fp

		# replace gen_directory value
		regsub -all {("gen_directory"\s*:\s*)"[^"]*"} $content {\1"."} content

		# Replace OUTPUTDIR value
		regsub -all {("OUTPUTDIR"\s*:\s*\[\s*\{\s*"value"\s*:\s*)"[^"]*"} $content {\1"."} content

		# write back the modified content
		set fp [open $xci_dest w]
		puts -nonewline $fp $content
		close $fp
		#puts "Updated ${ip_name}.xci: set gen_directory and OUTPUTDIR to '.'"
	}

    puts "$sep_line"
}

# restore console message config
reset_msg_config -severity {INFO} -suppress
#reset_msg_config -severity {WARNING} -suppress

puts "Done"
puts "$sep_line"

# remove .xil folder
set xil_dir [file join $self_script_dir ".xil"]
if {[file isdirectory $xil_dir]} { file delete -force $xil_dir }