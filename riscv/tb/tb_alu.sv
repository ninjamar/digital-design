module tb_alu;

    logic [31:0] a;
    logic [31:0] b;
    logic [1:0]  opcode;
    logic [31:0] result;
    logic cout;
    logic zero;
    logic negative;

    alu dut (
        .a,
        .b,
        .opcode,
        .result,
        .cout,
        .zero,
        .negative
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_alu);

        a = 'b011;
        b = 'b111;
        opcode = 'b01;
        #1
        $display("Result: %b, Cout: %b, Zero: %b, Neg: %b", result, cout, zero, negative);

        $finish;
    end

endmodule
