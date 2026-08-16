module display (
    input logic en,
    input logic [2:0] digit_sel,
    input logic [3:0] digit,
    output logic [7:0] seg, // cathode
    output logic [3:0] an // anode
);
    // given a column and digit, switch to it
    // an is (on = 0, off = 1)
    
    // convert from col to an
    always_comb begin
        an = ~(4'b0000);
        if (en) begin
            case (digit_sel)
                3'd1: an = ~(4'b0111);
                3'd2: an = ~(4'b1011);
                3'd3: an = ~(4'b1101);
                3'd4: an = ~(4'b1110);
            endcase 
        end
    end
    // convert from digit to cathode
    always_comb begin
        seg = 8'b00000000; // prevent latch
        if (en) begin
            case (digit)
                4'd0: seg = 8'b00000111;
                4'd1: seg = 8'b10011111;
                4'd2: seg = 8'b00100101;
                4'd3: seg = 8'b00001101;
                4'd4: seg = 8'b10011001;
                4'd5: seg = 8'b01001001;
                4'd6: seg = 8'b01000001;
                4'd7: seg = 8'b00011111;
                4'd8: seg = 8'b00000001;
                4'd9: seg = 8'b00001001;
            endcase 
        end
    end
endmodule