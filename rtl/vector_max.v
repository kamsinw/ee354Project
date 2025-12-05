`timescale 1ns / 1ps

module vector_max #(
    parameter integer WIDTH = 12
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   start,
    input  wire [4*WIDTH-1:0]     V_in,
    output reg  [WIDTH-1:0]       max_out,
    output reg                    done
);

    localparam integer LANE_COUNT = 4;

    wire [WIDTH-1:0] lanes [0:LANE_COUNT-1];
    reg              busy_q;
    reg              busy_n;
    reg              done_n;
    reg [WIDTH-1:0] max_out_n;

    assign lanes[0] = V_in[WIDTH-1:0];
    assign lanes[1] = V_in[2*WIDTH-1:WIDTH];
    assign lanes[2] = V_in[3*WIDTH-1:2*WIDTH];
    assign lanes[3] = V_in[4*WIDTH-1:3*WIDTH];

    wire [WIDTH-1:0] max_l = (lanes[0] > lanes[1]) ? lanes[0] : lanes[1];
    wire [WIDTH-1:0] max_r = (lanes[2] > lanes[3]) ? lanes[2] : lanes[3];
    wire [WIDTH-1:0] max_all = (max_l > max_r) ? max_l : max_r;

    always @(*) begin
        busy_n = busy_q;
        done_n = 1'b0;
        max_out_n = max_out;

        if (start && !busy_q) begin
            busy_n = 1'b1;
        end else if (busy_q) begin
            max_out_n = max_all;
            busy_n = 1'b0;
            done_n = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            busy_q <= 1'b0;
            max_out <= {WIDTH{1'b0}};
            done <= 1'b0;
        end else begin
            busy_q <= busy_n;
            max_out <= max_out_n;
            done <= done_n;
        end
    end

endmodule
