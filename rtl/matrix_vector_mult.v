`timescale 1ns / 1ps

module matrix_vector_mult #(
    parameter integer OUT_WIDTH = 12
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [16*4-1:0]        A,
    input  wire [4*4-1:0]         V,
    output reg  [4*OUT_WIDTH-1:0] Y,
    output reg                    done
);

    localparam integer PARTIAL_WIDTH = (OUT_WIDTH >= 10) ? OUT_WIDTH + 2 : 12;
    localparam [OUT_WIDTH-1:0]         OUT_MAX     = {OUT_WIDTH{1'b1}};
    localparam [PARTIAL_WIDTH-1:0]     OUT_MAX_EXT = {{(PARTIAL_WIDTH-OUT_WIDTH){1'b0}}, OUT_MAX};

    reg [1:0] row_idx_q;
    reg [1:0] row_idx_n;
    reg [1:0] col_idx_q;
    reg [1:0] col_idx_n;
    reg [PARTIAL_WIDTH-1:0] accum_q;
    reg [PARTIAL_WIDTH-1:0] accum_n;
    reg [4*OUT_WIDTH-1:0]   y_q;
    reg [4*OUT_WIDTH-1:0]   y_n;
    reg                     busy_q;
    reg                     busy_n;
    reg                     done_n;

    wire [3:0] matrix [0:3][0:3];
    assign matrix[0][0] = A[3:0];
    assign matrix[0][1] = A[7:4];
    assign matrix[0][2] = A[11:8];
    assign matrix[0][3] = A[15:12];
    assign matrix[1][0] = A[19:16];
    assign matrix[1][1] = A[23:20];
    assign matrix[1][2] = A[27:24];
    assign matrix[1][3] = A[31:28];
    assign matrix[2][0] = A[35:32];
    assign matrix[2][1] = A[39:36];
    assign matrix[2][2] = A[43:40];
    assign matrix[2][3] = A[47:44];
    assign matrix[3][0] = A[51:48];
    assign matrix[3][1] = A[55:52];
    assign matrix[3][2] = A[59:56];
    assign matrix[3][3] = A[63:60];

    wire [3:0] vec [0:3];
    assign vec[0] = V[3:0];
    assign vec[1] = V[7:4];
    assign vec[2] = V[11:8];
    assign vec[3] = V[15:12];

    wire [7:0] product      = matrix[row_idx_q][col_idx_q] * vec[col_idx_q];
    wire       last_col     = (col_idx_q == 2'd3);
    wire       last_row     = (row_idx_q == 2'd3);
    wire [PARTIAL_WIDTH-1:0] accum_sum = accum_q + product;
    wire [OUT_WIDTH-1:0]     row_result = (accum_sum > OUT_MAX_EXT)
                                        ? OUT_MAX
                                        : accum_sum[OUT_WIDTH-1:0];

    always @(*) begin
        row_idx_n = row_idx_q;
        col_idx_n = col_idx_q;
        accum_n   = accum_q;
        y_n       = y_q;
        busy_n    = busy_q;
        done_n    = 1'b0;

        if (start && !busy_q) begin
            row_idx_n = 2'd0;
            col_idx_n = 2'd0;
            accum_n   = {PARTIAL_WIDTH{1'b0}};
            y_n       = {4*OUT_WIDTH{1'b0}};
            busy_n    = 1'b1;
        end else if (busy_q) begin
            if (last_col) begin
                y_n[row_idx_q*OUT_WIDTH +: OUT_WIDTH] = row_result;
                accum_n = {PARTIAL_WIDTH{1'b0}};
                col_idx_n = 2'd0;
                if (last_row) begin
                    busy_n = 1'b0;
                    done_n = 1'b1;
                    row_idx_n = 2'd0;
                end else begin
                    row_idx_n = row_idx_q + 1'b1;
                end
            end else begin
                accum_n   = accum_sum;
                col_idx_n = col_idx_q + 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            row_idx_q <= 2'd0;
            col_idx_q <= 2'd0;
            accum_q   <= {PARTIAL_WIDTH{1'b0}};
            y_q       <= {4*OUT_WIDTH{1'b0}};
            busy_q    <= 1'b0;
            Y         <= {4*OUT_WIDTH{1'b0}};
            done      <= 1'b0;
        end else begin
            row_idx_q <= row_idx_n;
            col_idx_q <= col_idx_n;
            accum_q   <= accum_n;
            y_q       <= y_n;
            busy_q    <= busy_n;
            Y         <= y_n;
            done      <= done_n;
        end
    end

endmodule
