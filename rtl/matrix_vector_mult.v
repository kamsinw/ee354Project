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
                    Y <= {Y[63:16], A00*V0 + A01*V1 + A02*V2 + A03*V3};
                    row <= 2'b01;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b01: begin
                    Y <= {Y[63:32], A10*V0 + A11*V1 + A12*V2 + A13*V3, Y[15:0]};
                    row <= 2'b10;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b10: begin
                    Y <= {Y[63:48], A20*V0 + A21*V1 + A22*V2 + A23*V3, Y[31:0]};
                    row <= 2'b11;
                    done <= 1'b0;
                    done_reg <= 1'b0;
                end
                2'b11: begin
                    if (!done_reg) begin
                        Y <= {A30*V0 + A31*V1 + A32*V2 + A33*V3, Y[47:0]};
                        done_reg <= 1'b1;
                        done <= 1'b1;
                    end else begin
                        done <= 1'b0;
                        done_reg <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule
