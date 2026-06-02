// ==========================================================================
// Module Name:  uart_top
// Description:  Top-Level Integration Wrapper for the UART System
// Objective:    Connects Baud Generator, TX, and RX into a unified IP core
// ==========================================================================

`timescale 1ns / 1ps

module uart_top #(
    parameter CLK_FREQ   = 50000000, // System Clock Frequency (e.g., 50 MHz)
    parameter BAUD_RATE  = 9600,     // Operational Baud Rate (e.g., 9600 bps)
    parameter DATA_WIDTH = 8         // Size of data packet
)(
    input  wire                    clk,          // System Clock
    input  wire                    rst_n,        // System Asynchronous Reset
    
    // Transmitter Interface
    input  wire                    tx_start,     // Pulse high to trigger transmission
    input  wire [DATA_WIDTH-1:0]   tx_data,      // Byte payload to transmit
    output wire                    tx,           // Physical TX Pin
    output wire                    tx_busy,      // Status flag indicating active TX
    
    // Receiver Interface
    input  wire                    rx,           // Physical RX Pin
    output wire                    rx_done_tick, // Pulse high indicating data received
    output wire [DATA_WIDTH-1:0]   rx_data       // Valid parallel byte output
);

    // Internal connection wire for the 16x over-sampling tick
    wire w_baud_tick;

    // 1. Instantiate the Baud Rate Generator
    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_generator_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick)
    );

    // 2. Instantiate the UART Transmitter
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) transmitter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // 3. Instantiate the UART Receiver
    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH)
    ) receiver_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(w_baud_tick),
        .rx(rx),
        .rx_done_tick(rx_done_tick),
        .rx_data(rx_data)
    );

endmodule
// ==========================================================================