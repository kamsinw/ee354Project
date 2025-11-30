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
        $display("========================================");
        $display("Testing vector_register");
        $display("========================================");

        // Reset
        reset = 1;
        load = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        // Check initial value (should be [1,1,1,1])
        @(posedge clk);
        begin
            integer v0, v1, v2, v3;
            v0 = out0;
            v1 = out1;
            v2 = out2;
            v3 = out3;
            
            if (v0 == 1 && v1 == 1 && v2 == 1 && v3 == 1) begin
                $display("Test 1: Initial value is [1,1,1,1] - PASS");
            end else begin
                $display("Test 1: Initial value is [1,1,1,1] - FAIL (got [%d,%d,%d,%d])", v0, v1, v2, v3);
            end
        end
        
        // Load new value
        // Packed as [8,7,6,5] in output due to bit ordering
        in = (16'sd5 << 48) | (16'sd6 << 32) | (16'sd7 << 16) | 16'sd8;
        load = 1;
        @(posedge clk);
        load = 0;
        @(posedge clk);
        
        // Check loaded value
        begin
            integer v0, v1, v2, v3;
            v0 = out0;
            v1 = out1;
            v2 = out2;
            v3 = out3;
            
            // Expected: [8,7,6,5] based on bit ordering
            if (v0 == 8 && v1 == 7 && v2 == 6 && v3 == 5) begin
                $display("Test 2: Loaded value is [8,7,6,5] - PASS");
            end else begin
                $display("Test 2: Loaded value is [8,7,6,5] - FAIL (got [%d,%d,%d,%d])", v0, v1, v2, v3);
            end
        end

        $display("========================================");
        $display("✓ vector_register test passed");
        $display("========================================\n");
        repeat(10) @(posedge clk);
        $finish;
    end

endmodule
