module display (
    input logic clk,
    input logic [1:0] digit_sel,
    input logic [3:0] digit,
    output logic [7:0] seg, // cathode
    output logic [3:0] an // anode
);
    // given a column and digit, switch to it
    // an and seg are inverted (on = 0, off = 1)
    
    // convert from col to an
    always_comb begin
        an = 'b1111;
        case (digit_sel)
            'd1: an = 'b0111;
            'd2: an = 'b1011;
            'd3: an = 'b1101;
            'd4: an = 'b1110;
        endcase
    end
    // convert from digit to cathode
    always_comb begin
        seg = 'b00000000;
        case (digit)
            'd0: seg = 8'b00000111;
            'd1: seg = 8'b10011111;
            'd2: seg = 8'b00100101;
            'd3: seg = 8'b00001101;
            'd4: seg = 8'b10011001;
            'd5: seg = 8'b01001001;
            'd6: seg = 8'b01000001;
            'd7: seg = 8'b00011111;
            'd8: seg = 8'b00000001;
            'd9: seg = 8'b00001001;
        endcase
    end
endmodule