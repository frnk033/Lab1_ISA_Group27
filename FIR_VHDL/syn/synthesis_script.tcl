#### SYNTHESIS #####

source .synopsys_dc.setup

#  READING VHDL SOURCE FILES 
analyze -f vhdl -lib WORK ../src/constants.vhd
analyze -f vhdl -lib WORK ../src/FF.vhd
analyze -f vhdl -lib WORK ../src/mux2to1.vhd
analyze -f vhdl -lib WORK ../src/reg.vhd
analyze -f vhdl -lib WORK ../src/FIR.vhd 
set power_preserve_rtl_hier_names true
elaborate myfir -arch beh -lib WORK > ./elaborate.txt

# APPLYING CONSTRAINTS
create_clock -name MY_CLK -period 10.68 CLK
set_dont_touch_network MY_CLK
set_clock_uncertainty 0.07 [get_clocks MY_CLK]
set_input_delay 0.5 -max -clock MY_CLK [remove_from_collection [all_inputs] CLK]
set_output_delay 0.5 -max -clock MY_CLK [all_outputs]
set OLOAD [load_of NangateOpenCellLibrary/BUF_X4/A]
set_load $OLOAD [all_outputs]

# START THE SYNTHESIS
compile

# SAVE THE RESULTS
report_timing > report_timing.txt
report_area > report_area.txt

ungroup -all -flatten
change_names -hierarchy -rules verilog
write_sdf ../netlist/myfir.sdf
write -f verilog -hierarchy -output ../netlist/myfir.v
write_sdc ../netlist/myfir.sdc
