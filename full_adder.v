module half_adder(
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    wire h1_sum, h1_cout, h2_cout;

    half_adder h1_instance (
        .a (a),
        .b (b),
        .sum (h1_sum),
        .cout (h1_cout)
    );

    half_adder h2_instance (
        .a (h1_sum),
        .b (cin),
        .sum (sum),
        .cout (h2_cout)
    );
    assign cout = h1_cout | h2_cout;

endmodule

/* 
Note: Focus on writing synthesizable verilog code. instructions like multiplication
don't synthesize really well.
*/