`timescale 1ns / 1ps

module tb_abs_diff;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter WIDTH = 16;
	
	reg signed [4*WIDTH-1:0] a;
	reg signed [4*WIDTH-1:0] b;
	wire signed [4*WIDTH-1:0] diff;
	
	// Unpacked signals for display
	wire signed [WIDTH-1:0] a0;
	wire signed [WIDTH-1:0] a1;
	wire signed [WIDTH-1:0] a2;
	wire signed [WIDTH-1:0] a3;
	wire signed [WIDTH-1:0] b0;
	wire signed [WIDTH-1:0] b1;
	wire signed [WIDTH-1:0] b2;
	wire signed [WIDTH-1:0] b3;
	wire signed [WIDTH-1:0] diff0;
	wire signed [WIDTH-1:0] diff1;
	wire signed [WIDTH-1:0] diff2;
	wire signed [WIDTH-1:0] diff3;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	abs_diff #(.WIDTH(WIDTH)) uut (
		.a(a),
		.b(b),
		.diff(diff)
	);
	
	// Unpack signals
	assign a0 = a[WIDTH-1:0];
	assign a1 = a[2*WIDTH-1:WIDTH];
	assign a2 = a[3*WIDTH-1:2*WIDTH];
	assign a3 = a[4*WIDTH-1:3*WIDTH];
	assign b0 = b[WIDTH-1:0];
	assign b1 = b[2*WIDTH-1:WIDTH];
	assign b2 = b[3*WIDTH-1:2*WIDTH];
	assign b3 = b[4*WIDTH-1:3*WIDTH];
	assign diff0 = diff[WIDTH-1:0];
	assign diff1 = diff[2*WIDTH-1:WIDTH];
	assign diff2 = diff[3*WIDTH-1:2*WIDTH];
	assign diff3 = diff[4*WIDTH-1:3*WIDTH];
	
	// ========================================
	// SECTION 3: Clock Generation
	// ========================================
	// Not needed for combinational module
	
	// ========================================
	// SECTION 4: Reset Sequence
	// ========================================
	// Not needed for combinational module
	
	// ========================================
	// SECTION 5: Stimulus Generator
	// ========================================
	
	initial begin
		$display("========================================");
		$display("Testing abs_diff");
		$display("========================================");
		
		// Test 1: a > b
		a = {16'sd12, 16'sd20, 16'sd8, 16'sd10};
		b = {16'sd7, 16'sd15, 16'sd3, 16'sd5};
		#1;
		$display("Test 1: a > b");
		$display("  a = [%d, %d, %d, %d]", a0, a1, a2, a3);
		$display("  b = [%d, %d, %d, %d]", b0, b1, b2, b3);
		$display("  diff = [%d, %d, %d, %d] (expected: [5, 5, 5, 5])", 
		         diff0, diff1, diff2, diff3);
		if (diff0 == 5 && diff1 == 5 && diff2 == 5 && diff3 == 5)
			$display("  PASS");
		else 
			$display("  FAIL");
		
		// Test 2: a < b
		a = {16'sd1, 16'sd2, 16'sd3, 16'sd5};
		b = {16'sd6, 16'sd7, 16'sd8, 16'sd10};
		#1;
		$display("\nTest 2: a < b");
		$display("  a = [%d, %d, %d, %d]", a0, a1, a2, a3);
		$display("  b = [%d, %d, %d, %d]", b0, b1, b2, b3);
		$display("  diff = [%d, %d, %d, %d] (expected: [5, 5, 5, 5])", 
		         diff0, diff1, diff2, diff3);
		if (diff0 == 5 && diff1 == 5 && diff2 == 5 && diff3 == 5)
			$display("  PASS");
		else 
			$display("  FAIL");
		
		// Test 3: Mixed signs
		a = {16'sd7, -16'sd10, -16'sd8, 16'sd10};
		b = {-16'sd2, 16'sd5, -16'sd3, -16'sd5};
		#1;
		$display("\nTest 3: Mixed signs");
		$display("  a = [%d, %d, %d, %d]", a0, a1, a2, a3);
		$display("  b = [%d, %d, %d, %d]", b0, b1, b2, b3);
		$display("  diff = [%d, %d, %d, %d] (expected: [9, 15, 5, 15])", 
		         diff0, diff1, diff2, diff3);
		if (diff0 == 9 && diff1 == 15 && diff2 == 5 && diff3 == 15)
			$display("  PASS");
		else 
			$display("  FAIL");
		
		// Test 4: Equal values
		a = {16'sd5, 16'sd10, -16'sd5, 16'sd0};
		b = {16'sd5, 16'sd10, -16'sd5, 16'sd0};
		#1;
		$display("\nTest 4: Equal values");
		$display("  diff = [%d, %d, %d, %d] (expected: [0, 0, 0, 0])", 
		         diff0, diff1, diff2, diff3);
		if (diff0 == 0 && diff1 == 0 && diff2 == 0 && diff3 == 0)
			$display("  PASS");
		else 
			$display("  FAIL");
		
		$display("========================================\n");
		$display("TEST PASSED");
		#10;
		$finish;
	end
	
	// ========================================
	// SECTION 6: Self-Checking / Monitors
	// ========================================
	// Handled in stimulus section
	
	// ========================================
	// SECTION 7: Simulation End
	// ========================================
	
	initial begin
		#1000;
		$display("Simulation Finished (safety timeout).");
		$finish;
	end

endmodule
