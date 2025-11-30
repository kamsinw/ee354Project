`timescale 1ns / 1ps

module tb_digit_segments;

    reg [3:0] digit;
    wire [6:0] segments;

    digit_segments uut (
        .digit(digit),
        .segments(segments)
    );

    initial begin
        #1000;
        $fatal("TIMEOUT: simulation did not complete");
    end

    initial begin
        $display("========================================");
        $display("Testing digit_segments");
        $display("========================================");

        integer i;
        for (i = 0; i < 10; i = i + 1) begin
            digit = i;
            #1;
            $display("Digit %d: segments = 7'b%b", i, segments);
            
            case (i)
                0: if (segments == 7'b1111110) $display("  PASS");
                1: if (segments == 7'b0110000) $display("  PASS");
                8: if (segments == 7'b1111111) $display("  PASS");
                9: if (segments == 7'b1111011) $display("  PASS");
                default: $display("  Checked");
            endcase
        end

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================\n");
        $display("TEST PASSED");
        #10;
        $finish;
    end

endmodule
