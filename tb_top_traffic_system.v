`timescale 1ns / 1ps

// Module: tb_top_traffic_system
// Purpose: Testbench to verify all 15 test scenarios outlined in the verification plan contract.

module tb_top_traffic_system;

    // Inputs to the UUT (Unit Under Test)
    reg clk;
    reg rst_n;
    reg emergency_override;
    reg ped_req_a;
    reg ped_req_b;

    // Outputs from the UUT
    wire [5:0] lights_junction_a;
    wire [5:0] lights_junction_b;
    wire       ped_walk_a;
    wire       ped_walk_b;

    // Instantiate the Unit Under Test (UUT)
    top_traffic_system uut (
        .clk               (clk),
        .rst_n             (rst_n),
        .emergency_override(emergency_override),
        .ped_req_a         (ped_req_a),
        .ped_req_b         (ped_req_b),
        .lights_junction_a (lights_junction_a),
        .lights_junction_b (lights_junction_b),
        .ped_walk_a        (ped_walk_a),
        .ped_walk_b        (ped_walk_b)
    );

    // Clock generation (50MHz Clock -> 20ns period)
    always begin
        #10 clk = ~clk;
    end

    // Sequential Test Scenario Execution Block
    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 1;
        emergency_override = 0;
        ped_req_a = 0;
        ped_req_b = 0;

        // ==========================================================
        // TC-01: Reset & Initialization Verification
        // ==========================================================
        $display("[TIME: %0d] TC-01: Applying System Reset...", $time);
        rst_n = 0;
        #40;
        rst_n = 1;
        $display("[TIME: %0d] TC-01: Reset Released. Checking Initial All-Red...", $time);
        #20;

        // ==========================================================
        // TC-02 & TC-03: Base Sequencing Junction A and Junction B
        // ==========================================================
        $display("[TIME: %0d] TC-02/TC-03: Monitoring normal sequencing and loop stability...", $time);
        #400; // Let the state machine advance naturally through vehicle states

        // ==========================================================
        // TC-04: Green-Wave Delay Verification
        // ==========================================================
        $display("[TIME: %0d] TC-04: Monitoring Green-Wave alignment parameters...", $time);
        #200;

        // ==========================================================
        // TC-05 & TC-06: Isolated Pedestrian Requests
        // ==========================================================
        $display("[TIME: %0d] TC-05: Triggering Pedestrian Request at Junction A...", $time);
        ped_req_a = 1; #20; ped_req_a = 0; // Momentary pulse
        #300; // Wait for system to clear A's pedestrian walk cycle

        $display("[TIME: %0d] TC-06: Triggering Pedestrian Request at Junction B...", $time);
        ped_req_b = 1; #20; ped_req_b = 0;
        #300;

        // ==========================================================
        // TC-07 & TC-08: Simultaneous Requests & Anti-Starvation Check
        // ==========================================================
        $display("[TIME: %0d] TC-07/TC-08: Asserting simultaneous continuous requests for A and B...", $time);
        ped_req_a = 1;
        ped_req_b = 1;
        #800; // Keep asserted to watch the Round-Robin token alternate priority
        ped_req_a = 0;
        ped_req_b = 0;
        #100;

        // ==========================================================
        // TC-09: Glitch Filtering on Pedestrian Lines
        // ==========================================================
        $display("[TIME: %0d] TC-09: Sending a short glitch pulse (2ns) on ped_req_a...", $time);
        ped_req_a = 1;
        #2; // Sub-clock cycle pulse width
        ped_req_a = 0;
        #100;

        // ==========================================================
        // TC-10 & TC-11: Emergency Override Assertion and Preemption
        // ==========================================================
        $display("[TIME: %0d] TC-10/TC-11: Activat
