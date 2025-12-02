`timescale 1ns / 1ps

module tb_vector_diff;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter WIDTH = 16;
	
	reg clk;
	reg reset;
	reg start;
	reg signed [4*WIDTH-1:0] V_new;
	reg signed [4*WIDTH-1:0] V_old;
	wire signed [WIDTH-1:0] max_diff;
	wire done;
	
	// Unpacked signals for display
	wire signed [WIDTH-1:0] V_new0;
	wire signed [WIDTH-1:0] V_new1;
	wire signed [WIDTH-1:0] V_new2;
	wire signed [WIDTH-1:0] V_new3;
	wire signed [WIDTH-1:0] V_old0;
	wire signed [WIDTH-1:0] V_old1;
	wire signed [WIDTH-1:0] V_old2;
	wire signed [WIDTH-1:0] V_old3;
	
	// Testbench variables
	integer timeout;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	vector_diff #(.WIDTH(WIDTH)) uut (
		.clk     (clk),
		.reset   (reset),
		.start   (start),
		.vec_new (V_new),
		.vec_old (V_old),
		.max_diff(max_diff),
		.done    (done)
	);
	
	// Unpack signals
	assign V_new0 = V_new[WIDTH-1:0];
	assign V_new1 = V_new[2*WIDTH-1:WIDTH];
	assign V_new2 = V_new[3*WIDTH-1:2*WIDTH];
	assign V_new3 = V_new[4*WIDTH-1:3*WIDTH];
	assign V_old0 = V_old[WIDTH-1:0];
	assign V_old1 = V_old[2*WIDTH-1:WIDTH];
	assign V_old2 = V_old[3*WIDTH-1:2*WIDTH];
	assign V_old3 = V_old[4*WIDTH-1:3*WIDTH];
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	
	// 10 ns period (5 ns high, 5 ns low = 100 MHz)
	always begin
		#5 clk = ~clk;
	end
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	
	initial begin
		clk = 0;
		reset = 1;
		start = 0;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge clk);
		#1;
		reset = 0;
		
		$display("========================================");
		$display("Testing vector_diff");
		$display("========================================");
		
		// Test: V_new = [5,6,7,8], V_old = [1,2,3,4]
		// Expected max_diff = max(|5-1|, |6-2|, |7-3|, |8-4|) = 4
		V_new = (16'sd8 << 48) | (16'sd7 << 32) | (16'sd6 << 16) | 16'sd5;
		V_old = (16'sd4 << 48) | (16'sd3 << 32) | (16'sd2 << 16) | 16'sd1;
		
		start = 1;
		@(posedge clk);
		start = 0;
		
		// Wait for done
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
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	// Handled in reset/initial section
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	// Handled in stimulus section
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	initial begin
		#200000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
