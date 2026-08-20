module top #(
    parameter real CLOCK_FREQ = 1.0,
    parameter real DISPLAY_FREQ = 1000
) (
    input logic clk,
    input logic rst,
    output logic [6:0] seg,  // cathode
    output logic [3:0] an  // anode
);
    // Enable module
    logic digit_mod_en;  // module enable

    clock_enable_generator #(
        .FREQ(CLOCK_FREQ)
    ) digit_clk_generator (
        .pulse(digit_mod_en),
        .*
    );

    logic display_mod_en;
    clock_enable_generator #(
        .FREQ(DISPLAY_FREQ)
    ) display_clk_generator (
        .pulse(display_mod_en),
        .*
    );

    // Display module
    logic [3:0] digits[3:0] = '{4'd0, 4'd0, 4'd0, 4'd0};
    logic [1:0] digit_sel = 2'b0;

    display display (
        // .en (display_mod_en),
        .digit_sel(digit_sel),
        .digit(digits[digit_sel]),
        .seg,
        .an
    );



    logic [3:0] carry;
    logic [3:0] digits_buf[3:0];

    // Keep logic combinational (blocking)
    always_comb begin
        carry = 4'd0;
        digits_buf = digits;
        // Digit loop: updating digits using clocking
        if (digit_mod_en) begin
            // Add 1, then propgate carry
            digits_buf[3] = digits[3] + 1'd1;
            for (int i = 3; i >= 0; i--) begin
                if (digits_buf[i] > 4'd9) begin
                    carry = digits_buf[i] - 4'd9;
                    digits_buf[i] = 4'd0;
                end
                if ((carry > 0) && (i - 1 >= 4'd0)) begin
                    digits_buf[i-1] = digits[i-1] + carry;
                    carry = 'b0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (digit_mod_en) begin
            digits <= digits_buf;
        end
        if (display_mod_en) begin
            // When using non-blocking logic, everything executes all at once:
            // if i do digit <= digits[digit_sel] but change digit_sel in the line
            // below, then digit gets the new value of digit_sel, which is not what
            // I want. Remember: any reference updates anywhere, so digit is already
            // redundant: I can drive display with digits[digit_sel]
            // Setting digit <= digits[digit_sel]
            // digit <= digits[digit_sel];
            digit_sel <= digit_sel + 'd1;
            // digit_sel <= (digit_sel + 'd1 > 'd4) ? 'd0 : (digit_sel + 'd1);
            // if (digit_sel > 'd4) digit_sel 
        end
    end
endmodule
