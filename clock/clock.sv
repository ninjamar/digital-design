import constants::CLOCK_FREQ;
import utils::cycles_half_period_conversion;

module clock_new #(
    localparam int FREQ = 1 // f = 1 cycle / sec

)(
    input logic clk,
    input logic rst,
    output logic clk_new
);
    localparam int SINGLE_EDGE_CYCLE_COUNT = cycles_half_period_conversion(CLOCK_FREQ, FREQ);
    // need to cycle clock every n seconds
    // 1 posedge = 1 cycle. freq = cycl/sec
    // 10
    
    logic [31:0] cycles = 0;
    logic [31:0] next_toggle_cycle = 0;

    always_ff @( posedge clk ) begin
        cycles <= cycles + 1;

        if (cycles == next_toggle_cycle) begin
            clk_new <= 0;
            next_toggle_cycle <= 0;
        end else if (cycles == SINGLE_EDGE_CYCLE_COUNT) begin
            clk_new <= 1;
            cycles <= 0;
            next_toggle_cycle <= SINGLE_EDGE_CYCLE_COUNT;
        end
    end

endmodule
// 100 cycles per sec
