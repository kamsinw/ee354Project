// vector_diff.v
// Computes max |v_new - v_old| for convergence test

module vector_diff #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      start,
    input  wire signed [WIDTH-1:0]   V_new [0:3],
    input  wire signed [WIDTH-1:0]   V_old [0:3],
    output reg  signed [WIDTH-1:0]   max_diff,
    output reg                       done
);

    wire signed [WIDTH-1:0] d [0:3];

    // compute per-element absolute differences using array-style abs_diff
    wire signed [WIDTH-1:0] d_in [0:3];
    abs_diff #(WIDTH) AD (
        .a(V_new),
        .b(V_old),
        .diff(d_in)
    );

    wire signed [WIDTH-1:0] maxv;
    max_finder #(WIDTH) MF (
        .a(d_in),
        .max_val(maxv)
    );

    always @(posedge clk) begin
        if (start) begin
            max_diff <= maxv;
            done     <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
