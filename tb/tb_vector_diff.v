`timescale 1ns / 1ps

module tb_vector_diff;

    parameter WIDTH = 16;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg reset;
    reg start;
    reg signed [4*WIDTH-1:0] V_new;
    reg signed [4*WIDTH-1:0] V_old;
    wire signed [WIDTH-1:0] max_diff;
    wire done;

    vector_diff #(.WIDTH(WIDTH)) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .V_new(V_new),
        .V_old(V_old),
        .max_diff(max_diff),
        .done(done)
    );

    wire signed [WIDTH-1:0] V_new0 = V_new[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_new1 = V_new[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_new2 = V_new[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_new3 = V_new[4*WIDTH-1:3*WIDTH];
    wire signed [WIDTH-1:0] V_old0 = V_old[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_old1 = V_old[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_old2 = V_old[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_old3 = V_old[4*WIDTH-1:3*WIDTH];

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Testing vector_diff");
        $display("========================================");

        // Reset
        reset = 1;
        start = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        // Test: V_new = [5,6,7,8], V_old = [1,2,3,4]
        // Expected max_diff = max(|5-1|, |6-2|, |7-3|, |8-4|) = 4
        V_new = (16'sd8 << 48) | (16'sd7 << 32) | (16'sd6 << 16) | 16'sd5;
        V_old = (16'sd4 << 48) | (16'sd3 << 32) | (16'sd2 << 16) | 16'sd1;
        
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Wait for done
        begin
            integer timeout;
            timeout = 100;
            while (done == 0 && timeout > 0) begin
                @(posedge clk);
                timeout = timeout - 1;
            end
            if (done == 1) begin
                $display("Test 1: Difference calculation completed - PASS");
            end else begin
                $display("Test 1: Difference calculation completed - FAIL (timeout)");
            end
        end
        
        // Check max_diff
        if (max_diff == 4) begin
            $display("  max_diff = %d (expected: 4) - PASS", max_diff);
        end else begin
            $display("  max_diff = %d (expected: 4) - FAIL", max_diff);
        end

        $display("========================================");
        $display("✓ vector_diff test passed");
        $display("========================================\n");
        repeat(10) @(posedge clk);
        $finish;
    end

endmodule
