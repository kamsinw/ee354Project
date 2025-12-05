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
    localparam [1:0]   IDLE = 2'd0;
    localparam [1:0]   ACCUM = 2'd1;
    localparam [1:0]   SQRT  = 2'd2;

    reg [1:0] state_q;
    reg [1:0] state_n;

    reg [1:0] sample_idx_q;
    reg [1:0] sample_idx_n;

    reg [SUM_BITS-1:0] sum_sq_q;
    reg [SUM_BITS-1:0] sum_sq_n;

    reg [SUM_BITS-1:0] rem_q;
    reg [SUM_BITS-1:0] rem_n;

    reg [NORM_WIDTH:0] root_q;
    reg [NORM_WIDTH:0] root_n;

    reg [SUM_BITS-1:0] bit_val_q;
    reg [SUM_BITS-1:0] bit_val_n;

    reg [4:0] sqrt_iter_q;
    reg [4:0] sqrt_iter_n;

    reg [NORM_WIDTH-1:0] norm_n;
    reg                   done_n;

    wire [WIDTH-1:0] lanes [0:3];
    assign lanes[0] = V_in[WIDTH-1:0];
    assign lanes[1] = V_in[2*WIDTH-1:WIDTH];
    assign lanes[2] = V_in[3*WIDTH-1:2*WIDTH];
    assign lanes[3] = V_in[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] current_sample        = lanes[sample_idx_q];
    wire [2*WIDTH-1:0] sample_square       = current_sample * current_sample;
    wire [SUM_BITS-1:0] sample_square_ext  = {{(SUM_BITS-2*WIDTH){1'b0}}, sample_square};
    wire [SUM_BITS-1:0] sqrt_seed          = {{(SUM_BITS-1){1'b0}}, 1'b1} << (2*WIDTH - 2);

    always @(*) begin
        state_n      = state_q;
        sample_idx_n = sample_idx_q;
        sum_sq_n     = sum_sq_q;
        rem_n        = rem_q;
        root_n       = root_q;
        bit_val_n    = bit_val_q;
        sqrt_iter_n  = sqrt_iter_q;
        norm_n       = norm_out;
        done_n       = 1'b0;

        case (state_q)
            IDLE: begin
                if (start) begin
                    state_n      = ACCUM;
                    sample_idx_n = 2'd0;
                    sum_sq_n     = {SUM_BITS{1'b0}};
                end
            end

            ACCUM: begin
                sum_sq_n = sum_sq_q + sample_square_ext;
                if (sample_idx_q == 2'd3) begin
                    state_n      = SQRT;
                    rem_n        = sum_sq_q + sample_square_ext;
                    root_n       = {(NORM_WIDTH+1){1'b0}};
                    bit_val_n    = sqrt_seed;
                    sqrt_iter_n  = NORM_WIDTH;
                end else begin
                    sample_idx_n = sample_idx_q + 1'b1;
                end
            end

            SQRT: begin
                if (sqrt_iter_q != 0) begin
                    if (rem_q >= (root_q + bit_val_q)) begin
                        rem_n  = rem_q - (root_q + bit_val_q);
                        root_n = (root_q >> 1) + bit_val_q;
                    end else begin
                        rem_n  = rem_q;
                        root_n = root_q >> 1;
                    end
                    bit_val_n   = bit_val_q >> 2;
                    sqrt_iter_n = sqrt_iter_q - 1'b1;
                end else begin
                    norm_n  = root_q[NORM_WIDTH-1:0];
                    done_n  = 1'b1;
                    state_n = IDLE;
                end
            end

            default: begin
                state_n = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q      <= IDLE;
            sample_idx_q <= 2'd0;
            sum_sq_q     <= {SUM_BITS{1'b0}};
            rem_q        <= {SUM_BITS{1'b0}};
            root_q       <= {(NORM_WIDTH+1){1'b0}};
            bit_val_q    <= {SUM_BITS{1'b0}};
            sqrt_iter_q  <= 5'd0;
            norm_out     <= {NORM_WIDTH{1'b0}};
            done         <= 1'b0;
        end else begin
            state_q      <= state_n;
            sample_idx_q <= sample_idx_n;
            sum_sq_q     <= sum_sq_n;
            rem_q        <= rem_n;
            root_q       <= root_n;
            bit_val_q    <= bit_val_n;
            sqrt_iter_q  <= sqrt_iter_n;
            norm_out     <= norm_n;
            done         <= done_n;
        end
    end

endmodule
