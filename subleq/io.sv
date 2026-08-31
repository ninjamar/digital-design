interface io_if #(
    parameter WIDTH = 8
);
    // logic clk;
    // logic rst;
    logic out_en;
    logic in_en;

    logic [WIDTH-1:0] out_pkt;
    logic [WIDTH-1:0] in_val;

    busy::status_t input_status;
    busy::status_t output_status;

    modport responder(
        input  /*clk, rst,*/ out_en, in_en, out_pkt,
        output in_val, input_status, output_status
    );
    modport requester(
        input in_val, input_status, output_status,
        output  /*clk, rst,*/ out_en, in_en, out_pkt
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
            bus.input_status <= busy::IDLE;
            bus.output_status <= busy::IDLE;
        end else begin
            if (bus.in_en) begin
                bus.input_status <= busy::BUSY;
                bus.in_val <= in_data[i];
            end else begin
                bus.input_status <= busy::IDLE;
            end
            if (bus.out_en) begin
                bus.output_status <= busy::BUSY;
                // right now, dummy console output --in future, use uart
                $display("%x", bus.out_pkt);
            end else begin
                bus.output_status <= busy::IDLE;
            end
        end
    end
endmodule
