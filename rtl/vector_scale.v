`timescale 1ns / 1ps

module vector_scale #(parameter WIDTH = 16) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire signed [4*WIDTH-1:0] V_in,
    output reg  signed [4*WIDTH-1:0] V_out,
    output reg                       done
);

    wire signed [WIDTH-1:0] V_in0 = V_in[WIDTH-1:0];
    wire signed [WIDTH-1:0] V_in1 = V_in[2*WIDTH-1:WIDTH];
    wire signed [WIDTH-1:0] V_in2 = V_in[3*WIDTH-1:2*WIDTH];
    wire signed [WIDTH-1:0] V_in3 = V_in[4*WIDTH-1:3*WIDTH];

    wire signed [WIDTH:0] V_in0_17 = {V_in0[15], V_in0};
    wire signed [WIDTH:0] V_in1_17 = {V_in1[15], V_in1};
    wire signed [WIDTH:0] V_in2_17 = {V_in2[15], V_in2};
    wire signed [WIDTH:0] V_in3_17 = {V_in3[15], V_in3};

    wire signed [WIDTH:0] abs_V_in0_17 = (V_in0_17 < 0) ? (-V_in0_17) : V_in0_17;
    wire signed [WIDTH:0] abs_V_in1_17 = (V_in1_17 < 0) ? (-V_in1_17) : V_in1_17;
    wire signed [WIDTH:0] abs_V_in2_17 = (V_in2_17 < 0) ? (-V_in2_17) : V_in2_17;
    wire signed [WIDTH:0] abs_V_in3_17 = (V_in3_17 < 0) ? (-V_in3_17) : V_in3_17;

    wire [WIDTH-1:0] abs_V_in0 = abs_V_in0_17[WIDTH-1:0];
    wire [WIDTH-1:0] abs_V_in1 = abs_V_in1_17[WIDTH-1:0];
    wire [WIDTH-1:0] abs_V_in2 = abs_V_in2_17[WIDTH-1:0];
    wire [WIDTH-1:0] abs_V_in3 = abs_V_in3_17[WIDTH-1:0];

    wire [4*WIDTH-1:0] abs_V_in = {abs_V_in3, abs_V_in2, abs_V_in1, abs_V_in0};

    wire [WIDTH-1:0] max_val;

    max_finder #(WIDTH) MF (
        .a(abs_V_in),
        .max_val(max_val)
    );

    wire signed [WIDTH-1:0] scale = max_val;
    
    wire signed [31:0] V_in0_ext = {{16{V_in0[15]}}, V_in0};
    wire signed [31:0] V_in1_ext = {{16{V_in1[15]}}, V_in1};
    wire signed [31:0] V_in2_ext = {{16{V_in2[15]}}, V_in2};
    wire signed [31:0] V_in3_ext = {{16{V_in3[15]}}, V_in3};
    
    wire signed [31:0] scale_ext = {{16{scale[15]}}, scale};
    
    wire signed [31:0] V_in0_shifted = V_in0_ext << 15;
    wire signed [31:0] V_in1_shifted = V_in1_ext << 15;
    wire signed [31:0] V_in2_shifted = V_in2_ext << 15;
    wire signed [31:0] V_in3_shifted = V_in3_ext << 15;
    
    wire signed [31:0] V_out0_div_raw = (scale > 0) ? (V_in0_shifted / scale_ext) : V_in0_ext;
    wire signed [31:0] V_out1_div_raw = (scale > 0) ? (V_in1_shifted / scale_ext) : V_in1_ext;
    wire signed [31:0] V_out2_div_raw = (scale > 0) ? (V_in2_shifted / scale_ext) : V_in2_ext;
    wire signed [31:0] V_out3_div_raw = (scale > 0) ? (V_in3_shifted / scale_ext) : V_in3_ext;
    
    wire signed [WIDTH-1:0] max_pos = ((1 << (WIDTH-1)) - 1);
    wire signed [WIDTH-1:0] min_neg = -(1 << (WIDTH-1));
    
    wire signed [15:0] V_out0;
    wire signed [15:0] V_out1;
    wire signed [15:0] V_out2;
    wire signed [15:0] V_out3;
    
    assign V_out0 = (V_out0_div_raw > max_pos) ? max_pos : 
                    ((V_out0_div_raw < min_neg) ? min_neg : V_out0_div_raw[WIDTH-1:0]);
    assign V_out1 = (V_out1_div_raw > max_pos) ? max_pos : 
                    ((V_out1_div_raw < min_neg) ? min_neg : V_out1_div_raw[WIDTH-1:0]);
    assign V_out2 = (V_out2_div_raw > max_pos) ? max_pos : 
                    ((V_out2_div_raw < min_neg) ? min_neg : V_out2_div_raw[WIDTH-1:0]);
    assign V_out3 = (V_out3_div_raw > max_pos) ? max_pos : 
                    ((V_out3_div_raw < min_neg) ? min_neg : V_out3_div_raw[WIDTH-1:0]);

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            V_out <= {V_out3, V_out2, V_out1, V_out0};
            done_reg <= 1'b1;
            done <= 1'b1;
        end else if (done_reg) begin
            done <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end

endmodule
