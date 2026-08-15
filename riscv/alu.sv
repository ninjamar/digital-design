/*
32 bit alu with signed integers. simple and sythesizable. 
delegate synthesis to synthesis software.

a[31:0], b[31:0], control[1:0] -> result[31: 0], cout

Operations:
- addition
- subtraction
- a nand b

These operations could be implemented using logic gates: but the job of the
synthesis software is to turn operations in verilog like "+" and "-" into
gates and units (half adders, full adders, ...) on the actual chip itself.
*/

module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0] opcode,
    output logic [31:0] result,
    output logic cout,
    output logic zero,
    output logic negative
);
    always_comb begin // combinational logic
    // no assign needed inside
        case (opcode)
            'b00: begin
                // addition
                {cout, result} = a + b; // add extra bit left for cout
                // ~(a | b) returns same bus size. a ~| b reduces it to 1 bit
            end
            'b01: begin
                // subtraction
                {cout, result} = a - b;
            end
            'b10: begin
                result = ~(a & b); // bus output
                cout = 0;
            end
            default: begin
                result = 32'b0;
                cout = 0;
            end
        endcase
        zero = ~|result; // check if all bits are zero; nor result: ~(R[31] | R[30]...)
        negative = result[31]; // 1 = negative 
    end
endmodule
