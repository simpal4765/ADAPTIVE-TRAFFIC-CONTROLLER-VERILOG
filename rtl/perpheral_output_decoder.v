 Module: peripheral_output_decoder
 Purpose: Combinational logic to decode internal FSM states into physical hardware light lines.

module peripheral_output_decoder (
    input  wire [3:0] ja_state,
    input  wire [3:0] jb_state,
    output reg  [5:0] lights_junction_a, // [5]=NS_R, [4]=NS_Y, [3]=NS_G, [2]=EW_R, [1]=EW_Y, [0]=EW_G
    output reg  [5:0] lights_junction_b,
    output reg        ped_walk_a,
    output reg        ped_walk_b
);

     Internal FSM States Mapping
    localparam ALL_RED    = 4'b0000,
               NS_GREEN   = 4'b0001,
               NS_YELLOW  = 4'b0010,
               EW_GREEN   = 4'b0011,
               EW_YELLOW  = 4'b0100,
               PED_WALK   = 4'b0101;

     Combinational Decoding Logic for Junction A
    always @(*) begin
         Default values: All-Red and Pedestrian off
        lights_junction_a = 6'b100_100; 
        ped_walk_a        = 1'b0;

        case (ja_state)
            ALL_RED:   lights_junction_a = 6'b100_100; // NS=Red, EW=Red
            NS_GREEN:  lights_junction_a = 6'b001_100; // NS=Green, EW=Red
            NS_YELLOW: lights_junction_a = 6'b010_100; // NS=Yellow, EW=Red
            EW_GREEN:  lights_junction_a = 6'b100_001; // NS=Red, EW=Green
            EW_YELLOW: lights_junction_a = 6'b100_010; // NS=Red, EW=Yellow
            PED_WALK: begin
                lights_junction_a = 6'b100_100; // Vehicles are All-Red
                ped_walk_a        = 1'b1;       // Pedestrian Walk indicator ON
            end
            default:   lights_junction_a = 6'b100_100;
        endcase
    end

    // Combinational Decoding Logic for Junction B
    always @(*) begin
        // Default values: All-Red and Pedestrian off
        lights_junction_b = 6'b100_100;
        ped_walk_b        = 1'b0;

        case (jb_state)
            ALL_RED:   lights_junction_b = 6'b100_100;
            NS_GREEN:  lights_junction_b = 6'b001_100;
            NS_YELLOW: lights_junction_b = 6'b010_100;
            EW_GREEN:  lights_junction_b = 6'b100_001;
            EW_YELLOW: lights_junction_b = 6'b100_010;
            PED_WALK: begin
                lights_junction_b = 6'b100_100;
                ped_walk_b        = 1'b1;
            end
            default:   lights_junction_b = 6'b100_100;
        endcase
    end

endmodule
