module uart_rx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    rx_serial,
    input  wire                    baud_tick,
    output reg                     rx_done_tick,
    output reg  [DATA_WIDTH-1:0]   rx_data,
    output reg                     parity_error,
    output reg                     framing_error
);

    localparam [2:0] ST_IDLE   = 3'b000,
                     ST_START  = 3'b001,
                     ST_DATA   = 3'b010,
                     ST_PARITY = 3'b011,
                     ST_STOP   = 3'b100;

    reg [2:0]            state_curr;
    reg [2:0]            state_next;
    reg [3:0]            tick_count_reg,  tick_count_next;
    reg [2:0]            bit_count_reg,   bit_count_next;
    reg [DATA_WIDTH-1:0] shift_reg,       shift_next;
    reg                  parity_err_next;
    reg                  framing_err_next;
    reg                  rx_done_next;

    always @(posedge clk) begin
        if (!rst_n) begin
            state_curr      <= ST_IDLE;
            tick_count_reg  <= 4'b0;
            bit_count_reg   <= 3'b0;
            shift_reg       <= {DATA_WIDTH{1'b0}};
            rx_data         <= {DATA_WIDTH{1'b0}};
            parity_error    <= 1'b0;
            framing_error   <= 1'b0;
            rx_done_tick    <= 1'b0;
        end else begin
            state_curr      <= state_next;
            tick_count_reg  <= tick_count_next;
            bit_count_reg   <= bit_count_next;
            shift_reg       <= shift_next;
            rx_done_tick    <= rx_done_next;
            
            if (rx_done_next) begin
                rx_data       <= shift_next;
                parity_error  <= parity_err_next;
                framing_error <= framing_err_next;
            end
        end
    end

    always @(*) begin
        state_next       = state_curr;
        tick_count_next  = tick_count_reg;
        bit_count_next   = bit_count_reg;
        shift_next       = shift_reg;
        parity_err_next  = parity_error;
        framing_err_next = framing_error;
        rx_done_next     = 1'b0;

        case (state_curr)
            ST_IDLE: begin
                if (!rx_serial) begin
                    state_next      = ST_START;
                    tick_count_next = 4'b0;
                end
            end

            ST_START: begin
                if (baud_tick) begin
                    if (tick_count_reg == 7) begin
                        state_next      = ST_DATA;
                        tick_count_next = 4'b0;
                        bit_count_next  = 3'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_DATA: begin
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 4'b0;
                        shift_next      = {rx_serial, shift_reg[DATA_WIDTH-1:1]};
                        if (bit_count_reg == (DATA_WIDTH - 1))
                            state_next = ST_PARITY;
                        else
                            bit_count_next = bit_count_reg + 1'b1;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_PARITY: begin
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 4'b0;
                        parity_err_next = (rx_serial != (^shift_reg));
                        state_next      = ST_STOP;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_STOP: begin
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        framing_err_next = (rx_serial == 1'b0);
                        rx_done_next     = 1'b1;
                        state_next       = ST_IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            default: state_next = ST_IDLE;
        endcase
    end

endmodule
