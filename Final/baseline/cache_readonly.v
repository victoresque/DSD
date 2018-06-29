/*
    Module:         Read-only Cache
    Author:         Victor Huang
    Description:
        32 words (8 blocks x 4 words) cache
        Placement:              direct mapped 
*/

module cache_readonly(
    clk,
    proc_reset,
    proc_read,
    proc_write,
    proc_addr,
    proc_wdata,
    proc_stall,
    proc_rdata,
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready
);

//==== input/output definition ============================
    input          clk;
    // processor interface
    input          proc_reset;
    input          proc_read, proc_write;
    input   [29:0] proc_addr;
    input   [31:0] proc_wdata;
    output         proc_stall;
    output  [31:0] proc_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output         mem_read, mem_write;
    output  [27:0] mem_addr;
    output [127:0] mem_wdata;

    assign mem_write = 1'b0;
    assign mem_wdata = 128'b0;

//==== states =============================================
    reg   [2:0] state, state_next;
    parameter S_IDLE = 3'd0;
    parameter S_MEM_READ = 3'd1;
    parameter S_UPDATE = 3'd2;

//==== wire/reg definition ================================
    // proc_addr: 30b
    // tag: 25b, index: 3b, word offset: 2b
    // block: valid(1b) + dirty(1b) + tag(25b) + data(32b*4) = 155b
    reg  [154:0] block [0:7];
    reg  [154:0] block_next [0:7];
    reg   [24:0] proc_tag;
    reg    [2:0] proc_index;
    reg    [1:0] proc_offset;

    reg  [154:0] proc_block;
    reg          proc_block_valid;
    reg          proc_block_dirty;
    reg   [24:0] proc_block_tag;
    reg  [127:0] proc_block_data;

    reg  [127:0] proc_new_data;
    reg  [127:0] proc_replace_data;
    reg   [31:0] proc_block_word;

    wire         proc_stall;
    reg          proc_stall_r, proc_stall_w;
    wire  [31:0] proc_rdata;
    reg   [31:0] proc_rdata_r, proc_rdata_w;

    reg          hit;
    reg          mem_read, mem_read_next;
    reg   [27:0] mem_addr, mem_addr_next;
    reg   [31:0] mem_rdata_word;

    reg  [127:0] mem_rdata_r, mem_rdata_w;

    integer i;

//==== combinational circuit ==============================
    assign proc_stall = proc_stall_w;
    assign proc_rdata = proc_rdata_w;

    always @ (*) begin
        proc_tag = proc_addr[29:5];
        proc_index = proc_addr[4:2];
        proc_offset = proc_addr[1:0];
        proc_block = block[proc_index];
        proc_block_valid = proc_block[154];
        proc_block_dirty = proc_block[153];
        proc_block_tag = proc_block[152:128];
        proc_block_data = proc_block[127:0];
        hit = proc_tag == proc_block_tag;

        case (proc_offset)
            2'd0: begin
                proc_block_word = proc_block_data[31:0];
                mem_rdata_word = mem_rdata_r[31:0];
            end
            2'd1: begin
                proc_block_word = proc_block_data[63:32];
                mem_rdata_word = mem_rdata_r[63:32];
            end
            2'd2: begin
                proc_block_word = proc_block_data[95:64];
                mem_rdata_word = mem_rdata_r[95:64];
            end
            2'd3: begin
                proc_block_word = proc_block_data[127:96];
                mem_rdata_word = mem_rdata_r[127:96];
            end
        endcase
    end

    always @ (*) begin
        case (state)
        S_IDLE: begin
            if (proc_read) begin
                if (proc_block_valid) begin
                    if (hit) begin
                        // * read hit, valid, clean/dirty
                        // > read from cache
                        proc_rdata_w = proc_block_word;
                        proc_stall_w = 1'b0;

                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        mem_read_next = mem_read; 
                        mem_addr_next = proc_addr[29:2];
                        mem_rdata_w = mem_rdata_r;
                        state_next = state;
                    end
                    else begin
                        // * read miss, valid, clean
                        // > read from memory
                        mem_read_next = 1'b1;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ;

                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_rdata_w = proc_rdata_r;
                        mem_addr_next = proc_addr[29:2];
                        mem_rdata_w = mem_rdata_r;
                    end
                end
                else begin
                    // * read miss/hit, invalid, clean/dirty
                    // > read from memory
                    mem_read_next = 1'b1;
                    proc_stall_w = 1'b1;
                    state_next = S_MEM_READ;

                    for (i=0; i<8; i=i+1) block_next[i] = block[i];
                    proc_rdata_w = proc_rdata_r;
                    mem_addr_next = proc_addr[29:2];
                    mem_rdata_w = mem_rdata_r;
                end
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                mem_read_next = mem_read; 
                mem_addr_next = proc_addr[29:2];
                mem_rdata_w = mem_rdata_r;
                state_next = state;
            end
        end
        S_MEM_READ: begin
            if (mem_ready) begin
                mem_read_next = 1'b0;                
                mem_rdata_w = mem_rdata;
                state_next = S_UPDATE;

                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                mem_addr_next = proc_addr[29:2];
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                mem_read_next = mem_read; 
                mem_addr_next = proc_addr[29:2];
                mem_rdata_w = mem_rdata_r;
                state_next = state;
            end
        end
        S_UPDATE: begin
            for (i=0; i<8; i=i+1) block_next[i] = block[i];
            mem_read_next = mem_read; 
            mem_addr_next = proc_addr[29:2];
            mem_rdata_w = mem_rdata_r;

            block_next[proc_index] = {1'b1, 1'b0, proc_tag, mem_rdata_r};
            proc_rdata_w = mem_rdata_word;
            proc_stall_w = 1'b0;
            state_next = S_IDLE;
        end
        default: begin
            for (i=0; i<8; i=i+1) block_next[i] = block[i];
            proc_stall_w = proc_stall_r;
            proc_rdata_w = proc_rdata_r;
            mem_read_next = mem_read; 
            mem_addr_next = proc_addr[29:2];
            mem_rdata_w = mem_rdata_r;
            state_next = state;
        end
        endcase
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            for (i=0; i<8; i=i+1) block[i] <= 155'b0;
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            mem_read <= 1'b0;
            mem_addr <= 28'b0;
            mem_rdata_r <= 128'b0;
            state <= S_IDLE;
        end
        else begin
            for (i=0; i<8; i=i+1) block[i] <= block_next[i];
            proc_stall_r <= proc_stall_w;
            proc_rdata_r <= proc_rdata_w;
            mem_read <= mem_read_next;
            mem_addr <= mem_addr_next;
            mem_rdata_r <= mem_rdata_w;
            state <= state_next;
        end
    end
endmodule
