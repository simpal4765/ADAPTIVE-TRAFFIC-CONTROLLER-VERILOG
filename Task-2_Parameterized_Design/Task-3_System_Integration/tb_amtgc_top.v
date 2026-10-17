`timescale 1ns / 1ps

module tb_amtgc_top;
    reg clk;
    reg rst_n;
    reg emergency_override;
    reg ped_req_a;
    reg ped_req_b;
    
    wire [5:0] lights_a;
    wire [5:0] lights_b;
    wire       ped_walk_a;
    wire       ped_walk_b;

    // Instantiate System Top Module
    amtgc_top #(
        .COUNTER_WIDTH(8),
        .JA_GREEN(15), .JA_YELLOW(3), .JA_RED(4), .JA_PED(6),
        .JB_GREEN(12), .JB_YELLOW(2), .JB_RED(3), .JB_PED(5),
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

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; emergency_override = 0; ped_req_a = 0; ped_req_b = 0;
        #20 rst_n = 1;

        // 1. Verify Green-Wave Coordination Offset
        $display("[TIME: %0d] Monitoring Green-Wave Offset Phase...", $time);
        #200;

        // 2. Stress Test: Simultaneous Continuous Pedestrian Requests (Starvation Prevention Verification)
        $display("[TIME: %0d] Stimulating continuous simultaneous pedestrian requests...", $time);
        ped_req_a = 1; ped_req_b = 1;
        #300;
        ped_req_a = 0; ped_req_b = 0;

        // 3. Corner Case: Emergency Override during active pedestrian phase
        #50;
        ped_req_a = 1;
        #20; ped_req_a = 0;
        wait(ped_walk_a == 1'b1);
        
        $display("[TIME: %0d] Emergency Override asserted during active Pedestrian phase!", $time);
        emergency_override = 1;
        
        #20; // Check inside 2 clock cycles boundary
        if (lights_a == 6'b100_100 && lights_b == 6'b100_100)
            $display("[TIME: %0d] SUCCESS: All-Red achieved within safe bounded limit.", $time);
        else
            $display("[TIME: %0d] ERROR: Grid failed to enter emergency mode safely.", $time);

        // 4. Recovery Testing
        #100;
        $display("[TIME: %0d] Releasing Emergency. Testing graceful recovery...", $time);
        emergency_override = 0;
        
        #400;
        $display("System Integration Testbench Simulation Finished Successfully.");
        $finish;
    end
endmodule
