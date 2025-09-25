
# Makefile for packetrouter testbench
THIS_FOLDER := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
RTL_FOLDER  := $(realpath $(THIS_FOLDER)/../../rtl)
TB_FOLDER   := $(realpath $(THIS_FOLDER)/../src)

EXECUTABLE := packet_router_simv

WAVES ?= NO

ifeq ("$(WAVES)", "YES")
	VVP_OPTS += +vcd+waves.vcd
endif

help:
	@printf "\n"
	@printf '\033[32m%-30s\033[0m' "Packet router Makefile"
	@printf "\n"
	@printf "================================\n"
	@printf 'compile: Compile and elaborate the simulation environment\n'
	@printf 'sim:     Run a test. Use WAVES=YES to output waves\n'
	@printf 'clean:   Remove generated files\n'

compile:
	iverilog  -g2012 $(RTL_FOLDER)/*.sv $(TB_FOLDER)/*.sv -o $(THIS_FOLDER)/$(EXECUTABLE)

sim: compile sim_no_build

sim_no_build:
	vvp $(THIS_FOLDER)/$(EXECUTABLE) $(VVP_OPTS)

clean:
	rm -rf *.vcd $(EXECUTABLE)