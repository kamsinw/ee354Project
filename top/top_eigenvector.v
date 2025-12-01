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
    output wire        an0, an1, an2, an3, an4, an5, an6, an7,
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_red,
    output wire [3:0]  vga_green,
    output wire [3:0]  vga_blue
);

    // CPU_RESET on Nexys A7 is active-low (pressed=0, released=1)
    // Invert to get active-high reset for internal logic
    wire reset_internal = ~reset;
    
    // Button debouncing on main clock (clk = 100 MHz)
    // Using longer shift registers for reliable debouncing at higher frequency
    reg [15:0] btnl_sr, btnr_sr, btnu_sr, btnd_sr, btnc_sr;
    reg btnl_stable, btnr_stable, btnu_stable, btnd_stable, btnc_stable;
    reg btnl_d, btnr_d, btnu_d, btnd_d, btnc_d;
    reg btnl_pulse, btnr_pulse, btnu_pulse, btnd_pulse, btnc_pulse;
    
    always @(posedge clk) begin
        if (reset_internal) begin
            btnl_sr <= 16'd0;
            btnr_sr <= 16'd0;
            btnu_sr <= 16'd0;
            btnd_sr <= 16'd0;
            btnc_sr <= 16'd0;
            btnl_stable <= 1'b0;
            btnr_stable <= 1'b0;
            btnu_stable <= 1'b0;
            btnd_stable <= 1'b0;
            btnc_stable <= 1'b0;
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
            // Shift in new button values
            btnl_sr <= {btnl_sr[14:0], btnl};
            btnr_sr <= {btnr_sr[14:0], btnr};
            btnu_sr <= {btnu_sr[14:0], btnu};
            btnd_sr <= {btnd_sr[14:0], btnd};
            btnc_sr <= {btnc_sr[14:0], btnc};
            
            // Button is stable if all bits in shift register are the same
            btnl_stable <= (btnl_sr == 16'hFFFF) ? 1'b1 : (btnl_sr == 16'h0000) ? 1'b0 : btnl_stable;
            btnr_stable <= (btnr_sr == 16'hFFFF) ? 1'b1 : (btnr_sr == 16'h0000) ? 1'b0 : btnr_stable;
            btnu_stable <= (btnu_sr == 16'hFFFF) ? 1'b1 : (btnu_sr == 16'h0000) ? 1'b0 : btnu_stable;
            btnd_stable <= (btnd_sr == 16'hFFFF) ? 1'b1 : (btnd_sr == 16'h0000) ? 1'b0 : btnd_stable;
            btnc_stable <= (btnc_sr == 16'hFFFF) ? 1'b1 : (btnc_sr == 16'h0000) ? 1'b0 : btnc_stable;
            
            // Delayed versions for edge detection
            btnl_d <= btnl_stable;
            btnr_d <= btnr_stable;
            btnu_d <= btnu_stable;
            btnd_d <= btnd_stable;
            btnc_d <= btnc_stable;
            
            // Rising edge detection
            btnl_pulse <= btnl_stable & ~btnl_d;
            btnr_pulse <= btnr_stable & ~btnr_d;
            btnu_pulse <= btnu_stable & ~btnu_d;
            btnd_pulse <= btnd_stable & ~btnd_d;
            btnc_pulse <= btnc_stable & ~btnc_d;
        end
    end
    
    reg [1:0] edit_row;
    reg [1:0] edit_col;
    reg signed [15:0] edit_val;
    reg signed [15:0] matrix_a [0:3][0:3];
    reg signed [15:0] vector_v [0:3];
    
    // Cell locked state - controls edit mode behavior
    // 0 = unlocked (can navigate), 1 = locked (editing value)
    reg cell_locked;
    
    // Next-state logic for edit_row and edit_col (combinational)
    // MUST be declared as reg since assigned in always block
    reg [1:0] next_edit_row;
    reg [1:0] next_edit_col;
    
    // Next-state logic for matrix_a and vector_v (combinational)
    // MUST be declared as reg arrays since assigned in always block
    reg signed [15:0] next_matrix_a [0:3][0:3];
    reg signed [15:0] next_vector_v [0:3];
    
    // Next-state logic for edit_val (combinational)
    // MUST be declared as reg since assigned in always block
    reg signed [15:0] next_edit_val;
    
    // SINGLE always @(*) block for next-state computation (edit_row/edit_col)
    always @(*) begin
        // Default: keep current values
        next_edit_row = edit_row;
        next_edit_col = edit_col;
        
        // Navigation only works when in edit mode AND cell is NOT locked
        if (~sw0 && ~cell_locked) begin
            // Handle row changes
            if (btnu_pulse) begin
                if (edit_row > 2'b00)
                    next_edit_row = edit_row - 1'b1;
            end else if (btnd_pulse) begin
                if (edit_row < 2'b11)
                    next_edit_row = edit_row + 1'b1;
            end
            
            // Handle column changes (matrix only)
            if (sw1 == 1'b0) begin  // Matrix mode
                if (btnl_pulse) begin
                    if (edit_col > 2'b00)
                        next_edit_col = edit_col - 1'b1;
                end else if (btnr_pulse) begin
                    if (edit_col < 2'b11)
                        next_edit_col = edit_col + 1'b1;
                end
            end
        end
        // When locked or in run mode, keep current values (already set as default)
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
        
        if (reset_internal) begin
            // Initialize on reset
            next_matrix_a[0][0] = 16'sd4; next_matrix_a[0][1] = 16'sd1; next_matrix_a[0][2] = 16'sd1; next_matrix_a[0][3] = 16'sd1;
            next_matrix_a[1][0] = 16'sd1; next_matrix_a[1][1] = 16'sd4; next_matrix_a[1][2] = 16'sd1; next_matrix_a[1][3] = 16'sd1;
            next_matrix_a[2][0] = 16'sd1; next_matrix_a[2][1] = 16'sd1; next_matrix_a[2][2] = 16'sd4; next_matrix_a[2][3] = 16'sd1;
            next_matrix_a[3][0] = 16'sd1; next_matrix_a[3][1] = 16'sd1; next_matrix_a[3][2] = 16'sd1; next_matrix_a[3][3] = 16'sd4;
            for (i = 0; i < 4; i = i + 1) begin
                next_vector_v[i] = 16'sd1;
            end
        end else if (~sw0 && btnc_pulse && cell_locked) begin
            // Edit mode with cell locked: SAVE value and unlock
            if (sw1 == 1'b0) begin
                // Edit matrix
                next_matrix_a[edit_row][edit_col] = edit_val;
            end else begin
                // Edit vector
                next_vector_v[edit_row] = edit_val;
            end
        end
    end
    
    // SINGLE always block for edit_row, edit_col, and cell_locked state update
    // Now on main clock for proper synchronization with VGA
    always @(posedge clk) begin
        if (reset_internal) begin
            edit_row <= 2'b00;
            edit_col <= 2'b00;
            cell_locked <= 1'b0;
        end else begin
            edit_row <= next_edit_row;
            edit_col <= next_edit_col;
            
            // Handle cell_locked state transitions with BTNC
            if (~sw0 && btnc_pulse) begin
                // Toggle locked state when BTNC pressed in edit mode
                cell_locked <= ~cell_locked;
            end else if (sw0) begin
                // Force unlock when entering run mode
                cell_locked <= 1'b0;
            end
        end
    end
    
    reg sw0_prev, sw1_prev;
    reg [1:0] edit_row_prev;
    
    always @(posedge clk) begin
        if (reset_internal) begin
            sw0_prev <= 1'b0;
            sw1_prev <= 1'b0;
            edit_row_prev <= 2'b00;
        end else begin
            sw0_prev <= sw0;
            sw1_prev <= sw1;
            edit_row_prev <= edit_row;
        end
    end
    
    reg cell_locked_prev;
    
    always @(posedge clk) begin
        if (reset_internal) begin
            cell_locked_prev <= 1'b0;
        end else begin
            cell_locked_prev <= cell_locked;
        end
    end
    
    // SINGLE always @(*) block for next_edit_val computation
    always @(*) begin
        // Default: keep current value
        next_edit_val = edit_val;
        
        if (reset_internal) begin
            next_edit_val = 16'sd0;
        end else if (~sw0) begin
            // When locking onto a cell (transition from unlocked to locked), load current value
            if (~cell_locked_prev && cell_locked) begin
                if (sw1 == 1'b0) begin
                    next_edit_val = matrix_a[edit_row][edit_col];
                end else begin
                    next_edit_val = vector_v[edit_row];
                end
            end
            // When cell is locked, allow value editing with left/right buttons
            else if (cell_locked) begin
                if (btnl_pulse) begin
                    next_edit_val = edit_val - 16'sd1;
                end else if (btnr_pulse) begin
                    next_edit_val = edit_val + 16'sd1;
                end
            end
            // When not locked and navigating, show preview of cell value
            else if ((sw1_prev != sw1) || (edit_row_prev != edit_row)) begin
                if (sw1 == 1'b0) begin
                    next_edit_val = matrix_a[edit_row][edit_col];
                end else begin
                    next_edit_val = vector_v[edit_row];
                end
            end
        end
    end
    
    // SINGLE always @(posedge clk) block for edit_val state update
    always @(posedge clk) begin
        edit_val <= next_edit_val;
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
    wire [7:0] fsm_state;
    wire signed [15:0] v_old0, v_old1, v_old2, v_old3;
    
    // Iteration counter
    reg [7:0] iteration_count;
    reg load_v_old_prev;
    
    reg sw0_r;
    wire sw0_edge;
    
    always @(posedge clk) begin
        if (reset_internal) begin
            sw0_r <= 1'b0;
            iteration_count <= 8'd0;
            load_v_old_prev <= 1'b0;
        end else begin
            sw0_r <= sw0;
            load_v_old_prev <= load_v_old;
            // Count iterations: increment when load_v_old transitions from 0 to 1
            if (load_v_old && !load_v_old_prev) begin
                iteration_count <= iteration_count + 1'b1;
            end
            // Reset counter when starting new computation
            if (sw0_edge) begin
                iteration_count <= 8'd0;
            end
        end
    end
    
    assign sw0_edge = sw0 & ~sw0_r;
    
    dominant_fsm fsm_inst (
        .clk(clk),
        .reset(reset_internal),
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
        .done(fsm_done),
        .state_out(fsm_state)
    );
    
    dominant_datapath datapath_inst (
        .clk(clk),
        .reset(reset_internal),
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
        .v3(v_out[63:48]),
        .v_old0(v_old0),
        .v_old1(v_old1),
        .v_old2(v_old2),
        .v_old3(v_old3)
    );
    
    // ========================================================================
    // DEBUG: LED ASSIGNMENTS
    // ========================================================================
    // LED[0]: Cell locked indicator (ON when editing a cell value)
    // LED[1]: Any button pulse active (flashes when button pressed)
    // LED[2]: Mode indicator (sw0: 0=Edit, 1=Run)
    // LED[3]: Edit target (sw1: 0=Matrix, 1=Vector)
    // LED[4:5]: Current edit row (binary)
    // LED[6:7]: Current edit col (binary)
    
    wire any_button_pulse = btnl_pulse | btnr_pulse | btnu_pulse | btnd_pulse | btnc_pulse;
    
    assign led[0] = cell_locked;  // Shows locked/unlocked state
    assign led[1] = any_button_pulse;
    assign led[2] = sw0;
    assign led[3] = sw1;
    assign led[5:4] = edit_row;
    assign led[7:6] = edit_col;
    
    // ========================================================================
    // DEBUG: SEVEN SEGMENT DISPLAY
    // ========================================================================
    // Display useful debug information based on mode:
    // - Edit mode (sw0=0): Show current edit value (with sign handling)
    // - Run mode (sw0=1): Show iteration count
    
    reg [15:0] ssd_display_value;
    wire [3:0] ssd_anode;
    wire [6:0] ssd_segments;
    
    // Select what to display based on mode
    always @(*) begin
        if (sw0 == 1'b0) begin
            // Edit mode: Display edit_val
            // Handle negative numbers by displaying absolute value
            // (The MSB LED can indicate sign)
            if (edit_val[15] == 1'b1) begin
                // Negative: display 2's complement magnitude
                ssd_display_value = (~edit_val + 16'd1) & 16'h7FFF;
            end else begin
                // Positive: display as-is
                ssd_display_value = edit_val & 16'h7FFF;
            end
        end else begin
            // Run mode: Display iteration count
            ssd_display_value = {8'd0, iteration_count};
        end
    end
    
    // Instantiate 7-segment display counter (4 digits)
    ssd_counter ssd_debug (
        .clk(clk),
        .displayNumber(ssd_display_value),
        .anode(ssd_anode),
        .ssdOut(ssd_segments)
    );
    
    // Map to individual segment outputs (ssd_segments is already active-low)
    assign {ca, cb, cc, cd, ce, cf, cg} = ssd_segments;
    
    // Decimal point: active-low (0=on, 1=off)
    // In edit mode: on for negative (dark), off for positive (lit)
    // In run mode: always off (lit)
    assign dp = (sw0 == 1'b0) ? edit_val[15] : 1'b1;
    
    // Map 4-bit anode to 8 anodes (use lower 4 digits, upper 4 off)
    assign {an7, an6, an5, an4} = 4'b1111;  // Upper 4 digits off
    assign {an3, an2, an1, an0} = ssd_anode; // Lower 4 digits active
    
    wire signed [16*16-1:0] matrix_a_packed;
    assign matrix_a_packed = {matrix_a[3][3], matrix_a[3][2], matrix_a[3][1], matrix_a[3][0],
                              matrix_a[2][3], matrix_a[2][2], matrix_a[2][1], matrix_a[2][0],
                              matrix_a[1][3], matrix_a[1][2], matrix_a[1][1], matrix_a[1][0],
                              matrix_a[0][3], matrix_a[0][2], matrix_a[0][1], matrix_a[0][0]};

    wire signed [4*16-1:0] vector_v_packed;
    assign vector_v_packed = {vector_v[3], vector_v[2], vector_v[1], vector_v[0]};

    wire signed [63:0] v_old_packed = {v_old3, v_old2, v_old1, v_old0};
    wire signed [63:0] v_new_packed = v_out;
    
    vga_top vga_display (
        .clk_100mhz(clk),
        .reset(reset_internal),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .cell_locked(cell_locked),
        .sw0(sw0),
        .sw1(sw1),
        .sw_eps(sw_eps),
        .matrix_a(matrix_a_packed),
        .vector_v(vector_v_packed),
        .fsm_state(fsm_state),
        .fsm_done(fsm_done),
        .iteration_count(iteration_count),
        .v_old(v_old_packed),
        .v_new(v_new_packed),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );
    
endmodule
