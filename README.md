# Synthesizable Parameterized UART Communication Core

A fully synthesizable, hardware-validated UART (Universal Asynchronous Receiver-Transmitter) subsystem written in Verilog HDL. This IP block features decoupled control state machines, adjustable configuration parameters, and a noise-resilient mid-bit over-sampling matrix.

## Core Features
* **16x Over-Sampling Receiver:** Samples incoming serial data precisely at the stable mid-point (7th and 15th clock ticks) to maximize timing margin and suppress line noise.
* **Fully Parameterized Stack:** Configurable `CLK_FREQ`, `BAUD_RATE`, and `DATA_WIDTH` registers for multi-system plug-and-play reuse.
* **Hardware Interlock Flags:** Integrated `tx_busy` and `rx_done_tick` signals for stable handshake interfaces with master processors.
* **Automated Self-Checking Environment:** Includes a loopback verification testbench that dynamically validates data streams and reports simulation logs automatically.

## Directory Structure
* `rtl/` - Synthesizable hardware source files (`baud_gen.v`, `uart_tx.v`, `uart_rx.v`, `uart_top.v`)
* `tb/` - Functional verification environment (`uart_tb.v`)

## How to Compile & Simulate
Run the following commands in your terminal to compile the source and view the waveforms:
```powershell
# Compile the design modules
iverilog -s uart_tb -o uart_sim.vvp rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/uart_tb.v

# Execute simulation to dump VCD trace file
vvp uart_sim.vvp

# Launch waveform visualization grid
gtkwave uart_sim.vcd
