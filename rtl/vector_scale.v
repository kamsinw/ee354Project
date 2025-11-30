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

    wire signed [31:0] scale_num = 32'sd32767;
    wire signed [31:0] scale_den = {16'b0, max_val};
    
    wire signed [31:0] V_out0_scaled = (max_val > 0) ? ((V_in0 * scale_num) / scale_den) : V_in0;
    wire signed [31:0] V_out1_scaled = (max_val > 0) ? ((V_in1 * scale_num) / scale_den) : V_in1;
    wire signed [31:0] V_out2_scaled = (max_val > 0) ? ((V_in2 * scale_num) / scale_den) : V_in2;
    wire signed [31:0] V_out3_scaled = (max_val > 0) ? ((V_in3 * scale_num) / scale_den) : V_in3;

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            V_out <= {V_out3_scaled[15:0], V_out2_scaled[15:0], V_out1_scaled[15:0], V_out0_scaled[15:0]};
            done_reg <= 1'b1;
            done <= 1'b1;
        end else begin
            done <= done_reg;
        end
    end

endmodule
