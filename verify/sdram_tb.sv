`timescale 1ns/1ps

module sdram_tb;

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam ROW_BITS   = 11;
    localparam COL_BITS   = 8;


    // -----------------------
    // Signals
    // -----------------------
    logic cs_n, ras_n, cas_n, we_n;
    logic [ROW_BITS-1:0] sdram_addr;
    logic [1:0] bank_select;
    logic [DATA_WIDTH-1:0] dq_in;
    logic [DATA_WIDTH-1:0] dq_out;

    // -----------------------
    // DUT
    // -----------------------
    sdram_module #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROW_BITS(ROW_BITS),
        .COL_BITS(COL_BITS) 
        ) dut (
        .clk(clk),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .sdram_addr(sdram_addr),
        .bank_select(bank_select),
        .dq_in(dq_in),
        .dq_out(dq_out)
    );

    // -----------------------
    // Clock
    // -----------------------
    logic clk;
    always #5 clk = ~clk;   // 100 MHz


    // -----------------------
    // SDRAM command tasks
    // -----------------------
    task cmd_nop();
        begin
            cs_n  = 0;
            ras_n = 1;
            cas_n = 1;
            we_n  = 1;
            @(posedge clk);
        end
    endtask

    task cmd_activate(input [1:0] bank, 
                      input [ROW_BITS-1:0] row);
        begin
            cs_n         = 0;
            ras_n        = 0;
            cas_n        = 1;
            we_n         = 1;
            sdram_addr   = row;
            bank_select  = bank;
            @(posedge clk);
        end
    endtask

    task cmd_write(input [1:0] bank,
                   input [COL_BITS-1:0] col,
                   input [DATA_WIDTH-1:0] data);
        begin
            cs_n         = 0;
            ras_n        = 1;
            cas_n        = 0;
            we_n         = 0;
            sdram_addr   = {{(ROW_BITS-COL_BITS){1'b0}}, col};
            bank_select  = bank;
            dq_in        = data;
            @(posedge clk);
        end
    endtask

    task cmd_read(input [1:0] bank, 
                  input [COL_BITS-1:0] col);
        begin
            cs_n         = 0;
            ras_n        = 1;
            cas_n        = 0;
            we_n         = 1;
            sdram_addr   = {{(ROW_BITS-COL_BITS){1'b0}}, col};
            bank_select  = bank;
            @(posedge clk);
        end
    endtask

    task write_data(input [1:0] bank, 
                    input [ROW_BITS-1:0] row, 
                    input [COL_BITS-1:0] col,
                    input [DATA_WIDTH-1:0] data);
        begin
            $display("[%0t] Writing: Bank=%0d, Row=%0d, Col=%0d, Data=0x%0h", $time, bank, row, col, data);
            cmd_activate(bank, row);
            //tRCD - time from ACTIVATE to ACCESS ROW/COLUMN (2 cycles)
            cmd_write(bank, col, data);
            //tWR - write recovery time (3 cycles)
            cmd_nop();
            cmd_nop();
            cmd_nop(); // write_ready activates when nop_count = 2 on the 3rd NOP
        end
    endtask

    task  read_data(input [1:0] bank,
                    input [ROW_BITS-1:0] row, 
                    input [COL_BITS-1:0] col);
        begin
            $display("[%0t] Reading: Bank=%0d, Row=%0d, Col=%0d", $time, bank, row, col);
            cmd_activate(bank, row);
            cmd_read(bank, col);
            // CL - time from read to data output ( CAS Latency) (1 cycle)
            @(posedge clk); // wait for read to finish
            @(posedge clk); // read data on dq_out
            $display("[%0t] Read Data: 0x%0h", $time, dq_out);
        end
    endtask

    // -----------------------
    // Main Test sequence
    // -----------------------
    initial begin
        $dumpfile("SDRAM.vcd");
        $dumpvars(0, dut);

        // Initialize signals
        clk          = 0;
        cs_n         = 1;
        ras_n        = 1;
        cas_n        = 1;
        we_n         = 1;
        sdram_addr   = 0;
        bank_select  = 0;
        dq_in        = 0;

        // Wait a few cycles
        repeat(5) @(posedge clk);
        $display("\n====================================================================================");
        $display("                                         SDRAM Testbench                              ");        
        $display("======================================================================================");
        $display("Memory Size: %0d rows × %0d cols × 16 bits × 4 banks", (1<<ROW_BITS), (1<<COL_BITS));
        $display("Total Memory: %0d Kb", ((1<<ROW_BITS) * (1<<COL_BITS) * 16 * 4) / 1024);
        
        // TEST 1: Bank 0
        $display("\nTEST 1: Bank 0 write");
        write_data(2'b00, 11'd5, 8'd10, 16'hA5A5);
        repeat(2) @(posedge clk);
        
        $display("\nTEST 1: Bank 0 read");
        read_data(2'b00, 11'd5, 8'd10);
        repeat(2) @(posedge clk);

        // TEST 2: Writing/Reading - multiple banks
        $display("\nTEST 2: Write to multiple banks ");
        write_data(2'b00, 11'd1, 8'd2, 16'h1111);
        write_data(2'b01, 11'd3, 8'd4, 16'h2222);
        write_data(2'b10, 11'd5, 8'd6, 16'h3333);
        write_data(2'b11, 11'd7, 8'd8, 16'h4444);
        repeat(2) @(posedge clk);

        $display("\nTEST 2: Read from multiple banks ");
        read_data(2'b00, 11'd1, 8'd2);
        read_data(2'b01, 11'd3, 8'd4);
        read_data(2'b10, 11'd5, 8'd6);
        read_data(2'b11, 11'd7, 8'd8);
        repeat(2) @(posedge clk);

        // TEST 3: Immediate Read/Write to same bank
        $display("\nTEST 3: Immediate Read and Write ");
        write_data(2'b10, 11'd100, 8'd200, 16'h5555);
        //repeat(3) @(posedge clk);
        read_data(2'b10, 11'd100, 8'd200);
        repeat(2) @(posedge clk);

        // TEST 4: Sequential Writes to the same bank
        $display("\nTEST 4: Sequential Writes to same row, different col");
        write_data(2'b11, 11'd50, 8'd7, 16'hAAAA);
        write_data(2'b11, 11'd50, 8'd8, 16'hBBBB);
        write_data(2'b11, 11'd50, 8'd9, 16'hCCCC);
        repeat(2) @(posedge clk);


        // TEST 5: Sequential Reads from same bank
        $display("\nTEST 5: Sequential Reads to Verify previous Writes to same row, different col");
        read_data(2'b11, 11'd50, 8'd7);
        read_data(2'b11, 11'd50, 8'd8);
        read_data(2'b11, 11'd50, 8'd9);
        repeat(2) @(posedge clk);

        // TEST 6: Edge Cases
        $display("\nTEST 6: Edge Cases: Max Addresses");
        write_data(2'b00, 11'd2047, 8'd255, 16'hFFFF);
        read_data(2'b00, 11'd2047, 8'd255);
        repeat(2) @(posedge clk);
        
        
        $display("\n====================================================================================");
        $display("                             SDRAM Testbench Completed                                ");        
        $display("======================================================================================");
        
        repeat(10) @(posedge clk);
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t | cs_n=%b ras_n=%b cas_n=%b we_n=%b | Bank=%0d Addr=%0d | dq_in=0x%0h dq_out=0x%0h", 
                 $time, cs_n, ras_n, cas_n, we_n, bank_select, sdram_addr, dq_in, dq_out);
    end

endmodule