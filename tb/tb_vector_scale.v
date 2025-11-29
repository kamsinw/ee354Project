// tb_vector_scale.v
// Testbench for vector_scale module

`timescale 1ns / 1ps

module tb_vector_scale;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [WIDTH-1:0] V_in [0:3];
    wire signed [WIDTH-1:0] V_out [0:3];
    wire done;

    vector_scale #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .start(start),
        .V_in(V_in),
        .V_out(V_out),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vector_scale");
        $display("========================================");

        start = 0;

        // Test 1: Positive values
        V_in[0] = 16'sd20;
        V_in[1] = 16'sd16;
        V_in[2] = 16'sd12;
        V_in[3] = 16'sd8;
        
        $display("Test 1: Positive values");
        $display("  V_in = [%d, %d, %d, %d]", V_in[0], V_in[1], V_in[2], V_in[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Vector scale shifts right by 1 (divides by 2)
        $display("  V_out = [%d, %d, %d, %d] (expected: [10, 8, 6, 4])", 
                 V_out[0], V_out[1], V_out[2], V_out[3]);
        if (V_out[0] == 10 && V_out[1] == 8 && V_out[2] == 6 && V_out[3] == 4)
            $display("  PASS");
        else $display("  FAIL");

        // Test 2: Mixed positive and negative
        V_in[0] = 16'sd20;
        V_in[1] = -16'sd16;
        V_in[2] = 16'sd12;
        V_in[3] = -16'sd8;
        
        $display("\nTest 2: Mixed signs");
        $display("  V_in = [%d, %d, %d, %d]", V_in[0], V_in[1], V_in[2], V_in[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  V_out = [%d, %d, %d, %d] (expected: [10, -8, 6, -4])", 
                 V_out[0], V_out[1], V_out[2], V_out[3]);
        if (V_out[0] == 10 && V_out[1] == -8 && V_out[2] == 6 && V_out[3] == -4)
            $display("  PASS");
        else $display("  FAIL");

        // Test 3: Odd numbers (arithmetic shift)
        V_in[0] = 16'sd15;
        V_in[1] = 16'sd7;
        V_in[2] = -16'sd15;
        V_in[3] = -16'sd7;
        
        $display("\nTest 3: Odd numbers");
        $display("  V_in = [%d, %d, %d, %d]", V_in[0], V_in[1], V_in[2], V_in[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Arithmetic shift: 15>>>1 = 7, -15>>>1 = -8
        $display("  V_out = [%d, %d, %d, %d] (expected: [7, 3, -8, -4])", 
                 V_out[0], V_out[1], V_out[2], V_out[3]);
        if (V_out[0] == 7 && V_out[1] == 3 && V_out[2] == -8 && V_out[3] == -4)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule

