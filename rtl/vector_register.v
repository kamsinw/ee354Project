`timescale 1ns / 1ps

module vector_register #(
    parameter integer ELEM_WIDTH = 4
) (
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    load,
    input  wire [4*ELEM_WIDTH-1:0] vec_in,
    output reg  [4*ELEM_WIDTH-1:0] vec_out
);

    localparam [ELEM_WIDTH-1:0] INIT_VALUE = {{(ELEM_WIDTH-1){1'b0}}, 1'b1};
    wire [4*ELEM_WIDTH-1:0]     init_vector = {4{INIT_VALUE}};

    always @(posedge clk) begin
        if (reset) begin
            vec_out <= init_vector;
        end else if (load) begin
            vec_out <= vec_in;
        end
    end

endmodule
