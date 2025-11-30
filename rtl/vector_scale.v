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
    
    wire signed [31:0] V_in0_shifted = V_in0 << 15;
    wire signed [31:0] V_in1_shifted = V_in1 << 15;
    wire signed [31:0] V_in2_shifted = V_in2 << 15;
    wire signed [31:0] V_in3_shifted = V_in3 << 15;
    
    wire signed [31:0] scale_ext = {16'b0, scale};
    
    wire signed [31:0] V_out0_div = (scale > 0) ? (V_in0_shifted / scale_ext) : V_in0;
    wire signed [31:0] V_out1_div = (scale > 0) ? (V_in1_shifted / scale_ext) : V_in1;
    wire signed [31:0] V_out2_div = (scale > 0) ? (V_in2_shifted / scale_ext) : V_in2;
    wire signed [31:0] V_out3_div = (scale > 0) ? (V_in3_shifted / scale_ext) : V_in3;
    
    wire signed [15:0] V_out0_clamped;
    wire signed [15:0] V_out1_clamped;
    wire signed [15:0] V_out2_clamped;
    wire signed [15:0] V_out3_clamped;
    
    assign V_out0_clamped = (V_out0_div > 32767) ? 16'sd32767 : 
                             ((V_out0_div < -32768) ? -16'sd32768 : V_out0_div[15:0]);
    assign V_out1_clamped = (V_out1_div > 32767) ? 16'sd32767 : 
                             ((V_out1_div < -32768) ? -16'sd32768 : V_out1_div[15:0]);
    assign V_out2_clamped = (V_out2_div > 32767) ? 16'sd32767 : 
                             ((V_out2_div < -32768) ? -16'sd32768 : V_out2_div[15:0]);
    assign V_out3_clamped = (V_out3_div > 32767) ? 16'sd32767 : 
                             ((V_out3_div < -32768) ? -16'sd32768 : V_out3_div[15:0]);

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            V_out <= {V_out3_clamped, V_out2_clamped, V_out1_clamped, V_out0_clamped};
            done_reg <= 1'b1;
            done <= 1'b1;
        end else begin
            done <= done_reg;
            if (!start && done_reg) begin
                done_reg <= 1'b0;
            end
        end
    end

endmodule
