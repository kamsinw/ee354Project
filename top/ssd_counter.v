`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ssd_counter
// Description:    Seven-segment display counter with scanning
//                 Renamed from 'counter' to avoid conflict with VGA counter
//////////////////////////////////////////////////////////////////////////////////
module ssd_counter(
    input clk,
    input [15:0] displayNumberLow,
    input [15:0] displayNumberHigh,
    output reg [7:0] anode,
    output reg [6:0] ssdOut
);

    reg [20:0] refresh;
    reg [3:0] LEDNumber;
    wire [2:0] LEDCounter;

    // Registered BCD digits for lower and upper displays
    reg [3:0] digit_low3, digit_low2, digit_low1, digit_low0;
    reg [3:0] digit_high3, digit_high2, digit_high1, digit_high0;

    reg [15:0] clamped_value_low;
    reg [15:0] clamped_value_high;
    reg [19:0] bcd_digits_low;
    reg [19:0] bcd_digits_high;

    // 16-bit to BCD (shift-add-3) helper
    function [19:0] bin16_to_bcd;
        input [15:0] value;
        integer idx;
        reg [35:0] shift_reg;
        begin
            shift_reg = 36'd0;
            shift_reg[15:0] = value;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
                if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
                if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
                if (shift_reg[31:28] >= 5) shift_reg[31:28] = shift_reg[31:28] + 3;
                shift_reg = shift_reg << 1;
            end
            bin16_to_bcd = shift_reg[35:16];
        end
    endfunction

    // Initialize refresh counter to zero
    initial begin
        refresh = 21'd0;
    end

    // Refresh counter for multiplexing
    always @(posedge clk) begin
        refresh <= refresh + 21'd1;
    end
    assign LEDCounter = refresh[20:18];

    // Update the BCD digits once per clock
    always @(posedge clk) begin
        if (displayNumberLow > 16'd9999) begin
            clamped_value_low = 16'd9999;
        end else begin
            clamped_value_low = displayNumberLow;
        end
        bcd_digits_low = bin16_to_bcd(clamped_value_low);
        digit_low3 <= bcd_digits_low[15:12];
        digit_low2 <= bcd_digits_low[11:8];
        digit_low1 <= bcd_digits_low[7:4];
        digit_low0 <= bcd_digits_low[3:0];

        if (displayNumberHigh > 16'd9999) begin
            clamped_value_high = 16'd9999;
        end else begin
            clamped_value_high = displayNumberHigh;
        end
        bcd_digits_high = bin16_to_bcd(clamped_value_high);
        digit_high3 <= bcd_digits_high[15:12];
        digit_high2 <= bcd_digits_high[11:8];
        digit_high1 <= bcd_digits_high[7:4];
        digit_high0 <= bcd_digits_high[3:0];
    end

    // Register the anode and digit selection
    always @(posedge clk) begin
        case (LEDCounter)
            3'd0: begin
                anode <= 8'b0111_1111;
                LEDNumber <= digit_high3;
            end
            3'd1: begin
                anode <= 8'b1011_1111;
                LEDNumber <= digit_high2;
            end
            3'd2: begin
                anode <= 8'b1101_1111;
                LEDNumber <= digit_high1;
            end
            3'd3: begin
                anode <= 8'b1110_1111;
                LEDNumber <= digit_high0;
            end
            3'd4: begin
                anode <= 8'b1111_0111;
                LEDNumber <= digit_low3;
            end
            3'd5: begin
                anode <= 8'b1111_1011;
                LEDNumber <= digit_low2;
            end
            3'd6: begin
                anode <= 8'b1111_1101;
                LEDNumber <= digit_low1;
            end
            3'd7: begin
                anode <= 8'b1111_1110;
                LEDNumber <= digit_low0;
            end
        endcase
    end

    // Register the segment output for clean display
    always @(posedge clk) begin
        case (LEDNumber)
            4'b0000: ssdOut <= 7'b0000001;
            4'b0001: ssdOut <= 7'b1001111;
            4'b0010: ssdOut <= 7'b0010010;
            4'b0011: ssdOut <= 7'b0000110;
            4'b0100: ssdOut <= 7'b1001100;
            4'b0101: ssdOut <= 7'b0100100;
            4'b0110: ssdOut <= 7'b0100000;
            4'b0111: ssdOut <= 7'b0001111;
            4'b1000: ssdOut <= 7'b0000000;
            4'b1001: ssdOut <= 7'b0000100;
            default: ssdOut <= 7'b0000001;
        endcase
    end

endmodule

