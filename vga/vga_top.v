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

    // Clock is now 25MHz directly, no division needed
    wire clk_25mhz = clk_100mhz;  // Input clock is now 25MHz (40ns period)

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

    wire [3:0] red_comb, green_comb, blue_comb;
    
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
        .red(red_comb),
        .green(green_comb),
        .blue(blue_comb)
    );
    
    // Register VGA outputs to prevent glitches (single output register allowed per spec)
    reg [3:0] vga_red_reg, vga_green_reg, vga_blue_reg;
    
    always @(posedge clk_25mhz) begin
        if (reset) begin
            vga_red_reg <= 4'b0000;
            vga_green_reg <= 4'b0000;
            vga_blue_reg <= 4'b0000;
        end else begin
            vga_red_reg <= red_comb;
            vga_green_reg <= green_comb;
            vga_blue_reg <= blue_comb;
        end
    end
    
    assign vga_red = vga_red_reg;
    assign vga_green = vga_green_reg;
    assign vga_blue = vga_blue_reg;

endmodule
