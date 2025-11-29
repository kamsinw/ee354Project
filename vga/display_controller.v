// display_controller.v - VGA rendering controller using rectangles only

module display_controller (
    input  wire [9:0] hcount,
    input  wire [9:0] vcount,
    input  wire visible,
    input  wire [1:0] edit_row,
    input  wire [1:0] edit_col,
    input  wire sw0,
    input  wire sw1,
    input  wire signed [15:0] matrix_a [0:3][0:3],
    input  wire signed [15:0] vector_v [0:3],
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

    wire [1:0] matrix_row = (py >= MATRIX_Y && py < MATRIX_Y + 4*CELL_HEIGHT) ? 
                            ((py - MATRIX_Y) / CELL_HEIGHT) : 2'b00;
    wire [1:0] matrix_col = (px >= MATRIX_X && px < MATRIX_X + 4*CELL_WIDTH) ? 
                            ((px - MATRIX_X) / CELL_WIDTH) : 2'b00;
    
    wire in_matrix_cell = (px >= MATRIX_X) && (px < MATRIX_X + 4*CELL_WIDTH) &&
                          (py >= MATRIX_Y) && (py < MATRIX_Y + 4*CELL_HEIGHT);
    
    wire [9:0] cell_x = px - MATRIX_X - (matrix_col * CELL_WIDTH);
    wire [9:0] cell_y = py - MATRIX_Y - (matrix_row * CELL_HEIGHT);

    wire in_vector_cell = (px >= VECTOR_X) && (px < VECTOR_X + CELL_WIDTH) &&
                          (py >= VECTOR_Y) && (py < VECTOR_Y + 4*CELL_HEIGHT);
    
    wire [1:0] vector_row = (py >= VECTOR_Y && py < VECTOR_Y + 4*CELL_HEIGHT) ?
                            ((py - VECTOR_Y) / CELL_HEIGHT) : 2'b00;
    
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

    wire signed [15:0] matrix_val = matrix_a[matrix_row][matrix_col];
    wire signed [15:0] vector_val = vector_v[vector_row];
    
    wire [15:0] matrix_abs = (matrix_val < 0) ? -matrix_val : matrix_val;
    wire [15:0] vector_abs = (vector_val < 0) ? -vector_val : vector_val;
    
    wire [3:0] matrix_hundreds = (matrix_abs >= 100) ? ((matrix_abs / 100) % 10) : 4'd0;
    wire [3:0] matrix_tens = (matrix_abs >= 10) ? ((matrix_abs / 10) % 10) : 4'd0;
    wire [3:0] matrix_ones = matrix_abs % 10;
    
    wire [3:0] vector_hundreds = (vector_abs >= 100) ? ((vector_abs / 100) % 10) : 4'd0;
    wire [3:0] vector_tens = (vector_abs >= 10) ? ((vector_abs / 10) % 10) : 4'd0;
    wire [3:0] vector_ones = vector_abs % 10;

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

    wire sign_bar_matrix = in_matrix_cell && (digit_area_x >= 0) && (digit_area_x < 8) &&
                           (digit_area_y >= DIGIT_HEIGHT/2 - 2) && (digit_area_y < DIGIT_HEIGHT/2 + 2) &&
                           (matrix_val < 0);
    
    wire sign_bar_vector = in_vector_cell && (vec_digit_area_x >= 0) && (vec_digit_area_x < 8) &&
                          (vec_digit_area_y >= DIGIT_HEIGHT/2 - 2) && (vec_digit_area_y < DIGIT_HEIGHT/2 + 2) &&
                          (vector_val < 0);

    always @(*) begin
        if (!visible) begin
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end else if (mode_box) begin
            if (sw0 == 1'b0) begin
                red = 4'b1111;
                green = 4'b1111;
                blue = 4'b0000;
            end else begin
                red = 4'b0000;
                green = 4'b1111;
                blue = 4'b0000;
            end
        end else if (cursor_border) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b0000;
        end else if (matrix_border || vector_border) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_matrix_cell && in_digit_area && matrix_digit_pixel) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (sign_bar_matrix) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_vector_cell && in_vec_digit_area && vector_digit_pixel) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (sign_bar_vector) begin
            red = 4'b1111;
            green = 4'b1111;
            blue = 4'b1111;
        end else if (in_matrix_cell) begin
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0100;
        end else if (in_vector_cell) begin
            red = 4'b0010;
            green = 4'b0010;
            blue = 4'b0010;
        end else begin
            red = 4'b0000;
            green = 4'b0000;
            blue = 4'b0000;
        end
    end

endmodule

