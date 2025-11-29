// tb_matrix_vector_mult.v
// Testbench for matrix_vector_mult module

`timescale 1ns / 1ps

module tb_matrix_vector_mult;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg start;
    reg signed [15:0] A [0:3][0:3];
    reg signed [15:0] V [0:3];
    wire signed [15:0] Y [0:3];
    wire done;

    matrix_vector_mult uut (
        .clk(clk),
        .start(start),
        .A(A),
        .V(V),
        .Y(Y),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing matrix_vector_mult");
        $display("========================================");

        start = 0;
        
        // Test 1: Identity matrix
        A[0][0] = 1; A[0][1] = 0; A[0][2] = 0; A[0][3] = 0;
        A[1][0] = 0; A[1][1] = 1; A[1][2] = 0; A[1][3] = 0;
        A[2][0] = 0; A[2][1] = 0; A[2][2] = 1; A[2][3] = 0;
        A[3][0] = 0; A[3][1] = 0; A[3][2] = 0; A[3][3] = 1;
        
        V[0] = 10; V[1] = 20; V[2] = 30; V[3] = 40;
        
        $display("Test 1: Identity matrix");
        $display("  V = [%d, %d, %d, %d]", V[0], V[1], V[2], V[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        wait(done == 1);
        #(CLK_PERIOD);
        
        $display("  Y = [%d, %d, %d, %d] (expected: [10, 20, 30, 40])", 
                 Y[0], Y[1], Y[2], Y[3]);
        if (Y[0] == 10 && Y[1] == 20 && Y[2] == 30 && Y[3] == 40)
            $display("  PASS");
        else $display("  FAIL");

        // Test 2: Simple matrix
        A[0][0] = 1; A[0][1] = 2; A[0][2] = 3; A[0][3] = 4;
        A[1][0] = 5; A[1][1] = 6; A[1][2] = 7; A[1][3] = 8;
        A[2][0] = 9; A[2][1] = 10; A[2][2] = 11; A[2][3] = 12;
        A[3][0] = 13; A[3][1] = 14; A[3][2] = 15; A[3][3] = 16;
        
        V[0] = 1; V[1] = 1; V[2] = 1; V[3] = 1;
        
        $display("\nTest 2: Simple matrix");
        $display("  V = [%d, %d, %d, %d]", V[0], V[1], V[2], V[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Expected: Y[0] = 1+2+3+4 = 10, Y[1] = 5+6+7+8 = 26, etc.
        $display("  Y = [%d, %d, %d, %d] (expected: [10, 26, 42, 58])", 
                 Y[0], Y[1], Y[2], Y[3]);
        if (Y[0] == 10 && Y[1] == 26 && Y[2] == 42 && Y[3] == 58)
            $display("  PASS");
        else $display("  FAIL");

        // Test 3: Test matrix from power iteration
        A[0][0] = 4; A[0][1] = 1; A[0][2] = 1; A[0][3] = 1;
        A[1][0] = 1; A[1][1] = 4; A[1][2] = 1; A[1][3] = 1;
        A[2][0] = 1; A[2][1] = 1; A[2][2] = 4; A[2][3] = 1;
        A[3][0] = 1; A[3][1] = 1; A[3][2] = 1; A[3][3] = 4;
        
        V[0] = 1; V[1] = 1; V[2] = 1; V[3] = 1;
        
        $display("\nTest 3: Power iteration test matrix");
        $display("  V = [%d, %d, %d, %d]", V[0], V[1], V[2], V[3]);
        
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        
        wait(done == 1);
        #(CLK_PERIOD);
        
        // Expected: Y[0] = 4+1+1+1 = 7, Y[1] = 1+4+1+1 = 7, etc.
        $display("  Y = [%d, %d, %d, %d] (expected: [7, 7, 7, 7])", 
                 Y[0], Y[1], Y[2], Y[3]);
        if (Y[0] == 7 && Y[1] == 7 && Y[2] == 7 && Y[3] == 7)
            $display("  PASS");
        else $display("  FAIL");

        $display("========================================\n");
        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule

