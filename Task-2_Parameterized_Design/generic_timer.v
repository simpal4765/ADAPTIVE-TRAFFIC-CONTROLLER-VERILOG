// Module: generic_timer
// Description: Fully independent, reusable hardware timer with zero-count safety logic.

module generic_timer #(
    parameter COUNTER_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    input  wire [COUNTER_WIDTH-1:0] count_target,
    output reg                      done
);

    reg [COUNTER_WIDTH-1:0] count_reg;
    reg                     running;

    // Sequential Timer Controller
    always @(posedge clk) begin
        if (!rst_n) begin
            count_reg <= {COUNTER_WIDTH{1'b0}};
            running   <= 1'b0;
            done      <= 1'b0;
        end else begin
            if (start) begin
                count_reg <= {COUNTER_WIDTH{1'b0}};
                if (count_target == {COUNTER_WIDTH{1'b0}}) begin
                    running <= 1'b0;
                    done    <= 1'b1; // Immediate completion if target is zero
                end else begin
                    running <= 1'b1;
                    done    <= 1'b0;
                end
            end else if (running) begin
                if (count_reg + 1'b1 >= count_target) begin
                    count_reg <= {COUNTER_WIDTH{1'b0}};
                    running   <= 1'b0;
                    done      <= 1'b1;
                end else begin
                    count_reg <= count_reg + 1'b1;
                    done      <= 1'b0;
                end
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
