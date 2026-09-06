/*

Loop:
fetch
decode
execute
write
*/

module cpu #(
   localparam DATA_MEM_WIDTH = 8,
   localparam DATA_MEM_SIZE = 16,
   localparam INSTR_MEM_WIDTH = 32,
   localparam INSTR_MEM_SIZE = 256
)(
    input logic clk,
    input logic rst
);  
    
    // Data memory
    localparam DATA_ADDR_SIZE = $clog2(DATA_MEM_SIZE);
    logic [DATA_ADDR_SIZE-1:0] data_read_addr;
    // logic data_read_enable
    logic [DATA_ADDR_SIZE-1:0] data_write_addr;
    logic [DATA_MEM_WIDTH-1:0] data_write_val;
    logic data_write_enable;
    logic [DATA_MEM_WIDTH-1:0] data_read_result;

    memory #(
        .ITEM_WIDTH(DATA_MEM_WIDTH),
        .ITEMS     (DATA_MEM_SIZE)
    ) data_mem (
        .clk         (clk),
        .read_addr   (data_read_addr),
        // .read_enable (data_read_enable),
        .write_addr  (data_write_addr),
        .write_val   (data_write_val),
        .write_enable(data_write_enable),
        .read_result (data_read_result)
    );

    // Registers
    /*
    typedef struct packed {
        logic [DATA_ADDR_SIZE-1:0] addr,
        logic []
    } register_t;
    localparam PC_ADDR = ;
    */
    logic [MEM_WIDTH-1:0] pc; // program counter
    logic [MEM_WIDTH-1:0] pc_next;

    // Instruction memory
    localparam INSTR_ADDR_SIZE = $clog2(INSTR_MEM_SIZE);
    logic [INSTR_ADDR_SIZE-1:0] instr_read_addr;
    // logic instr_read_enable
    logic [INSTR_ADDR_SIZE-1:0] instr_write_addr;
    logic [MEM_WIDTH-1:0] instr_write_val;
    logic instr_write_enable;
    logic [MEM_WIDTH-1:0] instr_read_result;
    
    memory #(
        .ITEM_WIDTH(MEM_WIDTH /* default 8 */),
        .ITEMS     (INSTR_MEM_SIZE /* default 256 */)
    ) instr_mem (
        .clk         (clk),
        .read_addr   (instr_read_addr),
        // .read_enable (instr_read_enable),
        .write_addr  (instr_write_addr),
        .write_val   (instr_write_val),
        .write_enable(instr_write_enable),
        .read_result (instr_read_result)
    );

    // ALU
    /*
    logic [MEM_WIDTH-1:0] alu_a;
    logic [MEM_WIDTH-1:0] alu_b;
    logic [MEM_WIDTH-1:0] alu_opcode;
    logic [MEM_WIDTH-1:0] alu_result;
    
    alu_bitwise #(
        .WIDTH(MEM_WIDTH)
    ) alu_bitwise (
        .a (alu_a),
        .b (alu_b),
        .opcode (alu_opcode),
        .result (alu_result)
    );
    */

    // Loop
    typedef enum logic [2:0] {
        IDLE = 3'd0,
        FETCH = 3'd1,
        DECODE = 3'd2,
        EXECUTE = 3'd3,
        WRITE = 3'd4,
        WAIT = 3'd5
    } state_t;

    state_t current_state;
    state_t next_state;
    state_t post_wait_state;

    logic [MEM_WIDTH-1: 0] curr_instr;
    logic [MEM_WIDTH-1: 0] curr_instr_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            // Inputs only
            data_read_addr <= 0;
            // data_read_enable <= 0;
            data_write_addr <= 0;
            data_write_val <= 0;
            data_write_enable <= 0;

            // instr_read_addr <= 0;
            // instr_read_enable <= 0;
            instr_write_addr <= 0;
            instr_write_val <= 0;
            instr_write_enable <= 0;
            
            current_state <= IDLE;
            pc <= 'b0;
            curr_instr <= 'b0;
        end else begin
            // Drive combinational pairs
            current_state <= next_state;
            pc <= pc_next;
            curr_instr <= curr_instr_next;
        end
    end

    // mem width = 2^8 = 256
    logic [8-1:0] opcode;
    
    always_comb begin
        next_state = IDLE;
        pc_next = pc;
        curr_instr_next = 'b0;
        instr_read_addr = pc; // NOTE: Remember cost of memory
        opcode = 'd0;

        case (current_state)
            // you can do this since state switches once per cycle, so adding
            // an extra state introduces a one cycle delay
            // WAIT: next_state = post_wait_state...
            IDLE: begin
                next_state = FETCH;
            end
            FETCH: begin
                // Get instruction at PC by reading, then incrementing PC
                // Already driven above
                // instr_read_addr = pc;
                curr_instr_next = instr_read_result;
                pc_next = pc + 1;
                next_state = DECODE;
            end
            DECODE: begin
                // From curr_instr, decode it into an opcode and parameters
                // instr format: opcode, a, b
                
                opcode = curr_instr;
                next_state = EXECUTE;
            end
            EXECUTE: begin
                // opcodes: write val, addr
                // read val to_addr
                // and addr addr
                // or addr addr
                // nand addr addr
                // comp a b
                // je addr // jump if equal
                // jne addr // jump if not equal

                // execute the opcode
                case (opcode)
                    'd0: begin
                        
                    end
                    'd1: begin
                        
                    end
                    'd2: begin
                        
                    end
                    'd2: begin
                        
                    end
                endcase
                next_state = WRITE;
            end
            WRITE: begin
                next_state = FETCH;
            end
            default: ; // semicolon means null here
        endcase
    end
    /*
    Fetch
    Decode
    Execute
    Write
    */
endmodule