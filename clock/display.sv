/* 
Bus width:
Given [n: 0], width = 2^(n+1). indexed from 0 to width - 1. 0 -> 2^(n+1) - 1
Eg [1:0]. Width = 2^2 = 4. Indexed from 0 to 3
*/
module display (
    input logic en,
    input logic [1:0] digit_sel, // 4 digits, indexed 0 -> 3. total 
    input logic [3:0] digit,
    output logic [6:0] seg, // cathode
    output logic [3:0] an // anode
);
    // given a column and digit, switch to it
    // an is (on = 0, off = 1)
    
    // convert from col to an
    always_comb begin
        an = ~(4'b0000);
        if (en) begin
            case (digit_sel)
                2'd0: an = ~(4'b1000);
                2'd1: an = ~(4'b0100);
                2'd2: an = ~(4'b0010);
                2'd3: an = ~(4'b0001);
            endcase 
        end
    end
    // convert from digit to cathode
    always_comb begin
        seg = 7'b0000000; // prevent latch
        if (en) begin
            case (digit)
                4'd0: seg = 7'b0000111;
                4'd1: seg = 7'b0011111;
                4'd2: seg = 7'b0100101;
                4'd3: seg = 7'b0001101;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b1001001;
                4'd6: seg = 7'b1000001;
                4'd7: seg = 7'b0011111;
                4'd8: seg = 7'b0000001;
                4'd9: seg = 7'b0001001;
            endcase 
        end
    end
endmodule
