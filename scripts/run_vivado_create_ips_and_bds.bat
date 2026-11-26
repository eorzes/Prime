REM ################################################################################
REM # Vivado 2025.2 batch file to create the ip and bd files from tcl files
REM # This batch file uses the default Xilinx installation path.
REM ################################################################################

call C:\AMDDesignTools\2025.2\Vivado\\.\\bin\\vivado.bat -mode batch -notrace -nolog -nojournal -quiet -source vivado_create_ips.tcl

call C:\AMDDesignTools\2025.2\Vivado\\.\\bin\\vivado.bat -mode batch -notrace -nolog -nojournal -quiet -source vivado_create_bds.tcl

REM #del *.jou
REM #del *.log

pause