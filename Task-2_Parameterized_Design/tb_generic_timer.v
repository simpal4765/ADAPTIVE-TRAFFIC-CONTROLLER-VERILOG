`timescale 1ns / 1ps

module tb_generic_timer;
    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] count_target;
    wire done;

    // Instantiate with parameter COUNTER_WIDTH = 8
    generic_timer #(.COUNTER_WIDTH(8)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .count_target(count_target),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; start = 0; count_target = 0;
        #20 rst_n = 1;

        // Configuration Parameter Test 1: Count target = 5
        #10 count_target = 8'd5; start = 1; #10 start = 0;
        @(posedge done); #20;

        // Configuration Parameter Test 2: Count target = 12
        #10 count_target = 8'd12; start = 1; #10 start = 0;
        @(posedge done); #20;

        // Configuration Parameter Test 3: Corner Case Target = 0
        #10 count_target = 8'd0; start = 1; #10 start = 0;
        #20;
        if (done) $display("SUCCESS: Target 0 handled properly.");

        $display("Timer Testbench Completed.");
        $finish;
    end
endmodule
