`timescale 1ns / 1ps

// vga_top.v - 

module vga_top (
    input  wire clk_100mhz,
    input  wire reset,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire sw0,
    input  wire sw1,
    input  wire signed [255:0] matrix_a,
    input  wire signed [63:0] vector_v,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue
);

    reg [1:0] clk_div;
    wire clk_25mhz;
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            clk_div <= 2'b00;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end
    
    assign clk_25mhz = clk_div[0];  // Changed from [1] to [0] to divide by 2 instead of 4 (for 50MHz input clock)

    wire [9:0] hcount, vcount;
    wire visible;
    
    counter vga_counter (
        .clk(clk_25mhz),
        .reset(reset),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .visible(visible)
    );

    display_controller renderer (
        .hcount(hcount),
        .vcount(vcount),
        .visible(visible),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .sw0(sw0),
        .sw1(sw1),
        .matrix_a(matrix_a),
        .vector_v(vector_v),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );

endmodule
