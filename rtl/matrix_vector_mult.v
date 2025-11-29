// matrix_vector_mult.v

module matrix_vector_mult (
    input  wire        clk,
    input  wire        start,
    input  wire signed [15:0] A [0:3][0:3],
    input  wire signed [15:0] V [0:3],
    output reg  signed [15:0] Y [0:3],
    output reg         done
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
                    done <= 0;
                end
                1: begin
                    Y[1] <= A[1][0]*V[0] + A[1][1]*V[1] + A[1][2]*V[2] + A[1][3]*V[3];
                    row <= 2;
                    done <= 0;
                end
                2: begin
                    Y[2] <= A[2][0]*V[0] + A[2][1]*V[1] + A[2][2]*V[2] + A[2][3]*V[3];
                    row <= 3;
                    done <= 0;
                end
                3: begin
                    Y[3] <= A[3][0]*V[0] + A[3][1]*V[1] + A[3][2]*V[2] + A[3][3]*V[3];
                    done <= 1;
                end
            endcase
        end
    end

endmodule
