REM ################################################################################
REM # Vivado 2023.2 batch file to create the m_top vivado project
REM # This batch file uses the default Xilinx installation path.
REM ################################################################################
REM #call C:\Xilinx\Vivado\2025.2\\.\\bin\\vivado.bat -mode batch -source m_top.tcl
call C:\AMDDesignTools\2025.2\Vivado\\.\\bin\\vivado.bat -mode batch -source m_top.tcl

del *.jou
del *.log

pause