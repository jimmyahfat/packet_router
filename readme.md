
# Packet router

Softwares used:

- GNU Make 4.3
- iverilog Version 11.0 (stable)
- GTKWave Analyzer v3.3.104 (w)1999-2020 BSI
- Vivado 2025.1 (can be downloaded and evaluated for 30days for free)

## Summary

### What has been implemented

- Architecture of a packet router
- RTL implementation
- Basic simulation to check that it is alive
- Synthesis using Vivado 2025.1.

A design of DATA WIDTH=32bits and FIFO DEPTH=1024 synthesises on an Artix 7 AC701 evaluation board (part number: xc7a200tfbg676-2).
It times at 234MHz and uses 4 BRAMS see reports and provided design checkpoint.


### What has not been implemented

- Proper and extensive verification that reports whether a test passed or failed. Right now, it is still a manual check waves.
- Absolutely no coverage
- Absolutely no formal verification

I spent quite a lot of time trying to get a simulation working on verilator and I eventually gave up.
Instead I am using iverilog.

Even iverilog did not allow me to use features of the systemverilog language (such as packages, or a verification fifo) so I gave up making a proper testbench.

For example, I wanted the testbench to be able to queue packets to the scoreboard so the scoreboard could then compare whenever it receives an output from the slave BFM - getting strange errors.
```sv
typedef logic [TDATA_WIDTH-1:0] packet_t [];
packet_t fifo [$];
// /home/jimmy/packet_router/tb/src/scoreboard.sv:37: error: Array ``expected_fifo'' has already been declared.
// 1 error(s) during elaboration.
```

## Instructions

RTL Simulation:

```bash
cd $REPO_ROOT/tb/sim
make sim WAVES=YES # This will output a waves.vcd file in the folder that can be opened using gtkwavs
```

Synthesis:

```bash
cd $REPO_ROOT/syn
make syn TARGET=xc7a200tfbg676-2 REQ_FREQ_MHZ=200    # This will generate an output/ folder with timing reports and design checkpoints
```

