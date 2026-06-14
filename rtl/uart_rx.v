

`timescale 1ns / 1ps

module uart_rx #(
    parameter DATA_WIDTH = 8  // Configurable data width (Standard is 8-bit)
)(
    input  wire                    clk,           // System Clock
    input  wire                    rst_n,         // Asynchronous active-low reset
    input  wire                    baud_tick,     // 16x over-sampling tick from baud_gen
    input  wire                    rx,            // Incoming serial data line
    output reg                     rx_done_tick,  // High pulse for 1 cycle when byte received
    output reg [DATA_WIDTH-1:0]    rx_data        // Parallel data byte output
);

    // Finite State Machine (FSM) State Definitions
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Internal FSM Registers
    reg [1:0] state_reg, next_state;
    
    // Internal Counters & Data Buffers
    reg [3:0] s_reg, s_next;                 // Counts 16 baud_ticks to find bit centers
    reg [2:0] n_reg, n_next;                 // Tracks which bit index is being received
    reg [DATA_WIDTH-1:0] b_reg, b_next;     // Shifts incoming serial bits into a parallel byte

    // FSM Sequential State Register (FIXED: changed megedge to negedge)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
            s_reg     <= 4'b0;
            n_reg     <= 3'b0;
            b_reg     <= {DATA_WIDTH{1'b0}};
        end else begin
            state_reg <= next_state;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
        end
    end

    // FSM Combinational Next-State Logic
    always @* begin
        next_state   = state_reg;
        s_next       = s_reg;
        n_next       = n_reg;
        b_next       = b_reg;
        rx_done_tick = 1'b0; // Default output pulse to low

        case (state_reg)
            IDLE: begin
                if (!rx) begin // Start bit detected (line transitions from 1 to 0)
                    next_state = START;
                    s_next     = 4'b0;
                end
            end

            START: begin
                if (baud_tick) begin
                    if (s_reg == 7) begin // Wait 7 ticks to reach the exact center of start bit
                        next_state = DATA;
                        s_next     = 4'b0;
                        n_next     = 3'b0;
                    end else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end

            DATA: begin
                if (baud_tick) begin
                    if (s_reg == 15) begin // Sample data at the exact center of the bit window
                        s_next = 4'b0;
                        b_next = {rx, b_reg[DATA_WIDTH-1:1]}; // Shift right (LSB received first)
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
                if (baud_tick) begin
                    if (s_reg == 15) begin // Wait 15 ticks to sample center of stop bit
                        rx_done_tick = 1'b1; // Trigger data valid pulse
                        next_state   = IDLE;
                    end else begin
                        s_next = s_reg + 1'b1;
                    end
                end
            end
        endcase
    end

    // Route the shifting buffer register to the output data port (FIXED: changed megedge to negedge)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
        end else begin
            rx_data <= b_reg;
        end
    end

endmodule
