`timescale 1ns / 1ps

module counter (
    input  wire clk,
    output wire hSync,
    output wire vSync,
    output reg  bright,
    output reg  [9:0] hCount,
    output reg  [9:0] vCount
);

    initial begin
        hCount = 10'd0;
        vCount = 10'd0;
        bright = 1'b0;
    end

    always @(posedge clk) begin
        if (hCount < 10'd799) begin
            hCount <= hCount + 1'b1;
        end else if (vCount < 10'd524) begin
            hCount <= 10'd0;
            vCount <= vCount + 1'b1;
        end else begin
            hCount <= 10'd0;
            vCount <= 10'd0;
        end
    end

    assign hSync = (hCount < 10'd96) ? 1'b1 : 1'b0;
    assign vSync = (vCount < 10'd2) ? 1'b1 : 1'b0;

    always @(posedge clk) begin
        if (hCount > 10'd143 && hCount < 10'd784 && vCount > 10'd34 && vCount < 10'd516)
            bright <= 1'b1;
        else
            bright <= 1'b0;
    end

endmodule
