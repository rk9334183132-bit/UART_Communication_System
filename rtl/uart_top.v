module uart_top #(
    parameter CLK_FREQ   = 50000000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    tx_start,
    input  wire [DATA_WIDTH-1:0]   tx_data,
    input  wire                    rx_serial,
    output wire                    tx_serial,
    output wire                    tx_busy,
    output wire                    rx_done_tick,
    output wire [DATA_WIDTH-1:0]   rx_data,
    output wire                    parity_error,
    output wire                    framing_error
);

    wire w_baud_tick;

    baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (w_baud_tick)
    );

    uart_tx #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_uart_tx (
        .clk        (clk),
        .rst_n      (rst_n),
        .tx_start   (tx_start),
        .baud_tick  (w_baud_tick),
        .tx_data    (tx_data),
        .tx_serial  (tx_serial),
        .tx_busy    (tx_busy)
    );

    uart_rx #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_uart_rx (
        .clk           (clk),
        .rst_n         (rst_n),
        .rx_serial     (rx_serial),
        .baud_tick     (w_baud_tick),
        .rx_done_tick  (rx_done_tick),
        .rx_data       (rx_data),
        .parity_error  (parity_error),
        .framing_error (framing_error)
    );

endmodule
