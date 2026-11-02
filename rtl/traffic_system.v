// Module: top_traffic_system
// Purpose: Top-level structural wrapper module interconnecting all components of the traffic controller system.

module top_traffic_system (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       emergency_override,
    input  wire       ped_req_a,
    input  wire       ped_req_b,
    output wire [5:0] lights_junction_a,
    output wire [5:0] lights_junction_b,
    output wire       ped_walk_a,
    output wire       ped_walk_b
);

    // Internal structural wire declarations to bridge the sub-modules
    wire       global_emergency_active;
    wire       ja_sync_en;
    wire       jb_sync_en;
    wire [3:0] ja_state;
    wire [3:0] jb_state;
    wire       ja_ped_gnt;
    wire       jb_ped_gnt;

    // 1. Centralized System Control Unit Instance
    sys_ctrl_unit u_sys_ctrl_unit (
        .clk                     (clk),
        .rst_n                   (rst_n),
        .emergency_override      (emergency_override),
        .global_emergency_active (global_emergency_active),
        .ja_sync_en              (ja_sync_en),
        .jb_sync_en              (jb_sync_en)
    );

    // 2. Local State Machine for Junction A
    junction_fsm u_junction_fsm_a (
        .clk                     (clk),
        .rst_n                   (rst_n),
        .global_emergency_active (global_emergency_active),
        .sync_en                 (ja_sync_en),
        .ped_clear_granted       (ja_ped_gnt),
        .state_vector            (ja_state)
    );

    // 3. Local State Machine for Junction B (Green-Wave Sync Controlled)
    junction_fsm u_junction_fsm_b (
        .clk                     (clk),
        .rst_n                   (rst_n),
        .global_emergency_active (global_emergency_active),
        .sync_en                 (jb_sync_en),
        .ped_clear_granted       (jb_ped_gnt),
        .state_vector            (jb_state)
    );

    // 4. Shared Pedestrian Arbiter Instance with Starvation Prevention
    shared_ped_arbiter u_shared_ped_arbiter (
        .clk        (clk),
        .rst_n      (rst_n),
        .ped_req_a  (ped_req_a),
        .ped_req_b  (ped_req_b),
        .ja_state   (ja_state),
        .jb_state   (jb_state),
        .ja_ped_gnt (ja_ped_gnt),
        .jb_ped_gnt (jb_ped_gnt)
    );

    // 5. Peripheral Output Decoder Module Instance
    peripheral_output_decoder u_peripheral_output_decoder (
        .ja_state          (ja_state),
        .jb_state          (jb_state),
        .lights_junction_a (lights_junction_a),
        .lights_junction_b (lights_junction_b),
        .ped_walk_a        (ped_walk_a),
        .ped_walk_b        (ped_walk_b)
    );

endmodule
