// import constants::DEVICE_CLOCK_FREQ;

module clock_pulse_generator #(
    parameter int BASE_FREQ = 1,
    parameter int FREQ = 1  // f = 1 cycle / sec
) (
    input logic clk,
    input logic rst,
    output logic pulse
);
    // half of total peroid
    // Every 100th cycle = clk -> 99 cycles between pulse

    // 100 MHz -> 25 MHz = clk / 4

    localparam int EDGE_CYCLE_COUNT = BASE_FREQ / FREQ;  // 100 MHz / 4 MHz = 25 Mhz


    logic [31:0] cycles;

    always_ff @(posedge clk) begin
        if (rst) begin
            cycles <= 32'b0;
            pulse <= 0;
        end else begin
            pulse <= 0;
            if (cycles == EDGE_CYCLE_COUNT - 1) begin
                pulse  <= 1'b1;
                cycles <= 32'b0;
            end else begin
                cycles <= cycles + 1'b1;
            end
        end
    end

endmodule
// 100 cycles per sec