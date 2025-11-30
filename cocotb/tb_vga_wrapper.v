`timescale 1ns / 1ps

module tb_vga_wrapper;

    parameter CLK_PERIOD = 40;  // 25MHz clock (40ns period)
    
    reg clk_100mhz;
    reg reset;
    reg [1:0] edit_row;
    reg [1:0] edit_col;
    reg sw0;
    reg sw1;
    reg signed [255:0] matrix_a;
    reg signed [63:0] vector_v;
    
    wire vga_hsync;
    wire vga_vsync;
    wire [3:0] vga_red;
    wire [3:0] vga_green;
    wire [3:0] vga_blue;
    
    vga_top uut (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .sw0(sw0),
        .sw1(sw1),
        .matrix_a(matrix_a),
        .vector_v(vector_v),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );

endmodule

