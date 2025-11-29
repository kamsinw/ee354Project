// tb_abs_diff.v
// Testbench for abs_diff module

`timescale 1ns / 1ps

module tb_abs_diff;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg signed [WIDTH-1:0] a [0:3];
    reg signed [WIDTH-1:0] b [0:3];
    wire signed [WIDTH-1:0] diff [0:3];

    abs_diff #(.WIDTH(WIDTH)) uut (
        .a(a),
        .b(b),
        .diff(diff)
    );

    initial begin
        $display("========================================");
        $display("Testing abs_diff");
        $display("========================================");

        // Test 1: a > b (all positive)
        a[0] = 16'sd10; b[0] = 16'sd5;
        a[1] = 16'sd20; b[1] = 16'sd15;
        a[2] = 16'sd8;  b[2] = 16'sd3;
        a[3] = 16'sd12; b[3] = 16'sd7;
        #1;
        $display("Test 1: a > b");
        $display("  a = [%d, %d, %d, %d]", a[0], a[1], a[2], a[3]);
        $display("  b = [%d, %d, %d, %d]", b[0], b[1], b[2], b[3]);
        $display("  diff = [%d, %d, %d, %d] (expected: [5, 5, 5, 5])", 
                 diff[0], diff[1], diff[2], diff[3]);
        if (diff[0] == 5 && diff[1] == 5 && diff[2] == 5 && diff[3] == 5)
            $display("  PASS");
        else $display("  FAIL");

        // Test 2: a < b (result should be positive)
        a[0] = 16'sd5;  b[0] = 16'sd10;
        a[1] = 16'sd3;  b[1] = 16'sd8;
        a[2] = 16'sd2;  b[2] = 16'sd7;
        a[3] = 16'sd1;  b[3] = 16'sd6;
        #1;
        $display("\nTest 2: a < b");
        $display("  a = [%d, %d, %d, %d]", a[0], a[1], a[2], a[3]);
        $display("  b = [%d, %d, %d, %d]", b[0], b[1], b[2], b[3]);
        $display("  diff = [%d, %d, %d, %d] (expected: [5, 5, 5, 5])", 
                 diff[0], diff[1], diff[2], diff[3]);
        if (diff[0] == 5 && diff[1] == 5 && diff[2] == 5 && diff[3] == 5)
            $display("  PASS");
        else $display("  FAIL");

        // Test 3: Mixed signs
        a[0] = 16'sd10; b[0] = -16'sd5;
        a[1] = -16'sd10; b[1] = 16'sd5;
        a[2] = -16'sd8; b[2] = -16'sd3;
        a[3] = 16'sd7;  b[3] = -16'sd2;
        #1;
        $display("\nTest 3: Mixed signs");
        $display("  a = [%d, %d, %d, %d]", a[0], a[1], a[2], a[3]);
        $display("  b = [%d, %d, %d, %d]", b[0], b[1], b[2], b[3]);
        $display("  diff = [%d, %d, %d, %d] (expected: [15, 15, 5, 9])", 
                 diff[0], diff[1], diff[2], diff[3]);
        if (diff[0] == 15 && diff[1] == 15 && diff[2] == 5 && diff[3] == 9)
            $display("  PASS");
        else $display("  FAIL");

        // Test 4: Equal values
        a[0] = 16'sd5; b[0] = 16'sd5;
        a[1] = 16'sd10; b[1] = 16'sd10;
        a[2] = -16'sd5; b[2] = -16'sd5;
        a[3] = 16'sd0; b[3] = 16'sd0;
        #1;
        $display("\nTest 4: Equal values");
        $display("  diff = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
                 diff[0], diff[1], diff[2], diff[3]);
        if (diff[0] == 0 && diff[1] == 0 && diff[2] == 0 && diff[3] == 0)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #10;
        $finish;
    end

endmodule

