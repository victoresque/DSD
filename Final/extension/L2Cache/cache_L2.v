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
    reg   [31:0] L2_rdata_word;

    wire         proc_stall;
    reg          proc_stall_r, proc_stall_w;
    wire  [31:0] proc_rdata;
    reg   [31:0] proc_rdata_r, proc_rdata_w;

    wire         L2_read;
    reg          L2_read_r, L2_read_w;
    wire         L2_write;
    reg          L2_write_r, L2_write_w;
    reg          L2_write_request_r, L2_write_request_w;
    wire  [27:0] L2_addr;
    reg   [27:0] L2_addr_r, L2_addr_w;
    wire [127:0] L2_wdata;
    reg  [127:0] L2_wdata_r, L2_wdata_w;

    reg          hit;
    wire [127:0] L2_rdata;
    wire         L2_stall;

    integer i;

//==== instances ==========================================
    L2_cache L2_cache_inst(
        .clk(clk),
        .proc_reset(proc_reset),
        .proc_addr(L2_addr),
        .proc_read(L2_read),
        .proc_write(L2_write),
        .proc_rdata(L2_rdata),
        .proc_wdata(L2_wdata),
        .proc_stall(L2_stall),
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
    assign L2_read = L2_read_w;
    assign L2_write = L2_write_w;
    assign L2_addr = L2_addr_w;
    assign L2_wdata = L2_wdata_w;

    always @ (*) begin
        for (i=0; i<8; i=i+1) block_next[i] = block[i];

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
            2'd0: proc_block_word = proc_block_data[31:0];
            2'd1: proc_block_word = proc_block_data[63:32];
            2'd2: proc_block_word = proc_block_data[95:64];
            2'd3: proc_block_word = proc_block_data[127:96];
        endcase
        case (proc_offset)
            2'd0: proc_new_data = {proc_block_data[127:32], proc_wdata};
            2'd1: proc_new_data = {proc_block_data[127:64], proc_wdata, proc_block_data[31:0]};
            2'd2: proc_new_data = {proc_block_data[127:96], proc_wdata, proc_block_data[63:0]};
            2'd3: proc_new_data = {proc_wdata, proc_block_data[95:0]};
        endcase
        case (proc_offset)
            2'd0: L2_rdata_word = L2_rdata[31:0];
            2'd1: L2_rdata_word = L2_rdata[63:32];
            2'd2: L2_rdata_word = L2_rdata[95:64];
            2'd3: L2_rdata_word = L2_rdata[127:96];
        endcase
        case (proc_offset)
            2'd0: proc_replace_data = {L2_rdata[127:32], proc_wdata};
            2'd1: proc_replace_data = {L2_rdata[127:64], proc_wdata, L2_rdata[31:0]};
            2'd2: proc_replace_data = {L2_rdata[127:96], proc_wdata, L2_rdata[63:0]};
            2'd3: proc_replace_data = {proc_wdata, L2_rdata[95:0]};
        endcase

        proc_stall_w = proc_stall_r;
        proc_rdata_w = proc_rdata_r;
        L2_addr_w = L2_addr_r;
        L2_wdata_w = L2_wdata_r;
        L2_write_request_w = L2_write_request_r;
        state_next = state;

        L2_read_w = L2_read_r;
        L2_write_w = L2_write_r;

        if (state == S_IDLE) begin
            if (proc_read) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid) begin
                    if (hit) begin
                        // * read hit, valid, clean/dirty
                        // > read from cache
                        L2_read_w = 1'b0;
                        L2_write_w = 1'b0;
                        proc_rdata_w = proc_block_word;
                        proc_stall_w = 1'b0;
                    end
                    else if (proc_block_dirty) begin
                        // * read miss, valid, dirty
                        // > read from memory, and write to memory
                        if (~L2_stall) begin
                            L2_read_w = 1'b1;
                            L2_write_w = 1'b0;
                            L2_wdata_w = proc_block_data;
                            L2_addr_w = proc_addr[29:2];
                            proc_stall_w = 1'b1;
                            state_next = S_READ_WRITE;
                        end
                    end
                    else begin
                        // * read miss, valid, clean
                        // > read from memory
                        if (~L2_stall) begin
                            L2_read_w = 1'b1;
                            L2_write_w = 1'b0;
                            L2_addr_w = proc_addr[29:2];
                            proc_stall_w = 1'b1;
                            state_next = S_MEM_READ;
                        end
                    end
                end
                else begin
                    // * read miss/hit, invalid, clean/dirty
                    // > read from memory
                    if (~L2_stall) begin
                        L2_read_w = 1'b1;
                        L2_write_w = 1'b0;
                        L2_addr_w = proc_addr[29:2];
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ;
                    end
                end
            end
            else if (proc_write) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid & hit) begin
                    // * write hit, valid, clean/dirty
                    // > update the word in cache block
                    L2_read_w = 1'b0;
                    L2_write_w = 1'b0;
                    block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_new_data};
                    proc_stall_w = 1'b0;
                end
                else if (proc_block_valid & proc_block_dirty) begin
                    // * write miss, valid, dirty
                    // > read from memory, then replace the word in block, write cache block to memory
                    if (~L2_stall) begin
                        L2_wdata_w = proc_block_data;
                        L2_read_w = 1'b1;
                        L2_write_w = 1'b0;
                        L2_addr_w = proc_addr[29:2];
                        L2_write_request_w = 1'b1;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;
                    end
                end
                else begin
                    // * write miss, valid, clean
                    // * write miss, invalid, clean/dirty
                    // > read from memory, then replace the word in block
                    if (~L2_stall) begin
                        L2_read_w = 1'b1;
                        L2_write_w = 1'b0;
                        L2_addr_w = proc_addr[29:2];
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;
                    end
                end
            end
        end
        else if (state == S_MEM_READ) begin
            if (~L2_stall) begin
                L2_read_w = 1'b0;
                L2_write_w = 1'b0;
                proc_rdata_w = L2_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, L2_rdata};
                state_next = S_IDLE;
            end
        end
        else if (state == S_MEM_READ_REPLACE) begin
            if (~L2_stall) begin
                if (~L2_write_request_r) begin
                    L2_read_w = 1'b0;
                    L2_write_w = 1'b0;
                end
                else begin
                    L2_write_w = 1'b1;
                    L2_read_w = 1'b0;
                    L2_addr_w = {proc_block_tag, proc_index};
                    L2_write_request_w = 1'b0;
                end
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_replace_data};
                state_next = S_IDLE;
            end
        end
        else if (state == S_READ_WRITE) begin
            if (~L2_stall) begin
                L2_read_w = 1'b0;
                L2_write_w = 1'b1;
                L2_addr_w = {proc_block_tag, proc_index};
                proc_rdata_w = L2_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, L2_rdata};
                state_next = S_IDLE;
            end
        end
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            for (i=0; i<8; i=i+1) block[i] <= 155'b0;
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            L2_read_r <= 1'b0;
            L2_write_r <= 1'b0;
            L2_addr_r <= 28'b0;
            L2_wdata_r <= 128'b0;
            L2_write_request_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            for (i=0; i<8; i=i+1) block[i] <= block_next[i];
            proc_stall_r <= proc_stall_w;
            proc_rdata_r <= proc_rdata_w;
            L2_read_r <= L2_read_w;
            L2_write_r <= L2_write_w;
            L2_addr_r <= L2_addr_w;
            L2_wdata_r <= L2_wdata_w;
            L2_write_request_r <= L2_write_request_w;
            state <= state_next;
        end
    end

endmodule


module L2_cache(
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
    input   [27:0] proc_addr;
    input  [127:0] proc_wdata;
    output         proc_stall;
    output [127:0] proc_rdata;
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
    parameter N_BLOCKS = 64;
    parameter INDEX_WIDTH = 6; // log(N_BLOCKS)
    parameter TAG_WIDTH = 28 - INDEX_WIDTH;
    parameter BLOCK_SIZE = 1 + 1 + TAG_WIDTH + 128;
    // proc_addr: 28b
    // tag: 22b, index: 6b
    // block: valid(1b) + dirty(1b) + tag(22b) + data(128b) = 152b
    reg  [BLOCK_SIZE-1:0] block [0:N_BLOCKS-1];
    reg  [BLOCK_SIZE-1:0] block_next [0:N_BLOCKS-1];
    reg   [TAG_WIDTH-1:0] proc_tag;
    reg    [INDEX_WIDTH-1:0] proc_index;

    reg  [BLOCK_SIZE-1:0] proc_block;
    reg          proc_block_valid;
    reg          proc_block_dirty;
    reg   [TAG_WIDTH-1:0] proc_block_tag;
    reg  [127:0] proc_block_data;

    reg  [127:0] proc_new_data;
    reg  [127:0] proc_replace_data;

    wire         proc_stall;
    reg          proc_stall_r, proc_stall_w;
    wire [127:0] proc_rdata;
    reg  [127:0] proc_rdata_r, proc_rdata_w;

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
    assign proc_stall = proc_stall_r;
    assign proc_rdata = proc_rdata_r;
    assign buf_addr = buf_addr_w;
    assign buf_wdata = buf_wdata_w;

    always @ (*) begin
        for (i=0; i<N_BLOCKS; i=i+1) block_next[i] = block[i];

        proc_tag = proc_addr[27:INDEX_WIDTH];
        proc_index = proc_addr[INDEX_WIDTH-1:0];

        proc_block = block[proc_index];
        proc_block_valid = proc_block[BLOCK_SIZE-1];
        proc_block_dirty = proc_block[BLOCK_SIZE-2];
        proc_block_tag = proc_block[BLOCK_SIZE-3:128];
        proc_block_data = proc_block[127:0];
        hit = proc_tag == proc_block_tag;

        proc_stall_w = proc_stall_r;
        proc_rdata_w = proc_rdata_r;
        buf_addr_w = buf_addr_r;
        buf_wdata_w = buf_wdata_r;
        buf_write_request_w = buf_write_request_r;
        state_next = state;

        buf_read = 1'b0;
        buf_write = 1'b0;

        if (state == S_IDLE) begin
            if (proc_read) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid) begin
                    if (hit) begin
                        // * read hit, valid, clean/dirty
                        // > read from cache
                        proc_rdata_w = proc_block_data;
                        proc_stall_w = 1'b0;
                    end
                    else if (proc_block_dirty) begin
                        // * read miss, valid, dirty
                        // > read from memory, and write to memory
                        if (~buf_stall) begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            buf_wdata_w = proc_block_data;
                            buf_addr_w = proc_addr;
                            proc_stall_w = 1'b1;
                            state_next = S_READ_WRITE;
                        end
                    end
                    else begin
                        // * read miss, valid, clean
                        // > read from memory
                        if (~buf_stall) begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            buf_addr_w = proc_addr;
                            proc_stall_w = 1'b1;
                            state_next = S_MEM_READ;
                        end
                    end
                end
                else begin
                    // * read miss/hit, invalid, clean/dirty
                    // > read from memory
                    if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_addr_w = proc_addr;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ;
                    end
                end
            end
            else if (proc_write) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid & hit) begin
                    // * write hit, valid, clean/dirty
                    // > update the word in cache block
                    block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_wdata};
                    proc_stall_w = 1'b0;
                end
                else if (proc_block_valid & proc_block_dirty) begin
                    // * write miss, valid, dirty
                    // > read from memory, then replace the word in block, write cache block to memory
                    if (~buf_stall) begin
                        buf_wdata_w = proc_block_data;
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_addr_w = proc_addr;
                        buf_write_request_w = 1'b1;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;
                    end
                end
                else begin
                    // * write miss, valid, clean
                    // * write miss, invalid, clean/dirty
                    // > read from memory, then replace the word in block
                    if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_addr_w = proc_addr;
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;
                    end
                end
            end
        end
        else if (state == S_MEM_READ) begin
            if (~buf_stall) begin
                buf_read = 1'b0;
                buf_write = 1'b0;
                proc_rdata_w = buf_rdata;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, buf_rdata};
                state_next = S_IDLE;
            end
        end
        else if (state == S_MEM_READ_REPLACE) begin
            if (~buf_stall) begin
                if (~buf_write_request_r) begin
                    buf_read = 1'b0;
                    buf_write = 1'b0;
                end
                else begin
                    buf_write = 1'b1;
                    buf_read = 1'b0;
                    buf_addr_w = {proc_block_tag, proc_index};
                    buf_write_request_w = 1'b0;
                end
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b1, proc_tag, proc_wdata};
                state_next = S_IDLE;
            end
        end
        else if (state == S_READ_WRITE) begin
            if (~buf_stall) begin
                buf_read = 1'b0;
                buf_write = 1'b1;
                buf_addr_w = {proc_block_tag, proc_index};
                proc_rdata_w = buf_rdata;
                proc_stall_w = 1'b0;
                block_next[proc_index] = {1'b1, 1'b0, proc_tag, buf_rdata};
                state_next = S_IDLE;
            end
        end
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            for (i=0; i<N_BLOCKS; i=i+1) block[i] <= 256'b0;
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            buf_addr_r <= 28'b0;
            buf_wdata_r <= 128'b0;
            buf_write_request_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            for (i=0; i<N_BLOCKS; i=i+1) block[i] <= block_next[i];
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
    assign mem_addr = mem_addr_w;
    assign mem_read = mem_read_w;
    assign mem_write = mem_write_w;
    assign mem_wdata = mem_wdata_w;

    always @ (*) begin
        buf_rdata_w = buf_rdata_r;
        buf_stall_w = buf_stall_r;
        mem_addr_w = mem_addr_r;
        mem_read_w = mem_read_r;
        mem_write_w = mem_write_r;
        mem_wdata_w = mem_wdata_r;
        state_next = state;

        if (state == S_IDLE) begin
            if (buf_write) begin
                buf_stall_w = 1'b1;
                mem_write_w = 1'b1;
                mem_addr_w = buf_addr;
                mem_wdata_w = buf_wdata;
                state_next = S_WRITE;
            end
            else if (buf_read) begin
                buf_stall_w = 1'b1;
                mem_read_w = 1'b1;
                mem_addr_w = buf_addr;
                state_next = S_READ;
            end
        end
        else if (state == S_WRITE) begin
            if (mem_ready) begin
                buf_stall_w = 1'b0;
                mem_write_w = 1'b0;
                state_next = S_IDLE;
            end
        end
        else if (state == S_READ) begin
            if (mem_ready) begin
                buf_stall_w = 1'b0;
                buf_rdata_w = mem_rdata;
                mem_read_w = 1'b0;
                state_next = S_IDLE;
            end
        end
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
