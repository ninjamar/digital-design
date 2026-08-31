module mem_io_mux (
    input logic clk,
    input logic rst,
    output busy::status_t status,
    mem_if.responder cpu_bus,

    mem_if.requester mem_bus,
    io_if.requester io_bus
);
    // The CPU talks to the MUX: mux is responder
    // MUX talks to IO: MUX is requester
    // MUX talks to MEM: MUX is requester

    /*
    States:
    - IDLE; ready to receive from bus (CPU holds WAIT)
    - WRITING; writing to memory/output
    - READING; reading from memory/input
    - DONE;
    CPU waits from IDLE -> READING/WRITING -> DONE
    */
    typedef enum logic [3:0] {
        IDLE = 'd1,
        WRITING_IO = 'd2,
        READING_IO = 'd3,
        WRITING_MEM = 'd4,
        READING_MEM = 'd5,
        DONE = 'd6
    } state_t;

    state_t state;
    
    // continuous assignment; could use always_comb but this is shorter
    // assign status = (state == IDLE) ? busy::IDLE : busy::BUSY;
    always_comb begin
        if (cpu_bus.write_en || cpu_bus.read_en) begin
            status = busy::BUSY;
        end else begin
            status = busy::IDLE;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;

            mem_bus.write_en <= 0;
            mem_bus.read_en <= 0;
            io_bus.in_en <= 0;
            io_bus.out_en <= 0;
        end else case (state)
            IDLE: begin
                // detect operation
                if (cpu_bus.write_en) begin
                    // write
                    // check routing
                    if (cpu_bus.write_addr == cpu_bus.ADDR_WIDTH'(-'d1)) begin
                        // route to io
                        io_bus.out_pkt <= cpu_bus.write_val;
                        io_bus.out_en <= 1;
                        state <= WRITING_IO;
                    end else begin
                        // route to mem
                        mem_bus.write_addr <= cpu_bus.write_addr;
                        mem_bus.write_val <= cpu_bus.write_val;
                        mem_bus.write_en <= 1;
                        state <= WRITING_MEM;
                    end
                end else if (cpu_bus.read_en) begin
                    // read
                    if (cpu_bus.read_addr == cpu_bus.ADDR_WIDTH'(-'d1)) begin
                        // route to io
                        io_bus.in_en <= 1;
                        state <= READING_IO;
                    end else begin
                        mem_bus.read_addr <= cpu_bus.read_addr;
                        mem_bus.read_en <= 1;
                        state <= READING_MEM;
                    end
                end
            end
            WRITING_IO: begin
                if (io_bus.output_status == busy::IDLE) begin
                    // if it has finished
                    io_bus.out_en <= 0;
                    state <= DONE;
                end
            end
            WRITING_MEM: begin
                if (mem_bus.write_status == busy::IDLE) begin
                    // finish
                    mem_bus.write_en <= 0;
                    state <= DONE;
                end
            end
            READING_IO: begin
                if (io_bus.input_status == busy::IDLE) begin
                    io_bus.in_en <= 0;
                    cpu_bus.read_result <= io_bus.in_val;
                    state <= DONE;
                end
            end
            READING_MEM: begin
                if (mem_bus.read_status == busy::IDLE) begin
                    mem_bus.read_en <= 0;
                    cpu_bus.read_result <= mem_bus.read_result;
                    state <= DONE;
                end
            end
            DONE: begin
                state <= IDLE;
            end
        endcase
    end
endmodule
