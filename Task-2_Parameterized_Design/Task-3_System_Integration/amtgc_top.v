// Module: amtgc_top
// Description: Top-level integration for the Adaptive Multi-Junction Traffic Grid Controller.

module amtgc_top #(
    parameter COUNTER_WIDTH = 8,
    parameter JA_GREEN      = 20,
    parameter JA_YELLOW     = 4,
    parameter JA_RED        = 5,
    parameter JA_PED        = 10,
    
    parameter JB_GREEN      = 15, // Different timing parameters for reusability
    parameter JB_YELLOW     = 3,
    parameter JB_RED        = 4,
    parameter JB_PED        = 8,
    
    parameter GREEN_WAVE_OFFSET = 8
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       emergency_override,
    input  wire       ped_req_a,
    input  wire       ped_req_b,
    output wire [5:0] lights_a,
    output wire [5:0] lights_b,
    output wire       ped_walk_a,
    output wire       ped_walk_b
);

    // Internal Wires for Interconnect (Strict Hierarchical Structure)
    wire ped_gnt_a;
    wire ped_gnt_b;
    
    // Emergency Pipeline registers for bounded 2-cycle transition
    reg  emerg_d1;
    reg  emerg_d2;
    wire internal_rst_n;

    always @(posedge clk) begin
        if (!rst_n) begin
            emerg_d1 <= 1'b0;
            emerg_d2 <= 1'b0;
        end else begin
            emerg_d1 <= emergency_override;
            emerg_d2 <= emerg_d1;
        end
    end

    // Combine reset strategy with emergency override cleanly without conflicts
    assign internal_rst_n = rst_n && !emerg_d2;

    // Green-Wave Coordination Link Logic
    reg [COUNTER_WIDTH-1:0] gw_counter;
    reg                     jb_start_trigger;

    // Detect when Junction A enters its North-South Green phase (lights_a == 6'b001_100)
    always @(posedge clk) begin
        if (!internal_rst_n) begin
            gw_counter       <= {COUNTER_WIDTH{1'b0}};
            jb_start_trigger <= 1'b0;
        end else begin
            if (lights_a == 6'b001_100) begin
                if (gw_counter == GREEN_WAVE_OFFSET) begin
                    jb_start_trigger <= 1'b1;
                end else begin
                    gw_counter       <= gw_counter + 1'b1;
                    jb_start_trigger <= 1'b0;
                end
            end else begin
                gw_counter       <= {COUNTER_WIDTH{1'b0}};
                jb_start_trigger <= 1'b0;
            end
        end
    end

    // 1. Fair Pedestrian Arbiter Instance
    ped_arbiter u_ped_arbiter (
        .clk      (clk),
        .rst_n    (internal_rst_n),
        .ped_req_a(ped_req_a),
        .ped_req_b(ped_req_b),
        .ped_gnt_a(ped_gnt_a),
        .ped_gnt_b(ped_gnt_b)
    );

    // 2. Junction A Controller Instance (Named Port Mapping)
    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME   (JA_GREEN),
        .YELLOW_TIME  (JA_YELLOW),
        .RED_TIME     (JA_RED),
        .PED_TIME     (JA_PED)
    ) u_junction_a (
        .clk     (clk),
        .rst_n   (internal_rst_n),
        .ped_req (ped_gnt_a),
        .lights  (lights_a),
        .ped_walk(ped_walk_a)
    );

    // 3. Junction B Controller Instance (Synchronized by Green-Wave trigger)
    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME   (JB_GREEN),
        .YELLOW_TIME  (JB_YELLOW),
        .RED_TIME     (JB_RED),
        .PED_TIME     (JB_PED)
    ) u_junction_b (
        .clk     (clk),
        .rst_n   (internal_rst_n && jb_start_trigger), // Held in safe state until wave arrives
        .ped_req (ped_gnt_b),
        .lights  (lights_b),
        .ped_walk(ped_walk_b)
    );

endmodule
