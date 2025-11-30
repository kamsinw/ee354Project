`timescale 1ns / 1ps

module matrix_vector_mult (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire signed [16*16-1:0] A,
    input  wire signed [4*16-1:0] V,
    output reg  signed [4*16-1:0] Y,
    output reg         done
);

    wire signed [15:0] A00 = A[15:0];
    wire signed [15:0] A01 = A[31:16];
    wire signed [15:0] A02 = A[47:32];
    wire signed [15:0] A03 = A[63:48];
    wire signed [15:0] A10 = A[79:64];
    wire signed [15:0] A11 = A[95:80];
    wire signed [15:0] A12 = A[111:96];
    wire signed [15:0] A13 = A[127:112];
    wire signed [15:0] A20 = A[143:128];
    wire signed [15:0] A21 = A[159:144];
    wire signed [15:0] A22 = A[175:160];
    wire signed [15:0] A23 = A[191:176];
    wire signed [15:0] A30 = A[207:192];
    wire signed [15:0] A31 = A[223:208];
    wire signed [15:0] A32 = A[239:224];
    wire signed [15:0] A33 = A[255:240];

    wire signed [15:0] V0 = V[15:0];
    wire signed [15:0] V1 = V[31:16];
    wire signed [15:0] V2 = V[47:32];
    wire signed [15:0] V3 = V[63:48];

    // TIMING OPTIMIZATION: Use tree structure and reduce to 20-bit sums
    // Break 4-way sum into 2+2 tree structure for better timing
    // Reduce width from 24-bit to 20-bit for faster carry propagation
    wire signed [31:0] prod0_0 = A00 * V0;
    wire signed [31:0] prod0_1 = A01 * V1;
    wire signed [31:0] prod0_2 = A02 * V2;
    wire signed [31:0] prod0_3 = A03 * V3;
    wire signed [19:0] sum0_pair1 = prod0_0[19:0] + prod0_1[19:0];
    wire signed [19:0] sum0_pair2 = prod0_2[19:0] + prod0_3[19:0];
    wire signed [19:0] sum0 = sum0_pair1 + sum0_pair2;
    
    wire signed [31:0] prod1_0 = A10 * V0;
    wire signed [31:0] prod1_1 = A11 * V1;
    wire signed [31:0] prod1_2 = A12 * V2;
    wire signed [31:0] prod1_3 = A13 * V3;
    wire signed [19:0] sum1_pair1 = prod1_0[19:0] + prod1_1[19:0];
    wire signed [19:0] sum1_pair2 = prod1_2[19:0] + prod1_3[19:0];
    wire signed [19:0] sum1 = sum1_pair1 + sum1_pair2;
    
    wire signed [31:0] prod2_0 = A20 * V0;
    wire signed [31:0] prod2_1 = A21 * V1;
    wire signed [31:0] prod2_2 = A22 * V2;
    wire signed [31:0] prod2_3 = A23 * V3;
    wire signed [19:0] sum2_pair1 = prod2_0[19:0] + prod2_1[19:0];
    wire signed [19:0] sum2_pair2 = prod2_2[19:0] + prod2_3[19:0];
    wire signed [19:0] sum2 = sum2_pair1 + sum2_pair2;
    
    wire signed [31:0] prod3_0 = A30 * V0;
    wire signed [31:0] prod3_1 = A31 * V1;
    wire signed [31:0] prod3_2 = A32 * V2;
    wire signed [31:0] prod3_3 = A33 * V3;
    wire signed [19:0] sum3_pair1 = prod3_0[19:0] + prod3_1[19:0];
    wire signed [19:0] sum3_pair2 = prod3_2[19:0] + prod3_3[19:0];
    wire signed [19:0] sum3 = sum3_pair1 + sum3_pair2;

    reg [1:0] row;
    reg done_reg;

    always @(posedge clk) begin
        if (reset) begin
            row <= 2'b00;
            Y <= 64'd0;
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            row <= 2'b00;
            done <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            case (row)
                2'b00: begin
                    // TIMING OPTIMIZATION: Use pre-computed 24-bit sum (reduces carry chain depth)
                    Y <= {Y[63:16], sum0[15:0]};
                    row <= 2'b01;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b01: begin
                    Y <= {Y[63:32], sum1[15:0], Y[15:0]};
                    row <= 2'b10;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b10: begin
                    Y <= {Y[63:48], sum2[15:0], Y[31:0]};
                    row <= 2'b11;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b11: begin
                    if (!done_reg) begin
                        Y <= {sum3[15:0], Y[47:0]};
                        done_reg <= 1'b1;
                        done <= 1'b1;
                    end else begin
                        done <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
