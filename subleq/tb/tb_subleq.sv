module tb_subleq;

    logic clk = 0;
    logic rst = 0;
    subleq #(
        .ITEMS(4096)  // set to large power of 2
    ) dut (
        .clk(clk),
        .rst(rst)
    );
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/subleq.fst");
        $dumpvars(3, dut);  // depth 2

        $display("Starting CPU");
        $readmemh("prog/prog.hex", dut.memory.memory);
        // if the program uses __in:
        // $readmemh("input.hex", dut.io.in_data);
        rst = 1;
        repeat (1) @(posedge clk);
        rst = 0;
        forever begin
            // repeat (1000) begin
            @(posedge clk);
            if (dut.ctrl.stall) $finish();
        end
        $display("CPU Finished");
    end
endmodule
