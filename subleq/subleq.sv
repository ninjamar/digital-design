module subleq #(
    // Arch width = 32 bits
    parameter XLEN = 32,
    parameter ADDR_SIZE = 32,  // ensure within bounds of $clog2(items)
    parameter ITEMS = 256
) (
    input logic clk,
    input logic rst
);

    // Memory
    /*
    logic [ADDR_SIZE-1:0] read_addr;
    logic [ADDR_SIZE-1:0] write_addr;
    logic [XLEN-1:0] write_val;
    logic write_enable;
    logic [XLEN-1:0] read_result;
    */

    // Write to mux
    mem_if #(
        .ITEM_WIDTH(XLEN  /* default 8 */),
        .ADDR_WIDTH(ADDR_SIZE  /* default 8 */),
        .ITEMS(ITEMS  /* default 2 ** ADDR_WIDTH */)
    ) mux_bus (); // writer

    // Write memory directly
    mem_if #(
        .ITEM_WIDTH(XLEN /* default 8 */),
        .ADDR_WIDTH(ADDR_SIZE /* default 8 */),
        .ITEMS     (ITEMS /* default 2 ** ADDR_WIDTH */)
     ) mem_bus ();

    io_if #(.WIDTH(XLEN  /* default 8 */)) io_bus ();

    memory memory (
        .clk(clk),
        .bus(mem_bus)
    );

    io io (
        .clk(clk),
        .rst(rst),
        .bus(io_bus)
    );

    busy::status_t mux_status;    
    mem_io_mux mem_io_mux (
        .clk(clk),
        .rst(rst),
        .status(mux_status),
        .cpu_bus(mux_bus),
        .mem_bus(mem_bus),
        .io_bus(io_bus)
    );

    typedef enum logic [2:0] {
        IDLE = 3'd0,
        FETCH = 3'd1,
        DECODE = 3'd2,
        EXECUTE = 3'd3,
        WRITE = 3'd4
        //WAIT = 3'd5
    } state_t;

    // Control side
    typedef struct packed {
        state_t state;
        logic [3:0] step;
    } ctrl_t;

    ctrl_t ctrl;
    ctrl_t ctrl_next;

    // state_t curr_state;
    // state_t next_state;

    // logic [3:0] step;

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
    } regs_t;

    // Control side
    regs_t regs;
    regs_t regs_next;
    
    // Stall when mux is busy
    logic stall;
    assign stall = (mux_status == busy::BUSY);
    // Datapath
    always_comb begin
        // SUBLEQ: subtract and branch if less than or equal
        // subleq a, b, c
        // mem[b] = mem[b] - mem[a]
        // if mem[b] <= 0: jump to c
        // else: continue to next instruction (pc += 3)

        // States
        ctrl_next.state = IDLE;
        regs_next = regs;

        // Safe defaults (combinational)
        mux_bus.read_addr = ADDR_SIZE'('b0);
        mux_bus.read_en = 0;
        mux_bus.write_addr = ADDR_SIZE'('b0);
        mux_bus.write_val = XLEN'('b0);
        mux_bus.write_en = 0;

        case (ctrl.state)
            IDLE: ctrl_next.state = FETCH;
            FETCH: begin
                // Load instruction from memory
                case (ctrl.step)
                    0: begin
                        mux_bus.read_addr   = regs.pc;
                        mux_bus.read_en = 1;
                        // CPU stalls here
                        // Shift to mem wait state, then copy to a
                        regs_next.a = mux_bus.read_result;
                        ctrl_next.state  = FETCH;
                    end
                    1: begin
                        mux_bus.read_addr   = regs.pc + 'd1;
                        mux_bus.read_en = 1;
                        regs_next.b = mux_bus.read_result;
                        ctrl_next.state  = FETCH;
                    end
                    2: begin
                        mux_bus.read_addr   = regs.pc + 'd2;
                        mux_bus.read_en = 1;
                        regs_next.c = mux_bus.read_result;
                        ctrl_next.state  = DECODE;
                    end
                    default: ;
                endcase
            end
            DECODE: ctrl_next.state = EXECUTE;
            EXECUTE: begin
                // Execute instruction

                // Need to fetch mem[b] and mem[a]
                // Separate based on read cycle
                case (ctrl.step)
                    // Mem a
                    0: begin
                        mux_bus.read_addr = regs.a;
                        mux_bus.read_en = 1;
                        regs_next.mem_a = mux_bus.read_result;
                        ctrl_next.state  = EXECUTE;
                    end
                    // Mem b
                    1: begin
                        mux_bus.read_addr = regs.b;
                        mux_bus.read_en = 1;
                        regs_next.mem_b = mux_bus.read_result;

                        ctrl_next.state  = EXECUTE;
                    end
                    2: begin
                        // subtract mem[b] and mem[a]
                        regs_next.sub_result = $signed(regs.mem_b - regs.mem_a);
                        // store the final write of mem[b] (but do not write it to mem[b])
                        // do the comparison, and update pc

                        if (regs_next.sub_result <= 0) begin
                            // jmp c
                            regs_next.pc = regs.c;
                        end else begin
                            // increase pc
                            regs_next.pc = regs.pc + 'd3;
                        end

                        ctrl_next.state = WRITE;
                    end
                    default: ;
                endcase
            end
            WRITE: begin
                // write mem[b]
                mux_bus.write_addr = regs.b;
                mux_bus.write_val  = $unsigned(regs.sub_result);
                mux_bus.write_en = 1;

                // write, then next cycle clear write_enable to 0
                ctrl_next.state = FETCH;
            end
            default: ;
        endcase
    end

    // Control
    always_ff @(posedge clk) begin
        if (rst) begin
            ctrl.state <= IDLE;
            ctrl.step <= 'b0;

            regs <= '{default: 0};  // reset back to default of 0
        end else if (!stall) begin
            // Only increment if we are not switching.
            if (ctrl.state == ctrl_next.state) begin
                ctrl.step <= ctrl.step + 1;
            end else begin
                ctrl.step <= 'b0;
            end

            ctrl.state <= ctrl_next.state;

            regs <= regs_next;
        end
    end
endmodule
