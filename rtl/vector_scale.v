`timescale 1ns / 1ps

// vector_scale.v - 
module vector_scale #(parameter WIDTH = 64) (
    input  wire                      clk,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_in,
    output reg  signed [4*WIDTH-1:0] V_out,
    output reg                       done
);

    wire signed [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        .a(V_in),
        .max_val(max_val)
    );

    wire signed [WIDTH-1:0] V_in0 = V_in[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_in1 = V_in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_in2 = V_in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_in3 = V_in[4*WIDTH-1:3*WIDTH];

    always @(posedge clk) begin
        if (start) begin
            V_out <= {V_in3 >>> 1, V_in2 >>> 1, V_in1 >>> 1, V_in0 >>> 1};
            done <= 1;
        end else begin
            done <= 0;
        end
    end

endmodule
