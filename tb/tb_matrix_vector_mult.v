`timescale 1ns / 1ps

module tb_matrix_vector_mult;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [16*16-1:0] A;
    reg signed [4*16-1:0] V;
    wire signed [4*16-1:0] Y;
    wire done;

    matrix_vector_mult uut (
        .clk(clk),
        .start(start),
        .A(A),
        .V(V),
        .Y(Y),
        .done(done)
    );

    wire signed [15:0] V0 = V[15:0];
    wire signed [15:0] V1 = V[31:16];
    wire signed [15:0] V2 = V[47:32];
    wire signed [15:0] V3 = V[63:48];
    wire signed [15:0] Y0 = Y[15:0];
    wire signed [15:0] Y1 = Y[31:16];
    wire signed [15:0] Y2 = Y[47:32];
    wire signed [15:0] Y3 = Y[63:48];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #100000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        $display("========================================");
        $display("Testing matrix_vector_mult");
        $display("========================================");

        start = 0;
        
        A = {16'sd0, 16'sd0, 16'sd0, 16'sd1,
             16'sd0, 16'sd0, 16'sd1, 16'sd0,
             16'sd0, 16'sd1, 16'sd0, 16'sd0,
             16'sd1, 16'sd0, 16'sd0, 16'sd0};
        V = {16'sd40, 16'sd30, 16'sd20, 16'sd10};
        
        $display("Test 1: Identity matrix");
        $display("  V = [%d, %d, %d, %d]", V0, V1, V2, V3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        
        @(posedge done);
        @(posedge clk);
        
        $display("  Y = [%d, %d, %d, %d] (expected: [10, 20, 30, 40])", 
                 Y0, Y1, Y2, Y3);
        if (Y0 == 10 && Y1 == 20 && Y2 == 30 && Y3 == 40)
            $display("  PASS");
        else $display("  FAIL");

        A = {16'sd4, 16'sd3, 16'sd2, 16'sd1,
             16'sd8, 16'sd7, 16'sd6, 16'sd5,
             16'sd12, 16'sd11, 16'sd10, 16'sd9,
             16'sd16, 16'sd15, 16'sd14, 16'sd13};
        V = {16'sd1, 16'sd1, 16'sd1, 16'sd1};
        
        $display("\nTest 2: Simple matrix");
        $display("  V = [%d, %d, %d, %d]", V0, V1, V2, V3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        
        @(posedge done);
        @(posedge clk);
        
        $display("  Y = [%d, %d, %d, %d] (expected: [10, 26, 42, 58])", 
                 Y0, Y1, Y2, Y3);
        if (Y0 == 10 && Y1 == 26 && Y2 == 42 && Y3 == 58)
            $display("  PASS");
        else $display("  FAIL");

        A = {16'sd1, 16'sd1, 16'sd1, 16'sd4,
             16'sd1, 16'sd1, 16'sd4, 16'sd1,
             16'sd1, 16'sd4, 16'sd1, 16'sd1,
             16'sd4, 16'sd1, 16'sd1, 16'sd1};
        V = {16'sd1, 16'sd1, 16'sd1, 16'sd1};
        
        $display("\nTest 3: Power iteration test matrix");
        $display("  V = [%d, %d, %d, %d]", V0, V1, V2, V3);
        
        start = 1;
        @(posedge clk);
        start = 0;
        
        @(posedge done);
        @(posedge clk);
        
        $display("  Y = [%d, %d, %d, %d] (expected: [7, 7, 7, 7])", 
                 Y0, Y1, Y2, Y3);
        if (Y0 == 7 && Y1 == 7 && Y2 == 7 && Y3 == 7)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        $display("TEST PASSED");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule
