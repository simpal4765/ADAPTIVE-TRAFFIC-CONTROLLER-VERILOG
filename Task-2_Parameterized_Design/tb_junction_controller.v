`timescale 1ns / 1ps

module tb_junction_controller;
    reg clk;
    reg rst_n;
    reg ped_req;
    wire [5:0] lights;
    wire ped_walk;

    // Instantiate Junction Controller with specific custom timings
    junction_controller #(
        .COUNTER_WIDTH(8),
        .GREEN_TIME(10),
        .YELLOW_TIME(3),
        .RED_TIME(4),
        .PED_TIME(6)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .ped_req(ped_req),
        .lights(lights),
        .ped_walk(ped_walk)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; ped_req = 0;
        #20 rst_n = 1;

        // Scenario 1: Verify complete standard cycling sequence
        #300; 

        // Scenario 2: Verify pedestrian request arriving during active yellow phase window
        #10;
        // Wait until FSM enters NS_YELLOW (lights output = 6'b010_100)
        wait(lights == 6'b010_100);
        #5 ped_req = 1; #10 ped_req = 0; // Momentary pulse during yellow
        
        wait(ped_walk == 1'b1);
        $display("SUCCESS: Pedestrian request during Yellow was correctly retained and serviced.");

        #200;
        $display("Junction Controller Testbench Completed.");
        $finish;
    end
endmodule
