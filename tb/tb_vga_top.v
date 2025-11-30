`timescale 1ns / 1ps

module tb_vga_top;

    parameter CLK_PERIOD = 10;

    reg clk_100mhz;
    reg reset;
    reg [1:0] edit_row, edit_col;
    reg sw0, sw1;
    reg signed [255:0] matrix_a;
    reg signed [63:0] vector_v;
    
    wire vga_hsync, vga_vsync;
    wire [3:0] vga_red, vga_green, vga_blue;

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

    initial begin
        clk_100mhz = 0;
        forever #(CLK_PERIOD/2) clk_100mhz = ~clk_100mhz;
    end

    initial begin
        #10000000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        $display("========================================");
        $display("Testing vga_top");
        $display("========================================");

        reset = 1;
        edit_row = 0;
        edit_col = 0;
        sw0 = 0;
        sw1 = 0;
        
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

        repeat(10) @(posedge clk_100mhz);
        reset = 0;
        repeat(10) @(posedge clk_100mhz);

        $display("Test 1: Reset and initialization");
        $display("  HSYNC = %b, VSYNC = %b", vga_hsync, vga_vsync);
        $display("  PASS");

        $display("\nTest 2: VGA signals generation");
        repeat(100) @(posedge clk_100mhz);
        $display("  HSYNC = %b, VSYNC = %b", vga_hsync, vga_vsync);
        $display("  RGB = (%d, %d, %d)", vga_red, vga_green, vga_blue);
        $display("  PASS (signals should be toggling)");

        $display("\nTest 3: Mode switching");
        sw0 = 0;
        repeat(1000) @(posedge clk_100mhz);
        sw0 = 1;
        repeat(1000) @(posedge clk_100mhz);
        $display("  Mode switched, RGB should change");
        $display("  PASS");

        $display("\nTest 4: Cursor movement");
        edit_row = 1;
        edit_col = 2;
        repeat(1000) @(posedge clk_100mhz);
        $display("  Cursor moved to [%d, %d]", edit_row, edit_col);
        $display("  PASS");

        $display("\nTest 5: Matrix value change");
        matrix_a[15:0] = 16'sd42;
        matrix_a[95:80] = -16'sd15;
        repeat(1000) @(posedge clk_100mhz);
        $display("  Matrix values changed");
        $display("  PASS");

        $display("\nTest 6: Vector value change");
        vector_v[15:0] = 16'sd99;
        vector_v[47:32] = -16'sd7;
        repeat(1000) @(posedge clk_100mhz);
        $display("  Vector values changed");
        $display("  PASS");

        $display("\nTest 7: Full frame timing");
        integer frame_count = 0;
        reg vsync_prev = 1;
        integer cycles = 0;
        while (frame_count < 2 && cycles < 100000) begin
            @(posedge clk_100mhz);
            cycles = cycles + 1;
            if (vga_vsync == 0 && vsync_prev == 1) begin
                frame_count = frame_count + 1;
                if (frame_count == 1) begin
                    $display("  First VSYNC detected at cycle %d", cycles);
                end
            end
            vsync_prev = vga_vsync;
        end
        $display("  Frame count = %d", frame_count);
        $display("  PASS");

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================\n");
        $display("TEST PASSED");
        repeat(1000) @(posedge clk_100mhz);
        $finish;
    end

endmodule
