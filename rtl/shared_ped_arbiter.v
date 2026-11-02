 Module: shared_ped_arbiter
 Purpose: Fair Round-Robin arbitration to manage pedestrian requests from both junctions without starvation.

module shared_ped_arbiter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ped_req_a,
    input  wire       ped_req_b,
    input  wire [3:0] ja_state,
    input  wire [3:0] jb_state,
    output reg        ja_ped_gnt,
    output reg        jb_ped_gnt
);

     States tracking lines from junction FSMs
    localparam NS_YELLOW = 4'b0010;

     Internal registers to latch requests and track priority token
    reg ped_req_a_latched;
    reg ped_req_b_latched;
    reg priority_token; // 0: Junction A has priority, 1: Junction B has priority

     Latch incoming pedestrian requests safely
    always @(posedge clk) begin
        if (!rst_n) begin
            ped_req_a_latched <= 1'b0;
            ped_req_b_latched <= 1'b0;
        end else begin
            if (ped_req_a) ped_req_a_latched <= 1'b1;
            else if (ja_state == 4'b0101) ped_req_a_latched <= 1'b0; // Clear once served

            if (ped_req_b) ped_req_b_latched <= 1'b1;
            else if (jb_state == 4'b0101) ped_req_b_latched <= 1'b0; // Clear once served
        end
    end

    // Fair Arbitration Logic with Starvation Prevention
    always @(posedge clk) begin
        if (!rst_n) begin
            ja_ped_gnt     <= 1'b0;
            jb_ped_gnt     <= 1'b0;
            priority_token <= 1'b0; // Default priority to Junction A
        end else begin
            ja_ped_gnt <= 1'b0;
            jb_ped_gnt <= 1'b0;

            // Check during the Yellow window if a pedestrian request can be granted safely
            if (priority_token == 1'b0) begin
                if (ped_req_a_latched && ja_state == NS_YELLOW) begin
                    ja_ped_gnt     <= 1'b1;
                    priority_token <= 1'b1; // Pass token to B after granting A
                end else if (ped_req_b_latched && jb_state == NS_YELLOW) begin
                    jb_ped_gnt     <= 1'b1;
                    priority_token <= 1'b0; // Pass token to A after granting B
                end
            end else begin
                if (ped_req_b_latched && jb_state == NS_YELLOW) begin
                    jb_ped_gnt     <= 1'b1;
                    priority_token <= 1'b0; // Pass token to A after granting B
                end else if (ped_req_a_latched && ja_state == NS_YELLOW) begin
                    ja_ped_gnt     <= 1'b1;
                    priority_token <= 1'b1; // Pass token to B after granting A
                end
            end
        end
    end

endmodule
