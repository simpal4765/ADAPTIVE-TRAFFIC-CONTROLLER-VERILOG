 Module: sys_ctrl_unit
 Purpose: Central control unit managing global timers, emergency override, and green-wave synchronization.

module sys_ctrl_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       emergency_override,
    output reg        global_emergency_active,
    output reg        ja_sync_en,
    output reg        jb_sync_en
);

     Standard timing parameter definitions (in clock cycles)
    parameter GREEN_WAVE_DELAY = 8;
    
    reg [7:0] dynamic_counter;
    reg       emergency_reg_d1;
    reg       emergency_reg_d2;

    2-Cycle Deterministic Emergency Override Pipeline Safeguard
    always @(posedge clk) begin
        if (!rst_n) begin
            emergency_reg_d1        <= 1'b0;
            emergency_reg_d2        <= 1'b0;
            global_emergency_active <= 1'b0;
        end else begin
            emergency_reg_d1        <= emergency_override;
            emergency_reg_d2        <= emergency_reg_d1;
            global_emergency_active <= emergency_reg_d2;
        end
    end

     Global Timing Counter Logic & Green-Wave Trigger Generation
    always @(posedge clk) begin
        if (!rst_n || global_emergency_active) begin
            dynamic_counter <= 8'd0;
            ja_sync_en      <= 1'b0;
            jb_sync_en      <= 1'b0;
        end else begin
            dynamic_counter <= dynamic_counter + 1'b1;
            
             Junction A sync strobe trigger
            if (dynamic_counter == 8'd0) begin
                ja_sync_en <= 1'b1;
            end else begin
                ja_sync_en <= 1'b0;
            end

            Junction B Green-Wave time-delayed sync strobe trigger
            if (dynamic_counter == GREEN_WAVE_DELAY) begin
                jb_sync_en <= 1'b1;
            end else begin
                jb_sync_en <= 1'b0;
            end
        end
    end

endmodule
