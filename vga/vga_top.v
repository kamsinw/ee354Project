`timescale 1ns / 1ps

// vga_top.v - 

module vga_top (
    input  wire clk_100mhz,
    input  wire reset,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire sw0,
    input  wire sw1,
    input  wire [2:0] sw_eps,
    input  wire signed [255:0] matrix_a,
    input  wire signed [63:0] vector_v,
    input  wire [6:0] fsm_state,
    input  wire fsm_done,
    input  wire [7:0] iteration_count,
    input  wire signed [63:0] v_old,
    input  wire signed [63:0] v_new,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue
);

    // Divide 62.5 MHz down to 25 MHz (divide by 2.5)
    // Input: 62.5 MHz (16ns period), Output: 25 MHz (40ns period)
    // Use a 5-state counter (0-4) and toggle at states 0 and 2
    // This gives 2.5 input cycles per output cycle
    reg clk_25mhz_reg;
    reg [2:0] clk_div_counter;
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            clk_25mhz_reg <= 1'b0;
            clk_div_counter <= 3'd0;
        end else begin
            if (clk_div_counter == 3'd0 || clk_div_counter == 3'd2) begin
                clk_25mhz_reg <= ~clk_25mhz_reg;
            end
            if (clk_div_counter == 3'd4) begin
                clk_div_counter <= 3'd0;
            end else begin
                clk_div_counter <= clk_div_counter + 1'b1;
            end
        end
    end
    
    wire clk_25mhz = clk_25mhz_reg;

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
        .sw_eps(sw_eps),
        .matrix_a(matrix_a),
        .vector_v(vector_v),
        .fsm_state(fsm_state),
        .fsm_done(fsm_done),
        .iteration_count(iteration_count),
        .v_old(v_old),
        .v_new(v_new),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );

endmodule
