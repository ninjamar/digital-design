module tb_full_adder;

    reg a, b, cin;
    wire sum, cout;
    reg expected_sum, expected_cout;

    
    full_adder dut (
        .a (a),
        .b (b),
        .cin (cin),
        .sum (sum),
        .cout (cout)
    );


    integer i;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_full_adder);

        
        for (i = 0; i < 8; i = i + 1) begin
            // get 3 bits of i; 3 variables = 8 combinations, and 8 is 3 bits in binary
            {a, b, cin} = i[2: 0];
            #1; // wait 1 tick for the full adder to run
            {expected_cout, expected_sum} = a + b + cin; // upper is carry, lower is sum
            if (sum != expected_sum || cout != expected_cout) begin
                $display("[ERROR]: a=%b, b=%b, cin=%b, sum=%b, cout=%b, exp_sum=%b, exp_cout=%b",
                    a, b, cin, sum, cout, expected_sum, expected_cout
                );
            end

        end
        $finish;
    end

endmodule