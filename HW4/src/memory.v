// DSD spring 2014
// memory Interface with Handshake Signal

module memory(
    clk,
    mem_read,
    mem_write,
    mem_addr,
    mem_wdata,
    mem_rdata,
    mem_ready
);
    
    parameter MEM_NUM = 256;
    parameter MEM_WIDTH = 128;
    parameter READ_LATENCY = 15;  // 15ns
    parameter RESPONSE_TIME = 5;  // 5ns
    
    input                  clk;
    input                  mem_read, mem_write;
    input           [27:0] mem_addr;
    input  [MEM_WIDTH-1:0] mem_wdata;
    output [MEM_WIDTH-1:0] mem_rdata;

    output                  mem_ready;
    reg                     mem_ready;
    reg    [MEM_WIDTH-1:0] mem[MEM_NUM-1:0];
    reg    [MEM_WIDTH-1:0] data_out;
    reg    [MEM_WIDTH-1:0] mask_out;
    reg             [27:0] read_addr;
    
    reg [2:0] counter;
    
    initial counter = 1;
    always@( negedge clk ) begin
        counter <= counter + 3'd1;
    end
    
    always@( posedge counter[1] ) begin
        if( ~mem_read && ~mem_write ) begin
            // idle
            mem_ready = 1'b0;
        end
        else if( ~mem_read && mem_write ) begin
            mem[mem_addr] <= mem_wdata;
            mem_ready = 1'b0;
            #(READ_LATENCY);
            mem_ready = 1'b1;
        end
        else if( mem_read && ~mem_write ) begin
            read_addr = mem_addr;
            mem_ready = 1'b0;
            #(RESPONSE_TIME);
            if( data_out != mem[read_addr] ) mask_out = {MEM_WIDTH{1'bx}};           
            else mask_out = {MEM_WIDTH{1'b0}};
            data_out = mem[read_addr];
            #(READ_LATENCY-RESPONSE_TIME);
            mask_out = {MEM_WIDTH{1'b0}};
            mem_ready = 1'b1;
        end
        else begin
            // idle
            mem_ready = 1'b0;
        end
    end
    
    assign  mem_rdata = data_out ^ mask_out;
    
endmodule


  
  