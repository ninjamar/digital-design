module mem_io_mux (
    input logic clk,
    input logic rst,
    mem_if.responder mem_sender // write data here
    // mem_if.mem_requester mem_receiver, // get output from here
    // io_if.responder io_sender // write
    // io_if.io_responder io_receiver // read
);
    // Usage: mux is driven with args of mem

    // Assume same clock settings for now; depending on bus in the future, this
    // could change.
    always_ff @(clk) begin
        if (mem)
    end
    busy::state_t state;
    always_ff @(clk) begin
        if (rst) begin
            state <= busy::IDLE;
        end else
        if (state == busy::BUSY) begin
            if (!)
        end else if (state == busy::IDLE) begin
            if (mem_bus.read_addr == mem_bus.ADDR_WIDTH'(-'d1)) begin
                io_bus.in_en <= 1; // input
            end else if (mem_bus.write_addr == mem_bus.ADDR_WIDTH'(-'d1)) begin
                io_bus.out_en <= 1;
                io_bus.out_pkt <= mem_bus.write_val;
            end
            state <= busy::BUSY;
        end
    end
endmodule
