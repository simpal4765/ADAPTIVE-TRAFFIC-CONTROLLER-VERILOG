// Module: junction_controller_adaptive
// Description: Advanced traffic-adaptive controller computing dynamic target counts on phase entry.

module junction_controller_adaptive #(
    parameter COUNTER_WIDTH = 8,
    parameter MIN_GREEN     = 10,  // Guaranteed Minimum Green Limit
    parameter MAX_GREEN     = 30,  // Absolute Maximum Safety Cap
    parameter EXT_PER_LEVEL = 3,   // Clock cycles added per density level
    parameter YELLOW_TIME   = 4,
    parameter RED_TIME      = 5,
    parameter PED_TIME      = 10
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ped_req,
    input  wire [2:0] traffic_density, // 3-bit input representing levels 0 to 7
    output reg  [5:0] lights,
    output reg        ped_walk
);

    // States
    localparam [2:0] STATE_AR_START = 3'b000,
                     STATE_NS_GREEN = 3'b001,
                     STATE_NS_YELLOW= 3'b010,
                     STATE_AR_GAP1  = 3'b011,
                     STATE_PED_WALK = 3'b100,
                     STATE_EW_GREEN = 3'b101,
                     STATE_EW_YELLOW= 3'b110,
                     STATE_AR_GAP2  = 3'b111;

    reg [2:0] current_state, next_state;
    reg                      timer_start;
    reg [COUNTER_WIDTH-1:0]  timer_target;
    wire                     timer_done;

    // Internal register to capture density ONLY at the exact start edge of Green phase
    reg [COUNTER_WIDTH-1:0]  calculated_green_time;

    generic_timer #(.COUNTER_WIDTH(COUNTER_WIDTH)) u_generic_timer (
        .clk(clk), .rst_n(rst_n), .start(timer_start), .count_target(timer_target), .done(timer_done)
    );

    reg ped_req_latched;
    always @(posedge clk) begin
        if (!rst_n) ped_req_latched <= 1'b0;
        else if (ped_req) ped_req_latched <= 1'b1;
        else if (current_state == STATE_PED_WALK) ped_req_latched <= 1'b0;
    end

    always @(posedge clk) begin
        if (!rst_n) current_state <= STATE_AR_START;
        else        current_state <= next_state;
    end

    // Next state decoder logic
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

    // Decision Logic Matrix: Enforces limits and prevents mid-phase sampling instability
    always @(posedge clk) begin
        if (!rst_n) begin
            timer_start           <= 1'b1;
            timer_target          <= RED_TIME;
            lights                <= 6'b100_100;
            ped_walk              <= 1'b0;
            calculated_green_time <= MIN_GREEN;
        end else begin
            timer_start <= 1'b0;
            case (current_state)
                STATE_AR_START: begin
                    lights <= 6'b100_100; ped_walk <= 1'b0;
                    if (timer_done) begin
                        timer_start <= 1'b1;
                        // Design Decision: Sample traffic_density exactly once on entry
                        if (MIN_GREEN + (traffic_density * EXT_PER_LEVEL) > MAX_GREEN)
                            timer_target <= MAX_GREEN; // Absolute Safety Cap
                        else
                            timer_target <= MIN_GREEN + (traffic_density * EXT_PER_LEVEL);
                    end
                end
                STATE_NS_GREEN: begin
