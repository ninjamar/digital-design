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
        EXECUTE = 3'd3
        // WRITE = 3'd4,
        // WAIT = 3'd5
    } state_t;

    state_t curr_state;
    state_t next_state;

    logic [ADDR_SIZE-1:0] pc;
    logic [ADDR_SIZE-1:0] pc_next;

    logic [3:0] step;
    logic [3:0] next_step;

    // A, B, C
    logic [XLEN-1:0] arg[0:2];  // 3 items each of XLEN-1:0.

    logic [XLEN-1:0] arg_next[0:2];
    logic [XLEN-1:0] mem_b;
    logic [XLEN-1:0] mem_a;
    logic [XLEN-1:0] temp;


    // SUBLEQ: subtract and branch if less than or equal
    // subleq a, b, c
    // mem[b] = mem[b] - mem[a]
    // if mem[b] <= 0: jump to c
    // else: continue to next instruction (pc += 3)
    always_comb begin
        next_state = IDLE;
        // arg_next = {XLEN'('b0), XLEN'('b0), XLEN'('b0)};
        arg_next = arg; // falls through
        mem_b = XLEN'('b0);
        mem_a = XLEN'('b0);
        temp = XLEN'('b0);
        read_addr = ADDR_SIZE'('b0);
        write_addr = ADDR_SIZE'('b0);
        write_val = XLEN'('b0);
        write_enable = 0;
        pc_next = pc;
        
        case (curr_state)
            IDLE: next_state = FETCH;
            // Fetch a, b, and c (all stored in memory)
            FETCH: begin
                // Fetch next 3 segments from memory
                // Step goes from 0 to 2. This allows one read operation per
                // cycle.
                // pc+0, pc+1, pc+2
                read_addr = pc + ADDR_SIZE'(step);
                arg_next[step] = read_result;
                if (step == 2) begin
                    next_state = DECODE;
                end else begin
                    next_state = FETCH;
                end
            end
            // Not much to do here
            DECODE: next_state = EXECUTE;
            // mem[b] = mem[b] - mem[a]
            // check condition: jump via pc
            EXECUTE: begin
                // Fetch mem[b], mem[a]
                next_state = EXECUTE;
                case (step)
                    0: begin
                        read_addr = arg[1];
                        mem_b = read_result;
                    end
                    1: begin
                        read_addr = arg[0];
                        mem_a = read_result;
                    end
                    2: begin
                        
                    end
                    3:
                    4:
                    5:
                endcase

                
                // Compute mem[b]
                temp = mem_b - mem_a;
                write_addr = arg[1];
                write_val = temp;
                write_enable = 1;
                write_enable = 0;
                // Do the jump condition 
                if (temp <= 0) begin
                    pc_next = arg[2];
                end else begin
                    pc_next = pc + 3;
                end

                next_state = FETCH;
            end
            // Write nmem[b]
            // WRITE:
            // WAIT:
            default: ;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            // read_addr <= ADDR_SIZE'('b0);
            // write_addr <= ADDR_SIZE'('b0);
            // write_val <= XLEN'('b0);
            // write_enable <= 0;
            curr_state <= IDLE;

            pc <= ADDR_SIZE'('b0);

            arg <= {XLEN'('b0), XLEN'('b0), XLEN'('b0)};
            step <= 'b0;
        end else begin
            // Only increment if we are not switching.
            if (curr_state == next_state) begin
                step <= step + 1;
            end else begin
                step <= 'b0;
            end

            curr_state <= next_state;
            pc <= pc_next;

            arg <= arg_next;            
        end
    end
endmodule
