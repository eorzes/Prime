
#### Getting started

In order to set up the Vivado environment you can:

- [ ] IP Cores (.xci) and Block Designs (.bd) have to be generated from the corresponding .tcl scripts: 
	  click on run_vivado_create_ips_and_bds.bat (on Windows) or equivalent on Linux (.sh)
- [ ] Generate the Vivado project by running generate_project.bat (on Windows) or equivalent on Linux (.sh)
- [ ] Open the project and enjoy

- [ ] If new ips/bds are added or modified, run run_vivado_export_ips_and_bds.bat (on Windows) or equivalent on Linux (.sh)
      to generate the vivado_create_ip_<ip_name>.tcl / vivado_create_bd_<bd_name>.tcl scripts to publish on git.
	  
- [ ] When regenerating the project.tcl, runt his before, to avoid AppData\Roaming dependencies:  
		```
		set root_dir [file normalize [file join [get_property DIRECTORY [current_project]] ../..]]  
		write_project_tcl -force -paths_relative_to $root_dir -use_bd_files $root_dir/prj/m_top.tcl
		```

Or, manually:

- Create a Vivado project called m_top, located in a folder prj next to src
- Set board and part
- Import all VHDL and Verilog files (.vhd .v)
- Import all ip core   (.xci) which have to be generated running (in Vivado) the corresponding vivado_create_ip_<ip_name>.tcl
- Import block diagrams (.bd) which have to be generated running (in Vivado) the corresponding vivado_create_bd_<bd_name>.tcl
- Import constrain file (.xdc)
- Set VHDL 2019 where required
- Right click on block diagrams > generate HDL wrapper (if not already present in src/bd/<bd_name>/hdl/)
- Only for non Versal transceivers:
	- Find GT in sources > gt_inst > m_gth : right click > open ip example design
	- example design should get saved in prj next to m_top
	- From that example design import the QPLL required files
- Disable unused sources (those not appearing under top level)
- Disable core containers for IP Cores if enabled: settings > IP Cores
