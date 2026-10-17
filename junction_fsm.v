 Module: junction_fsm
 Purpose: Implements the local finite state machine for individual 4-way junctions.

module junction_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       global_emergency_active,
    input  wire       sync_en,
    input  wire       ped_clear_granted,
    output reg  [3:0] state_vector
);

     State Encoding Definitions using One-Hot/Binary scheme
    localparam ALL_RED    = 4'b0000,
               NS_GREEN   = 4'b0001,
               NS_YELLOW  = 4'b0010,
               EW_GREEN   = 4'b0011,
               EW_YELLOW  = 4'b0100,
               PED_WALK   = 4'b0101;

     Standard timing counter setup for state durations
    reg [5:0] cycle_timer;

    always @(posedge clk) begin
        if (!rst_n) begin
            state_vector <= ALL_RED;
            cycle_timer  <= 6'd0;
        end else if (global_emergency_active) begin
            state_vector <= ALL_RED; // Force immediate All-Red safe state
            cycle_timer  <= 6'd0;
        end else begin
            case (state_vector)
                ALL_RED: begin
                    if (sync_en) begin
                        state_vector <= NS_GREEN;
                        cycle_timer  <= 6'd0;
                    end
                end

                NS_GREEN: begin
                    if (cycle_timer >= 6'd20) begin // 20 clock cycles for green
                        state_vector <= NS_YELLOW;
                        cycle_timer  <= 6'd0;
                    end else begin
                        cycle_timer <= cycle_timer + 1'b1;
                    end
                end

                NS_YELLOW: begin
                    if (cycle_timer >= 6'd4) begin  // 4 clock cycles for yellow
                        // Check if a pedestrian crossing was authorized by the arbiter
                        if (ped_clear_granted) begin
                            state_vector <= PED_WALK;
                        end else begin
                            state_vector <= EW_GREEN;
                        end
                        cycle_timer <= 6'd0;
                    end else begin
                        cycle_timer <= cycle_timer + 1'b1;
                    end
                end

                EW_GREEN: begin
                    if (cycle_timer >= 6'd20) begin
                        state_vector <= EW_YELLOW;
                        cycle_timer  <= 6'd0;
                    end else begin
                        cycle_timer <= cycle_timer + 1'b1;
                    end
                end

                EW_YELLOW: begin
                    if (cycle_timer >= 6'd4) begin
                        state_vector <= ALL_RED;
                        cycle_timer  <= 6'd0;
                    end else begin
                        cycle_timer <= cycle_timer + 1'b1;
                    end
                end

                PED_WALK: begin
                    if (cycle_timer >= 6'd10) begin // 10 clock cycles for pedestrian walk
                        state_vector <= EW_GREEN;   // Return to standard vehicle sequence
                        cycle_timer  <= 6'd0;
                    end else begin
                        cycle_timer <= cycle_timer + 1'b1;
                    end
                end

                default: state_vector <= ALL_RED;
            endcase
        end
    end

endmodule
