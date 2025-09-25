
THIS_FOLDER  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PART         ?= xc7a200tfbg676-2
REQ_FREQ_MHZ ?= 230

syn: clean
	mkdir output
	cd output && /tools/Xilinx/2025.1/Vivado/bin/vivado -mode batch -notrace -script $(THIS_FOLDER)/run_ooc_synthesis.tcl -tclargs  $(PART) $(REQ_FREQ_MHZ)

clean:
	rm -rf output
