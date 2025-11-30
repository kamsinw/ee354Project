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

    reg done_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            V_out <= {(4*WIDTH){1'b0}};
            done <= 1'b0;
            done_reg <= 1'b0;
        end else if (start) begin
            if (max_val > 0) begin
                V_out <= {(V_in3 / max_val), (V_in2 / max_val), (V_in1 / max_val), (V_in0 / max_val)};
            end else begin
                V_out <= V_in;
            end
            done_reg <= 1'b1;
            done <= 1'b1;
        end else begin
            done <= done_reg;
        end
    end

endmodule
