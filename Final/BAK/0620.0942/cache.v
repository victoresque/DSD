/*
    Module:         Cache
    Author:         Victor Huang
    Description:
        32 words (8 blocks x 4 words) cache
        Placement:              direct mapped 
        Write policy:           write back + write buffer
*/

module cache(
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

//==== states =============================================
    reg   [2:0] state, state_next;
    parameter S_IDLE = 3'd0;
    parameter S_MEM_READ = 3'd1;
    parameter S_MEM_READ_REPLACE = 3'd2;
    parameter S_READ_WRITE = 3'd3;

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
    reg   [31:0] buf_rdata_word;

    wire         proc_stall;
    reg          proc_stall_r, proc_stall_w;
    wire  [31:0] proc_rdata;
    reg   [31:0] proc_rdata_r, proc_rdata_w;

    reg          buf_read;
    reg          buf_write;
    reg          buf_write_request_r, buf_write_request_w;
    wire  [27:0] buf_addr;
    reg   [27:0] buf_addr_r, buf_addr_w;
    wire [127:0] buf_wdata;
    reg  [127:0] buf_wdata_r, buf_wdata_w;

    reg          hit;
    wire [127:0] buf_rdata;
    wire         buf_stall;

    integer i;

//==== instances ==========================================
    buffer buffer_inst(
        .clk(clk),
        .rst(proc_reset),
        .buf_addr(buf_addr),
        .buf_read(buf_read),
        .buf_write(buf_write),
        .buf_rdata(buf_rdata),
        .buf_wdata(buf_wdata),
        .buf_stall(buf_stall),
        .mem_addr(mem_addr),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .mem_ready(mem_ready)
    );

//==== combinational circuit ==============================
    assign proc_stall = proc_stall_w;
    assign proc_rdata = proc_rdata_w;
    assign buf_addr = buf_addr_w;
    assign buf_wdata = buf_wdata_w;

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
                proc_new_data = {proc_block_data[127:32], proc_wdata};
                buf_rdata_word = buf_rdata[31:0];
                proc_replace_data = {buf_rdata[127:32], proc_wdata};
            end
            2'd1: begin
                proc_block_word = proc_block_data[63:32];
                proc_new_data = {proc_block_data[127:64], proc_wdata, proc_block_data[31:0]};
                buf_rdata_word = buf_rdata[63:32];
                proc_replace_data = {buf_rdata[127:64], proc_wdata, buf_rdata[31:0]};
            end
            2'd2: begin
                proc_block_word = proc_block_data[95:64];
                proc_new_data = {proc_block_data[127:96], proc_wdata, proc_block_data[63:0]};
                buf_rdata_word = buf_rdata[95:64];
                proc_replace_data = {buf_rdata[127:96], proc_wdata, buf_rdata[63:0]};
            end
            2'd3: begin
                proc_block_word = proc_block_data[127:96];
                proc_new_data = {proc_wdata, proc_block_data[95:0]};
                buf_rdata_word = buf_rdata[127:96];
                proc_replace_data = {proc_wdata, buf_rdata[95:0]};
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
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                        state_next = state;
                        buf_read = 1'b0;
                        buf_write = 1'b0;
                    end
                    else if (proc_block_dirty) begin
                        // * read miss, valid, dirty
                        // > read from memory, and write to memory
                        if (~buf_stall) begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            buf_wdata_w = proc_block_data;
                            proc_stall_w = 1'b1;
                            state_next = S_READ_WRITE;

                            for (i=0; i<8; i=i+1) block_next[i] = block[i];
                            proc_rdata_w = proc_rdata_r;
                            buf_addr_w = proc_addr[29:2];
                            buf_write_request_w = buf_write_request_r;
                        end
                        else begin
                            for (i=0; i<8; i=i+1) block_next[i] = block[i];
                            proc_stall_w = 1'b1;
                            proc_rdata_w = proc_rdata_r;
                            buf_addr_w = proc_addr[29:2];
                            buf_wdata_w = buf_wdata_r;
                            buf_write_request_w = buf_write_request_r;
                            state_next = state;
                            buf_read = 1'b0;
                            buf_write = 1'b0;
                        end
                    end
                    else begin
                        // * read miss, valid, clean
                        // > read from memory
                        if (~buf_stall) begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            proc_stall_w = 1'b1;
                            state_next = S_MEM_READ;

                            for (i=0; i<8; i=i+1) block_next[i] = block[i];
                            proc_rdata_w = proc_rdata_r;
                            buf_addr_w = proc_addr[29:2];
                            buf_wdata_w = buf_wdata_r;
                            buf_write_request_w = buf_write_request_r;
                        end
                        else begin
                            for (i=0; i<8; i=i+1) block_next[i] = block[i];
                            proc_stall_w = 1'b1;
                            proc_rdata_w = proc_rdata_r;
                            buf_addr_w = proc_addr[29:2];
                            buf_wdata_w = buf_wdata_r;
                            buf_write_request_w = buf_write_request_r;
                            state_next = state;
                            buf_read = 1'b0;
                            buf_write = 1'b0;
                        end
                    end
                end
                else begin
                    // * read miss/hit, invalid, clean/dirty
                    // > read from memory
                    if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ;
                        
                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                    end
                    else begin
                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_stall_w = 1'b1;
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                        state_next = state;
                        buf_read = 1'b0;
                        buf_write = 1'b0;
                    end
                end
            end
            else if (proc_write) begin
                if (proc_block_valid & hit) begin
                    // * write hit, valid, clean/dirty
                    // > update the word in cache block
                    for (i=0; i<8; i=i+1) block_next[i] = block[i];
                    proc_rdata_w = proc_rdata_r;
                    buf_addr_w = proc_addr[29:2];
                    buf_wdata_w = buf_wdata_r;
                    buf_write_request_w = buf_write_request_r;
                    state_next = state;
                    buf_read = 1'b0;
                    buf_write = 1'b0;

                    block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_new_data};
                    proc_stall_w = 1'b0;
                end
                else if (proc_block_valid & proc_block_dirty) begin
                    // * write miss, valid, dirty
                    // > read from memory, then replace the word in block, write cache block to memory
                    if (~buf_stall) begin
                        buf_wdata_w = proc_block_data;
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_write_request_w = 1'b1;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;

                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                    end
                    else begin
                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_stall_w = 1'b1;
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                        state_next = state;
                        buf_read = 1'b0;
                        buf_write = 1'b0;
                    end
                end
                else begin
                    // * write miss, valid, clean
                    // * write miss, invalid, clean/dirty
                    // > read from memory, then replace the word in block
                    if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;

                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                    end
                    else begin
                        for (i=0; i<8; i=i+1) block_next[i] = block[i];
                        proc_stall_w = 1'b1;
                        proc_rdata_w = proc_rdata_r;
                        buf_addr_w = proc_addr[29:2];
                        buf_wdata_w = buf_wdata_r;
                        buf_write_request_w = buf_write_request_r;
                        state_next = state;
                        buf_read = 1'b0;
                        buf_write = 1'b0;
                    end
                end
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                buf_addr_w = proc_addr[29:2];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;
                state_next = state;
                buf_read = 1'b0;
                buf_write = 1'b0;
            end
        end
        S_MEM_READ: begin
            if (~buf_stall) begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                buf_addr_w = proc_addr[29:2];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;

                buf_read = 1'b0;
                buf_write = 1'b0;
                proc_rdata_w = buf_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, buf_rdata};
                state_next = S_IDLE;
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                buf_addr_w = proc_addr[29:2];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;
                state_next = state;
                buf_read = 1'b0;
                buf_write = 1'b0;
            end
        end
        S_MEM_READ_REPLACE: begin
            if (~buf_stall) begin
                if (~buf_write_request_r) begin
                    for (i=0; i<8; i=i+1) block_next[i] = block[i];
                    proc_rdata_w = proc_rdata_r;
                    buf_addr_w = proc_addr[29:2];
                    buf_wdata_w = buf_wdata_r;
                    buf_write_request_w = buf_write_request_r;
                    proc_stall_w = 1'b0;
                    block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_replace_data};
                    state_next = S_IDLE;

                    buf_read = 1'b0;
                    buf_write = 1'b0;
                end
                else begin
                    for (i=0; i<8; i=i+1) block_next[i] = block[i];
                    proc_rdata_w = proc_rdata_r;
                    buf_wdata_w = buf_wdata_r;
                    proc_stall_w = 1'b0;
                    block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_replace_data};
                    state_next = S_IDLE;

                    buf_write = 1'b1;
                    buf_read = 1'b0;
                    buf_addr_w = {proc_block_tag, proc_index};
                    buf_write_request_w = 1'b0;
                end
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                buf_addr_w = proc_addr[29:2];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;
                state_next = state;
                buf_read = 1'b0;
                buf_write = 1'b0;
            end
        end
        S_READ_WRITE: begin
            if (~buf_stall) begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;

                buf_read = 1'b0;
                buf_write = 1'b1;
                buf_addr_w = {proc_block_tag, proc_index};
                proc_rdata_w = buf_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, buf_rdata};
                state_next = S_IDLE;
            end
            else begin
                for (i=0; i<8; i=i+1) block_next[i] = block[i];
                proc_stall_w = proc_stall_r;
                proc_rdata_w = proc_rdata_r;
                buf_addr_w = proc_addr[29:2];
                buf_wdata_w = buf_wdata_r;
                buf_write_request_w = buf_write_request_r;
                state_next = state;
                buf_read = 1'b0;
                buf_write = 1'b0;
            end
        end
        default: begin
            for (i=0; i<8; i=i+1) block_next[i] = block[i];
            proc_stall_w = proc_stall_r;
            proc_rdata_w = proc_rdata_r;
            buf_addr_w = proc_addr[29:2];
            buf_wdata_w = buf_wdata_r;
            buf_write_request_w = buf_write_request_r;
            state_next = state;
            buf_read = 1'b0;
            buf_write = 1'b0;
        end
        endcase
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            for (i=0; i<8; i=i+1) block[i] <= 155'b0;
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            buf_addr_r <= 28'b0;
            buf_wdata_r <= 128'b0;
            buf_write_request_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            for (i=0; i<8; i=i+1) block[i] <= block_next[i];
            proc_stall_r <= proc_stall_w;
            proc_rdata_r <= proc_rdata_w;
            buf_addr_r <= buf_addr_w;
            buf_wdata_r <= buf_wdata_w;
            buf_write_request_r <= buf_write_request_w;
            state <= state_next;
        end
    end
endmodule


module buffer(
    clk,
    rst,
    buf_addr,
    buf_read,
    buf_write,
    buf_rdata,
    buf_wdata,
    buf_stall,
    mem_addr,
    mem_read,
    mem_write,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    input          clk;
    input          rst;
    input   [27:0] buf_addr;
    input          buf_read;
    input          buf_write;
    output [127:0] buf_rdata;
    input  [127:0] buf_wdata;
    output         buf_stall;
    output  [27:0] mem_addr;
    output         mem_read;
    output         mem_write;
    input  [127:0] mem_rdata;
    output [127:0] mem_wdata;
    input          mem_ready;

//==== states =============================================
    reg  [2:0] state, state_next;
    parameter S_IDLE = 3'd0;
    parameter S_WRITE = 3'd1;
    parameter S_READ = 3'd2;

//==== wire/reg definition ================================
    reg  [127:0] buf_rdata_r, buf_rdata_w;
    reg          buf_stall_r, buf_stall_w;
    reg   [27:0] mem_addr_r, mem_addr_w;
    reg          mem_read_r, mem_read_w;
    reg          mem_write_r, mem_write_w;
    reg  [127:0] mem_wdata_r, mem_wdata_w;

//==== combinational circuit ==============================
    assign buf_stall = buf_stall_r;
    assign buf_rdata = buf_rdata_r;
    assign mem_addr = mem_addr_r;
    assign mem_read = mem_read_r;
    assign mem_write = mem_write_r;
    assign mem_wdata = mem_wdata_r;

    always @ (*) begin
        case (state)
        S_IDLE: begin
            if (buf_write) begin
                buf_stall_w = 1'b1;
                mem_write_w = 1'b1;
                mem_addr_w = buf_addr;
                mem_wdata_w = buf_wdata;
                state_next = S_WRITE;

                buf_rdata_w = buf_rdata_r;
                mem_read_w = mem_read_r;
            end
            else if (buf_read) begin
                buf_stall_w = 1'b1;
                mem_read_w = 1'b1;
                mem_addr_w = buf_addr;
                state_next = S_READ;

                buf_rdata_w = buf_rdata_r;
                mem_write_w = mem_write_r;
                mem_wdata_w = mem_wdata_r;
            end
            else begin
                buf_rdata_w = buf_rdata_r;
                buf_stall_w = buf_stall_r;
                mem_addr_w = mem_addr_r;
                mem_read_w = mem_read_r;
                mem_write_w = mem_write_r;
                mem_wdata_w = mem_wdata_r;
                state_next = state;
            end
        end
        S_WRITE: begin
            if (mem_ready) begin
                buf_stall_w = 1'b0;
                mem_write_w = 1'b0;
                state_next = S_IDLE;

                buf_rdata_w = buf_rdata_r;
                mem_addr_w = mem_addr_r;
                mem_read_w = mem_read_r;
                mem_wdata_w = mem_wdata_r;
            end
            else begin
                buf_rdata_w = buf_rdata_r;
                buf_stall_w = buf_stall_r;
                mem_addr_w = mem_addr_r;
                mem_read_w = mem_read_r;
                mem_write_w = mem_write_r;
                mem_wdata_w = mem_wdata_r;
                state_next = state;
            end
        end
        S_READ: begin
            if (mem_ready) begin
                buf_stall_w = 1'b0;
                buf_rdata_w = mem_rdata;
                mem_read_w = 1'b0;
                state_next = S_IDLE;

                mem_addr_w = mem_addr_r;
                mem_write_w = mem_write_r;
                mem_wdata_w = mem_wdata_r;
            end
            else begin
                buf_rdata_w = buf_rdata_r;
                buf_stall_w = buf_stall_r;
                mem_addr_w = mem_addr_r;
                mem_read_w = mem_read_r;
                mem_write_w = mem_write_r;
                mem_wdata_w = mem_wdata_r;
                state_next = state;
            end
        end
        default: begin
            buf_rdata_w = buf_rdata_r;
            buf_stall_w = buf_stall_r;
            mem_addr_w = mem_addr_r;
            mem_read_w = mem_read_r;
            mem_write_w = mem_write_r;
            mem_wdata_w = mem_wdata_r;
            state_next = state;
        end
        endcase
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            buf_rdata_r <= 128'b0;
            buf_stall_r <= 1'b0;
            mem_addr_r <= 28'b0;
            mem_read_r <= 1'b0;
            mem_write_r <= 1'b0;
            mem_wdata_r <= 128'b0;
            state <= S_IDLE;
        end
        else begin
            buf_rdata_r <= buf_rdata_w;
            buf_stall_r <= buf_stall_w;
            mem_addr_r <= mem_addr_w;
            mem_read_r <= mem_read_w;
            mem_write_r <= mem_write_w;
            mem_wdata_r <= mem_wdata_w;
            state <= state_next;
        end
    end
endmodule
