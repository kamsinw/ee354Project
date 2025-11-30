`timescale 1ns / 1ps

// vector_register.v - 

module vector_register #(parameter WIDTH = 16) (
    input  wire clk,
    input  wire reset,
    input  wire load,
    input  wire signed [4*WIDTH-1:0] in,
    output reg  signed [4*WIDTH-1:0] out
);

    always @(posedge clk) begin
        if (reset) begin
            out <= {(4*WIDTH){1'b0}};
        end else if (load) begin
            out <= in;
        end
    end

endmodule
