interface io_if #(
    parameter WIDTH = 8
);
    // logic clk;
    // logic rst;
    logic out_en;
    logic in_en;

    logic [WIDTH-1:0] out_pkt;
    logic [WIDTH-1:0] in_val;

    logic read_done;
    logic write_done;

    modport responder(
        input out_en, in_en, out_pkt,
        output in_val, read_done, write_done
    );
    modport requester(
        input in_val, read_done, write_done,
        output out_en, in_en, out_pkt
    );
endinterface

module io (
    input logic clk,
    input logic rst,
    io_if.responder bus
);

    logic [31:0] i;
    logic [31:0][bus.WIDTH-1:0] in_data;
    // Mock data for now: in the future, input could come via UART
    always_ff @(posedge clk) begin
        if (rst) begin
            i <= 0;
            bus.read_done <= 0;
            bus.write_done <= 0;
        end else begin
            if (!bus.read_done && bus.in_en) begin
                bus.in_val <= in_data[i];
                bus.read_done <= 1;
            end else if (bus.read_done && !bus.in_en) begin
                bus.read_done <= 0;
            end

            if (!bus.write_done && bus.out_en) begin
                // right now, dummy console output --in future, use uart
                $display("%x", bus.out_pkt);
                bus.write_done <= 1;
            end else if (bus.write_done && !bus.out_en) begin
                bus.write_done <= 0;
            end
        end
    end
endmodule
