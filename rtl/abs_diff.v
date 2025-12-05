`timescale 1ns / 1ps

module abs_diff #(
    parameter integer WIDTH = 4
) (
    input  wire [4*WIDTH-1:0] vec_new,
    input  wire [4*WIDTH-1:0] vec_old,
    output wire [4*WIDTH-1:0] vec_diff
);

    localparam integer LANE_COUNT = 4;

    wire [WIDTH-1:0] new_value [0:LANE_COUNT-1];
    wire [WIDTH-1:0] old_value [0:LANE_COUNT-1];
    wire [WIDTH-1:0] lane_abs  [0:LANE_COUNT-1];

    genvar lane_idx;

    generate
        for (lane_idx = 0; lane_idx < LANE_COUNT; lane_idx = lane_idx + 1) begin : slice_lane
            localparam integer LO = lane_idx * WIDTH;
            localparam integer HI = LO + WIDTH - 1;

            assign new_value[lane_idx] = vec_new[HI:LO];
            assign old_value[lane_idx] = vec_old[HI:LO];
            assign lane_abs[lane_idx]  = (new_value[lane_idx] >= old_value[lane_idx])
                                       ? (new_value[lane_idx] - old_value[lane_idx])
                                       : (old_value[lane_idx] - new_value[lane_idx]);
            assign vec_diff[HI:LO]     = lane_abs[lane_idx];
        end
    endgenerate

endmodule
