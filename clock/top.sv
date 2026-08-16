module top(
    input logic clk,
    input logic rst,
    output logic [7:0] seg, // cathode
    output logic [3:0] an // anode
);
    logic digit_clk;

    localparam real CLOCK_FREQ= 1.0;
    localparam real DISPLAY_FREQ = 1000; ///

    clock_new #(
      .FREQ(CLOCK_FREQ)
    ) digit_clk_generator(
        .clk_new(digit_clk),
        .*
    );

    logic display_clk;
    clock_new #(
        .FREQ(DISPLAY_FREQ)
    ) display_clk_generator(
        .clk_new(display_clk),
        .*
    );

    logic en_display = 2'b0;
    logic [3:0] digit = 4'b0;
    logic [2:0] digit_sel = 3'b0;

    display display (
        .en (en_display),
        .digit_sel(digit_sel),
        .digit    (digit),
        .seg,
        .an
    );

    // first is item width, second (outside) is unpacked
    logic [3:0] digits [3:0] = '{4'd1, 4'd0, 4'd1, 4'd9};
    logic carry = 1'd0;

    always_ff @(posedge digit_clk or posedge display_clk) begin
        if (digit_clk) begin
            // Every second update the digits array
            
            carry <= 1'd0;
            // Add 1, then propgate carry
            digits[3] <= digits[3] + 1'd1;
            for (int i = 3; i >= 0; i--) begin
                if (digits[i] > 4'd9) begin 
                    carry <= 1'd1;
                    digits[i] <= 4'd0;
                end
                if (carry && i-1 >= 4'd0) digits[i-1] <= digits[i-1] + carry;
            end
        end

        if (display_clk) begin
            // 1000 times per second re-render digits

            digit_sel <= digit_sel + 1'd1; // sized to 2^2 -> wraps around
            
            digit <= digits[digit_sel];
            en_display <= 1'b1;

         end else begin
            en_display <=1'b0;
         end
    end
endmodule