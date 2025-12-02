`timescale 1ns / 1ps

module multi_cycle_divider #(
    parameter integer WIDTH_DIVIDEND = 12,
    parameter integer WIDTH_DIVISOR  = 12,
    parameter integer WIDTH_QUOTIENT = 4
) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      start,
    input  wire [WIDTH_DIVIDEND-1:0] dividend,
    input  wire [WIDTH_DIVISOR-1:0]  divisor,
    output reg  [WIDTH_QUOTIENT-1:0] quotient,
    output reg                       done
);

    localparam [1:0] STATE_IDLE  = 2'b00;
    localparam [1:0] STATE_DIV   = 2'b01;
    localparam [1:0] STATE_DONE  = 2'b10;
    localparam integer COUNT_WIDTH = $clog2(WIDTH_QUOTIENT + 1) + 1;

    reg [1:0] state_q;
    reg [1:0] state_d;

    reg [WIDTH_DIVIDEND-1:0] dividend_shift_q;
    reg [WIDTH_DIVIDEND-1:0] dividend_shift_d;

    reg [WIDTH_DIVISOR-1:0] divisor_q;
    reg [WIDTH_DIVISOR-1:0] divisor_d;

    reg [WIDTH_QUOTIENT-1:0] quotient_q;
    reg [WIDTH_QUOTIENT-1:0] quotient_d;

    reg [WIDTH_DIVISOR:0] remainder_q;
    reg [WIDTH_DIVISOR:0] remainder_d;

    reg [COUNT_WIDTH-1:0] bit_count_q;
    reg [COUNT_WIDTH-1:0] bit_count_d;

    reg done_d;
    reg [WIDTH_QUOTIENT-1:0] quotient_out_d;

    wire [WIDTH_DIVISOR:0] remainder_shifted =
        {remainder_q[WIDTH_DIVISOR-1:0], dividend_shift_q[WIDTH_DIVIDEND-1]};
    wire [WIDTH_DIVISOR:0] remainder_after_sub =
        remainder_shifted - {1'b0, divisor_q};
    wire subtract_success = (remainder_after_sub[WIDTH_DIVISOR] == 1'b0);

    function [WIDTH_QUOTIENT-1:0] shift_in_bit;
        input [WIDTH_QUOTIENT-1:0] current;
        input                      new_bit;
        begin
            if (WIDTH_QUOTIENT == 1) begin
                shift_in_bit = {new_bit};
            end else begin
                shift_in_bit = {current[WIDTH_QUOTIENT-2:0], new_bit};
            end
        end
    endfunction

    wire [WIDTH_QUOTIENT-1:0] quotient_next = shift_in_bit(quotient_q, subtract_success);

    always @(*) begin
        state_d         = state_q;
        dividend_shift_d = dividend_shift_q;
        divisor_d        = divisor_q;
        quotient_d       = quotient_q;
        remainder_d      = remainder_q;
        bit_count_d      = bit_count_q;
        done_d           = 1'b0;
        quotient_out_d   = quotient;

        case (state_q)
            STATE_IDLE: begin
                if (start) begin
                    if (divisor == 0) begin
                        quotient_out_d = {WIDTH_QUOTIENT{1'b0}};
                        state_d        = STATE_DONE;
                    end else begin
                        dividend_shift_d = dividend;
                        divisor_d        = divisor;
                        quotient_d       = {WIDTH_QUOTIENT{1'b0}};
                        remainder_d      = {(WIDTH_DIVISOR+1){1'b0}};
                        bit_count_d      = WIDTH_QUOTIENT - 1;
                        state_d          = STATE_DIV;
                    end
                end
            end

            STATE_DIV: begin
                remainder_d = subtract_success ? remainder_after_sub : remainder_shifted;
                quotient_d  = quotient_next;
                dividend_shift_d = {dividend_shift_q[WIDTH_DIVIDEND-2:0], 1'b0};

                if (bit_count_q == 0) begin
                    quotient_out_d = quotient_next;
                    state_d        = STATE_DONE;
                end else begin
                    bit_count_d = bit_count_q - 1'b1;
                end
            end

            STATE_DONE: begin
                done_d = 1'b1;
                state_d = STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q         <= STATE_IDLE;
            dividend_shift_q <= {WIDTH_DIVIDEND{1'b0}};
            divisor_q        <= {WIDTH_DIVISOR{1'b0}};
            quotient_q       <= {WIDTH_QUOTIENT{1'b0}};
            remainder_q      <= {(WIDTH_DIVISOR+1){1'b0}};
            bit_count_q      <= {COUNT_WIDTH{1'b0}};
            quotient         <= {WIDTH_QUOTIENT{1'b0}};
            done             <= 1'b0;
        end else begin
            state_q         <= state_d;
            dividend_shift_q <= dividend_shift_d;
            divisor_q        <= divisor_d;
            quotient_q       <= quotient_d;
            remainder_q      <= remainder_d;
            bit_count_q      <= bit_count_d;
            quotient         <= quotient_out_d;
            done             <= done_d;
        end
    end

endmodule
