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
    // TODO: Could somehow have a proper response packet here
    logic [cpu_bus.ADDR_WIDTH-1:0] next_cpu_read_result;
    
    typedef enum logic [3:0] {
        IDLE = 'd1,
        WRITING_IO = 'd2,
        READING_IO = 'd3,
        WRITING_MEM = 'd4,
        READING_MEM = 'd5,
        DONE = 'd6
    } state_t;

    state_t state;
    state_t next_state;
        
    always_comb begin
        next_state = IDLE;
        io_bus.out_pkt = 'b0;
        io_bus.out_en = 0;

        io_bus.in_en = 0;


        mem_bus.write_addr = 'b0;
        mem_bus.write_val = 'b0;
        mem_bus.write_en = 0;

        mem_bus.read_addr = 'b0;
        mem_bus.read_en = 0;

        next_cpu_read_result = cpu_bus.ADDR_WIDTH'('b0);
        case (state)
            IDLE: begin
                // detect operation
                if (cpu_bus.write_en) begin
                    // write
                    // check routing
                    if (cpu_bus.write_addr == cpu_bus.ADDR_WIDTH'(-'d1)) begin
                        // route to io
                        io_bus.out_pkt = cpu_bus.write_val;
                        io_bus.out_en = 1;
                        next_state = WRITING_IO;
                    end else begin
                        // route to mem
                        mem_bus.write_addr = cpu_bus.write_addr;
                        mem_bus.write_val = cpu_bus.write_val;
                        mem_bus.write_en = 1;
                        next_state = WRITING_MEM;
                    end
                end else if (cpu_bus.read_en) begin
                    // read
                    if (cpu_bus.read_addr == cpu_bus.ADDR_WIDTH'(-'d1)) begin
                        // route to io
                        io_bus.in_en = 1;
                        next_state = READING_IO;
                    end else begin
                        mem_bus.read_addr = cpu_bus.read_addr;
                        mem_bus.read_en = 1;
                        next_state = READING_MEM;
                    end
                end
            end
            WRITING_IO: begin
                if (io_bus.output_status == busy::IDLE) begin
                    // if it has finished
                    io_bus.out_en = 0;
                    next_state = DONE;
                end
            end
            WRITING_MEM: begin
                if (mem_bus.write_status == busy::IDLE) begin
                    // finish
                    mem_bus.write_en = 0;
                    next_state = DONE;
                end
            end
            READING_IO: begin
                if (io_bus.input_status == busy::IDLE) begin
                    io_bus.in_en = 0;
                    next_cpu_read_result = io_bus.in_val;
                    // cpu_bus.read_result = io_bus.in_val;
                    next_state = DONE;
                end
            end
            READING_MEM: begin
                if (mem_bus.read_status == busy::IDLE) begin
                    mem_bus.read_en = 0;
                    next_cpu_read_result = mem_bus.read_result;
                    // cpu_bus.read_result = mem_bus.read_result;
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: ;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
            cpu_bus.read_result <= next_cpu_read_result;
        end
    end
endmodule
