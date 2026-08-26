module alu_bitwise #(
    parameter WIDTH = 8
) (
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [WIDTH-1:0] opcode,
    output logic [WIDTH-1:0] result
);
    always_comb begin
        result = 'd0;
        case (opcode)
            'd0: result = ~a;
            'd1: result = a | b;
            'd2: result = a & b;
            'd3: result = ~(a & b);
            'd4: result = ~(a | b);
            'd5: result = a ^ b;
        endcase
    end
endmodule