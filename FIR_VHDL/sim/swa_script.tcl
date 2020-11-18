### SWITCHING ACTIVITY FOR POWER REPORT #########

# launch modelsim with proper option and record switching activity ----> ON MODELSIM 
vcom -93 -work ./work ../tb/clk_gen.vhd
vcom -93 -work ./work ../tb/data_maker_new.vhd
vcom -93 -work ./work ../tb/data_sink.vhd

vlog -work ./work ../netlist/FIR_filter.v
vlog -work ./work ../tb/tb_fir.v

vsim -L /software/dk/nangate45/verilog/msim6.2g -sdftyp /tb_fir/UUT=../netlist/FIR_filter.sdf work.tb_fir

vcd file ../vcd/FIR_filter_syn.vcd
vcd add /tb_fir/UUT/*

run 2 us

# convert the file with the switching activity from vcd to saif ----> ON THE SHELL WHERE YOU RUN DESIGN COMPILER
#vcd2saif -input ../vcd/FIR_filter_syn.vcd -output ../saif/FIR_filter_syn.saif

# power consumption estimation with Synopsys Design Compiler  ----> ON SYNOPSYS DESIGN COMPILER
#read_verilog -netlist ../netlist/FIR_filter.v
#read_saif -input ../saif/FIR_filter_syn.saif -instance tb_fir/UUT -unit ns -scale 1
#create_clock -name MY_CLK CLK
#report_power
