// tb_max_finder.v 

`timescale 1ns / 1ps

module tb_max_finder;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg signed [4*WIDTH-1:0] a;
    wire signed [WIDTH-1:0] max_val;

    max_finder #(.WIDTH(WIDTH)) uut (
        .a(a),
        .max_val(max_val)
    );

    wire signed [WIDTH-1:0] a0 = a[WIDTH-1:0];
    wire signed [WIDTH-1:0] a1 = a[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] a2 = a[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] a3 = a[4*WIDTH-1:3*WIDTH];

    initial begin
        $display("========================================");
        $display("Testing max_finder");
        $display("========================================");

        a = {16'sd8, 16'sd5, 16'sd15, 16'sd10};
        #1;
        $display("Test 1: [%d, %d, %d, %d] -> max = %d (expected: 15)", 
                 a0, a1, a2, a3, max_val);
        if (max_val == 15) $display("  PASS");
        else $display("  FAIL");

        a = {16'sd5, -16'sd20, 16'sd10, -16'sd15};
        #1;
        $display("Test 2: [%d, %d, %d, %d] -> max = %d (expected: 20)", 
                 a0, a1, a2, a3, max_val);
        if (max_val == 20) $display("  PASS");
        else $display("  FAIL");

        a = {-16'sd8, -16'sd5, -16'sd15, -16'sd10};
        #1;
        $display("Test 3: [%d, %d, %d, %d] -> max = %d (expected: 15)", 
                 a0, a1, a2, a3, max_val);
        if (max_val == 15) $display("  PASS");
        else $display("  FAIL");

        a = {16'sd0, 16'sd0, 16'sd0, 16'sd0};
        #1;
        $display("Test 4: [%d, %d, %d, %d] -> max = %d (expected: 0)", 
                 a0, a1, a2, a3, max_val);
        if (max_val == 0) $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #10;
        $finish;
    end

endmodule
