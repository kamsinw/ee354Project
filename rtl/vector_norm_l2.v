`timescale 1ns / 1ps

module vector_norm_l2 #(
    parameter integer WIDTH = 4,
    parameter integer NORM_WIDTH = WIDTH + 2
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*WIDTH-1:0]     V_in,
    output reg  [NORM_WIDTH-1:0] norm_out,
    output reg                    done
);

    localparam integer SUM_BITS   = 2*WIDTH + 4;
    localparam [1:0]   STATE_IDLE = 2'd0;
    localparam [1:0]   STATE_ACCUM = 2'd1;
    localparam [1:0]   STATE_SQRT  = 2'd2;

    reg [1:0] state_q;
    reg [1:0] state_d;

    reg [1:0] sample_idx_q;
    reg [1:0] sample_idx_d;

    reg [SUM_BITS-1:0] sum_sq_q;
    reg [SUM_BITS-1:0] sum_sq_d;

    reg [SUM_BITS-1:0] rem_q;
    reg [SUM_BITS-1:0] rem_d;

    reg [NORM_WIDTH:0] root_q;
    reg [NORM_WIDTH:0] root_d;

    reg [SUM_BITS-1:0] bit_val_q;
    reg [SUM_BITS-1:0] bit_val_d;

    reg [4:0] sqrt_iter_q;
    reg [4:0] sqrt_iter_d;

    reg [NORM_WIDTH-1:0] norm_d;
    reg                   done_d;

    wire [WIDTH-1:0] lane_values [0:3];
    assign lane_values[0] = V_in[WIDTH-1:0];
    assign lane_values[1] = V_in[2*WIDTH-1:WIDTH];
    assign lane_values[2] = V_in[3*WIDTH-1:2*WIDTH];
    assign lane_values[3] = V_in[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] current_sample        = lane_values[sample_idx_q];
    wire [2*WIDTH-1:0] sample_square       = current_sample * current_sample;
    wire [SUM_BITS-1:0] sample_square_ext  = {{(SUM_BITS-2*WIDTH){1'b0}}, sample_square};
    wire [SUM_BITS-1:0] sqrt_seed          = {{(SUM_BITS-1){1'b0}}, 1'b1} << (2*WIDTH - 2);

    always @(*) begin
        state_d      = state_q;
        sample_idx_d = sample_idx_q;
        sum_sq_d     = sum_sq_q;
        rem_d        = rem_q;
        root_d       = root_q;
        bit_val_d    = bit_val_q;
        sqrt_iter_d  = sqrt_iter_q;
        norm_d       = norm_out;
        done_d       = 1'b0;

        case (state_q)
            STATE_IDLE: begin
                if (start) begin
                    state_d      = STATE_ACCUM;
                    sample_idx_d = 2'd0;
                    sum_sq_d     = {SUM_BITS{1'b0}};
                end
            end

            STATE_ACCUM: begin
                sum_sq_d = sum_sq_q + sample_square_ext;
                if (sample_idx_q == 2'd3) begin
                    state_d      = STATE_SQRT;
                    rem_d        = sum_sq_q + sample_square_ext;
                    root_d       = {(NORM_WIDTH+1){1'b0}};
                    bit_val_d    = sqrt_seed;
                    sqrt_iter_d  = NORM_WIDTH;
                end else begin
                    sample_idx_d = sample_idx_q + 1'b1;
                end
            end

            STATE_SQRT: begin
                if (sqrt_iter_q != 0) begin
                    if (rem_q >= (root_q + bit_val_q)) begin
                        rem_d  = rem_q - (root_q + bit_val_q);
                        root_d = (root_q >> 1) + bit_val_q;
                    end else begin
                        rem_d  = rem_q;
                        root_d = root_q >> 1;
                    end
                    bit_val_d   = bit_val_q >> 2;
                    sqrt_iter_d = sqrt_iter_q - 1'b1;
                end else begin
                    norm_d  = root_q[NORM_WIDTH-1:0];
                    done_d  = 1'b1;
                    state_d = STATE_IDLE;
                end
            end

            default: begin
                state_d = STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q      <= STATE_IDLE;
            sample_idx_q <= 2'd0;
            sum_sq_q     <= {SUM_BITS{1'b0}};
            rem_q        <= {SUM_BITS{1'b0}};
            root_q       <= {(NORM_WIDTH+1){1'b0}};
            bit_val_q    <= {SUM_BITS{1'b0}};
            sqrt_iter_q  <= 5'd0;
            norm_out     <= {NORM_WIDTH{1'b0}};
            done         <= 1'b0;
        end else begin
            state_q      <= state_d;
            sample_idx_q <= sample_idx_d;
            sum_sq_q     <= sum_sq_d;
            rem_q        <= rem_d;
            root_q       <= root_d;
            bit_val_q    <= bit_val_d;
            sqrt_iter_q  <= sqrt_iter_d;
            norm_out     <= norm_d;
            done         <= done_d;
        end
    end

endmodule
