`timescale 1ns / 1ps

// vga_top.v - VGA top module following EE354_vga_demo pattern

module vga_top (
    input  wire clk_100mhz,
    input  wire reset,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire cell_locked,
    input  wire sw0,
    input  wire sw1,
    input  wire [2:0] sw_eps,
    input  wire [63:0] matrix_a,
    input  wire [15:0] vector_v,
    input  wire [7:0] fsm_state,
    input  wire fsm_done,
    input  wire [7:0] iteration_count,
    input  wire [15:0] v_old,
    input  wire [15:0] v_new,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_red,
    output wire [3:0] vga_green,
    output wire [3:0] vga_blue
);

    // Simple clock divider: 100 MHz -> 25 MHz (divide by 4)
    // Following demo pattern: two-stage toggle divider
    reg pulse;
    reg clk25;
    
    initial begin
        pulse = 1'b0;
        clk25 = 1'b0;
    end
    
    always @(posedge clk_100mhz)
        pulse <= ~pulse;
    
    always @(posedge pulse)
        clk25 <= ~clk25;

    wire bright;
    wire [9:0] hCount, vCount;
    wire [11:0] rgb;
    
    // VGA timing generator (matches demo's display_controller)
    counter vga_counter (
        .clk(clk25),
        .hSync(vga_hsync),
        .vSync(vga_vsync),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount)
    );

    // Display renderer 
    display_controller renderer (
        .clk(clk25),
        .bright(bright),
        .hCount(hCount),
        .vCount(vCount),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .cell_locked(cell_locked),
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
        .rgb(rgb)
    );
    
    assign vga_red = rgb[11:8];
    assign vga_green = rgb[7:4];
    assign vga_blue = rgb[3:0];

endmodule
