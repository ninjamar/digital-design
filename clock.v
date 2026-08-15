module clock(
    input clk,
    output reg[31:0] out = 0
);

    reg[31:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;

        if (counter == 4) begin
            out <= counter;
            $finish;
        end
    end
endmodule

module tb_clock;
    reg clk = 0;
    wire [31:0] out;

    clock dut (
        .clk(clk),
        .out(out)
    );
    always #5 clk = ~clk;

    initial begin
        $monitor("t=%0t clk=%b counter=%0d out=%0d", $time, clk, dut.counter, out);

        #100; // safety timeout
        $display("Timeout");
        $finish;
    end
endmodule;