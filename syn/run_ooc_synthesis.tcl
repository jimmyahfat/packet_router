# script to run out of context synthesis and get max frequency achievable

set PART            [lindex $argv 0]
set REQ_FREQ_MHZ    [lindex $argv 1]

set REPO_FOLDER   [file dirname [file normalize [info script]/..]]
set REQ_PERIOD_NS [expr {1000.0/ $REQ_FREQ_MHZ}]

# Write a constraints.xdc file with the requested clk frequency
set fid [open constraints.xdc w+]
puts $fid "create_clock -period $REQ_PERIOD_NS -name clock_clk  \[get_ports clk\]"
close $fid

# load files
read_verilog -library work -sv $REPO_FOLDER/rtl/axis_packet_fifo.sv
read_verilog -library work -sv $REPO_FOLDER/rtl/axis_register_stage.sv
read_verilog -library work -sv $REPO_FOLDER/rtl/bram.sv
read_verilog -library work -sv $REPO_FOLDER/rtl/packet_router_regbank.sv
read_verilog -library work -sv $REPO_FOLDER/rtl/packet_router.sv
read_xdc                       constraints.xdc

# Run synthesis
synth_design -top packet_router -generic "DATA_WIDTH=32" -generic "DEPTH=1024" -flatten_hierarchy rebuilt -part $PART -mode out_of_context  
write_checkpoint -force post_synth.dcp

# Run place and route
opt_design
place_design
route_design   
write_checkpoint -force post_route.dcp

# Write utilisation and timing reports
report_utilization       -hierarchical -file util.rpt
report_timing_summary    -max_paths 10 -file timing_summary_routed.rpt

# We can get WNs and calculate maximum frequency
set WNS             [get_property  SLACK  [get_timing_paths]]
set MAX_FREQ_MHZ    [expr {1000.0 / ($REQ_PERIOD_NS - $WNS)}]

puts "Requested frequency: ${REQ_FREQ_MHZ}MHz"
puts "Maximum frequency achieved: ${MAX_FREQ_MHZ}MHz" 