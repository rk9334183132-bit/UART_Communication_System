# ⚡ Synthesizable Parameterized UART Core with Over-Sampling

![](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![](https://img.shields.io/badge/Simulator-Icarus%20Verilog-orange)
![](https://img.shields.io/badge/Viewer-GTKWave-green)
![]([https://img.shields.io/badge/Design-Synthesizable%20IP-brightgreen](https://img.shields.io/badge/Design-Synthesizable%20IP-brightgreen))

A silicon-grade, fully parameterizable **UART (Universal Asynchronous Receiver-Transmitter) Subsystem** designed in Verilog HDL. This IP core features decoupled finite state machines (FSM), integrated hardware parity computation matrixing, and a noise-resilient 16x mid-bit oversampling matrix for robust asynchronous data frame synchronization. Includes a fully automated loopback verification testbench environment.

---

## ◆ Features & Specifications

* **16x Over-Sampling Alignment Matrix:** The receiver module utilizes a 16x clock multiplier strobe to execute center-sampling alignment (sampling exactly at the stable 7th and 15th internal ticks). This maximizes timing margins, mitigates clock drift, and rejects line noise/glitches.
* **Integrated Hardware Parity Engine:** Configured with native structural Even Parity generation (Transmitter) and real-time computation validation (Receiver) to detect line errors instantly.
* **Strict Synchronous Reset Scheme:** Built using explicit, clock-edge synchronized active-low reset logic (`rst_n`) across all control paths to maintain fully predictable state boundaries and prevent hardware lockup.
* **Modular Two-Process FSM Topography:** Control units separate sequential current-state transitions from combinational next-state decoding, optimizing synthesis wire paths and boosting maximum clock frequency ($F_{max}$).
* **Dynamic Hardware Interlocking:** Features explicit handshake control signaling (`tx_busy`, `rx_done_tick`, `parity_error`, `framing_error`) for seamless interface integration with master microcontrollers or FIFO buffers.

---

## ◆ Hardware Timing Waveforms

Since GitHub doesn't render `.vcd` trace files directly, here is the architectural timing relationship demonstrating how the controller oversamples bits on the serial line:

![UART Simulation Waveforms](waveforms.png)

### Protocol Timing Mechanics (Oversampling Visualization)

```text
              Transaction Active (Start Bit) ──┐
                                               ▼
rx_serial   ───┐                               ┌────────────────────────
               └───────────────────────────────┘
               │                               │
baud_tick   ───┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴
Tick Count     0 1 2 3 4 5 6 7 8 ...   14 15 0 1 2 3 4 5 6 7 8 ...
                             ▲               ▲             ▲
                             │               │             │
                       [Center Sample]  [Reset Tick]  [Data Sample 0]
                        (Verify Start)  (Align FSM)   (Stable Center)
```
UART_Communication_System/
├── rtl/
│   ├── baud_gen.v       # Parameterized clock division strobe generator
│   ├── uart_tx.v        # Parallel-to-serial transmitter module with parity generation
│   ├── uart_rx.v        # Serial-to-parallel center-sampling receiver module
│   └── uart_top.v       # Structural top wrapper stitching subsystem blocks
├── tb/
│   └── uart_tb.v        # Automated self-checking functional verification testbench
└── waveforms/
    └── uart_sim_upgraded.vcd     # Generated simulation timing trace file
