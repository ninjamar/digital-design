module tb_subleq;

    logic clk = 0;
    logic rst = 0;
    subleq dut (
        .clk(clk),
        .rst(rst)
    );

    $readmemb("subleq.mem", dut.data_mem.memory);

endmodule
