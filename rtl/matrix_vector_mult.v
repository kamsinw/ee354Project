`timescale 1ns / 1ps

module matrix_vector_mult #(
    parameter OUT_WIDTH = 12
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [16*4-1:0]        A,
    input  wire [4*4-1:0]         V,
    output reg  [4*OUT_WIDTH-1:0] Y,
    output reg                    done
);

    localparam PARTIAL_WIDTH = OUT_WIDTH + 2;
    localparam [OUT_WIDTH-1:0] OUT_MAX = {OUT_WIDTH{1'b1}};
    localparam [PARTIAL_WIDTH-1:0] OUT_MAX_EXT = {{(PARTIAL_WIDTH-OUT_WIDTH){1'b0}}, OUT_MAX};

    reg [1:0] row_idx;
    reg [1:0] col_idx;
    reg [PARTIAL_WIDTH-1:0] accum;
    reg busy;

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

    reg [7:0]  product;
    reg [PARTIAL_WIDTH-1:0] accum_next;

    always @(posedge clk) begin
        if (reset) begin
            row_idx <= 2'd0;
            col_idx <= 2'd0;
            accum   <= {PARTIAL_WIDTH{1'b0}};
            Y       <= {4*OUT_WIDTH{1'b0}};
            done    <= 1'b0;
            busy    <= 1'b0;
        end else begin
            if (start && !busy) begin
                row_idx <= 2'd0;
                col_idx <= 2'd0;
                accum   <= {PARTIAL_WIDTH{1'b0}};
                Y       <= {4*OUT_WIDTH{1'b0}};
                busy    <= 1'b1;
                done    <= 1'b0;
            end else if (busy) begin
                product    = matrix[row_idx][col_idx] * vec[col_idx];
                accum_next = accum + product;
                accum      <= accum_next;
                if (col_idx == 2'd3) begin
                    if (accum_next > OUT_MAX_EXT)
                        Y[row_idx*OUT_WIDTH +: OUT_WIDTH] <= OUT_MAX;
                    else
                        Y[row_idx*OUT_WIDTH +: OUT_WIDTH] <= accum_next[OUT_WIDTH-1:0];
                    accum   <= {PARTIAL_WIDTH{1'b0}};
                    col_idx <= 2'd0;
                    if (row_idx == 2'd3) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        row_idx <= 2'd0;
                    end else begin
                        row_idx <= row_idx + 1'b1;
                    end
                end else begin
                    col_idx <= col_idx + 1'b1;
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule

