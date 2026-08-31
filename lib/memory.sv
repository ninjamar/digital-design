interface mem_if#(
    parameter ITEM_WIDTH = 8,
    // parameter ITEMS = 256,
    parameter ADDR_WIDTH = 8,
    parameter ITEMS = 2 ** ADDR_WIDTH
    // there are 256 items. width of n gives 2^n items. need solution to 2^n = 256
    // localparam ADDR_WIDTH = $clog2(ITEMS)
    // localparam is like const; also, when you instantiate dut, you don't pass it
);
    // logic clk;
    logic [ADDR_WIDTH-1:0] read_addr;
    logic read_en;
    logic [ADDR_WIDTH-1:0] write_addr;
    logic [ITEM_WIDTH-1:0] write_val;
    logic write_en;
    logic [ITEM_WIDTH-1:0] read_result;
    
    busy::status_t read_status;
    busy::status_t write_status; // single cycle lock

    modport responder (
        // the input means that this moduel consumes this signal.
        input /*clk,*/ read_addr, read_en, write_addr, write_val, write_en,
        // continuing, if this is an output, it becomes an input to something
        // else if it is chained.
        output read_result, read_status, write_status
    );
    modport requester (
        input read_result, read_status, write_status,
        output /*clk,*/ read_addr, read_en, write_addr, write_val, write_en
    );
endinterface

module memory(input logic clk, /*input logic rst,*/ mem_if.responder bus);
    // read and write can happen the same cycle
    logic [bus.ITEM_WIDTH-1:0] memory [bus.ITEMS]; // 256 items x 8 bits per item = 2048 bits of mem = 256 bytes

    always_ff @(posedge clk) begin
        // if (rst) begin
            // memory <= ; // TODO: fix
            // bus.write_status <= busy::IDLE;
        // end else
        if (bus.read_en) begin
            bus.read_result <= memory[bus.read_addr];
            bus.read_status <= busy::BUSY;
        end else begin
            bus.read_status <= busy::IDLE;
        end
        
        if (bus.write_en) begin // in sequential, you don't need all branches
            memory[bus.write_addr] <= bus.write_val;
            bus.write_status <= busy::BUSY;
        end else begin
            bus.write_status <= busy::IDLE;
        end
    end
endmodule
