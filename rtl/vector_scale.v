// vector_scale.v

module vector_scale #(parameter WIDTH = 64) (
    input  wire                      clk,
    input  wire                      start,
    input  wire signed [WIDTH-1:0]   V_in  [0:3],
    output reg  signed [WIDTH-1:0]   V_out [0:3],
    output reg                       done
);

    wire signed [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        .a(V_in),
        .max_val(max_val)
    );

    integer i;
    always @(posedge clk) begin
        if (start) begin
            for (i = 0; i < 4; i = i + 1)
                V_out[i] <= V_in[i] >>> 1;
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
