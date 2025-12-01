`timescale 1ns / 1ps

module vector_register #(parameter WIDTH = 16) (
    input  wire clk,
    input  wire reset,
    input  wire load,
    input  wire signed [4*WIDTH-1:0] in,
    output reg  signed [4*WIDTH-1:0] out
);

    wire signed [WIDTH-1:0] init_vec0 = 16'sd1;
    wire signed [WIDTH-1:0] init_vec1 = 16'sd1;
    wire signed [WIDTH-1:0] init_vec2 = 16'sd1;
    wire signed [WIDTH-1:0] init_vec3 = 16'sd1;
    wire signed [4*WIDTH-1:0] init_vec = {init_vec3, init_vec2, init_vec1, init_vec0};

    always @(posedge clk) begin
        if (reset) begin
            out <= init_vec;
        end else if (load) begin
            out <= in;
        end
    end

endmodule
