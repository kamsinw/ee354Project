`timescale 1ns / 1ps

// counter.v - VGA timing counter 

module counter (
    input  wire clk,
    input  wire reset,
    output reg  [9:0] hcount,
    output reg  [9:0] vcount,
    output reg  hsync,
    output reg  vsync,
    output reg  visible
);

    always @(posedge clk) begin
        if (reset) begin
            hcount <= 10'd0;
        end else begin
            if (hcount == 10'd799) begin
                hcount <= 10'd0;
            end else begin
                hcount <= hcount + 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            vcount <= 10'd0;
        end else begin
            if (hcount == 10'd799) begin
                if (vcount == 10'd524) begin
                    vcount <= 10'd0;
                end else begin
                    vcount <= vcount + 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            hsync <= 1'b1;
        end else begin
            if (hcount >= 10'd656 && hcount <= 10'd751) begin
                hsync <= 1'b0;
            end else begin
                hsync <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            vsync <= 1'b1;
        end else begin
            if (vcount >= 10'd490 && vcount <= 10'd491) begin
                vsync <= 1'b0;
            end else begin
                vsync <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            visible <= 1'b0;
        end else begin
            visible <= (hcount < 10'd640) && (vcount < 10'd480);
        end
    end

endmodule

