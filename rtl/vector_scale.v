`timescale 1ns / 1ps

module vector_scale #(
    parameter integer IN_WIDTH   = 10,
    parameter integer OUT_WIDTH  = 4,
    parameter integer NORM_WIDTH = IN_WIDTH + 2
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*IN_WIDTH-1:0]  V_in,
    input  wire [NORM_WIDTH-1:0]  norm_value,
    output reg  [4*OUT_WIDTH-1:0] V_out,
    output reg                    done
);

    localparam integer LANE_COUNT  = 4;
    localparam integer SCALE_SHIFT = 8;
    localparam integer EXT_WIDTH   = IN_WIDTH + SCALE_SHIFT;
    localparam [OUT_WIDTH-1:0] OUT_MAX = {OUT_WIDTH{1'b1}};

    wire [IN_WIDTH-1:0]   lane_input   [0:LANE_COUNT-1];
    reg  [IN_WIDTH-1:0]   lane_reg_q   [0:LANE_COUNT-1];
    reg  [IN_WIDTH-1:0]   lane_reg_d   [0:LANE_COUNT-1];
    wire [OUT_WIDTH-1:0]  lane_scaled  [0:LANE_COUNT-1];
    wire [LANE_COUNT-1:0] divider_done;
    wire [4*OUT_WIDTH-1:0] scaled_vector;

    reg [NORM_WIDTH-1:0] norm_q;
    reg [NORM_WIDTH-1:0] norm_d;
    reg                  waiting_q;
    reg                  waiting_d;
    reg                  div_start_q;
    reg                  div_start_d;
    reg  [4*OUT_WIDTH-1:0] v_out_d;
    reg                  done_d;

    genvar lane;

    generate
        for (lane = 0; lane < LANE_COUNT; lane = lane + 1) begin : lane_logic
            localparam integer IN_LO  = lane * IN_WIDTH;
            localparam integer IN_HI  = IN_LO + IN_WIDTH - 1;
            localparam integer OUT_LO = lane * OUT_WIDTH;
            localparam integer OUT_HI = OUT_LO + OUT_WIDTH - 1;

            wire [EXT_WIDTH-1:0] dividend_shifted = {lane_reg_q[lane], {SCALE_SHIFT{1'b0}}};
            wire [OUT_WIDTH-1:0] quotient_lane;

            assign lane_input[lane] = V_in[IN_HI:IN_LO];

            multi_cycle_divider #(
                .WIDTH_DIVIDEND(EXT_WIDTH),
                .WIDTH_DIVISOR (NORM_WIDTH),
                .WIDTH_QUOTIENT(OUT_WIDTH)
            ) lane_divider (
                .clk     (clk),
                .reset   (reset),
                .start   (div_start_q),
                .dividend(dividend_shifted),
                .divisor (norm_q),
                .quotient(quotient_lane),
                .done    (divider_done[lane])
            );

            assign lane_scaled[lane]               = (quotient_lane > OUT_MAX) ? OUT_MAX : quotient_lane;
            assign scaled_vector[OUT_HI:OUT_LO]    = lane_scaled[lane];
        end
    endgenerate

    wire all_dividers_done = &divider_done;

    integer idx;

    always @(*) begin
        norm_d      = norm_q;
        waiting_d   = waiting_q;
        div_start_d = 1'b0;
        done_d      = 1'b0;
        v_out_d     = V_out;

        for (idx = 0; idx < LANE_COUNT; idx = idx + 1) begin
            lane_reg_d[idx] = lane_reg_q[idx];
        end

        if (start && !waiting_q) begin
            norm_d = (norm_value == 0)
                   ? {{(NORM_WIDTH-1){1'b0}}, 1'b1}
                   : norm_value;
            for (idx = 0; idx < LANE_COUNT; idx = idx + 1) begin
                lane_reg_d[idx] = lane_input[idx];
            end
            waiting_d   = 1'b1;
            div_start_d = 1'b1;
        end else if (waiting_q && all_dividers_done) begin
            v_out_d   = scaled_vector;
            waiting_d = 1'b0;
            done_d    = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            norm_q    <= {NORM_WIDTH{1'b0}};
            waiting_q <= 1'b0;
            div_start_q <= 1'b0;
            V_out     <= {(4*OUT_WIDTH){1'b0}};
            done      <= 1'b0;
            for (idx = 0; idx < LANE_COUNT; idx = idx + 1) begin
                lane_reg_q[idx] <= {IN_WIDTH{1'b0}};
            end
        end else begin
            norm_q      <= norm_d;
            waiting_q   <= waiting_d;
            div_start_q <= div_start_d;
            V_out       <= v_out_d;
            done        <= done_d;
            for (idx = 0; idx < LANE_COUNT; idx = idx + 1) begin
                lane_reg_q[idx] <= lane_reg_d[idx];
            end
        end
    end

endmodule
