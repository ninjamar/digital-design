module clock(
    input logic clk,
    input logic rst,
    output logic led
);


    localparam CLOCK_FREQ = 10**8; // freq of clock; 100 mhz

    localparam INTERVAL_SEC = 1;
    localparam DURATION_SEC = 0.5; // how long led is on
    
    localparam INTERVAL_CYCLES = INTERVAL_SEC * CLOCK_FREQ;
    localparam DURATION_CYCLES = DURATION_SEC * CLOCK_FREQ;

    // need to cycle clock every n seconds
    // 1 posedge = 1 cycle. freq = cycl/sec
    // 10
    logic [31:0] cycles = 0;
    logic [31:0] led_toggle_cycle = 0;

    always_ff @( posedge clk ) begin
        cycles <= cycles + 1;

        if (cycles == led_toggle_cycle) begin
            led <= 0;
            led_toggle_cycle <= 0;
        end else if (cycles == INTERVAL_CYCLES) begin
            led <= 1;
            cycles <= 0;
            led_toggle_cycle <= DURATION_CYCLES;
        end
    end

endmodule
// 100 cycles per sec
