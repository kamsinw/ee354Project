`timescale 1ns / 1ps

module tb_vector_register;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg reset;
    reg load;
    reg signed [4*WIDTH-1:0] in;
    wire signed [4*WIDTH-1:0] out;

    vector_register #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .in(in),
        .out(out)
    );

    wire signed [WIDTH-1:0] in0 = in[WIDTH-1:0];
    wire signed [WIDTH-1:0] in1 = in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] in2 = in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] in3 = in[4*WIDTH-1:3*WIDTH];
    wire signed [WIDTH-1:0] out0 = out[WIDTH-1:0];
    wire signed [WIDTH-1:0] out1 = out[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] out2 = out[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] out3 = out[4*WIDTH-1:3*WIDTH];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #50000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        $display("========================================");
        $display("Testing vector_register");
        $display("========================================");

        reset = 1;
        load = 0;
        in = 64'd0;
        repeat(5) @(posedge clk);
        reset = 0;
        @(posedge clk);

        $display("Test 1: Reset");
        $display("  out = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
                 out0, out1, out2, out3);
        if (out0 == 0 && out1 == 0 && out2 == 0 && out3 == 0)
            $display("  PASS");
        else $display("  FAIL");

        reset = 0;
        in = {16'sd40, 16'sd30, 16'sd20, 16'sd10};
        load = 1;
        @(posedge clk);
        load = 0;
        @(posedge clk);
        $display("\nTest 2: Load values");
        $display("  in = [%d, %d, %d, %d]", in0, in1, in2, in3);
        $display("  out = [%d, %d, %d, %d] (expected: [10, 20, 30, 40])", 
                 out0, out1, out2, out3);
        if (out0 == 10 && out1 == 20 && out2 == 30 && out3 == 40)
            $display("  PASS");
        else $display("  FAIL");

        in = {16'sd400, 16'sd300, 16'sd200, 16'sd100};
        load = 0;
        @(posedge clk);
        $display("\nTest 3: No load signal");
        $display("  in = [%d, %d, %d, %d]", in0, in1, in2, in3);
        $display("  out = [%d, %d, %d, %d] (expected: [10, 20, 30, 40] - unchanged)", 
                 out0, out1, out2, out3);
        if (out0 == 10 && out1 == 20 && out2 == 30 && out3 == 40)
            $display("  PASS");
        else $display("  FAIL");

        load = 1;
        @(posedge clk);
        load = 0;
        @(posedge clk);
        $display("\nTest 4: Load new values");
        $display("  out = [%d, %d, %d, %d] (expected: [100, 200, 300, 400])", 
                 out0, out1, out2, out3);
        if (out0 == 100 && out1 == 200 && out2 == 300 && out3 == 400)
            $display("  PASS");
        else $display("  FAIL");

        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        $display("\nTest 5: Reset after load");
        $display("  out = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
                 out0, out1, out2, out3);
        if (out0 == 0 && out1 == 0 && out2 == 0 && out3 == 0)
            $display("  PASS");
        else $display("  FAIL");

        in = {-16'sd40, 16'sd30, -16'sd20, -16'sd10};
        load = 1;
        @(posedge clk);
        load = 0;
        @(posedge clk);
        $display("\nTest 6: Negative values");
        $display("  out = [%d, %d, %d, %d] (expected: [-10, -20, 30, -40])", 
                 out0, out1, out2, out3);
        if (out0 == -10 && out1 == -20 && out2 == 30 && out3 == -40)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        $display("TEST PASSED");
        #(CLK_PERIOD * 2);
        $finish;
    end

endmodule
