`timescale 1ns / 1ps

module top_eigenvector (
    input  wire        clk,
    input  wire        reset,
    input  wire        sw0,
    input  wire        sw1,
    input  wire [2:0]  sw_eps,
    input  wire        btnl,
    input  wire        btnr,
    input  wire        btnu,
    input  wire        btnd,
    input  wire        btnc,
    output wire [7:0]  led,
    output wire        ca, cb, cc, cd, ce, cf, cg, dp,
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_red,
    output wire [3:0]  vga_green,
    output wire [3:0]  vga_blue
);

    reg [19:0] clk_div;
    wire clk_1k;
    
    always @(posedge clk) begin
        if (reset) begin
            clk_div <= 20'd0;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end
    
    assign clk_1k = clk_div[16];
    reg btnl_r, btnr_r, btnu_r, btnd_r, btnc_r;
    reg btnl_d, btnr_d, btnu_d, btnd_d, btnc_d;
    reg btnl_pulse, btnr_pulse, btnu_pulse, btnd_pulse, btnc_pulse;
    
    always @(posedge clk_1k) begin
        if (reset) begin
            btnl_r <= 1'b0;
            btnr_r <= 1'b0;
            btnu_r <= 1'b0;
            btnd_r <= 1'b0;
            btnc_r <= 1'b0;
            btnl_d <= 1'b0;
            btnr_d <= 1'b0;
            btnu_d <= 1'b0;
            btnd_d <= 1'b0;
            btnc_d <= 1'b0;
            btnl_pulse <= 1'b0;
            btnr_pulse <= 1'b0;
            btnu_pulse <= 1'b0;
            btnd_pulse <= 1'b0;
            btnc_pulse <= 1'b0;
        end else begin
            btnl_r <= btnl;
            btnr_r <= btnr;
            btnu_r <= btnu;
            btnd_r <= btnd;
            btnc_r <= btnc;
            btnl_d <= btnl_r;
            btnr_d <= btnr_r;
            btnu_d <= btnu_r;
            btnd_d <= btnd_r;
            btnc_d <= btnc_r;
            btnl_pulse <= btnl_r & ~btnl_d;
            btnr_pulse <= btnr_r & ~btnr_d;
            btnu_pulse <= btnu_r & ~btnu_d;
            btnd_pulse <= btnd_r & ~btnd_d;
            btnc_pulse <= btnc_r & ~btnc_d;
        end
    end
    
    reg [1:0] edit_row;
    reg [1:0] edit_col;
    reg signed [15:0] edit_val;
    reg signed [15:0] matrix_a [0:3][0:3];
    reg signed [15:0] vector_v [0:3];
    
    // Next-state logic for edit_row and edit_col (combinational)
    // MUST be declared as reg since assigned in always block
    reg [1:0] next_edit_row;
    reg [1:0] next_edit_col;
    
    // Next-state logic for matrix_a and vector_v (combinational)
    // MUST be declared as reg arrays since assigned in always block
    reg signed [15:0] next_matrix_a [0:3][0:3];
    reg signed [15:0] next_vector_v [0:3];
    
    // SINGLE always @(*) block for next-state computation (edit_row/edit_col)
    always @(*) begin
        // Default: keep current values
        next_edit_row = edit_row;
        next_edit_col = edit_col;
        
        if (~sw0) begin
            // Handle row changes
            if (btnu_pulse) begin
                if (edit_row > 2'b00)
                    next_edit_row = edit_row - 1'b1;
            end else if (btnd_pulse) begin
                if (edit_row < 2'b11)
                    next_edit_row = edit_row + 1'b1;
            end
            
            // Handle column changes
            if (btnl_pulse) begin
                if (edit_col > 2'b00)
                    next_edit_col = edit_col - 1'b1;
            end else if (btnr_pulse) begin
                if (edit_col < 2'b11)
                    next_edit_col = edit_col + 1'b1;
            end
        end
        // In run mode (sw0 == 1), keep current values (already set as default)
    end
    
    // SINGLE always @(*) block for next-state computation (matrix_a/vector_v)
    integer i, j;
    always @(*) begin
        // Default: keep all current values
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                next_matrix_a[i][j] = matrix_a[i][j];
            end
            next_vector_v[i] = vector_v[i];
        end
        
        if (reset) begin
            // Initialize on reset
            next_matrix_a[0][0] = 16'sd4; next_matrix_a[0][1] = 16'sd1; next_matrix_a[0][2] = 16'sd1; next_matrix_a[0][3] = 16'sd1;
            next_matrix_a[1][0] = 16'sd1; next_matrix_a[1][1] = 16'sd4; next_matrix_a[1][2] = 16'sd1; next_matrix_a[1][3] = 16'sd1;
            next_matrix_a[2][0] = 16'sd1; next_matrix_a[2][1] = 16'sd1; next_matrix_a[2][2] = 16'sd4; next_matrix_a[2][3] = 16'sd1;
            next_matrix_a[3][0] = 16'sd1; next_matrix_a[3][1] = 16'sd1; next_matrix_a[3][2] = 16'sd1; next_matrix_a[3][3] = 16'sd4;
            for (i = 0; i < 4; i = i + 1) begin
                next_vector_v[i] = 16'sd1;
            end
        end else if (~sw0 && btnc_pulse) begin
            // Edit mode: update the edited cell
            if (sw1 == 1'b0) begin
                // Edit matrix
                next_matrix_a[edit_row][edit_col] = edit_val;
            end else begin
                // Edit vector
                next_vector_v[edit_row] = edit_val;
            end
        end
    end
    
    // SINGLE always block for edit_row and edit_col state update
    always @(posedge clk_1k) begin
        if (reset) begin
            edit_row <= 2'b00;
            edit_col <= 2'b00;
        end else begin
            edit_row <= next_edit_row;
            edit_col <= next_edit_col;
        end
    end
    
    // edit_val updates (separate from edit_row/edit_col)
    always @(posedge clk_1k) begin
        if (reset) begin
            edit_val <= 16'sd0;
        end else if (~sw0) begin
            if (btnl_pulse) begin
                edit_val <= edit_val - 16'sd1;
            end else if (btnr_pulse) begin
                edit_val <= edit_val + 16'sd1;
            end
        end
    end
    
    reg sw0_prev, sw1_prev;
    reg [1:0] edit_row_prev;
    
    always @(posedge clk) begin
        if (reset) begin
            sw0_prev <= 1'b0;
            sw1_prev <= 1'b0;
            edit_row_prev <= 2'b00;
        end else begin
            sw0_prev <= sw0;
            sw1_prev <= sw1;
            edit_row_prev <= edit_row;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            edit_val <= 16'sd0;
        end else if (~sw0) begin
            if ((sw0_prev & ~sw0) || (sw1_prev != sw1) || (edit_row_prev != edit_row)) begin
                if (sw1 == 1'b0) begin
                    edit_val <= matrix_a[edit_row][edit_col];
                end else begin
                    edit_val <= vector_v[edit_row];
                end
            end
        end
    end
    
    // SINGLE always block for matrix_a and vector_v state update
    // Updates from next_matrix_a/next_vector_v (which handles reset, edit mode, etc.)
    integer k, l;
    always @(posedge clk) begin
        // Update all elements from next-state (next-state logic handles reset and edits)
        for (k = 0; k < 4; k = k + 1) begin
            for (l = 0; l < 4; l = l + 1) begin
                matrix_a[k][l] <= next_matrix_a[k][l];
            end
            vector_v[k] <= next_vector_v[k];
        end
    end
    
    wire fsm_done;
    wire load_v_old, load_y, load_max_d;
    wire start_mult, start_scale, start_diff;
    wire mul_done, scale_done, diff_done;
    wire signed [15:0] max_d_out;
    wire signed [63:0] v_out;
    
    reg sw0_r;
    wire sw0_edge;
    
    always @(posedge clk) begin
        if (reset) begin
            sw0_r <= 1'b0;
        end else begin
            sw0_r <= sw0;
        end
    end
    
    assign sw0_edge = sw0 & ~sw0_r;
    
    dominant_fsm fsm_inst (
        .clk(clk),
        .reset(reset),
        .start(sw0_edge),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_in(max_d_out),
        .epsilon(sw_eps),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .done(fsm_done)
    );
    
    dominant_datapath datapath_inst (
        .clk(clk),
        .reset(reset),
        .load_v_old(load_v_old),
        .load_y(load_y),
        .load_max_d(load_max_d),
        .start_mult(start_mult),
        .start_scale(start_scale),
        .start_diff(start_diff),
        .A00(matrix_a[0][0]),
        .A01(matrix_a[0][1]),
        .A02(matrix_a[0][2]),
        .A03(matrix_a[0][3]),
        .A10(matrix_a[1][0]),
        .A11(matrix_a[1][1]),
        .A12(matrix_a[1][2]),
        .A13(matrix_a[1][3]),
        .A20(matrix_a[2][0]),
        .A21(matrix_a[2][1]),
        .A22(matrix_a[2][2]),
        .A23(matrix_a[2][3]),
        .A30(matrix_a[3][0]),
        .A31(matrix_a[3][1]),
        .A32(matrix_a[3][2]),
        .A33(matrix_a[3][3]),
        .mul_done(mul_done),
        .scale_done(scale_done),
        .diff_done(diff_done),
        .max_d_out(max_d_out),
        .v0(v_out[15:0]),
        .v1(v_out[31:16]),
        .v2(v_out[47:32]),
        .v3(v_out[63:48])
    );
    
    assign led[0] = fsm_done;
    assign led[1] = mul_done;
    assign led[2] = scale_done;
    assign led[3] = diff_done;
    assign led[4] = sw0;
    assign led[5] = sw1;
    assign led[7:6] = 2'b00;
    
    assign ca = 1'b1;
    assign cb = 1'b1;
    assign cc = 1'b1;
    assign cd = 1'b1;
    assign ce = 1'b1;
    assign cf = 1'b1;
    assign cg = 1'b1;
    assign dp = 1'b1;
    
    wire signed [16*16-1:0] matrix_a_packed;
    assign matrix_a_packed = {matrix_a[3][3], matrix_a[3][2], matrix_a[3][1], matrix_a[3][0],
                              matrix_a[2][3], matrix_a[2][2], matrix_a[2][1], matrix_a[2][0],
                              matrix_a[1][3], matrix_a[1][2], matrix_a[1][1], matrix_a[1][0],
                              matrix_a[0][3], matrix_a[0][2], matrix_a[0][1], matrix_a[0][0]};

    wire signed [4*16-1:0] vector_v_packed;
    assign vector_v_packed = {vector_v[3], vector_v[2], vector_v[1], vector_v[0]};

    vga_top vga_display (
        .clk_100mhz(clk),
        .reset(reset),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .sw0(sw0),
        .sw1(sw1),
        .matrix_a(matrix_a_packed),
        .vector_v(vector_v_packed),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );
    
endmodule
