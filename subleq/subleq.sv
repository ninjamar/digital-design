module subleq (
    input logic clk,
    input logic rst
);
    // Arch width = 32 bits
    localparam XLEN = 32;
    // Number of items: 1024 (note fpga max ram)

    localparam ADDR_SIZE = 32;  //$clog2(1024);
    logic [ADDR_SIZE-1:0] read_addr;
    logic [ADDR_SIZE-1:0] write_addr;
    logic [XLEN-1:0] write_val;
    logic write_enable;
    logic [XLEN-1:0] read_result;

    memory #(
        .ITEM_WIDTH(XLEN),
        .ADDR_WIDTH(ADDR_SIZE),
        .ITEMS(256)
    ) data_mem (
        .clk(clk),
        .read_addr(read_addr),
        .write_addr(write_addr),
        .write_val(write_val),
        .write_enable(write_enable),
        .read_result(read_result)
    );

    typedef enum logic [2:0] {
        IDLE = 3'd0,
        FETCH = 3'd1,
        DECODE = 3'd2,
        EXECUTE = 3'd3,
        WRITE = 3'd4
        // WAIT = 3'd5
    } state_t;

    // Control side
    state_t curr_state;
    state_t next_state;

    logic [3:0] step;
    logic [3:0] next_step;

    // Datapath
    typedef struct packed {
        logic [ADDR_SIZE-1:0] pc;
        // no unpacked vector inside struct
        // logic [2:0][XLEN-1:0] args; // a, b, c
        
        logic [XLEN-1:0] a;
        logic [XLEN-1:0] b;
        logic [XLEN-1:0] c;
        
        logic [XLEN-1:0] mem_a;
        logic [XLEN-1:0] mem_b;

        logic signed [XLEN-1:0] sub_result;
    } registers;
    
    // Control side
    registers regs;
    registers regs_next;
    
    // Datapath
    always_comb begin
        // SUBLEQ: subtract and branch if less than or equal
        // subleq a, b, c
        // mem[b] = mem[b] - mem[a]
        // if mem[b] <= 0: jump to c
        // else: continue to next instruction (pc += 3)
        
        // States
        next_state = IDLE;
        regs_next = regs;

        // Safe defaults (combinational)
        read_addr = ADDR_SIZE'('b0);
        write_addr = ADDR_SIZE'('b0);
        write_val = XLEN'('b0);
        write_enable = 0;

        case (curr_state)
            IDLE: next_state = FETCH;
            FETCH: begin
                // Load instruction from memory
                case (step)
                    0: begin
                        read_addr = regs_next.pc;
                        // Shift to mem wait state, then copy to a;
                        // TODO: Switch from 0 cycle read (which may not
                        // synthesize) to a 1 cycle read
                        regs_next.a = read_result;
                        next_state = FETCH;
                    end
                    1: begin
                        read_addr = regs_next.pc + 'd1;
                        regs_next.b = read_result;
                        next_state = FETCH;
                    end
                    2: begin
                        read_addr = regs_next.pc + 'd2;
                        regs_next.c = read_result;
                        next_state = DECODE;
                    end
                    default: ;
                endcase
            end
            DECODE: next_state = EXECUTE;
            EXECUTE: begin
                // Execute instruction

                // Need to fetch mem[b] and mem[a]
                // Separate based on read cycle
                case (step)
                    // Mem a
                    0: begin
                        read_addr = regs_next.a;
                        regs_next.mem_a = read_result;
                        next_state = EXECUTE;
                    end
                    // Mem b
                    1: begin
                        read_addr = regs_next.b;
                        regs_next.mem_b = read_result;
                        next_state = EXECUTE;
                    end

                    2: begin
                        // subtract mem[b] and mem[a]
                        regs_next.sub_result = $signed(regs_next.mem_b - regs_next.mem_a);
                        // store the final write of mem[b] (but do not write it to mem[b])
                        // do the comparison, and update pc

                        if (regs_next.sub_result <= 0) begin
                            // jmp c
                            regs_next.pc = regs_next.c;
                        end else begin
                            // increase pc
                            regs_next.pc = regs_next.pc + 'd3;
                        end

                        next_state = WRITE;
                    end

                    default: ;
                endcase
            end
            WRITE: begin
                // write mem[b]
                write_addr = regs_next.b;
                write_val = $unsigned(regs_next.sub_result);
                write_enable = 1;
                // write, then next cycle clear write_enable to 0
                next_state = FETCH;
            end
            // WAIT:
            default: ;
        endcase
    end

    // Control
    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= IDLE;
            step <= 'b0;

            regs <= '{default: 0}; // reset back to default of 0
        end else begin
            // Only increment if we are not switching.
            if (curr_state == next_state) begin
                step <= step + 1;
            end else begin
                step <= 'b0;
            end

            curr_state <= next_state;

            regs <= regs_next;
        end
    end
endmodule
