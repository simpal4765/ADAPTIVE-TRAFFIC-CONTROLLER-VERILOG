`timescale 1ns / 1ps

// Module: tb_amtgc_self_checking
// Description: Advanced unified self-checking testbench with automated scoreboarding and random stimuli generation.

module tb_amtgc_self_checking;

    // Inputs to UUT
    reg clk;
    reg rst_n;
    reg emergency_override;
    reg ped_req_a;
    reg ped_req_b;
    reg [2:0] density_a;
    reg [2:0] density_b;

    // Outputs from UUT
    wire [5:0] lights_a;
    wire [5:0] lights_b;
    wire       ped_walk_a;
    wire       ped_walk_b;

    // Verification Scoreboard Variables
    integer error_count = 0;
    integer ped_requests_served = 0;
    integer loop_index = 0;
    reg [2:0] rand_density;

    // Instantiate System Top Module with Custom Configurations
    amtgc_top #(
        .COUNTER_WIDTH(8),
        .JA_GREEN(12), .JA_YELLOW(3), .JA_RED(4), .JA_PED(5),
        .JB_GREEN(10), .JB_YELLOW(2), .JB_RED(3), .JB_PED(4),
        .GREEN_WAVE_OFFSET(6)
    ) uut (
        .clk               (clk),
        .rst_n             (rst_n),
        .emergency_override(emergency_override),
        .ped_req_a         (ped_req_a),
        .ped_req_b         (ped_req_b),
        .lights_a          (lights_a),
        .lights_b          (lights_b),
        .ped_walk_a        (ped_walk_a),
        .ped_walk_b        (ped_walk_b)
    );

    // 50MHz System Clock Generation Loop
    always begin
        #10 clk = ~clk;
    end

    // Automated Monitors: Instant Check for Safety Protocol Violations
    always @(posedge clk) begin
        // Safety Assertion: Ensure conflicting phases never receive green lights simultaneously
        if (lights_a[0] && lights_a[3]) begin
            $display("[ERROR - ASSERTION FAILED] Critical Safety Violation: Junction A NS and EW are Green together!");
            error_count = error_count + 1;
        end
        if (lights_b[0] && lights_b[3]) begin
            $display("[ERROR - ASSERTION FAILED] Critical Safety Violation: Junction B NS and EW are Green together!");
            error_count = error_count + 1;
        end

        // Pedestrian Crosswalk Safety: Vehicles must be All-Red during active walk phases
        if (ped_walk_a && (lights_a != 6'b100_100)) begin
            $display("[ERROR - ASSERTION FAILED] Pedestrian Hazard: Junction A walk light ON while vehicles moving!");
            error_count = error_count + 1;
        end
        if (ped_walk_b && (lights_b != 6'b100_100)) begin
            $display("[ERROR - ASSERTION FAILED] Pedestrian Hazard: Junction B walk light ON while vehicles moving!");
            error_count = error_count + 1;
        end
    end

    // Unified Test Sequences
    initial begin
        // Initialize Inputs
        clk = 0; rst_n = 1; emergency_override = 0;
        ped_req_a = 0; ped_req_b = 0;
        density_a = 3'b000; density_b = 3'b000;

        $display("==================================================================");
        $display("   STARTING AUTOMATED SELF-CHECKING VERIFICATION SUITE (TASK 5)   ");
        $display("==================================================================");

        // ------------------------------------------------------------------
        // TEST PHASE 1: Active Mid-Simulation Reset Check (Corner Case)
        // ------------------------------------------------------------------
        $display("[TIME: %0d] Phase 1: Applying Mid-Simulation Active Reset...", $time);
        #35; rst_n = 0; // Trigger reset off-sync
        #40; rst_n = 1;
        #10;
        if (lights_a != 6'b100_100 || lights_b != 6'b100_100) begin
            $display("[ERROR] Reset failure: Grid did not initialize to safe All-Red.");
            error_count = error_count + 1;
        end

        // ------------------------------------------------------------------
        // TEST PHASE 2: Directed Fast Emergency Override Toggle & Preemption
        // ------------------------------------------------------------------
        $display("[TIME: %0d] Phase 2: Simulating rapid high-frequency emergency toggle...", $time);
        #100;
        emergency_override = 1; #20; // Imm
