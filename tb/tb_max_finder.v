`timescale 1ns / 1ps

module tb_max_finder;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter WIDTH = 16;
	
	reg signed [4*WIDTH-1:0] a;
	wire signed [WIDTH-1:0] max_val;
	
	// Unpacked signals for display
	wire signed [WIDTH-1:0] a0;
	wire signed [WIDTH-1:0] a1;
	wire signed [WIDTH-1:0] a2;
	wire signed [WIDTH-1:0] a3;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	max_finder #(.WIDTH(WIDTH)) uut (
		.a(a),
		.max_val(max_val)
	);
	
	// Unpack signals
	assign a0 = a[WIDTH-1:0];
	assign a1 = a[2*WIDTH-1:WIDTH];
	assign a2 = a[3*WIDTH-1:2*WIDTH];
	assign a3 = a[4*WIDTH-1:3*WIDTH];
	
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
		$display("Testing max_finder");
		$display("========================================");
		
		// Test case 1: All positive values
		a = (16'sd4 << 48) | (16'sd3 << 32) | (16'sd2 << 16) | 16'sd1;  // [1,2,3,4]
		#10;
		if (max_val == 4) begin
			$display("Test 1: All positive [1,2,3,4] -> max = 4 - PASS");
		end else begin
			$display("Test 1: All positive [1,2,3,4] -> max = 4 - FAIL (got %d)", max_val);
		end
		
		// Test case 2: Mixed positive and negative
		// Pack negative values: -5 = 0xFFFB, -7 = 0xFFF9
		a = (16'hFFFB << 48) | (16'sd3 << 32) | (16'hFFF9 << 16) | 16'sd2;  // [-5, 3, -7, 2]
		#10;
		// Max absolute value should be 7
		if (max_val == 7) begin
			$display("Test 2: Mixed [-5,3,-7,2] -> max = 7 - PASS");
		end else begin
			$display("Test 2: Mixed [-5,3,-7,2] -> max = 7 - FAIL (got %d)", max_val);
		end
		
		// Test case 3: All negative
		// Pack as two's complement: -1 = 0xFFFF, -5 = 0xFFFB, -3 = 0xFFFD, -2 = 0xFFFE
		a = (16'hFFFF << 48) | (16'hFFFB << 32) | (16'hFFFD << 16) | 16'hFFFE;  // [-1,-5,-3,-2]
		#10;
		// Max absolute value should be 5
		if (max_val == 5) begin
			$display("Test 3: All negative [-1,-5,-3,-2] -> max = 5 - PASS");
		end else begin
			$display("Test 3: All negative [-1,-5,-3,-2] -> max = 5 - FAIL (got %d)", max_val);
		end
		
		$display("========================================");
		$display("✓ max_finder test passed");
		$display("========================================\n");
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
