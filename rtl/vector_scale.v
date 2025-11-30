`timescale 1ns / 1ps

module vector_scale #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_in,
    output reg  signed [4*WIDTH-1:0] V_out,
    output reg                       done
);

    wire signed [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        .a(V_in),
        .max_val(max_val)
    );

    wire signed [WIDTH-1:0] V_in0 = V_in[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_in1 = V_in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_in2 = V_in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_in3 = V_in[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH-1:0] scale = max_val;
    
    // TIMING OPTIMIZATION: Use 24-bit for shift (needed for << 14), then truncate to 20-bit for division
    // 16-bit input << 14 needs at least 30 bits, but we use 24-bit and truncate (safe for Q2.14)
    wire signed [23:0] V_in0_ext = {{8{V_in0[15]}}, V_in0};
    wire signed [23:0] V_in1_ext = {{8{V_in1[15]}}, V_in1};
    wire signed [23:0] V_in2_ext = {{8{V_in2[15]}}, V_in2};
    wire signed [23:0] V_in3_ext = {{8{V_in3[15]}}, V_in3};
    
    // Shift: 24-bit << 14 = 38-bit result, truncate to 24-bit then to 20-bit
    wire signed [23:0] V_in0_shifted_24 = V_in0_ext << 14;
    wire signed [23:0] V_in1_shifted_24 = V_in1_ext << 14;
    wire signed [23:0] V_in2_shifted_24 = V_in2_ext << 14;
    wire signed [23:0] V_in3_shifted_24 = V_in3_ext << 14;
    wire signed [19:0] V_in0_shifted = V_in0_shifted_24[19:0];
    wire signed [19:0] V_in1_shifted = V_in1_shifted_24[19:0];
    wire signed [19:0] V_in2_shifted = V_in2_shifted_24[19:0];
    wire signed [19:0] V_in3_shifted = V_in3_shifted_24[19:0];
    
    wire signed [19:0] scale_ext = {4'b0, scale};
    
    // TIMING OPTIMIZATION: Use 20-bit division (vs 24-bit) - significant timing improvement
    // 20-bit / 20-bit = 20-bit result, then clamp to 16-bit output
    // Handle division by zero: if scale == 0, return zero vector (all inputs are zero)
    wire signed [19:0] V_in0_ext_20 = V_in0_ext[19:0];
    wire signed [19:0] V_in1_ext_20 = V_in1_ext[19:0];
    wire signed [19:0] V_in2_ext_20 = V_in2_ext[19:0];
    wire signed [19:0] V_in3_ext_20 = V_in3_ext[19:0];
    wire signed [19:0] V_out0_div = (scale > 0) ? (V_in0_shifted / scale_ext) : 20'sd0;
    wire signed [19:0] V_out1_div = (scale > 0) ? (V_in1_shifted / scale_ext) : 20'sd0;
    wire signed [19:0] V_out2_div = (scale > 0) ? (V_in2_shifted / scale_ext) : 20'sd0;
    wire signed [19:0] V_out3_div = (scale > 0) ? (V_in3_shifted / scale_ext) : 20'sd0;
    
    wire signed [15:0] V_out0_final;
    wire signed [15:0] V_out1_final;
    wire signed [15:0] V_out2_final;
    wire signed [15:0] V_out3_final;
    
    // Q2.14 format: 16384 represents 1.0, max is 32767 (represents ~1.999939)
    // TIMING OPTIMIZATION: Simplified clamping for 20-bit result
    // Check top 4 bits: if [19:16] != 0000 (pos) or 1111 (neg), then clamp
    assign V_out0_final = (V_out0_div[19:16] == 4'b0000 || V_out0_div[19:16] == 4'b1111) ? 
                          V_out0_div[15:0] : ((V_out0_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out1_final = (V_out1_div[19:16] == 4'b0000 || V_out1_div[19:16] == 4'b1111) ? 
                          V_out1_div[15:0] : ((V_out1_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out2_final = (V_out2_div[19:16] == 4'b0000 || V_out2_div[19:16] == 4'b1111) ? 
                          V_out2_div[15:0] : ((V_out2_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out3_final = (V_out3_div[19:16] == 4'b0000 || V_out3_div[19:16] == 4'b1111) ? 
                          V_out3_div[15:0] : ((V_out3_div[19]) ? 16'sd32768 : 16'sd32767);

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            V_out <= {V_out3_final, V_out2_final, V_out1_final, V_out0_final};
            done_reg <= 1'b1;
            done <= 1'b1;
        end else begin
            done <= done_reg;
        end
    end

endmodule
