// max_finder.v

module max_finder #(parameter WIDTH = 16) (
    input  wire signed [WIDTH-1:0] a [0:3],
    output wire signed [WIDTH-1:0] max_val
);

    wire signed [WIDTH-1:0] abs_a [0:3];
    assign abs_a[0] = (a[0] < 0) ? -a[0] : a[0];
    assign abs_a[1] = (a[1] < 0) ? -a[1] : a[1];
    assign abs_a[2] = (a[2] < 0) ? -a[2] : a[2];
    assign abs_a[3] = (a[3] < 0) ? -a[3] : a[3];

    wire signed [WIDTH-1:0] m0 = (abs_a[0] > abs_a[1]) ? abs_a[0] : abs_a[1];
    wire signed [WIDTH-1:0] m1 = (abs_a[2] > abs_a[3]) ? abs_a[2] : abs_a[3];

    assign max_val = (m0 > m1) ? m0 : m1;

endmodule
