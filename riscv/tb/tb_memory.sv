`timescale 1ps/1ps

module tb_memory #(
    parameter ITEM_WIDTH = 8,
    parameter ITEMS = 256
);
    localparam ADDR_WIDTH = $clog2(ITEMS);
    
    logic clk = 0; // w/o it starts on X -> ~X: useless
    // there a 256 items. width of n gives 2^n items. need solution to 2^n = 256
    logic [ADDR_WIDTH-1: 0] read_addr;
    logic [ADDR_WIDTH-1: 0] write_addr;
    logic [ITEM_WIDTH-1:0] write_val;
    logic write_enable;
    logic [ITEM_WIDTH-1:0] read_result;

    memory #(
        .ITEM_WIDTH, // .WIDTH(WIDTH)
        .ITEMS
    ) dut ( // name of instance is dut
        .clk,
        .read_addr,
        .write_addr,
        .write_val,
        .write_enable,
        .read_result
    );
    
    task write_mem(
        input logic [ADDR_WIDTH-1: 0] addr,
        input logic [ITEM_WIDTH-1:0] val,
        input bit we // write enable
    );
        begin
            @(posedge clk); // write is clock driven, so wait for the clk
            write_addr = addr;
            write_val = val;
            write_enable = we;
            #1;
            write_addr = ADDR_WIDTH'('bx); // cast: size'(...)
            write_val = ITEM_WIDTH'('bx);
            write_enable = 0;
        end
    endtask
    
    task read_mem(
        input logic [ADDR_WIDTH-1:0] addr,
        output logic [ITEM_WIDTH-1:0] result
    );
        begin
            read_addr = addr;
            #1;
            result = read_result;
            read_addr = ADDR_WIDTH'('bx);
        end
    endtask
    
    always #10 clk = ~clk;

    task write_read_check(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [ITEM_WIDTH-1:0] val
    );
        begin
            read_result = 0;
            write_mem(addr, val, 1);
            read_mem(addr, read_result);
            assert(read_result == val) 
            else    $error("Wrote to %b. Read %b, expected %b", addr, read_result, val);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_memory);
        /*
        write(addr, val, enable)
        read(addr)

        write
        - enable flag; only write with flag
        - write to all addrs
        - write to addr already written to
        read
        - read from all addr
        - read from existing addr
        */
        // Check write and read
        write_read_check('d0, 'd1);
        write_read_check('d1, 'd2);

        // write enable
        write_read_check('d3, 'd4);
        write_mem('d3, 'd5, 0);
        read_mem('d3, read_result);
        assert(read_result == 'd4);
        
        for (int i = 0; i < ITEMS ; i++) begin
            let x = ADDR_WIDTH'(i); // block scoped macro
            write_mem(x, x, 1);
        end
        for (int i = 0; i < ITEMS ; i++) begin
            let x = ADDR_WIDTH'(i);
            read_mem(x, read_result);
            assert (read_result == x)
            else   $error("Expected %b", x);
        end

        $finish();
    end
endmodule