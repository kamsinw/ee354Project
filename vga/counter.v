`timescale 1ns / 1ps

// counter.v - VGA timing counter following EE354_vga_demo pattern
// Matches the demo's display_controller.v exactly

module counter (
    input  wire clk,
    output wire hSync,
    output wire vSync,
    output reg  bright,
    output reg  [9:0] hCount,
    output reg  [9:0] vCount
);

    // Initialize counters
    initial begin
        hCount = 10'd0;
        vCount = 10'd0;
        bright = 1'b0;
    end
    
    // Horizontal and vertical counter logic (matches demo exactly)
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
    
    // Sync signals (active low during sync pulse)
    // Demo uses: hSync active when hCount < 96, vSync active when vCount < 2
    assign hSync = (hCount < 10'd96) ? 1'b1 : 1'b0;
    assign vSync = (vCount < 10'd2) ? 1'b1 : 1'b0;
    
    // Bright signal - visible area
    // Demo: hCount > 143 && hCount < 784 && vCount > 34 && vCount < 516
    always @(posedge clk) begin
        if (hCount > 10'd143 && hCount < 10'd784 && vCount > 10'd34 && vCount < 10'd516)
            bright <= 1'b1;
        else
            bright <= 1'b0;
    end

endmodule
