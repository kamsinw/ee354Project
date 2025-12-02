`timescale 1ns / 1ps

module vector_scale #(
    parameter IN_WIDTH   = 10,
    parameter OUT_WIDTH  = 4,
    parameter NORM_WIDTH = IN_WIDTH + 2
) (
    input  wire                        clk,
    input  wire                        reset,
    input  wire                        start,
    input  wire [4*IN_WIDTH-1:0]       V_in,
    input  wire [NORM_WIDTH-1:0]       norm_value,
    output reg  [4*OUT_WIDTH-1:0]      V_out,
    output reg                         done
);

    wire [IN_WIDTH-1:0] V_in0 = V_in[IN_WIDTH-1:0];
    wire [IN_WIDTH-1:0] V_in1 = V_in[2*IN_WIDTH-1:IN_WIDTH];
    wire [IN_WIDTH-1:0] V_in2 = V_in[3*IN_WIDTH-1:2*IN_WIDTH];
    wire [IN_WIDTH-1:0] V_in3 = V_in[4*IN_WIDTH-1:3*IN_WIDTH];

    reg [NORM_WIDTH-1:0] norm_reg;
    reg [IN_WIDTH-1:0] vin_reg0, vin_reg1, vin_reg2, vin_reg3;
    reg waiting_for_div;
    reg div_start;

    localparam integer SCALE_SHIFT = 8;
    localparam integer EXT_WIDTH   = IN_WIDTH + SCALE_SHIFT;
    localparam [OUT_WIDTH-1:0] OUT_MAX = {OUT_WIDTH{1'b1}};

    wire [EXT_WIDTH-1:0] V_in0_shifted = {vin_reg0, {SCALE_SHIFT{1'b0}}};
    wire [EXT_WIDTH-1:0] V_in1_shifted = {vin_reg1, {SCALE_SHIFT{1'b0}}};
    wire [EXT_WIDTH-1:0] V_in2_shifted = {vin_reg2, {SCALE_SHIFT{1'b0}}};
    wire [EXT_WIDTH-1:0] V_in3_shifted = {vin_reg3, {SCALE_SHIFT{1'b0}}};

    wire [OUT_WIDTH-1:0] div_result0, div_result1, div_result2, div_result3;
    wire div_done0, div_done1, div_done2, div_done3;

    multi_cycle_divider #(
        .WIDTH_DIVIDEND(EXT_WIDTH),
        .WIDTH_DIVISOR(NORM_WIDTH),
        .WIDTH_QUOTIENT(OUT_WIDTH)
    ) div0 (
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(V_in0_shifted),
        .divisor(norm_reg),
        .quotient(div_result0),
        .done(div_done0)
    );

    multi_cycle_divider #(
        .WIDTH_DIVIDEND(EXT_WIDTH),
        .WIDTH_DIVISOR(NORM_WIDTH),
        .WIDTH_QUOTIENT(OUT_WIDTH)
    ) div1 (
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(V_in1_shifted),
        .divisor(norm_reg),
        .quotient(div_result1),
        .done(div_done1)
    );

    multi_cycle_divider #(
        .WIDTH_DIVIDEND(EXT_WIDTH),
        .WIDTH_DIVISOR(NORM_WIDTH),
        .WIDTH_QUOTIENT(OUT_WIDTH)
    ) div2 (
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(V_in2_shifted),
        .divisor(norm_reg),
        .quotient(div_result2),
        .done(div_done2)
    );

    multi_cycle_divider #(
        .WIDTH_DIVIDEND(EXT_WIDTH),
        .WIDTH_DIVISOR(NORM_WIDTH),
        .WIDTH_QUOTIENT(OUT_WIDTH)
    ) div3 (
        .clk(clk),
        .reset(reset),
        .start(div_start),
        .dividend(V_in3_shifted),
        .divisor(norm_reg),
        .quotient(div_result3),
        .done(div_done3)
    );

    wire [OUT_WIDTH-1:0] V_out0_final = (div_result0 > OUT_MAX) ? OUT_MAX : div_result0;
    wire [OUT_WIDTH-1:0] V_out1_final = (div_result1 > OUT_MAX) ? OUT_MAX : div_result1;
    wire [OUT_WIDTH-1:0] V_out2_final = (div_result2 > OUT_MAX) ? OUT_MAX : div_result2;
    wire [OUT_WIDTH-1:0] V_out3_final = (div_result3 > OUT_MAX) ? OUT_MAX : div_result3;

    always @(posedge clk) begin
        if (reset) begin
            norm_reg <= {NORM_WIDTH{1'b0}};
            vin_reg0 <= {IN_WIDTH{1'b0}};
            vin_reg1 <= {IN_WIDTH{1'b0}};
            vin_reg2 <= {IN_WIDTH{1'b0}};
            vin_reg3 <= {IN_WIDTH{1'b0}};
            V_out <= {(4*OUT_WIDTH){1'b0}};
            waiting_for_div <= 1'b0;
            div_start <= 1'b0;
            done <= 1'b0;
        end else begin
            div_start <= 1'b0;
            done <= 1'b0;
            if (start && !waiting_for_div) begin
                norm_reg <= (norm_value == 0) ? {{(NORM_WIDTH-1){1'b0}},1'b1} : norm_value;
                vin_reg0 <= V_in0;
                vin_reg1 <= V_in1;
                vin_reg2 <= V_in2;
                vin_reg3 <= V_in3;
                waiting_for_div <= 1'b1;
                div_start <= 1'b1;
            end else if (waiting_for_div) begin
                if (div_done0 && div_done1 && div_done2 && div_done3) begin
                    V_out <= {V_out3_final, V_out2_final, V_out1_final, V_out0_final};
                    waiting_for_div <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule

