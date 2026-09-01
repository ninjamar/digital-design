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
    
    logic read_done;
    logic write_done;

    modport responder (
        // the input means that this moduel consumes this signal.
        input read_addr, read_en, write_addr, write_val, write_en,
        // continuing, if this is an output, it becomes an input to something
        // else if it is chained.
        output read_result, read_done, write_done
    );
    modport requester (
        input read_result, read_done, write_done,
        output read_addr, read_en, write_addr, write_val, write_en
    );
endinterface

module memory(input logic clk, input logic rst, mem_if.responder bus);
    // read and write can happen the same cycle
    logic [bus.ITEM_WIDTH-1:0] memory [bus.ITEMS]; // 256 items x 8 bits per item = 2048 bits of mem = 256 bytes

    always_ff @(posedge clk) begin
        if (rst) begin
            bus.read_done <= 0;
            bus.write_done <= 0;
        end else begin
            // READ
            // On single cycle: if idle, and requester is asking, read. 
            // if completed and requester has dropped request, go back to idle.
            // this requires caller to manage it's state. this is better
            // because the _done is held not pulsed.
            
            // the requester holds read_en until it sees read_done
            if (!bus.read_done && bus.read_en) begin
                bus.read_result <= memory[bus.read_addr];
                bus.read_done <= 1;
            end else if (bus.read_done && !bus.read_en) begin
                bus.read_done <= 0;
            end

            // WRITE
            if (!bus.write_done && bus.write_en) begin
                memory[bus.write_addr] <= bus.write_val;
                bus.write_done <= 1;
            end else if (bus.write_done && !bus.write_en) begin
                bus.write_done <= 0;
            end
        end
    end
endmodule
