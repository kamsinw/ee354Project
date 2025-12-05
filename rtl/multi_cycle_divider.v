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

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] DIV   = 2'b01;
    localparam [1:0] DONE  = 2'b10;
    localparam integer COUNT_WIDTH = $clog2(WIDTH_QUOTIENT + 1) + 1;

    reg [1:0] state_q;
    reg [1:0] state_n;

    reg [WIDTH_DIVIDEND-1:0] div_shift_q;
    reg [WIDTH_DIVIDEND-1:0] div_shift_n;

    reg [WIDTH_DIVISOR-1:0] divisor_q;
    reg [WIDTH_DIVISOR-1:0] divisor_n;

    reg [WIDTH_QUOTIENT-1:0] quot_q;
    reg [WIDTH_QUOTIENT-1:0] quot_n;

    reg [WIDTH_DIVISOR:0] rem_q;
    reg [WIDTH_DIVISOR:0] rem_n;

    reg [COUNT_WIDTH-1:0] bit_cnt_q;
    reg [COUNT_WIDTH-1:0] bit_cnt_n;

    reg done_n;
    reg [WIDTH_QUOTIENT-1:0] quot_out_n;

    wire [WIDTH_DIVISOR:0] rem_shifted =
        {rem_q[WIDTH_DIVISOR-1:0], div_shift_q[WIDTH_DIVIDEND-1]};
    wire [WIDTH_DIVISOR:0] rem_after_sub =
        rem_shifted - {1'b0, divisor_q};
    wire subtract_ok = (rem_after_sub[WIDTH_DIVISOR] == 1'b0);

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

    wire [WIDTH_QUOTIENT-1:0] quot_next = shift_in_bit(quot_q, subtract_ok);

    always @(*) begin
        state_n         = state_q;
        div_shift_n = div_shift_q;
        divisor_n        = divisor_q;
        quot_n       = quot_q;
        rem_n      = rem_q;
        bit_cnt_n      = bit_cnt_q;
        done_n           = 1'b0;
        quot_out_n   = quotient;

        case (state_q)
            IDLE: begin
                if (start) begin
                    if (divisor == 0) begin
                        quot_out_n = {WIDTH_QUOTIENT{1'b0}};
                        state_n        = DONE;
                    end else begin
                        div_shift_n = dividend;
                        divisor_n        = divisor;
                        quot_n       = {WIDTH_QUOTIENT{1'b0}};
                        rem_n      = {(WIDTH_DIVISOR+1){1'b0}};
                        bit_cnt_n      = WIDTH_QUOTIENT - 1;
                        state_n          = DIV;
                    end
                end
            end

            DIV: begin
                rem_n = subtract_ok ? rem_after_sub : rem_shifted;
                quot_n  = quot_next;
                div_shift_n = {div_shift_q[WIDTH_DIVIDEND-2:0], 1'b0};

                if (bit_cnt_q == 0) begin
                    quot_out_n = quot_next;
                    state_n        = DONE;
                end else begin
                    bit_cnt_n = bit_cnt_q - 1'b1;
                end
            end

            DONE: begin
                done_n = 1'b1;
                state_n = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state_q         <= IDLE;
            div_shift_q <= {WIDTH_DIVIDEND{1'b0}};
            divisor_q        <= {WIDTH_DIVISOR{1'b0}};
            quot_q       <= {WIDTH_QUOTIENT{1'b0}};
            rem_q      <= {(WIDTH_DIVISOR+1){1'b0}};
            bit_cnt_q      <= {COUNT_WIDTH{1'b0}};
            quotient         <= {WIDTH_QUOTIENT{1'b0}};
            done             <= 1'b0;
        end else begin
            state_q         <= state_n;
            div_shift_q <= div_shift_n;
            divisor_q        <= divisor_n;
            quot_q       <= quot_n;
            rem_q      <= rem_n;
            bit_cnt_q      <= bit_cnt_n;
            quotient         <= quot_out_n;
            done             <= done_n;
        end
    end

endmodule
