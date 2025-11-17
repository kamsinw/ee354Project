// matrix_vector_mult.v
// Computes y = A * v using 1 row per clock

module matrix_vector_mult #(parameter WIDTH = 16) (
    input clk,
    input start,
    input signed [WIDTH-1:0] a00, a01, a02, a03,
    input signed [WIDTH-1:0] a10, a11, a12, a13,
    input signed [WIDTH-1:0] a20, a21, a22, a23,
    input signed [WIDTH-1:0] a30, a31, a32, a33,
    input signed [WIDTH-1:0] v0, v1, v2, v3,
    output reg signed [WIDTH-1:0] y0,
    output reg signed [WIDTH-1:0] y1,
    output reg signed [WIDTH-1:0] y2,
    output reg signed [WIDTH-1:0] y3,
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
                    y0 <= a00*v0 + a01*v1 + a02*v2 + a03*v3;
                    row <= 1;
                end
                1: begin
                    y1 <= a10*v0 + a11*v1 + a12*v2 + a13*v3;
                    row <= 2;
                end
                2: begin
                    y2 <= a20*v0 + a21*v1 + a22*v2 + a23*v3;
                    row <= 3;
                end
                3: begin
                    y3 <= a30*v0 + a31*v1 + a32*v2 + a33*v3;
                    done <= 1;
                end
            endcase
        end
    end

endmodule
