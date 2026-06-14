module baud_gen #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    output wire       baud_tick
);

    localparam TICK_COUNT = CLK_FREQ / (BAUD_RATE * 16);
    localparam WIDTH      = $clog2(TICK_COUNT);

    reg [WIDTH-1:0] count_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            count_reg <= {WIDTH{1'b0}};
        end else if (count_reg == (TICK_COUNT - 1)) begin
            count_reg <= {WIDTH{1'b0}};
        end else begin
            count_reg <= count_reg + 1'b1;
        end
    end

    assign baud_tick = (count_reg == (TICK_COUNT - 1));

endmodule
