`timescale 1ns / 1ps

module vector_max #(
    parameter integer WIDTH = 12
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*WIDTH-1:0]     V_in,
    output reg  [WIDTH-1:0]       max_out,
    output reg                    done
);

    localparam integer LANE_COUNT = 4;
    
    wire [WIDTH-1:0] lane_values [0:LANE_COUNT-1];
    reg              busy_q;
    reg              busy_d;
    reg              done_d;
    reg [WIDTH-1:0] max_out_d;

    // Extract lane values (combinational)
    assign lane_values[0] = V_in[WIDTH-1:0];
    assign lane_values[1] = V_in[2*WIDTH-1:WIDTH];
    assign lane_values[2] = V_in[3*WIDTH-1:2*WIDTH];
    assign lane_values[3] = V_in[4*WIDTH-1:3*WIDTH];

    // Find maximum using tree structure (combinational)
    wire [WIDTH-1:0] max_01 = (lane_values[0] > lane_values[1]) ? lane_values[0] : lane_values[1];
    wire [WIDTH-1:0] max_23 = (lane_values[2] > lane_values[3]) ? lane_values[2] : lane_values[3];
    wire [WIDTH-1:0] max_result = (max_01 > max_23) ? max_01 : max_23;

    always @(*) begin
        busy_d = busy_q;
        done_d = 1'b0;
        max_out_d = max_out;

        if (start && !busy_q) begin
            busy_d = 1'b1;
        end else if (busy_q) begin
            // Max computation is combinational, just delay one cycle
            max_out_d = max_result;
            busy_d = 1'b0;
            done_d = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            busy_q <= 1'b0;
            max_out <= {WIDTH{1'b0}};
            done <= 1'b0;
        end else begin
            busy_q <= busy_d;
            max_out <= max_out_d;
            done <= done_d;
        end
    end

endmodule

