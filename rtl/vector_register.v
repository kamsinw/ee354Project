`timescale 1ns / 1ps

module vector_register #(parameter ELEM_WIDTH = 4) (
    input  wire clk,
    input  wire reset,
    input  wire load,
    input  wire [4*ELEM_WIDTH-1:0] in,
    output reg  [4*ELEM_WIDTH-1:0] out
);

    localparam [ELEM_WIDTH-1:0] INIT_VALUE = 4'd1;
    wire [4*ELEM_WIDTH-1:0] init_vec = {INIT_VALUE, INIT_VALUE, INIT_VALUE, INIT_VALUE};

    always @(posedge clk) begin
        if (reset) begin
            out <= init_vec;
        end else if (load) begin
            out <= in;
        end
    end

endmodule
