// tb_vector_scale.v - 

`timescale 1ns / 1ps

module tb_vector_scale;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [4*WIDTH-1:0] V_in;
    wire signed [4*WIDTH-1:0] V_out;
    wire done;

    vector_scale #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .start(start),
        .V_in(V_in),
        .V_out(V_out),
        .done(done)
    );

    wire signed [WIDTH-1:0] V_in0 = V_in[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_in1 = V_in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_in2 = V_in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_in3 = V_in[4*WIDTH-1:3*WIDTH];
    wire signed [WIDTH-1:0] V_out0 = V_out[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_out1 = V_out[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_out2 = V_out[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_out3 = V_out[4*WIDTH-1:3*WIDTH];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vector_scale");
        $display("========================================");

        start = 0;

        V_in = {16'sd8, 16'sd12, 16'sd16, 16'sd20};
        
        $display("Test 1: Positive values");
        $display("  V_in = [%d, %d, %d, %d]", V_in0, V_in1, V_in2, V_in3);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  V_out = [%d, %d, %d, %d] (expected: [4, 6, 8, 10])", 
                 V_out0, V_out1, V_out2, V_out3);
        if (V_out0 == 10 && V_out1 == 8 && V_out2 == 6 && V_out3 == 4)
            $display("  PASS");
        else $display("  FAIL");

        V_in = {-16'sd8, 16'sd16, -16'sd12, 16'sd20};
        
        $display("\nTest 2: Mixed signs");
        $display("  V_in = [%d, %d, %d, %d]", V_in0, V_in1, V_in2, V_in3);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  V_out = [%d, %d, %d, %d] (expected: [10, -6, 8, -4])", 
                 V_out0, V_out1, V_out2, V_out3);
        if (V_out0 == 10 && V_out1 == -6 && V_out2 == 8 && V_out3 == -4)
            $display("  PASS");
        else $display("  FAIL");

        V_in = {-16'sd7, 16'sd15, -16'sd15, 16'sd7};
        
        $display("\nTest 3: Odd numbers");
        $display("  V_in = [%d, %d, %d, %d]", V_in0, V_in1, V_in2, V_in3);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  V_out = [%d, %d, %d, %d] (expected: [3, -8, 7, -4])", 
                 V_out0, V_out1, V_out2, V_out3);
        if (V_out0 == 3 && V_out1 == -8 && V_out2 == 7 && V_out3 == -4)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule
