import constants::CLOCK_FREQ;
// non-synthesizable: outputs a constant so it gets inlined
function automatic int cycles_half_period_conversion(int from_freq, int to_freq);
    // given a clock frequency, and an output frequency, calculate how many
    // cycles half a period (single edge) is
    real period = 1.0 / real'(to_freq); // in a function you can have variables
    return int'((period / 2.0) * real'(from_freq));
endfunction

module clock_new #(
    parameter int FREQ = 1 // f = 1 cycle / sec
)(
    input logic clk,
    input logic rst,
    output logic clk_new
);
    // half of total peroid
    localparam int SINGLE_EDGE_CYCLE_COUNT = cycles_half_period_conversion(CLOCK_FREQ, FREQ);
    // need to cycle clock every n seconds
    // 1 posedge = 1 cycle. freq = cycl/sec
    // 10
    
    logic [31:0] cycles = 1'b0;
    logic [31:0] next_toggle_cycle = 1'b0;

    always_ff @( posedge clk ) begin
        cycles <= cycles + 1'b1;

        if (cycles == next_toggle_cycle) begin
            clk_new <= 1'b0;
            next_toggle_cycle <= 1'b0;
            cycles <= 1'b0;
        end else if (cycles == SINGLE_EDGE_CYCLE_COUNT) begin
            clk_new <= 1'b1;
            cycles <= 1'b0;
            next_toggle_cycle <= SINGLE_EDGE_CYCLE_COUNT;
        end
    end

endmodule
// 100 cycles per sec
