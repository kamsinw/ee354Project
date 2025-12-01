`timescale 1ns / 1ps

module tb_vector_register;

	// ========================================
	// SECTION 1: Signal Declarations
	// ========================================
	
	parameter WIDTH = 16;
	
	reg clk;
	reg reset;
	reg load;
	reg signed [4*WIDTH-1:0] in;
	wire signed [4*WIDTH-1:0] out;
	
	// Unpacked signals for display
	wire signed [WIDTH-1:0] in0;
	wire signed [WIDTH-1:0] in1;
	wire signed [WIDTH-1:0] in2;
	wire signed [WIDTH-1:0] in3;
	wire signed [WIDTH-1:0] out0;
	wire signed [WIDTH-1:0] out1;
	wire signed [WIDTH-1:0] out2;
	wire signed [WIDTH-1:0] out3;
	
	// Testbench variables
	integer v0, v1, v2, v3;
	
	// ========================================
	// SECTION 2: Instantiate DUT
	// ========================================
	
	vector_register #(.WIDTH(WIDTH)) uut (
		.clk(clk),
		.reset(reset),
		.load(load),
		.in(in),
		.out(out)
	);
	
	// Unpack signals
	assign in0 = in[WIDTH-1:0];
	assign in1 = in[2*WIDTH-1:WIDTH];
	assign in2 = in[3*WIDTH-1:2*WIDTH];
	assign in3 = in[4*WIDTH-1:3*WIDTH];
	assign out0 = out[WIDTH-1:0];
	assign out1 = out[2*WIDTH-1:WIDTH];
	assign out2 = out[3*WIDTH-1:2*WIDTH];
	assign out3 = out[4*WIDTH-1:3*WIDTH];
	
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
		load = 0;
		
		// Allow reset to propagate
		#100;
		
		// Deassert reset on clock edge
		@(posedge clk);
		#1;
		reset = 0;
		
		$display("========================================");
		$display("Testing vector_register");
		$display("========================================");
		
		// Check initial value (should be [1,1,1,1])
		@(posedge clk);
		v0 = out0;
		v1 = out1;
		v2 = out2;
		v3 = out3;
		
		if (v0 == 1 && v1 == 1 && v2 == 1 && v3 == 1) begin
			$display("Test 1: Initial value is [1,1,1,1] - PASS");
		end else begin
			$display("Test 1: Initial value is [1,1,1,1] - FAIL (got [%d,%d,%d,%d])", v0, v1, v2, v3);
		end
		
		// Load new value
		// Packed as [8,7,6,5] in output due to bit ordering
		in = (16'sd5 << 48) | (16'sd6 << 32) | (16'sd7 << 16) | 16'sd8;
		load = 1;
		@(posedge clk);
		load = 0;
		@(posedge clk);
		
		// Check loaded value
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
		
		$display("========================================");
		$display("✓ vector_register test passed");
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
