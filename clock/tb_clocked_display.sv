`timescale 1ns/1ps // 100 MHz driving clock;

module tb_clocked_display;
    
    logic clk = 0;
    always #5 clk = ~clk; // 10 ns period = 100 mhz

    logic rst = 0;
    logic [6:0] seg;
    logic [3:0] an;

    top #(
        .CLOCK_FREQ(100_000.0),
        .DISPLAY_FREQ(1_000_000.0)
    ) dut (
        .clk(clk),
        .rst(rst),
        .seg(seg),
        .an (an)
    );

    initial begin
        $dumpfile("tb_clocked_display_wave.fst");
        $dumpvars(2, tb_clocked_display); // depth 2
        // check 
        for (int i = 0; i < 1000; i++) begin
            @(posedge dut.digit_mod_en);
            $display("%d %d %d %d", dut.digits[0], dut.digits[1], dut.digits[2], dut.digits[3]);
        end
        $finish();
    end
endmodule
