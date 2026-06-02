// ==========================================================================
// Module Name:  uart_tb
// Description:  Self-Checking Loopback Testbench for UART System
// Objective:    Automated PASS/FAIL verification with VCD waveform dumping
// ==========================================================================

`timescale 1ns / 1ps

module uart_tb;

    // Testbench Parameters (Accelerated clock/baud for fast simulation)
    localparam CLK_FREQ   = 50000000; // 50 MHz
    localparam BAUD_RATE  = 115200;   // 115200 bps
    localparam DATA_WIDTH = 8;
    localparam CLK_PERIOD = 20;       // 50 MHz clock is exactly 20ns period

    // Testbench Regs (Drivers)
    reg                    clk;
    reg                    rst_n;
    reg                    tx_start;
    reg [DATA_WIDTH-1:0]   tx_data;

    // Testbench Wires (Monitors)
    wire                   tx_to_rx; // Internal loopback wire connecting TX -> RX
    wire                   tx_busy;
    wire                   rx_done_tick;
    wire [DATA_WIDTH-1:0]  rx_data;

    // Global Error Tracker
    integer error_count = 0;

    // 1. Instantiate the Top Level Device Under Test (DUT)
    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx_to_rx),       // TX output connected directly to...
        .tx_busy(tx_busy),
        .rx(tx_to_rx),       // ...RX input (Loopback Network)
        .rx_done_tick(rx_done_tick),
        .rx_data(rx_data)
    );

    // 2. System Clock Generator
    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2);
        clk = 1'b1;
        #(CLK_PERIOD/2);
    end

    // 3. Automated Stimulus and Verification Task
    task send_and_verify(input [DATA_WIDTH-1:0] test_byte);
        begin
            // Wait until transmitter is free
            while (tx_busy) @(posedge clk);
            
            // Apply data and assert start pulse
            @(posedge clk);
            tx_data  = test_byte;
            tx_start = 1'b1;
            
            @(posedge clk);
            tx_start = 1'b0; // De-assert start pulse
            
            $display("[TX_DRIVE] Transmitting Data Byte: 0x%h (0b%b)", test_byte, test_byte);
            
            // Wait for the receiver to completely capture the frame
            @(posedge rx_done_tick);
            #(CLK_PERIOD * 2); // Small stabilization delay
            
            // Self-checking checking condition
            if (rx_data === test_byte) begin
                $display("[RX_CHECK] MATCH SUCCESS: Received 0x%h", rx_data);
            end else begin
                $display("[RX_CHECK] ERROR MISMATCH! Expected: 0x%h, Received: 0x%h", test_byte, rx_data);
                error_count = error_count + 1;
            end
        end
    endtask

    // 4. Main Verification Procedure
    initial begin
        // Setup GTKWave Waveform Dumping
        $dumpfile("uart_sim.vcd");
        $dumpvars(0, uart_tb);

        // System Initialization
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'b0;
        
        // Assert Asynchronous Reset for 5 clock cycles
        #(CLK_PERIOD * 5);
        rst_n    = 1'b1;
        #(CLK_PERIOD * 5);
        
        $display("\n==================================================");
        $display("     STARTING UART COMMUNICATION SYSTEM TEST bench");
        $display("==================================================\n");

        // Testcase 1: Standard Verification Vector (0x55 / Alternating bits)
        send_and_verify(8'h55);
        
        // Testcase 2: Upper Boundary Vector (0xAA)
        send_and_verify(8'hAA);
        
        // Testcase 3: Dynamic Random System Vector
        send_and_verify(8'h2D);

        // Final Report Generation
        $display("\n==================================================");
        $display("               VERIFICATION REPORT               ");
        $display("==================================================");
        if (error_count == 0) begin
            $display(" STATUS: PASS");
            $display(" All generated data bytes matched flawlessly!");
        end else begin
            $display(" STATUS: FAIL");
            $display(" Total Detected Mismatches: %d", error_count);
        end
        $display("==================================================\n");
        
        $finish;
    end

endmodule
// ==========================================================================