# ⚡ Synthesizable Parameterized UART Core with 16x Over-Sampling

![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-orange)
![GTKWave](https://img.shields.io/badge/Viewer-GTKWave-green)
![Design](https://img.shields.io/badge/Design-Synthesizable%20IP-brightgreen)

A silicon-grade, fully parameterized **UART (Universal Asynchronous Receiver-Transmitter) Communication Subsystem** designed in Verilog HDL.

The design incorporates modular FSM-based control, configurable baud-rate generation, parity support, and a robust **16x oversampling receiver architecture** for reliable asynchronous serial communication.

The project includes a complete self-checking verification environment and GTKWave simulation support.

---

## ◆ Features & Specifications

### 16x Over-Sampling Receiver

- Implements 16x baud-rate oversampling for accurate center-bit sampling.
- Samples incoming data at the middle of each bit period for improved noise immunity.
- Improves tolerance against clock mismatch and serial line jitter.

### Integrated Parity Engine

- Supports hardware parity generation.
- Real-time parity checking at the receiver.
- Generates `parity_error` for invalid frames.

### UART Transmitter

- FSM-based transmitter architecture.
- Generates Start Bit, Data Bits (LSB First), Parity Bit, and Stop Bit.
- Includes `tx_busy` handshake signal.

### UART Receiver

- Mid-bit sampling architecture.
- Serial-to-parallel conversion.
- Generates `rx_done_tick`.
- Supports framing error detection.

### Synthesizable RTL

- IEEE 1364 Verilog HDL compliant.
- FPGA and ASIC friendly.
- Fully synchronous design.

---

## ◆ Hardware Timing Waveforms

GitHub cannot directly render `.vcd` files. The generated waveform can be viewed using GTKWave.

![UART Simulation Waveforms](waveforms/waveforms.png)

### Protocol Timing Mechanics

```text
              Transaction Active (Start Bit)
                         │
                         ▼

RX Serial  ─────┐                         ┌──────────────
                └─────────────────────────┘

Baud Tick  ─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─

Tick Count  0 1 2 3 4 5 6 7 8 ... 14 15

                        ▲
                        │
                 Center Sampling Point
```

---

## ◆ Project Structure

```text
UART_Communication_System/
│
├── rtl/
│   ├── baud_gen.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   └── uart_top.v
│
├── tb/
│   └── uart_tb.v
│
├── waveforms/
│   ├── uart_waveform.png
│   └── uart_sim.vcd
│
└── README.md
```

---

## ◆ Verification

- Self-checking loopback testbench
- Automated PASS / FAIL reporting
- Randomized data transmission
- Parity error checking
- Framing error checking
- VCD waveform generation
- GTKWave analysis

---

## ◆ Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- GitHub

---

## ◆ Key Learning Outcomes

- UART Protocol Design
- FSM-Based RTL Development
- Serial Communication Systems
- 16x Oversampling Techniques
- Verification Methodology
- Waveform Debugging
- Parameterized Hardware Design

---


