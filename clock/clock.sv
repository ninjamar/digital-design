import constants::CLOCK_FREQ;

module clock_enable_generator #(
    parameter int FREQ = 1  // f = 1 cycle / sec
) (
    input logic clk,
    input logic rst,
    output logic pulse
);
    // half of total peroid
    // Every 100th cycle = clk -> 99 cycles between pulse

    // 100 MHz -> 25 MHz = clk / 4

    localparam int EDGE_CYCLE_COUNT = CLOCK_FREQ / FREQ;  // 100 MHz / 4 MHz = 25 Mhz


    logic [31:0] cycles = 1'b0;

    always_ff @(posedge clk) begin
        pulse <= 0;
        if (cycles == EDGE_CYCLE_COUNT - 1) begin
            pulse  <= 1'b1;
            cycles <= 1'b0;
        end else begin
            cycles <= cycles + 1'b1;
        end
    end

endmodule
// 100 cycles per sec
