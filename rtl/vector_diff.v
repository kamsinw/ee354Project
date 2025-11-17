// vector_diff.v
// Computes max |v_new - v_old| for convergence test

module vector_diff #(parameter WIDTH = 16) (
    input clk,
    input start,
    input signed [WIDTH-1:0] v0_new,
    input signed [WIDTH-1:0] v1_new,
    input signed [WIDTH-1:0] v2_new,
    input signed [WIDTH-1:0] v3_new,
    input signed [WIDTH-1:0] v0_old,
    input signed [WIDTH-1:0] v1_old,
    input signed [WIDTH-1:0] v2_old,
    input signed [WIDTH-1:0] v3_old,
    output reg signed [WIDTH-1:0] max_diff,
    output reg done
);

    wire signed [WIDTH-1:0] d0, d1, d2, d3;

    abs_diff #(WIDTH) D0(v0_new, v0_old, d0);
    abs_diff #(WIDTH) D1(v1_new, v1_old, d1);
    abs_diff #(WIDTH) D2(v2_new, v2_old, d2);
    abs_diff #(WIDTH) D3(v3_new, v3_old, d3);

    wire signed [WIDTH-1:0] maxv;

    max_finder #(WIDTH) MF(d0, d1, d2, d3, maxv);

    always @(posedge clk) begin
        if (start) begin
            max_diff <= maxv;
            done     <= 1;
        end
    end

endmodule
