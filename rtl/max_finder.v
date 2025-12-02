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

    wire [WIDTH-1:0] lane_data [0:LANE_COUNT-1];

    genvar lane_idx;
    generate
        for (lane_idx = 0; lane_idx < LANE_COUNT; lane_idx = lane_idx + 1) begin : unpack_lane
            localparam integer LO = lane_idx * WIDTH;
            localparam integer HI = LO + WIDTH - 1;
            assign lane_data[lane_idx] = lane_values[HI:LO];
        end
    endgenerate

    wire [WIDTH-1:0] left_pair  = (lane_data[0] > lane_data[1]) ? lane_data[0] : lane_data[1];
    wire [WIDTH-1:0] right_pair = (lane_data[2] > lane_data[3]) ? lane_data[2] : lane_data[3];

    reg [WIDTH-1:0] left_pair_q;
    reg [WIDTH-1:0] right_pair_q;

    always @(posedge clk) begin
        if (reset) begin
            left_pair_q  <= {WIDTH{1'b0}};
            right_pair_q <= {WIDTH{1'b0}};
            max_value    <= {WIDTH{1'b0}};
        end else begin
            left_pair_q  <= left_pair;
            right_pair_q <= right_pair;
            max_value    <= (left_pair_q > right_pair_q) ? left_pair_q : right_pair_q;
        end
    end

endmodule
