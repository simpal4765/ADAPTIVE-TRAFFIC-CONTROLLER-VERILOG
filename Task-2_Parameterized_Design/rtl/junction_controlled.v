// Module: junction_controller
// Description: Moore FSM traffic controller driving safe phase sequencing using external generic_timer.

module junction_controller #(
    parameter COUNTER_WIDTH = 8,
    parameter GREEN_TIME    = 20,
    parameter YELLOW_TIME   = 4,
    parameter RED_TIME      = 5, // Non-zero All-Red safety gap
    parameter PED_TIME      = 10
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ped_req,
    output reg  [5:0] lights,   // Layout: [5:3]=NS (R,Y,G), [2:0]=EW (R,Y,G)
    output reg        ped_walk
);

    // Local Parameters for FSM States Encoding
    localparam [2:0] STATE_AR_START = 3'b000,
                     STATE_NS_GREEN = 3'b001,
                     STATE_NS_YELLOW= 3'b010,
                     STATE_AR_GAP1  = 3'b011,
                     STATE_PED_WALK = 3'b100,
                     STATE_EW_GREEN = 3'b101,
                     STATE_EW_YELLOW= 3'b110,
                     STATE_AR_GAP2  = 3'b111;

    reg [2:0] current_state, next_state;
    
    // Interconnect lines to the sub-module generic timer
    reg                      timer_start;
    reg [COUNTER_WIDTH-1:0]  timer_target;
    wire                     timer_done;

    // Instantiate the standalone generic timer architecture
    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_generic_timer (
        .clk(clk),
        .rst_n(rst_n),
        .start(timer_start),
        .count_target(timer_target),
        .done(timer_done)
    );

    // Latch Pedestrian Request Logic: Non-volatile tracking through yellow phase windows
    reg ped_req_latched;
    always @(posedge clk) begin
        if (!rst_n) begin
            ped_req_latched <= 1'b0;
        end else begin
            if (ped_req) begin
                ped_req_latched <= 1'b1;
            end else if (current_state == STATE_PED_WALK) begin
                ped_req_latched <= 1'b0;
            end
        end
    end

    // FSM State Register update path
    always @(posedge clk) begin
        if (!rst_n) begin
            current_state <= STATE_AR_START;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational Logic for Next State Transitions (Latching Defended)
    always @(*) begin
        next_state = current_state; 
        case (current_state)
            STATE_AR_START:  if (timer_done) next_state = STATE_NS_GREEN;
            STATE_NS_GREEN:  if (timer_done) next_state = STATE_NS_YELLOW;
            STATE_NS_YELLOW: if (timer_done) next_state = STATE_AR_GAP1;
            STATE_AR_GAP1:   if (timer_done) begin
                                 if (ped_req_latched) next_state = STATE_PED_WALK;
                                 else                 next_state = STATE_EW_GREEN;
                             end
            STATE_PED_WALK:  if (timer_done) next_state = STATE_EW_GREEN;
            STATE_EW_GREEN:  if (timer_done) next_state = STATE_EW_YELLOW;
            STATE_EW_YELLOW: if (timer_done) next_state = STATE_AR_GAP2;
            STATE_AR_GAP2:   if (timer_done) next_state = STATE_NS_GREEN;
            default:         next_state = STATE_AR_START;
        endcase
    end

    // Output Mapping Logic Sequence Block
    always @(posedge clk) begin
        if (!rst_n) begin
            timer_start  <= 1'b1;
            timer_target <= RED_TIME;
            lights       <= 6'b100_100; 
            ped_walk     <= 1'b0;
        end else begin
            timer_start <= 1'b0;
            case (current_state)
                STATE_AR_START: begin
                    lights   <= 6'b100_100;
                    ped_walk <= 1'b0;
                    if (timer_done) begin
                        timer_start  <= 1'b1;
                        timer_target <= GREEN_TIME;
                    end
                end
                STATE_NS_GREEN: begin
                    lights   <= 6'b001_100;
                    ped_walk <= 1'b0;
                    if (timer_done) begin
                        timer_start  <= 1'b1;
                        timer_target <= YELLOW_TIME;
