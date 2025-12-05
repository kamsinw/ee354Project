`timescale 1ns / 1ps

module max_finder #(
    parameter integer WIDTH = 4
) (
    input  wire               clk,
    input  wire               reset,
    input  wire [4*WIDTH-1:0] lane_values,
    output reg  [WIDTH-1:0]   max_value
);

    localparam integer LANE_COUNT = 4;

    wire [WIDTH-1:0] lanes [0:LANE_COUNT-1];

    genvar lane_idx;
    generate
        for (lane_idx = 0; lane_idx < LANE_COUNT; lane_idx = lane_idx + 1) begin : unpack_lane
            localparam integer LO = lane_idx * WIDTH;
            localparam integer HI = LO + WIDTH - 1;
            assign lanes[lane_idx] = lane_values[HI:LO];
        end
    endgenerate

    wire [WIDTH-1:0] max_l = (lanes[0] > lanes[1]) ? lanes[0] : lanes[1];
    wire [WIDTH-1:0] max_r = (lanes[2] > lanes[3]) ? lanes[2] : lanes[3];

    reg [WIDTH-1:0] max_l_q;
    reg [WIDTH-1:0] max_r_q;

    always @(posedge clk) begin
        if (reset) begin
            max_l_q <= {WIDTH{1'b0}};
            max_r_q <= {WIDTH{1'b0}};
            max_value <= {WIDTH{1'b0}};
        end else begin
            max_l_q <= max_l;
            max_r_q <= max_r;
            max_value <= (max_l_q > max_r_q) ? max_l_q : max_r_q;
        end
    end

endmodule
