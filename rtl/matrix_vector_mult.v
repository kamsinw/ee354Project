// matrix_vector_mult.v
// Computes y = A * v using 1 row per clock

module matrix_vector_mult (
    input clk,
    input start,
    // input signed [WIDTH-1:0] a00, a01, a02, a03,
    // input signed [WIDTH-1:0] a10, a11, a12, a13,
    // input signed [WIDTH-1:0] a20, a21, a22, a23,
    // input signed [WIDTH-1:0] a30, a31, a32, a33,
    // input signed [WIDTH-1:0] v0, v1, v2, v3,
    // output reg signed [WIDTH*2-1:0] y0,
    // output reg signed [WIDTH*2-1:0] y1,
    // output reg signed [WIDTH*2-1:0] y2,
    // output reg signed [WIDTH*2-1:0] y3,

    input wire signed [15:0] A [0:3][0:3]
    
    input wire signed [15:0] V [0:3]

    output reg signed [63:0] Y [0:3]
    output reg done
);

    reg [1:0] row;

    always @(posedge clk) begin
        if (start) begin
            row  <= 0;
            done <= 0;
        end else begin
            case (row)
                0: begin
                    Y[0] <= A[0][0]*V[0] + A[0][1]*V[1] + A[0][2]*V[2] + A[0][3]*V[3];
                    row <= 1;
                end
                1: begin
                    Y[1] <= A[1][0]*V[0] + A[1][1]*V[1] + A[1][2]*V[2] + A[1][3]*V[3];
                    row <= 2;
                end
                2: begin
                    Y[2] <= A[2][0]*V[0] + A[2][1]*V[1] + A[2][2]*V[2] + A[2][3]*V[3];
                    row <= 3;
                end
                3: begin
                    Y[3] <= A[3][0]*V[0] + A[3][1]*V[1] + A[3][2]*V[2] + A[3][3]*V[3];
                    done <= 1;
                end
            endcase
        end
    end

endmodule
