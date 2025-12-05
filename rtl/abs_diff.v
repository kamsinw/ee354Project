`timescale 1ns / 1ps

module abs_diff #(
    parameter integer WIDTH = 4
) (
    input  wire [4*WIDTH-1:0] vec_new,
    input  wire [4*WIDTH-1:0] vec_old,
    output wire [4*WIDTH-1:0] vec_diff
);

    localparam integer LANE_COUNT = 4;

    wire [WIDTH-1:0] val_new [0:LANE_COUNT-1];
    wire [WIDTH-1:0] val_old [0:LANE_COUNT-1];
    wire [WIDTH-1:0] abs_lane [0:LANE_COUNT-1];

    genvar lane_idx;

    generate
        for (lane_idx = 0; lane_idx < LANE_COUNT; lane_idx = lane_idx + 1) begin : slice_lane
            localparam integer LO = lane_idx * WIDTH;
            localparam integer HI = LO + WIDTH - 1;

            assign val_new[lane_idx] = vec_new[HI:LO];
            assign val_old[lane_idx] = vec_old[HI:LO];
            assign abs_lane[lane_idx] = (val_new[lane_idx] >= val_old[lane_idx])
                                      ? (val_new[lane_idx] - val_old[lane_idx])
                                      : (val_old[lane_idx] - val_new[lane_idx]);
            assign vec_diff[HI:LO] = abs_lane[lane_idx];
        end
    endgenerate

endmodule
