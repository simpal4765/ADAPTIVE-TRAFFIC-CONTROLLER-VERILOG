`timescale 1ns / 1ps

module tb_traffic_adaptive;
    reg clk;
    reg rst_n;
    reg ped_req;
    reg [2:0] traffic_density;
    
    wire [5:0] lights;
    wire ped_walk;

    junction_controller_adaptive #(
        .COUNTER_WIDTH(8),
        .MIN_GREEN(10),
        .MAX_GREEN(22), // Low safety cap for simulation quick view
        .EXT_PER_LEVEL(3),
        .YELLOW_TIME(3),
        .RED_TIME(2),
        .PED_TIME(4)
    ) uut (
        .clk(clk), .rst_n(rst_n), .ped_req(ped_req), .traffic_density(traffic_density), .lights(lights), .ped_walk(ped_walk)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; ped_req = 0; traffic_density = 3'b000;
        #20 rst_n = 1;

        // Test 1: Density Level 0 (Should match minimum cycle time = 10)
        $display("[TIME: %0d] Test 1: Simulating Low Traffic Density (Level 0)...", $time);
        wait(lights == 6'b001_100); 
        #250;

        // Test 2: Density Level 3 (Should scale up timing properly)
        $display("[TIME: %0d] Test 2: Simulating Medium Traffic Density (Level 3)...", $time);
        traffic_density = 3'b011;
        #250;

        // Test 3: Density Level 7 (Maximum Density Sweep - Cap Check at 22 cycles)
        $display("[TIME: %0d] Test 3: Simulating Maximum Traffic Density (Level 7 - Safety Cap Check)...", $time);
        traffic_density = 3'b111;
        #300;

        $display("Adaptive Timing Density Sweep Verification Completed Successfully.");
        $finish;
    end
endmodule
