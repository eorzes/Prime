REM ################################################################################
REM # Vivado 2023.2 batch file to create the m_top vivado project
REM # This batch file uses the default Xilinx installation path.
REM ################################################################################
call C:\Xilinx\Vivado\2023.2\\.\\bin\\vivado.bat -mode batch -source m_top.tcl

del *.jou
del *.log

pause