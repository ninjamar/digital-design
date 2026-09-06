interface io_if #(
    parameter WIDTH = 8
);
    // logic clk;
    // logic rst;
    logic out_en;
    logic in_en;

    logic [WIDTH-1:0] out_pkt;
    logic [WIDTH-1:0] in_val;

    logic in_done;
    logic out_done;

    modport responder(input out_en, in_en, out_pkt, output in_val, in_done, out_done);
    modport requester(input in_val, in_done, out_done, output out_en, in_en, out_pkt);
endinterface

module io (
    input logic clk,
    input logic rst,
    io_if.responder bus
);

    logic [31:0] i;
    /* verilator lint_off UNDRIVEN */
    logic [31:0][bus.WIDTH-1:0] in_data;
    /* verilator lint_on UNDRIVEN */
    
    // Mock data for now: in the future, input could come via UART
    always_ff @(posedge clk) begin
        if (rst) begin
            i <= 0;
            bus.in_done <= 0;
            bus.out_done <= 0;
        end else begin
            if (!bus.in_done && bus.in_en) begin
                bus.in_val <= in_data[i];
                i <= i + 1;
                bus.in_done <= 1;
            end else if (bus.in_done && !bus.in_en) begin
                bus.in_done <= 0;
            end

            if (!bus.out_done && bus.out_en) begin
                // right now, dummy console output --in future, use uart
                // $write has no trailing newline; $display does
                $write("%c", bus.out_pkt);
                bus.out_done <= 1;
            end else if (bus.out_done && !bus.out_en) begin
                bus.out_done <= 0;
            end
        end
    end
endmodule
