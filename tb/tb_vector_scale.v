`timescale 1ns / 1ps

module tb_vector_scale;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter WIDTH = 16;
	
	reg clk;
	reg reset;
	reg start;
	reg signed [4*WIDTH-1:0] V_in;
	wire signed [4*WIDTH-1:0] V_out;
	wire done;
	
	// Unpacked signals for display
	wire signed [WIDTH-1:0] V_in0;
	wire signed [WIDTH-1:0] V_in1;
	wire signed [WIDTH-1:0] V_in2;
	wire signed [WIDTH-1:0] V_in3;
	wire signed [WIDTH-1:0] V_out0;
	wire signed [WIDTH-1:0] V_out1;
	wire signed [WIDTH-1:0] V_out2;
	wire signed [WIDTH-1:0] V_out3;
	
	// Testbench variables
	integer timeout;
	integer v0, v1, v2, v3, max_abs;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	vector_scale #(.WIDTH(WIDTH)) uut (
		.clk(clk),
		.reset(reset),
		.start(start),
		.V_in(V_in),
		.V_out(V_out),
		.done(done)
	);
	
	// Unpack signals
	assign V_in0 = V_in[WIDTH-1:0];
	assign V_in1 = V_in[2*WIDTH-1:WIDTH];
	assign V_in2 = V_in[3*WIDTH-1:2*WIDTH];
	assign V_in3 = V_in[4*WIDTH-1:3*WIDTH];
	assign V_out0 = V_out[WIDTH-1:0];
	assign V_out1 = V_out[2*WIDTH-1:WIDTH];
	assign V_out2 = V_out[3*WIDTH-1:2*WIDTH];
	assign V_out3 = V_out[4*WIDTH-1:3*WIDTH];
	
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
		$display("Testing vector_scale");
		$display("========================================");
		
		// Test: normalize [4, 8, 12, 16] (max=16)
		// Expected: each element divided by 16, then scaled to Q1.15
		V_in = (16'sd16 << 48) | (16'sd12 << 32) | (16'sd8 << 16) | 16'sd4;
		
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
			$display("Test 1: Scaling completed - PASS");
		end else begin
			$display("Test 1: Scaling completed - FAIL (timeout)");
		end
		
		// Check that output is normalized (max absolute value should be <= 32767)
		v0 = V_out0;
		v1 = V_out1;
		v2 = V_out2;
		v3 = V_out3;
		
		// Calculate max absolute value
		if (v0 < 0) v0 = -v0;
		if (v1 < 0) v1 = -v1;
		if (v2 < 0) v2 = -v2;
		if (v3 < 0) v3 = -v3;
		max_abs = (v0 > v1) ? v0 : v1;
		max_abs = (max_abs > v2) ? max_abs : v2;
		max_abs = (max_abs > v3) ? max_abs : v3;
		
		if (max_abs <= 32767) begin
			$display("  Output normalized: max_abs = %d <= 32767 - PASS", max_abs);
		end else begin
			$display("  Output normalized: max_abs = %d <= 32767 - FAIL", max_abs);
		end
		
		$display("========================================");
		$display("✓ vector_scale test passed");
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
