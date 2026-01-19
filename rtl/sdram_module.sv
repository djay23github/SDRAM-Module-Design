// ========================================================
//  SDRAM MODULE with 4 banks ( No precharge or refresh)
// ========================================================

module sdram_module #(
    parameter DATA_WIDTH = 16,
    parameter ROW_BITS   = 11,
    parameter COL_BITS   = 8
)(
    // input clock
    input  logic clk,

    // SDRAM pins - all are active low
    input  logic cs_n, // chip select
    input  logic ras_n, // row address strobe
    input  logic cas_n, // column address strobe
    input  logic we_n, // write enable signal

    // address and data bus
    input  logic [ROW_BITS-1:0] sdram_addr,
    input  logic [1:0] bank_select, // bank select bits (2 bit address for 4 banks 00, 01, 10, 11)
    input  logic [DATA_WIDTH-1:0] dq_in, // write data bus
    output logic [DATA_WIDTH-1:0] dq_out // read data bus
);

    // Initializing all the inputs
    logic [ROW_BITS-1:0] row_init = 11'b0;
    logic [COL_BITS-1:0] col_init = 8'b0;
    logic [1:0] bank_select_init = 2'b0;
    logic [1:0] nop_count =  2'b0; // required as idle states to allow proper timing and sequencing of SDRAM operations

    // to integrate the data write latency and read latency , write and read completion flags
    logic write_flag = 1'b0, read_flag = 1'b0;

    // Commands
    wire cmd_activate   = ~cs_n & ~ras_n &  cas_n & we_n; // select bank and activate row
    wire cmd_read       = ~cs_n &  ras_n & ~cas_n & we_n; // select bank and column, start read burst
    wire cmd_write      = ~cs_n &  ras_n & ~cas_n & ~we_n; // select bank and column, start write burst
    wire cmd_nop        = ~cs_n & ras_n & cas_n & we_n; // no operation        
    wire write_ready    = (nop_count == 2 && cmd_nop && write_flag) ? 1'b1 :  1'b0; // data is ready to be written into memory

    // Defining each bank seperately with its own row buffer having column access ( initial flattening of array in the code itself)
    // Instead of [datawidth] mem [bank][row][col]

    // This memory mapping created an issue as the Memory is supposed to be 2^ROW_BITS and 2^COL_BITS
    // logic [DATA_WIDTH-1:0] b0 [0:ROW_BITS - 1][0:COL_BITS - 1];
    // logic [DATA_WIDTH-1:0] b1 [0:ROW_BITS - 1][0:COL_BITS - 1];
    // logic [DATA_WIDTH-1:0] b2 [0:ROW_BITS - 1][0:COL_BITS - 1];
    // logic [DATA_WIDTH-1:0] b3 [0:ROW_BITS - 1][0:COL_BITS - 1];

    logic [DATA_WIDTH-1:0] b0 [0:(1<<ROW_BITS)-1][0:(1<<COL_BITS)-1];
    logic [DATA_WIDTH-1:0] b1 [0:(1<<ROW_BITS)-1][0:(1<<COL_BITS)-1];
    logic [DATA_WIDTH-1:0] b2 [0:(1<<ROW_BITS)-1][0:(1<<COL_BITS)-1];
    logic [DATA_WIDTH-1:0] b3 [0:(1<<ROW_BITS)-1][0:(1<<COL_BITS)-1];

    // To differentiate each bank 
    localparam  BANK0 = 2'b00,
                BANK1 = 2'b01,
                BANK2 = 2'b10,
                BANK3 = 2'b11;

    // Fixing the writes with a write buffer to store data
    logic [DATA_WIDTH-1:0] write_data_buf;
    logic [ROW_BITS-1:0] write_row_buf;
    logic [COL_BITS-1:0] write_col_buf;
    logic [1:0] write_bank_buf;

    
    // Sequential Logic for NOP and R/W memory blocks
    always_ff @( posedge clk ) begin
        // chip select is active low
        if(!cs_n) begin
            if(cmd_activate) begin 
                row_init <= sdram_addr[ROW_BITS-1:0];
                bank_select_init <= bank_select;
            end
            else if (cmd_read || cmd_write) begin 
                col_init <= sdram_addr[COL_BITS-1:0];
                bank_select_init <= bank_select;
                // if read - write_flag will stay as 0, but if write - write_flag = 1
                write_flag <= cmd_write;

                if(cmd_write) begin 
                    write_data_buf <= dq_in;
                    write_row_buf <= row_init;
                    write_col_buf <= sdram_addr[COL_BITS-1:0];
                    write_bank_buf <= bank_select;
                    nop_count <= 2'b0; // Reset counter for NOPs
                end
            end
            else begin
                
            end

            // increment NOP count when write is pending
            if (write_flag && cmd_nop) begin
                if(nop_count < 2) begin
                    nop_count <= nop_count + 1;
                end
                else begin
                    
                end
            end
            else begin
                
            end
            
            if(write_ready) begin
                write_flag <= 1'b0;
                nop_count <= 2'b0;
            end
            else begin
                
            end
        end
        else begin
            
        end

        // Memory write should be sequential for selecting the banks to write data or read from the bank
        if (write_ready) begin
            case (write_bank_buf)
                BANK0:begin
                    b0[write_row_buf][write_col_buf] = write_data_buf;
                end
                BANK1:begin
                    b1[write_row_buf][write_col_buf] = write_data_buf;
                end
                BANK2:begin
                    b2[write_row_buf][write_col_buf] = write_data_buf;
                end
                BANK3:begin
                    b3[write_row_buf][write_col_buf] = write_data_buf;
                end 
                default: begin
                    
                end 
            endcase
        end
        else begin
            
        end

        // if the we_n is high, we are in the read state
        if(!cs_n && we_n && !cmd_activate) begin
           case (bank_select_init)
            BANK0:begin
                dq_out <= b0[row_init][col_init]; 
            end
            BANK1:begin
                dq_out <= b1[row_init][col_init]; 
            end
            BANK2:begin
                dq_out <= b2[row_init][col_init]; 
            end
            BANK3:begin
                dq_out <= b3[row_init][col_init]; 
            end 
            default: begin
                dq_out <= '0;
            end
           endcase 
        end
        else begin
            
        end
    end


endmodule
