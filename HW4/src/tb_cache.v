// DSD spring 2014
// Testbench for Direct-Mapped Cache

`timescale 1 ns/10 ps
`define H_CYCLE     2.5
`define CYCLE       5.0
`define OUTPUT_DELAY    0.3
`define INPUT_DELAY     0.3

module tb_cache;

    parameter MEM_NUM = 256;
    parameter MEM_WIDTH = 128;
    
    reg             clk;
    reg             proc_reset;
    reg             proc_read;
    reg             proc_write;
    reg     [29:0]  proc_addr;
    reg     [31:0]  proc_wdata;
    wire    [31:0]  proc_rdata;
    wire            proc_stall;

    wire                    mem_ready;
    wire                    mem_read;
    wire                    mem_write;
    wire    [27:0]          mem_addr;
    wire    [MEM_WIDTH-1:0] mem_wdata;
    wire    [MEM_WIDTH-1:0] mem_rdata;

    reg     [MEM_WIDTH-1:0] temp_data;
    integer i, d;
    integer t1, t2, t3;
    
    memory u_mem (
        clk  ,
        mem_read  ,
        mem_write ,
        mem_addr  ,
        mem_wdata ,
        mem_rdata ,
        mem_ready
    );

    cache u_cache(
        clk,
        proc_reset,
        proc_read,
        proc_write,
        proc_addr,
        proc_rdata,
        proc_wdata,
        proc_stall,
        mem_read,
        mem_write,
        mem_addr,
        mem_rdata,
        mem_wdata,
        mem_ready
    );
    
    // waveform dump
    initial begin
        // $fsdbDumpfile( "cache.fsdb" );
        // $fsdbDumpvars;
        $dumpfile("cache.vcd");
        $dumpvars;
    end
    
    // abort if the design cannot halt
    initial begin
        #(`CYCLE * 100000 );
        $display( "\n" );
        $display( "Your design doesn't finish all operations in reasonable interval." );
        $display( "Terminated at: ", $time, " ns" );
        $display( "\n" );
        $finish;
    end
    
    // clock
    initial begin
        clk = 1'b0;
        forever #(`H_CYCLE) clk = ~clk;
    end
    
    // memory initialization
    initial begin
        for( i=0; i<MEM_NUM; i=i+1 ) begin
            d = i*4;
            temp_data[31:0]  = d[31:0];
            temp_data[63:32] = d[31:0] + 1;
            temp_data[95:64] = d[31:0] + 2;
            temp_data[127:96] = d[31:0] + 3;
            u_mem.mem[i] = temp_data;
            //$display("mem[%d]=%h", i[7:0], u_mem.mem[i] );
        end
        $display("Memory has been initialized.\n");
    end
    
    // simulation part
    integer k, error, h;
    initial begin
        error = 0;
        proc_read = 1'b0;
        proc_write = 1'b0;
        proc_addr = 0;
        proc_wdata = 0;
        proc_reset = 1'b1;
        #(`CYCLE*4 );
        proc_reset = 1'b0;
        #(`H_CYCLE );
        
        $display( "Processor: Read initial data from memory." );
        for( k=0; k<MEM_NUM*4; k=k) begin
            #(`INPUT_DELAY);
            proc_read = 1'b1;
            proc_write = 1'b0;
            proc_addr = k[29:0];
            #(`CYCLE - `OUTPUT_DELAY - `INPUT_DELAY);
            if( ~proc_stall ) begin
                if( proc_rdata !== k[31:0] ) begin
                    error = error+1;
                    $display( "    Error: proc_addr=%d, data=%d, expected=%d.", proc_addr, proc_rdata, k[31:0] );
                end
                k = k+1;
            end
            #(`OUTPUT_DELAY);
        end
        if(error==0) $display( "    Done correctly so far! ^_^\n" );
        else         $display( "    Total %d errors detected so far! >\"<\n", error[14:0] );
        
        t1 = $time / `CYCLE;
        $display("        >>>> Read session 1: \t%5d cycles\n", t1);
        $display("        >>>> hit:  %5d\n", u_cache.hit_counter);
        $display("        >>>> miss: %5d\n", 1024-u_cache.hit_counter);

        $display( "Processor: Write new data to memory." );
        for( k=0; k<MEM_NUM*4; k=k ) begin
            #(`INPUT_DELAY);
            proc_read = 1'b0;
            proc_write = 1'b1;
            proc_addr = k[29:0];
            proc_wdata = k*3+1;
            #(`CYCLE - `OUTPUT_DELAY - `INPUT_DELAY);
            if( ~proc_stall ) k = k+1;
            #(`OUTPUT_DELAY);
        end
        $display( "    Finish writing!\n" );

        t2 = $time / `CYCLE;
        $display("        >>>> Write session: \t%5d cycles\n", t2-t1);
        $display("        >>>> write hit:  %5d\n", u_cache.wr_hit_counter);
        $display("        >>>> write miss: %5d\n", 1024-u_cache.wr_hit_counter);
        
        $display( "Processor: Read new data from memory." );
        for( k=0; k<MEM_NUM*4; k=k ) begin
            #(`INPUT_DELAY);
            proc_read = 1'b1;
            proc_write = 1'b0;
            proc_addr = k[29:0];
            #(`CYCLE - `OUTPUT_DELAY - `INPUT_DELAY);
            if( ~proc_stall ) begin
                h = k*3+1;
                if( proc_rdata !== (h[31:0]) )begin
                    error = error + 1;
                    $display( "    Error: proc_addr=%d, data=%d, expected=%d.", proc_addr, proc_rdata, h[31:0] );
                end
                #(`OUTPUT_DELAY) k = k+1;
            end
            else #(`OUTPUT_DELAY);
        end
        if(error==0) $display( "    Done correctly so far! ^_^ \n" );
        else         $display( "    Total %d errors detected so far! >\"< \n", error[14:0] );

        t3 = $time / `CYCLE;
        $display("        >>>> Read session 2: \t%5d cycles\n", t3-t2);
        $display("        >>>> hit:  %5d\n", u_cache.hit_counter);
        $display("        >>>> miss: %5d\n", 2048-u_cache.hit_counter);
        
        #(`CYCLE*4);
        $display("        >>>> Total: \t  %5d cycles\n", $time / `CYCLE);
        if( error != 0 ) $display( "==== SORRY! There are %d errors. ====\n", error[14:0] );
        else $display( "==== CONGRATULATIONS! Pass cache read-write-read test. ====\n" );
        $display( "Finished all operations at:  ", $time, " ns" );
        
        #(`CYCLE * 10 );
        $display( "Exit testbench simulation at:", $time, " ns" );
        $display( "\n" );
        $finish;
    end

endmodule
