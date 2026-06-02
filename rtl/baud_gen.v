// ==========================================================================
// Module Name:  baud_gen
// Description:  Parameterized Baud Rate Generator creating a 16x Over-sampling Tick
// Objective:    Silicon-ready, clean synthesizable clock-enable generator
// ==========================================================================

`timescale 1ns / 1ps

module baud_gen #(
    parameter CLK_FREQ  = 50000000,  // Default System Clock: 50 MHz
    parameter BAUD_RATE = 9600       // Default Target Baud Rate: 9600 bps
)(
    input  wire       clk,        // System Clock
    input  wire       rst_n,      // Active-low asynchronous reset
    output reg        baud_tick   // 16x Over-sampling pulse output
);

    // Calculate maximum count limit for the internal counter
    localparam MAX_COUNT = CLK_FREQ / (BAUD_RATE * 16);
    
    // Determine required bit-width for the counter register automatically
    localparam COUNTER_WIDTH = $clog2(MAX_COUNT);

    // Internal Counter Register
    reg [COUNTER_WIDTH-1:0] count_reg;

    // Counter and Tick Generation Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= {COUNTER_WIDTH{1'b0}};
            baud_tick <= 1'b0;
        end else begin
            if (count_reg == (MAX_COUNT - 1)) begin
                count_reg <= {COUNTER_WIDTH{1'b0}};
                baud_tick <= 1'b1; // Generate high pulse for exactly 1 clk cycle
            end else begin
                count_reg <= count_reg + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
// ==========================================================================