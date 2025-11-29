// tb_vector_register.v
// Testbench for vector_register module

`timescale 1ns / 1ps

module tb_vector_register;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg reset;
    reg load;
    reg signed [WIDTH-1:0] in [0:3];
    wire signed [WIDTH-1:0] out [0:3];

    vector_register #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .in(in),
        .out(out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vector_register");
        $display("========================================");

        // Initialize
        reset = 1;
        load = 0;
        in[0] = 0; in[1] = 0; in[2] = 0; in[3] = 0;
        #(CLK_PERIOD * 2);

        // Test 1: Reset
        $display("Test 1: Reset");
        reset = 1;
        #(CLK_PERIOD);
        $display("  out = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == 0 && out[1] == 0 && out[2] == 0 && out[3] == 0)
            $display("  PASS");
        else $display("  FAIL");

        // Test 2: Load values
        reset = 0;
        in[0] = 16'sd10;
        in[1] = 16'sd20;
        in[2] = 16'sd30;
        in[3] = 16'sd40;
        load = 1;
        #(CLK_PERIOD);
        load = 0;
        #(CLK_PERIOD);
        $display("\nTest 2: Load values");
        $display("  in = [%d, %d, %d, %d]", in[0], in[1], in[2], in[3]);
        $display("  out = [%d, %d, %d, %d] (expected: [10, 20, 30, 40])", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == 10 && out[1] == 20 && out[2] == 30 && out[3] == 40)
            $display("  PASS");
        else $display("  FAIL");

        // Test 3: Load without load signal (should not change)
        in[0] = 16'sd100;
        in[1] = 16'sd200;
        in[2] = 16'sd300;
        in[3] = 16'sd400;
        load = 0;
        #(CLK_PERIOD);
        $display("\nTest 3: No load signal");
        $display("  in = [%d, %d, %d, %d]", in[0], in[1], in[2], in[3]);
        $display("  out = [%d, %d, %d, %d] (expected: [10, 20, 30, 40] - unchanged)", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == 10 && out[1] == 20 && out[2] == 30 && out[3] == 40)
            $display("  PASS");
        else $display("  FAIL");

        // Test 4: Load new values
        load = 1;
        #(CLK_PERIOD);
        load = 0;
        #(CLK_PERIOD);
        $display("\nTest 4: Load new values");
        $display("  out = [%d, %d, %d, %d] (expected: [100, 200, 300, 400])", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == 100 && out[1] == 200 && out[2] == 300 && out[3] == 400)
            $display("  PASS");
        else $display("  FAIL");

        // Test 5: Reset after load
        reset = 1;
        #(CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        $display("\nTest 5: Reset after load");
        $display("  out = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == 0 && out[1] == 0 && out[2] == 0 && out[3] == 0)
            $display("  PASS");
        else $display("  FAIL");

        // Test 6: Negative values
        in[0] = -16'sd10;
        in[1] = -16'sd20;
        in[2] = 16'sd30;
        in[3] = -16'sd40;
        load = 1;
        #(CLK_PERIOD);
        load = 0;
        #(CLK_PERIOD);
        $display("\nTest 6: Negative values");
        $display("  out = [%d, %d, %d, %d] (expected: [-10, -20, 30, -40])", 
                 out[0], out[1], out[2], out[3]);
        if (out[0] == -10 && out[1] == -20 && out[2] == 30 && out[3] == -40)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #(CLK_PERIOD * 2);
        $finish;
    end

endmodule

