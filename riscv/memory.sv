module memory #(
    parameter ITEM_WIDTH = 8,
    parameter ITEMS = 256,
    // there are 256 items. width of n gives 2^n items. need solution to 2^n = 256
    localparam ADDR_WIDTH = $clog2(ITEMS)
    // localparam is like const; also, when you instantiate dut, you don't pass it
)(
    input logic clk,
    input logic [ADDR_WIDTH-1:0] read_addr,
    input logic [ADDR_WIDTH-1:0] write_addr,
    input logic [ITEM_WIDTH-1:0] write_val,
    input logic write_enable,
    output logic [ITEM_WIDTH-1:0] read_result
);
    // read and write can happen the same cycle

    logic [ITEM_WIDTH-1:0] memory [ITEMS]; // 256 items x 8 bits per item = 2048 bits of mem = 256 bytes
    always_comb begin
        read_result = memory[read_addr];
    end
    always_ff @(posedge clk) begin
        if (write_enable == 1) begin // in sequential, you don't need all branches
            memory[write_addr] <= write_val;
        end
    end
endmodule
