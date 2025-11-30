`timescale 1ns / 1ps

// display_controller.v - 

module display_controller (
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    input  wire visible,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire sw0,
    input  wire sw1,
    input  wire signed [255:0] matrix_a,
    input  wire signed [63:0] vector_v,
    output reg  [3:0] red,
    output reg  [3:0] green,
    output reg  [3:0] blue
);

    parameter MATRIX_X = 20;
    parameter MATRIX_Y = 60;
    parameter CELL_WIDTH = 140;
    parameter CELL_HEIGHT = 100;
    parameter VECTOR_X = 500;
    parameter VECTOR_Y = 60;
    parameter DIGIT_WIDTH = 50;
    parameter DIGIT_HEIGHT = 70;
    parameter DIGIT_SPACING = 8;
    parameter MODE_BOX_SIZE = 30;

    wire [9:0] px = hcount;
    wire [9:0] py = vcount;

    wire mode_box = (px >= 10) && (px < (10 + MODE_BOX_SIZE)) && 
                    (py >= 10) && (py < (10 + MODE_BOX_SIZE));

    wire [9:0] matrix_row_temp = (py >= MATRIX_Y && py < MATRIX_Y + 4*CELL_HEIGHT) ? 
                                  ((py - MATRIX_Y) / CELL_HEIGHT) : 10'd0;
    wire [1:0] matrix_row = matrix_row_temp[1:0];
    wire [9:0] matrix_col_temp = (px >= MATRIX_X && px < MATRIX_X + 4*CELL_WIDTH) ? 
                                 ((px - MATRIX_X) / CELL_WIDTH) : 10'd0;
    wire [1:0] matrix_col = matrix_col_temp[1:0];
    
    wire in_matrix_cell = (px >= MATRIX_X) && (px < MATRIX_X + 4*CELL_WIDTH) &&
                          (py >= MATRIX_Y) && (py < MATRIX_Y + 4*CELL_HEIGHT);
    
    wire [9:0] cell_x = px - MATRIX_X - (matrix_col * CELL_WIDTH);
    wire [9:0] cell_y = py - MATRIX_Y - (matrix_row * CELL_HEIGHT);

    wire in_vector_cell = (px >= VECTOR_X) && (px < VECTOR_X + CELL_WIDTH) &&
                          (py >= VECTOR_Y) && (py < VECTOR_Y + 4*CELL_HEIGHT);
    
    wire [9:0] vector_row_temp = (py >= VECTOR_Y && py < VECTOR_Y + 4*CELL_HEIGHT) ?
                                  ((py - VECTOR_Y) / CELL_HEIGHT) : 10'd0;
    wire [1:0] vector_row = vector_row_temp[1:0];
    
    wire [9:0] vec_cell_x = px - VECTOR_X;
    wire [9:0] vec_cell_y = py - VECTOR_Y - (vector_row * CELL_HEIGHT);

    wire cursor_matrix = (sw1 == 1'b0) && (matrix_row == edit_row) && (matrix_col == edit_col);
    wire cursor_vector = (sw1 == 1'b1) && (vector_row == edit_row);
    
    wire cursor_border = (cursor_matrix && (
                          (cell_x < 4) || (cell_x >= CELL_WIDTH - 4) ||
                          (cell_y < 4) || (cell_y >= CELL_HEIGHT - 4))) ||
                         (cursor_vector && (
                          (vec_cell_x < 4) || (vec_cell_x >= CELL_WIDTH - 4) ||
                          (vec_cell_y < 4) || (vec_cell_y >= CELL_HEIGHT - 4)));

    wire matrix_border = in_matrix_cell && (
                         (cell_x < 2) || (cell_x >= CELL_WIDTH - 2) ||
                         (cell_y < 2) || (cell_y >= CELL_HEIGHT - 2));
    
    wire vector_border = in_vector_cell && (
                         (vec_cell_x < 2) || (vec_cell_x >= CELL_WIDTH - 2) ||
                         (vec_cell_y < 2) || (vec_cell_y >= CELL_HEIGHT - 2));

    wire signed [15:0] matrix_a_unpack [0:3][0:3];
    assign matrix_a_unpack[0][0] = matrix_a[15:0];
    assign matrix_a_unpack[0][1] = matrix_a[31:16];
    assign matrix_a_unpack[0][2] = matrix_a[47:32];
    assign matrix_a_unpack[0][3] = matrix_a[63:48];
    assign matrix_a_unpack[1][0] = matrix_a[79:64];
    assign matrix_a_unpack[1][1] = matrix_a[95:80];
    assign matrix_a_unpack[1][2] = matrix_a[111:96];
    assign matrix_a_unpack[1][3] = matrix_a[127:112];
    assign matrix_a_unpack[2][0] = matrix_a[143:128];
    assign matrix_a_unpack[2][1] = matrix_a[159:144];
    assign matrix_a_unpack[2][2] = matrix_a[175:160];
    assign matrix_a_unpack[2][3] = matrix_a[191:176];
    assign matrix_a_unpack[3][0] = matrix_a[207:192];
    assign matrix_a_unpack[3][1] = matrix_a[223:208];
    assign matrix_a_unpack[3][2] = matrix_a[239:224];
    assign matrix_a_unpack[3][3] = matrix_a[255:240];

    wire signed [15:0] vector_v_unpack [0:3];
    assign vector_v_unpack[0] = vector_v[15:0];
    assign vector_v_unpack[1] = vector_v[31:16];
    assign vector_v_unpack[2] = vector_v[47:32];
    assign vector_v_unpack[3] = vector_v[63:48];

    wire signed [15:0] matrix_val = matrix_a_unpack[matrix_row][matrix_col];
    wire signed [15:0] vector_val = vector_v_unpack[vector_row];
    
    wire [15:0] matrix_abs = (matrix_val < 0) ? -matrix_val : matrix_val;
    wire [15:0] vector_abs = (vector_val < 0) ? -vector_val : vector_val;
    
    // Simplified digit extraction using comparisons instead of division
    // Matrix hundreds digit (0-9)
    wire [3:0] matrix_hundreds = 
        (matrix_abs >= 900) ? 4'd9 :
        (matrix_abs >= 800) ? 4'd8 :
        (matrix_abs >= 700) ? 4'd7 :
        (matrix_abs >= 600) ? 4'd6 :
        (matrix_abs >= 500) ? 4'd5 :
        (matrix_abs >= 400) ? 4'd4 :
        (matrix_abs >= 300) ? 4'd3 :
        (matrix_abs >= 200) ? 4'd2 :
        (matrix_abs >= 100) ? 4'd1 : 4'd0;
    
    // Matrix remainder after hundreds (0-99)
    // Optimize: 100 = 64 + 32 + 4 = (x << 6) + (x << 5) + (x << 2)
    wire [15:0] matrix_hundreds_100 = ({12'd0, matrix_hundreds} << 6) + ({12'd0, matrix_hundreds} << 5) + ({12'd0, matrix_hundreds} << 2);
    wire [15:0] matrix_rem_h = matrix_abs - matrix_hundreds_100;
    
    // Matrix tens digit (0-9)
    wire [3:0] matrix_tens = 
        (matrix_rem_h >= 90) ? 4'd9 :
        (matrix_rem_h >= 80) ? 4'd8 :
        (matrix_rem_h >= 70) ? 4'd7 :
        (matrix_rem_h >= 60) ? 4'd6 :
        (matrix_rem_h >= 50) ? 4'd5 :
        (matrix_rem_h >= 40) ? 4'd4 :
        (matrix_rem_h >= 30) ? 4'd3 :
        (matrix_rem_h >= 20) ? 4'd2 :
        (matrix_rem_h >= 10) ? 4'd1 : 4'd0;
    
    // Matrix ones digit (0-9)
    // Optimize: 10 = 8 + 2 = (x << 3) + (x << 1)
    wire [15:0] matrix_tens_10 = ({12'd0, matrix_tens} << 3) + ({12'd0, matrix_tens} << 1);
    wire [15:0] matrix_ones_temp = matrix_rem_h - matrix_tens_10;
    wire [3:0] matrix_ones = matrix_ones_temp[3:0];
    
    // Vector hundreds digit (0-9)
    wire [3:0] vector_hundreds = 
        (vector_abs >= 900) ? 4'd9 :
        (vector_abs >= 800) ? 4'd8 :
        (vector_abs >= 700) ? 4'd7 :
        (vector_abs >= 600) ? 4'd6 :
        (vector_abs >= 500) ? 4'd5 :
        (vector_abs >= 400) ? 4'd4 :
        (vector_abs >= 300) ? 4'd3 :
        (vector_abs >= 200) ? 4'd2 :
        (vector_abs >= 100) ? 4'd1 : 4'd0;
    
    // Vector remainder after hundreds (0-99)
    // Optimize: 100 = 64 + 32 + 4 = (x << 6) + (x << 5) + (x << 2)
    wire [15:0] vector_hundreds_100 = ({12'd0, vector_hundreds} << 6) + ({12'd0, vector_hundreds} << 5) + ({12'd0, vector_hundreds} << 2);
    wire [15:0] vector_rem_h = vector_abs - vector_hundreds_100;
    
    // Vector tens digit (0-9)
    wire [3:0] vector_tens = 
        (vector_rem_h >= 90) ? 4'd9 :
        (vector_rem_h >= 80) ? 4'd8 :
        (vector_rem_h >= 70) ? 4'd7 :
        (vector_rem_h >= 60) ? 4'd6 :
        (vector_rem_h >= 50) ? 4'd5 :
        (vector_rem_h >= 40) ? 4'd4 :
        (vector_rem_h >= 30) ? 4'd3 :
        (vector_rem_h >= 20) ? 4'd2 :
        (vector_rem_h >= 10) ? 4'd1 : 4'd0;
    
    // Vector ones digit (0-9)
    // Optimize: 10 = 8 + 2 = (x << 3) + (x << 1)
    wire [15:0] vector_tens_10 = ({12'd0, vector_tens} << 3) + ({12'd0, vector_tens} << 1);
    wire [15:0] vector_ones_temp = vector_rem_h - vector_tens_10;
    wire [3:0] vector_ones = vector_ones_temp[3:0];

    wire [9:0] digit_area_x = (cell_x >= 10) ? (cell_x - 10) : 0;
    wire [9:0] digit_area_y = (cell_y >= 10) ? (cell_y - 10) : 0;
    wire in_digit_area = (digit_area_x < 3*DIGIT_WIDTH + 2*DIGIT_SPACING) &&
                         (digit_area_y < DIGIT_HEIGHT);
    
    wire [9:0] matrix_digit_base_x;
    wire [3:0] matrix_digit_val;
    
    assign matrix_digit_base_x = (digit_area_x < DIGIT_WIDTH) ? (MATRIX_X + matrix_col * CELL_WIDTH + 10) :
                                 (digit_area_x < DIGIT_WIDTH + DIGIT_SPACING + DIGIT_WIDTH) ? 
                                 (MATRIX_X + matrix_col * CELL_WIDTH + 10 + DIGIT_WIDTH + DIGIT_SPACING) :
                                 (MATRIX_X + matrix_col * CELL_WIDTH + 10 + 2*DIGIT_WIDTH + 2*DIGIT_SPACING);
    
    assign matrix_digit_val = (digit_area_x < DIGIT_WIDTH) ? matrix_hundreds :
                             (digit_area_x < DIGIT_WIDTH + DIGIT_SPACING + DIGIT_WIDTH) ? matrix_tens :
                             (digit_area_x < 2*DIGIT_WIDTH + 2*DIGIT_SPACING + DIGIT_WIDTH) ? matrix_ones : 4'd0;
    
    wire matrix_digit_pixel;
    block_digit_renderer #(
        .DIGIT_WIDTH(DIGIT_WIDTH),
        .DIGIT_HEIGHT(DIGIT_HEIGHT)
    ) matrix_digit (
        .digit(matrix_digit_val),
        .px(px),
        .py(py),
        .base_x(matrix_digit_base_x),
        .base_y(MATRIX_Y + matrix_row * CELL_HEIGHT + 10),
        .pixel_on(matrix_digit_pixel)
    );

    wire [9:0] vec_digit_area_x = (vec_cell_x >= 10) ? (vec_cell_x - 10) : 0;
    wire [9:0] vec_digit_area_y = (vec_cell_y >= 10) ? (vec_cell_y - 10) : 0;
    
    wire [3:0] vector_digit_val;
    wire [9:0] vector_digit_base_x;
    
    assign vector_digit_base_x = (vec_digit_area_x < DIGIT_WIDTH) ? (VECTOR_X + 10) :
                                 (vec_digit_area_x < DIGIT_WIDTH + DIGIT_SPACING + DIGIT_WIDTH) ? 
                                 (VECTOR_X + 10 + DIGIT_WIDTH + DIGIT_SPACING) :
                                 (VECTOR_X + 10 + 2*DIGIT_WIDTH + 2*DIGIT_SPACING);
    
    assign vector_digit_val = (vec_digit_area_x < DIGIT_WIDTH) ? vector_hundreds :
                             (vec_digit_area_x < DIGIT_WIDTH + DIGIT_SPACING + DIGIT_WIDTH) ? vector_tens :
                             (vec_digit_area_x < 2*DIGIT_WIDTH + 2*DIGIT_SPACING + DIGIT_WIDTH) ? vector_ones : 4'd0;
    
    wire vector_digit_pixel;
    wire in_vec_digit_area = (vec_digit_area_x < 3*DIGIT_WIDTH + 2*DIGIT_SPACING) &&
                             (vec_digit_area_y < DIGIT_HEIGHT);
    
    block_digit_renderer #(
        .DIGIT_WIDTH(DIGIT_WIDTH),
        .DIGIT_HEIGHT(DIGIT_HEIGHT)
    ) vector_digit (
        .digit(vector_digit_val),
        .px(px),
        .py(py),
        .base_x(vector_digit_base_x),
        .base_y(VECTOR_Y + vector_row * CELL_HEIGHT + 10),
        .pixel_on(vector_digit_pixel)
    );

    /* verilator lint_off UNSIGNED */
    wire sign_bar_matrix = in_matrix_cell && (digit_area_x >= 0) && (digit_area_x < 8) &&
                           (digit_area_y >= DIGIT_HEIGHT/2 - 2) && (digit_area_y < DIGIT_HEIGHT/2 + 2) &&
                           (matrix_val < 0);
    
    wire sign_bar_vector = in_vector_cell && (vec_digit_area_x >= 0) && (vec_digit_area_x < 8) &&
                          (vec_digit_area_y >= DIGIT_HEIGHT/2 - 2) && (vec_digit_area_y < DIGIT_HEIGHT/2 + 2) &&
                          (vector_val < 0);
    /* verilator lint_on UNSIGNED */

    // Combine conditions with same outputs for better timing
    wire white_pixel = (matrix_border || vector_border) ||
                       (in_matrix_cell && in_digit_area && matrix_digit_pixel) ||
                       sign_bar_matrix ||
                       (in_vector_cell && in_vec_digit_area && vector_digit_pixel) ||
                       sign_bar_vector;
    
    wire yellow_pixel = cursor_border || (mode_box && (sw0 == 1'b0));
    wire green_pixel = mode_box && (sw0 == 1'b1);

    always @(*) begin
        if (!visible) begin
            // Black when not visible
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end else if (white_pixel) begin
            // White for borders, digits, and sign bars
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (yellow_pixel) begin
            // Yellow for cursor border or edit mode box
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b0000;
        end else if (green_pixel) begin
            // Green for run mode box
            red = 4'b0000;
            green = 4'b1111;
            blue = 4'b0000;
        end else if (in_matrix_cell) begin
            // Blue background for matrix cells
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0100;
        end else if (in_vector_cell) begin
            // Gray background for vector cells
            red = 4'b0010;
            green = 4'b0010;
            blue = 4'b0010;
        end else begin
            // Black background
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end
    end

endmodule

