module mem_io_mux (
    input logic clk,
    input logic rst,
    input logic sel_io_read,
    input logic sel_io_write,
    mem_if.responder cpu_bus,

    mem_if.requester mem_bus,
    io_if.requester io_bus
);
    // The CPU talks to the MUX: mux is responder
    // MUX talks to IO: MUX is requester
    // MUX talks to MEM: MUX is requester

    // Select port by addr width
    // Enable/disable correct one depending on selector
    // Return the result + handshake back to cpu

    // Right now, mux is a combinational router

    // logic sel_io_read;
    // logic sel_io_write;
    always_comb begin
        // sel_io_read = (cpu_bus.read_addr == cpu_bus.ADDR_WIDTH'(-'d1));
        // sel_io_write = (cpu_bus.write_addr == cpu_bus.ADDR_WIDTH'(-'d1));

        // Read inputs
        io_bus.in_en = (cpu_bus.read_en && sel_io_read);

        mem_bus.read_en = (cpu_bus.read_en && !sel_io_read);
        mem_bus.read_addr = cpu_bus.read_addr;

        // Write inputs
        io_bus.out_en = (cpu_bus.write_en && sel_io_write);
        io_bus.out_pkt = cpu_bus.write_val;

        mem_bus.write_en = (cpu_bus.write_en && !sel_io_write);
        mem_bus.write_addr = cpu_bus.write_addr;
        mem_bus.write_val = cpu_bus.write_val;

        // Passthrough results to cpu bus. The requester still has to maintain
        // handshake
        cpu_bus.read_result = sel_io_read ? io_bus.in_val : mem_bus.read_result;

        cpu_bus.read_done = sel_io_read ? io_bus.in_done : mem_bus.read_done;
        cpu_bus.write_done = sel_io_write ? io_bus.out_done : mem_bus.write_done;
    end
endmodule
