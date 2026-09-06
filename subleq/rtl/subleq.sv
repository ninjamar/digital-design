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
    ) mux_bus ();  // writer

    // Write memory directly
    mem_if #(
        .ITEM_WIDTH(XLEN  /* default 8 */),
        .ADDR_WIDTH(ADDR_SIZE  /* default 8 */),
        .ITEMS(ITEMS  /* default 2 ** ADDR_WIDTH */)
    ) mem_bus ();

    io_if #(.WIDTH(XLEN  /* default 8 */)) io_bus ();

    memory memory (
        .clk(clk),
        .rst(rst),
        .bus(mem_bus)
    );

    io io (
        .clk(clk),
        .rst(rst),
        .bus(io_bus)
    );

    logic sel_io_read;
    logic sel_io_write;

    mem_io_mux mem_io_mux (
        .sel_io_read(sel_io_read),
        .sel_io_write(sel_io_write),
        .cpu_bus(mux_bus),
        .mem_bus(mem_bus),
        .io_bus(io_bus)
    );

    typedef enum logic [2:0] {
        IDLE,
        FETCH,
        DECODE,
        EXECUTE,
        WRITE
        //WAIT = 3'd5
    } state_t;

    // Control side
    typedef struct packed {
        state_t state;
        logic [3:0] step;
        logic stall;
    } ctrl_t;

    ctrl_t ctrl;
    ctrl_t ctrl_next;

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

    // Datapath

    logic is_out;
    logic is_in;

    always_comb begin
        // SUBLEQ: subtract and branch if less than or equal
        // subleq a, b, c
        // mem[b] = mem[b] - mem[a]
        // if mem[b] <= 0: jump to c
        // else: continue to next instruction (pc += 3)

        // States
        ctrl_next = ctrl;
        // ctrl_next = ctrl;
        regs_next = regs;

        // Safe defaults (combinational)
        mux_bus.read_addr = ADDR_SIZE'('b0);
        mux_bus.read_en = 0;
        mux_bus.write_addr = ADDR_SIZE'('b0);
        mux_bus.write_val = XLEN'('b0);
        mux_bus.write_en = 0;

        // If these signals are driven inside read_done, then verilator considers
        // them unoptimizable because they depend on read_done, which is what
        // these signals drive.

        is_out = regs.b == -'d1;
        is_in = regs.a == -'d1;

        sel_io_read = (ctrl.state == EXECUTE) && (ctrl.step == 0) && is_in;
        sel_io_write = (ctrl.state == EXECUTE) && (ctrl.step == 1) && is_out;

        case (ctrl.state)
            IDLE: ctrl_next.state = FETCH;
            FETCH: begin
                if (mux_bus.read_done) begin
                    case (ctrl.step)
                        0: regs_next.a = mux_bus.read_result;
                        1: regs_next.b = mux_bus.read_result;
                        2: regs_next.c = mux_bus.read_result;
                    endcase
                    mux_bus.read_en = 0;
                    if (ctrl.step == 2) begin
                        ctrl_next.state = DECODE;
                        ctrl_next.step  = 0;
                    end else ctrl_next.step = ctrl.step + 1;
                end else begin
                    mux_bus.read_addr = regs.pc + ADDR_SIZE'(ctrl.step);
                    mux_bus.read_en   = 1;
                end
            end
            DECODE: ctrl_next.state = EXECUTE;
            EXECUTE: begin
                if (ctrl.step != 2) begin
                    if (is_out && ctrl.step == 1) begin
                        if (mux_bus.write_done) begin
                            regs_next.pc = regs.pc + 'd3;
                            mux_bus.write_en = 0;
                            ctrl_next.state = FETCH;
                            ctrl_next.step = 0;
                        end else begin
                            // sel_io_write = 1;
                            mux_bus.write_val = regs.mem_a;
                            mux_bus.write_en  = 1;
                        end
                    end else begin
                        if (mux_bus.read_done) begin
                            case (ctrl.step)
                                0: regs_next.mem_a = mux_bus.read_result;
                                1: regs_next.mem_b = mux_bus.read_result;
                            endcase

                            mux_bus.read_en = 0;
                            ctrl_next.step  = ctrl.step + 1;
                        end else begin
                            // Need to fetch mem[b] and mem[a]

                            case (ctrl.step)
                                0: begin
                                    // sel_io_read = is_in; // read from io if a == -1
                                    mux_bus.read_addr = regs.a;
                                end
                                1: mux_bus.read_addr = regs.b;  // is_in -> use real addr to write
                            endcase
                            mux_bus.read_en = 1;
                        end
                    end
                end else begin
                    // Execute instruction

                    regs_next.sub_result = is_in ?
                        $signed(regs.mem_b + regs.mem_a)  // for hsq on in: mem[b] += ch
                        : $signed(regs.mem_b - regs.mem_a);
                    // store the final write of mem[b] (but do not write it to mem[b])
                    // do the comparison, and update pc

                    if (regs_next.sub_result <= 0) begin
                        // jmp c -- to negative addr means halt
                        if ($signed(regs.c) < 0) begin
                            // Stop CPU
                            ctrl_next.stall = 1;
                        end else begin
                            regs_next.pc = regs.c;
                        end
                    end else begin
                        // increase pc
                        regs_next.pc = regs.pc + 'd3;
                    end

                    ctrl_next.state = WRITE;
                end
            end
            WRITE: begin
                // write mem[b]
                if (mux_bus.write_done) begin
                    mux_bus.write_en = 0;
                    ctrl_next.state  = FETCH;
                end else begin
                    mux_bus.write_addr = regs.b;
                    mux_bus.write_val  = $unsigned(regs.sub_result);
                    mux_bus.write_en   = 1;
                end
                // write, then next cycle clear write_enable to 0
            end
            default: ;
        endcase
    end

    // Control
    always_ff @(posedge clk) begin
        if (rst) begin
            ctrl.state <= IDLE;
            ctrl.step <= 'b0;
            ctrl.stall <= 0;

            regs <= '{default: 0};  // reset back to default of 0
        end else if (!ctrl.stall) begin
            // Only increment if we are not switching.

            ctrl <= ctrl_next;
            // As this is non-blocking, values update only after the clock
            // changes

            // Here, ctrl has NOT changed yet
            if (ctrl.state != ctrl_next.state) begin
                ctrl.step <= 'b0;
            end

            // ctrl.step <= ctrl_next.step
            // ctrl.state <= ctrl_next.state;
            regs <= regs_next;
        end
    end
endmodule
