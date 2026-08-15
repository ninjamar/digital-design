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

module three_bit_adder(
    input a[2: 0],
    input b[2: 0],
    output sum[2: 0],
    output cout
);
    wire s1, cout1;
    half_adder step1 (
        .a (a[0]),
        .b (b[0]),
        .sum (s1),
        .cout (cout1)
    );

    wire s2, cout2;
    full_adder step2 (
        .a (a[1]),
        .b (b[1]),
        .cin (cout1),
        .sum (s2),
        .cout (cout2)
    );

    wire s3, cout3;
    full_adder step3 (
        .a (a[2]),
        .b (b[2]),
        .cin (cout2),
        .sum (s3),
        .cout (cout3)
    );

    assign sum = s1 + s2 + s3;
    assign cout = cout3;
endmodule

/* 
Note: Focus on writing synthesizable verilog code. instructions like multiplication
don't synthesize really well.
*/