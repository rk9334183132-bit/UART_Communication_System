module uart_tx #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    tx_start,
    input  wire                    baud_tick,
    input  wire [DATA_WIDTH-1:0]   tx_data,
    output reg                     tx_serial,
    output reg                     tx_busy
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
    reg                  parity_reg,      parity_next;
    reg                  tx_serial_next;
    reg                  tx_busy_next;

    always @(posedge clk) begin
        if (!rst_n) begin
            state_curr     <= ST_IDLE;
            tick_count_reg <= 4'b0;
            bit_count_reg  <= 3'b0;
            shift_reg      <= {DATA_WIDTH{1'b0}};
            parity_reg     <= 1'b0;
            tx_serial      <= 1'b1;
            tx_busy        <= 1'b0;
        end else begin
            state_curr     <= state_next;
            tick_count_reg <= tick_count_next;
            bit_count_reg  <= bit_count_next;
            shift_reg      <= shift_next;
            parity_reg     <= parity_next;
            tx_serial      <= tx_serial_next;
            tx_busy        <= tx_busy_next;
        end
    end

    always @(*) begin
        state_next      = state_curr;
        tick_count_next = tick_count_reg;
        bit_count_next  = bit_count_reg;
        shift_next      = shift_reg;
        parity_next     = parity_reg;
        tx_serial_next  = tx_serial;
        tx_busy_next    = tx_busy;

        case (state_curr)
            ST_IDLE: begin
                tx_serial_next = 1'b1;
                tx_busy_next   = 1'b0;
                if (tx_start) begin
                    state_next      = ST_START;
                    tick_count_next = 4'b0;
                    shift_next      = tx_data;
                    parity_next     = ^tx_data;
                    tx_busy_next    = 1'b1;
                end
            end

            ST_START: begin
                tx_serial_next = 1'b0;
                tx_busy_next   = 1'b1;
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        state_next      = ST_DATA;
                        tick_count_next = 4'b0;
                        bit_count_next  = 3'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_DATA: begin
                tx_serial_next = shift_reg[0];
                tx_busy_next   = 1'b1;
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 4'b0;
                        shift_next      = shift_reg >> 1;
                        if (bit_count_reg == (DATA_WIDTH - 1)) begin
                            state_next = ST_PARITY;
                        end else begin
                            bit_count_next = bit_count_reg + 1'b1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_PARITY: begin
                tx_serial_next = parity_reg;
                tx_busy_next   = 1'b1;
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        state_next      = ST_STOP;
                        tick_count_next = 4'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end

            ST_STOP: begin
                tx_serial_next = 1'b1;
                tx_busy_next   = 1'b1;
                if (baud_tick) begin
                    if (tick_count_reg == 15) begin
                        state_next   = ST_IDLE;
                        tx_busy_next = 1'b0;
                    end else begin
                        tick_count_next = tick_count_reg + 1'b1;
                    end
                end
            end
            
            default: state_next = ST_IDLE;
        endcase
    end

endmodule
