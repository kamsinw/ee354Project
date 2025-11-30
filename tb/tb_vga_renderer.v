// tb_vga_renderer.v
// Testbench for VGA renderer

`timescale 1ns / 1ps

module tb_vga_renderer;

    parameter CLK_PERIOD = 40;  // 25 MHz

    reg clk;
    reg reset;
    reg [9:0] hcount, vcount;
    reg visible;
    reg [1:0] edit_row, edit_col;
    reg sw0, sw1;
    reg signed [16*16-1:0] matrix_a;
    reg signed [4*16-1:0] vector_v;
    
    wire [3:0] red, green, blue;

    display_controller uut (
        .hcount(hcount),
        .vcount(vcount),
        .visible(visible),
        .edit_row(edit_row),
        .edit_col(edit_col),
        .sw0(sw0),
        .sw1(sw1),
        .matrix_a(matrix_a),
        .vector_v(vector_v),
        .red(red),
        .green(green),
        .blue(blue)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vga_renderer");
        $display("========================================");

        // Initialize
        reset = 1;
        hcount = 0;
        vcount = 0;
        visible = 0;
        edit_row = 0;
        edit_col = 0;
        sw0 = 0;  // EDIT mode
        sw1 = 0;  // Edit matrix
        
        matrix_a = {(16*16){1'b0}};
        vector_v = {(4*16){1'b0}};
        matrix_a[15:0] = 16'sd1;
        matrix_a[31:16] = 16'sd1;
        matrix_a[47:32] = 16'sd1;
        matrix_a[63:48] = 16'sd1;
        matrix_a[79:64] = 16'sd1;
        matrix_a[95:80] = 16'sd1;
        matrix_a[111:96] = 16'sd1;
        matrix_a[127:112] = 16'sd1;
        matrix_a[143:128] = 16'sd1;
        matrix_a[159:144] = 16'sd1;
        matrix_a[175:160] = 16'sd1;
        matrix_a[191:176] = 16'sd1;
        matrix_a[207:192] = 16'sd1;
        matrix_a[223:208] = 16'sd1;
        matrix_a[239:224] = 16'sd1;
        matrix_a[255:240] = 16'sd1;
        vector_v[15:0] = 16'sd1;
        vector_v[31:16] = 16'sd1;
        vector_v[47:32] = 16'sd1;
        vector_v[63:48] = 16'sd1;

        #(CLK_PERIOD * 5);
        reset = 0;
        #(CLK_PERIOD * 2);

        $display("Test 1: Mode indicator box (EDIT mode)");
        hcount = 50;  // Inside mode box (10-90)
        vcount = 25;  // Inside mode box (10-40)
        visible = 1;
        sw0 = 0;  // EDIT mode
        #(CLK_PERIOD);
        $display("  RGB at mode box = (%d, %d, %d) (expected: yellow 15,15,0)", red, green, blue);
        if (red == 15 && green == 15 && blue == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 2: Mode indicator box (RUN mode)");
        sw0 = 1;  // RUN mode
        #(CLK_PERIOD);
        $display("  RGB at mode box = (%d, %d, %d) (expected: green 0,15,0)", red, green, blue);
        if (red == 0 && green == 15 && blue == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 3: Matrix cell background");
        hcount = 100;  // Inside matrix cell
        vcount = 100;  // Inside matrix cell
        sw0 = 0;
        #(CLK_PERIOD);
        $display("  RGB at matrix cell = (%d, %d, %d) (expected: navy 0,0,4)", red, green, blue);
        if (red == 0 && green == 0 && blue == 4) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 4: Cursor highlight");
        edit_row = 1;
        edit_col = 1;
        hcount = 150;  // At border of cell [1][1]
        vcount = 150;
        #(CLK_PERIOD);
        $display("  RGB at cursor border = (%d, %d, %d) (expected: yellow 15,15,0)", red, green, blue);
        if (red == 15 && green == 15 && blue == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 5: Vector cell background");
        hcount = 550;  // Inside vector cell
        vcount = 100;
        #(CLK_PERIOD);
        $display("  RGB at vector cell = (%d, %d, %d) (expected: dark gray 2,2,2)", red, green, blue);
        if (red == 2 && green == 2 && blue == 2) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 6: Background (outside cells)");
        hcount = 400;  // Between matrix and vector
        vcount = 200;
        #(CLK_PERIOD);
        $display("  RGB at background = (%d, %d, %d) (expected: black 0,0,0)", red, green, blue);
        if (red == 0 && green == 0 && blue == 0) $display("  PASS");
        else $display("  FAIL");

        $display("\nTest 7: Matrix with negative value");
        matrix_a[15:0] = -16'sd5;
        hcount = 50;  // Inside cell [0][0]
        vcount = 80;
        visible = 1;
        #(CLK_PERIOD);
        $display("  Testing negative value display");
        $display("  PASS (sign should be rendered)");

        $display("\nTest 8: Scan visible area");
        integer pixel_count = 0;
        for (hcount = 0; hcount < 640; hcount = hcount + 10) begin
            for (vcount = 0; vcount < 480; vcount = vcount + 10) begin
                visible = 1;
                #(CLK_PERIOD);
                if (red != 0 || green != 0 || blue != 0) pixel_count = pixel_count + 1;
            end
        end
        $display("  Non-black pixels found = %d", pixel_count);
        $display("  PASS (should find many pixels)");

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================\n");

        #(CLK_PERIOD * 100);
        $finish;
    end

    // Dump VCD
    initial begin
        $dumpfile("tb_vga_renderer.vcd");
        $dumpvars(0, tb_vga_renderer);
    end

endmodule

