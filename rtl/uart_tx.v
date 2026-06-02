// ==========================================================================
// Module Name:  uart_tx
// Description:  Parameterized UART Transmitter with 16x Over-sampling Control
// Objective:    Silicon-ready, clean Finite State Machine (FSM) implementation
// ==========================================================================

`timescale 1ns / 1ps

module uart_tx #(
    parameter DATA_WIDTH = 8  // Configurable data width (Standard is 8-bit)
)(
    input  wire                    clk,        // System Clock
    input  wire                    rst_n,      // Asynchronous active-low reset
    input  wire                    baud_tick,  // 16x over-sampling tick from baud_gen
    input  wire                    tx_start,   // Command pulse to start transmission
    input  wire [DATA_WIDTH-1:0]   tx_data,    // Parallel data byte to transmit
    output reg                     tx,         // Serial output pin
    output reg                     tx_busy     // High when transmitting data
);

    // Finite State Machine (FSM) State Definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Internal FSM Registers
    reg [1:0] state_reg, next_state;
    
    // Internal Counters & Data Buffers
    reg [3:0] s_reg, s_next;                 // Counts 16 baud_ticks per bit period
    reg [2:0] n_reg, n_next;                 // Tracks which bit index is being sent
    reg [DATA_WIDTH-1:0] b_reg, b_next;     // Buffers the input data safely
    reg tx_reg, tx_next;                     // Latches the output tx state

    // FSM Sequential State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
            s_reg     <= 4'b0;
            n_reg     <= 3'b0;
            b_reg     <= {DATA_WIDTH{1'b0}};
            tx_reg    <= 1'b1; // UART idle state line is always pulled high (1)
        end else begin
            state_reg <= next_state;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
            tx_reg    <= tx_next;
        end
    end

    // FSM Combinational Next-State Logic
    always @* begin
        next_state = state_reg;
        s_next     = s_reg;
        n_next     = n_reg;
        b_next     = b_reg;
        tx_next    = tx_reg;
        tx_busy    = 1'b1;     // Default to busy; overridden explicitly in IDLE

        case (state_reg)
            IDLE: begin
                tx_busy = 1'b0;
                tx_next = 1'b1; // Maintain idle high line
                if (tx_start) begin
                    next_state = START;
                    s_next     = 4'b0;
                    b_next     = tx_data; // Capture input data into holding buffer
                end
            end

            START: begin
                tx_next = 1'b0; // Drive line LOW to signal START bit
                if (baud_tick) begin
                    if (s_reg == 15) begin
                        next_state = DATA;
                        s_next     = 4'b0;
                        n_next     = 3'b0;
                    end else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end

            DATA: begin
                tx_next = b_reg[0]; // Send out the Least Significant Bit (LSB) first
                if (baud_tick) begin
                    if (s_reg == 15) begin
                        s_next = 4'b0;
                        b_next = b_reg >> 1; // Shift right to bring next bit to position 0
                        if (n_reg == (DATA_WIDTH - 1)) begin
                            next_state = STOP;
                        end else begin
                            n_next = n_reg + 1'b1;
                        end
                    end else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1; // Drive line HIGH to signal STOP bit
                if (baud_tick) begin
                    if (s_reg == 15) begin
                        next_state = IDLE;
                        s_next     = 4'b0;
                    end else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
        endcase
    end

    // Assign internal register directly to physical output wire
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1'b1;
        end else begin
            tx <= tx_reg;
        end
    end

endmodule
// ==========================================================================