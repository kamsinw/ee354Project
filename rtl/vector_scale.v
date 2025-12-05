`timescale 1ns / 1ps

module vector_scale #(
    parameter integer IN_WIDTH   = 12,
    parameter integer OUT_WIDTH  = 4
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*IN_WIDTH-1:0]  V_in,
    output reg  [4*OUT_WIDTH-1:0] V_out,
    output reg                    done
);

    localparam integer LANE_COUNT = 4;

    localparam [1:0] IDLE    = 2'd0;
    localparam [1:0] COMPUTE = 2'd1;

    reg [1:0] state_q, state_n;
    reg [4*OUT_WIDTH-1:0] v_out_n;
    reg done_n;

    wire [IN_WIDTH-1:0] lane0 = V_in[0*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane1 = V_in[1*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane2 = V_in[2*IN_WIDTH +: IN_WIDTH];
    wire [IN_WIDTH-1:0] lane3 = V_in[3*IN_WIDTH +: IN_WIDTH];

    wire [IN_WIDTH-1:0] max_l = (lane0 > lane1) ? lane0 : lane1;
    wire [IN_WIDTH-1:0] max_r = (lane2 > lane3) ? lane2 : lane3;
    wire [IN_WIDTH-1:0] max_all = (max_l > max_r) ? max_l : max_r;

    reg [3:0] msb_pos;

    always @(*) begin
        if (max_all[11]) msb_pos = 4'd11;
        else if (max_all[10]) msb_pos = 4'd10;
        else if (max_all[9])  msb_pos = 4'd9;
        else if (max_all[8])  msb_pos = 4'd8;
        else if (max_all[7])  msb_pos = 4'd7;
        else if (max_all[6])  msb_pos = 4'd6;
        else if (max_all[5])  msb_pos = 4'd5;
        else if (max_all[4])  msb_pos = 4'd4;
        else if (max_all[3])  msb_pos = 4'd3;
        else if (max_all[2])  msb_pos = 4'd2;
        else if (max_all[1])  msb_pos = 4'd1;
        else msb_pos = 4'd0;
    end

    wire [3:0] shift_amt = (max_all == 0) ? 4'd0 : (4'd11 - msb_pos);
    wire [14:0] scale_factor = 15'd15 << shift_amt;

    wire [26:0] prod0 = lane0 * scale_factor;
    wire [26:0] prod1 = lane1 * scale_factor;
    wire [26:0] prod2 = lane2 * scale_factor;
    wire [26:0] prod3 = lane3 * scale_factor;

    wire [15:0] res0 = prod0[26:11];
    wire [15:0] res1 = prod1[26:11];
    wire [15:0] res2 = prod2[26:11];
    wire [15:0] res3 = prod3[26:11];

    wire [OUT_WIDTH-1:0] scaled0 = (max_all == 0) ? 4'd0 :
                                   (res0 > 16'd15) ? 4'd15 : res0[3:0];

    wire [OUT_WIDTH-1:0] scaled1 = (max_all == 0) ? 4'd0 :
                                   (res1 > 16'd15) ? 4'd15 : res1[3:0];

    wire [OUT_WIDTH-1:0] scaled2 = (max_all == 0) ? 4'd0 :
                                   (res2 > 16'd15) ? 4'd15 : res2[3:0];

    wire [OUT_WIDTH-1:0] scaled3 = (max_all == 0) ? 4'd0 :
                                   (res3 > 16'd15) ? 4'd15 : res3[3:0];

    wire [4*OUT_WIDTH-1:0] scaled_vec = {scaled3, scaled2, scaled1, scaled0};

    always @(*) begin
        state_n = state_q;
        v_out_n = V_out;
        done_n  = 1'b0;

        case (state_q)
            IDLE: begin
                if (start) begin
                    state_n = COMPUTE;
                end
            end

            COMPUTE: begin
                v_out_n = scaled_vec;
                done_n  = 1'b1;
                state_n = IDLE;
            end

            default: begin
                state_n = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q <= IDLE;
            V_out   <= {(4*OUT_WIDTH){1'b0}};
            done    <= 1'b0;
        end else begin
            state_q <= state_n;
            V_out   <= v_out_n;
            done    <= done_n;
        end
    end

endmodule
