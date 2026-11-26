# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "NUM_UNITS" -parent ${Page_0}


}

proc update_PARAM_VALUE.NUM_UNITS { PARAM_VALUE.NUM_UNITS } {
	# Procedure called to update NUM_UNITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_UNITS { PARAM_VALUE.NUM_UNITS } {
	# Procedure called to validate NUM_UNITS
	return true
}


proc update_MODELPARAM_VALUE.NUM_UNITS { MODELPARAM_VALUE.NUM_UNITS PARAM_VALUE.NUM_UNITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_UNITS}] ${MODELPARAM_VALUE.NUM_UNITS}
}

