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
    
    // TIMING OPTIMIZATION: Reduce from 32-bit to 24-bit operations
    // 16-bit input << 14 = 30 bits max, 24 bits provides 8-bit headroom
    wire signed [23:0] V_in0_ext = {{8{V_in0[15]}}, V_in0};
    wire signed [23:0] V_in1_ext = {{8{V_in1[15]}}, V_in1};
    wire signed [23:0] V_in2_ext = {{8{V_in2[15]}}, V_in2};
    wire signed [23:0] V_in3_ext = {{8{V_in3[15]}}, V_in3};
    
    wire signed [23:0] V_in0_shifted = V_in0_ext << 14;
    wire signed [23:0] V_in1_shifted = V_in1_ext << 14;
    wire signed [23:0] V_in2_shifted = V_in2_ext << 14;
    wire signed [23:0] V_in3_shifted = V_in3_ext << 14;
    
    wire signed [23:0] scale_ext = {8'b0, scale};
    
    // TIMING OPTIMIZATION: Reduce division result to 20-bit (vs 32-bit)
    // 24-bit / 16-bit = 20-bit result needed, then clamp to 16-bit output
    wire signed [23:0] V_out0_div_temp = (scale > 0) ? (V_in0_shifted / scale_ext) : V_in0_ext;
    wire signed [23:0] V_out1_div_temp = (scale > 0) ? (V_in1_shifted / scale_ext) : V_in1_ext;
    wire signed [23:0] V_out2_div_temp = (scale > 0) ? (V_in2_shifted / scale_ext) : V_in2_ext;
    wire signed [23:0] V_out3_div_temp = (scale > 0) ? (V_in3_shifted / scale_ext) : V_in3_ext;
    wire signed [19:0] V_out0_div = V_out0_div_temp[19:0];
    wire signed [19:0] V_out1_div = V_out1_div_temp[19:0];
    wire signed [19:0] V_out2_div = V_out2_div_temp[19:0];
    wire signed [19:0] V_out3_div = V_out3_div_temp[19:0];
    
    wire signed [15:0] V_out0_final;
    wire signed [15:0] V_out1_final;
    wire signed [15:0] V_out2_final;
    wire signed [15:0] V_out3_final;
    
    // Q2.14 format: 16384 represents 1.0, max is 32767 (represents ~1.999939)
    // TIMING OPTIMIZATION: Clamp 20-bit result to 16-bit range
    // Check if value exceeds 16-bit signed range: -32768 to 32767
    // For 20-bit: clamp if bits[19:15] are not all 0s (pos) or all 1s (neg)
    assign V_out0_final = (V_out0_div[19:15] == 5'b00000 || V_out0_div[19:15] == 5'b11111) ? 
                          V_out0_div[15:0] : ((V_out0_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out1_final = (V_out1_div[19:15] == 5'b00000 || V_out1_div[19:15] == 5'b11111) ? 
                          V_out1_div[15:0] : ((V_out1_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out2_final = (V_out2_div[19:15] == 5'b00000 || V_out2_div[19:15] == 5'b11111) ? 
                          V_out2_div[15:0] : ((V_out2_div[19]) ? 16'sd32768 : 16'sd32767);
    assign V_out3_final = (V_out3_div[19:15] == 5'b00000 || V_out3_div[19:15] == 5'b11111) ? 
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
