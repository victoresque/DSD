module cache(
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
    // tag: 26b, index: 2b, word offset: 2b
    // block: valid(1b) + dirty(1b) + tag(26b) + data(32b*4) = 156b
    //        valid: [155], dirty: [154], tag: [153:128], data: [127:0]
    reg  [155:0] block [0:3][0:1];
    reg  [155:0] block_next [0:3][0:1];
    reg          set_index [0:3];
    reg          set_index_next [0:3];
    reg   [25:0] proc_tag;
    reg    [1:0] proc_index;
    reg    [1:0] proc_offset;

    reg  [155:0] proc_block, proc_block0, proc_block1;
    reg   [25:0] proc_tag0, proc_tag1;
    reg          proc_block_valid;
    reg          proc_block_dirty;
    reg   [25:0] proc_block_tag;
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
    wire         buf_request;
    reg          buf_request_r, buf_request_w;

    reg          hit0, hit1, hit;
    reg          set_id;
    reg          buf_rhit;
    wire  [27:0] buf_raddr;
    wire [127:0] buf_rdata;
    wire         buf_stall;
    wire         buf_rdone;
    wire         buf_ravail;

    integer i, j;

//==== instances ==========================================
    buffer buffer_inst(
        .clk(clk),
        .rst(proc_reset),
        .buf_addr(buf_addr),
        .buf_request(buf_request),
        .buf_ravail(buf_ravail),
        .buf_raddr(buf_raddr),
        .buf_read(buf_read),
        .buf_write(buf_write),
        .buf_rdata(buf_rdata),
        .buf_wdata(buf_wdata),
        .buf_stall(buf_stall),
        .buf_rdone(buf_rdone),
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
    assign buf_request = buf_request_r;

    always @ (*) begin
        for (i=0; i<4; i=i+1) for (j=0; j<2; j=j+1) block_next[i][j] = block[i][j];
        for (i=0; i<4; i=i+1) set_index_next[i] = set_index[i];

        proc_tag = proc_addr[29:4];
        proc_index = proc_addr[3:2];
        proc_offset = proc_addr[1:0];

        {proc_block0, proc_block1} = {block[proc_index][0], block[proc_index][1]};
        {proc_tag0, proc_tag1} = {proc_block0[153:128], proc_block1[153:128]};
        hit0 = proc_tag == proc_tag0;
        hit1 = proc_tag == proc_tag1;
        hit = hit0 | hit1;
        set_id = set_index[proc_index];

        proc_block = block[proc_index][hit ? hit1 : set_index[proc_index]];
        proc_block_valid = proc_block[155];
        proc_block_dirty = proc_block[154];
        proc_block_tag = proc_block[153:128];
        proc_block_data = proc_block[127:0];

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
            2'd0: buf_rdata_word = buf_rdata[31:0];
            2'd1: buf_rdata_word = buf_rdata[63:32];
            2'd2: buf_rdata_word = buf_rdata[95:64];
            2'd3: buf_rdata_word = buf_rdata[127:96];
        endcase
        case (proc_offset)
            2'd0: proc_replace_data = {buf_rdata[127:32], proc_wdata};
            2'd1: proc_replace_data = {buf_rdata[127:64], proc_wdata, buf_rdata[31:0]};
            2'd2: proc_replace_data = {buf_rdata[127:96], proc_wdata, buf_rdata[63:0]};
            2'd3: proc_replace_data = {proc_wdata, buf_rdata[95:0]};
        endcase

        proc_stall_w = proc_stall_r;
        proc_rdata_w = proc_rdata_r;
        buf_addr_w = buf_addr_r;
        buf_wdata_w = buf_wdata_r;
        buf_write_request_w = buf_write_request_r;
        buf_request_w = 1'b0;
        state_next = state;

        buf_read = 1'b0;
        buf_write = 1'b0;

        buf_rhit = buf_raddr == proc_addr[29:2];

        if (state == S_IDLE) begin
            if (proc_read) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid) begin
                    if (hit) begin
                        // * read hit, valid, clean/dirty
                        // > read from cache
                        proc_rdata_w = proc_block_word;
                        proc_stall_w = 1'b0;
                    end
                    else if (proc_block_dirty) begin
                        // * read miss, valid, dirty
                        // > read from memory, and write to memory
                        if (~buf_stall) begin
                            if (buf_rhit & buf_ravail) begin
                                buf_read = 1'b0;
                                buf_write = 1'b1;
                                proc_rdata_w = buf_rdata_word;
                                proc_stall_w = 1'b0;
                                buf_addr_w = {proc_block_tag, proc_index};
                                buf_wdata_w = proc_block_data;
                                block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, buf_rdata};
                                set_index_next[proc_index] = ~set_index[proc_index];
                            end
                            else begin
                                buf_read = 1'b1;
                                buf_write = 1'b0;
                                buf_wdata_w = proc_block_data;
                                buf_addr_w = proc_addr[29:2];
                                proc_stall_w = 1'b1;
                                state_next = S_READ_WRITE;
                            end
                        end
                        else begin
                            buf_request_w = 1'b1;
                        end
                    end
                    else begin
                        // * read miss, valid, clean
                        // > read from memory
                        if (buf_rhit & buf_ravail) begin
                            proc_rdata_w = buf_rdata_word;
                            block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, buf_rdata};
                            set_index_next[proc_index] = ~set_index[proc_index];
                            proc_stall_w = 1'b0;
                        end
                        else if (~buf_stall) begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            buf_addr_w = proc_addr[29:2];
                            proc_stall_w = 1'b1;
                            state_next = S_MEM_READ;
                        end
                        else begin
                            buf_request_w = 1'b1;
                        end
                    end
                end
                else begin
                    // * read miss/hit, invalid, clean/dirty
                    // > read from memory
                    if (buf_rhit & buf_ravail) begin
                        proc_rdata_w = buf_rdata_word;
                        block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, buf_rdata};
                        set_index_next[proc_index] = ~set_index[proc_index];
                        proc_stall_w = 1'b0;
                    end
                    else if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_addr_w = proc_addr[29:2];
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ;
                    end
                    else begin
                        buf_request_w = 1'b1;
                    end
                end
            end
            else if (proc_write) begin
                proc_stall_w = 1'b1;
                if (proc_block_valid & hit) begin
                    // * write hit, valid, clean/dirty
                    // > update the word in cache block
                    block_next[proc_index][hit1] = {1'b1, 1'b1, proc_tag, proc_new_data};
                    proc_stall_w = 1'b0;
                end
                else if (proc_block_valid & proc_block_dirty) begin
                    // * write miss, valid, dirty
                    // > read from memory, then replace the word in block, write cache block to memory
                    if (~buf_stall) begin
                        buf_wdata_w = proc_block_data;
                        if (buf_rhit & buf_ravail) begin
                            buf_read = 1'b0;
                            buf_write = 1'b1;
                            buf_addr_w = {proc_block_tag, proc_index};
                            block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, proc_replace_data};
                            set_index_next[proc_index] = ~set_index[proc_index];
                            proc_stall_w = 1'b0;
                        end
                        else begin
                            buf_read = 1'b1;
                            buf_write = 1'b0;
                            buf_addr_w = proc_addr[29:2];
                            buf_write_request_w = 1'b1;
                            proc_stall_w = 1'b1;
                            state_next = S_MEM_READ_REPLACE;
                        end
                    end
                    else begin
                        buf_request_w = 1'b1;
                    end
                end
                else begin
                    // * write miss, valid, clean
                    // * write miss, invalid, clean/dirty
                    // > read from memory, then replace the word in block
                    if (buf_rhit & buf_ravail) begin
                        proc_rdata_w = buf_rdata_word;
                        block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, proc_replace_data};
                        set_index_next[proc_index] = ~set_index[proc_index];
                        proc_stall_w = 1'b0;
                    end
                    else if (~buf_stall) begin
                        buf_read = 1'b1;
                        buf_write = 1'b0;
                        buf_addr_w = proc_addr[29:2];
                        proc_stall_w = 1'b1;
                        state_next = S_MEM_READ_REPLACE;
                    end
                    else begin
                        buf_request_w = 1'b1;
                    end
                end
            end
        end
        else if (state == S_MEM_READ) begin
            if (buf_rdone) begin
                buf_read = 1'b0;
                buf_write = 1'b0;
                proc_rdata_w = buf_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, buf_rdata};
                set_index_next[proc_index] = ~set_index[proc_index];
                state_next = S_IDLE;
            end
        end
        else if (state == S_MEM_READ_REPLACE) begin
            if (buf_rdone) begin
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
                block_next[proc_index][set_id] = {1'b1, 1'b1, proc_tag, proc_replace_data};
                set_index_next[proc_index] = ~set_index[proc_index];
                state_next = S_IDLE;
            end
        end
        else if (state == S_READ_WRITE) begin
            if (buf_rdone) begin
                buf_read = 1'b0;
                buf_write = 1'b1;
                buf_addr_w = {proc_block_tag, proc_index};
                proc_rdata_w = buf_rdata_word;
                proc_stall_w = 1'b0;
                block_next[proc_index][set_id] = {1'b1, 1'b0, proc_tag, buf_rdata};
                set_index_next[proc_index] = ~set_index[proc_index];
                state_next = S_IDLE;
            end
        end
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            for (i=0; i<4; i=i+1) for (j=0; j<2; j=j+1) block[i][j] <= 156'b0;
            for (i=0; i<4; i=i+1) set_index[i] <= 1'b0;
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            buf_addr_r <= 28'b0;
            buf_wdata_r <= 128'b0;
            buf_request_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            for (i=0; i<4; i=i+1) for (j=0; j<2; j=j+1) block[i][j] <= block_next[i][j];
            for (i=0; i<4; i=i+1) set_index[i] <= set_index_next[i];
            proc_stall_r <= proc_stall_w;
            proc_rdata_r <= proc_rdata_w;
            buf_addr_r <= buf_addr_w;
            buf_wdata_r <= buf_wdata_w;
            buf_request_r <= buf_request_w;
            state <= state_next;
        end
    end

endmodule


module buffer(
    clk,
    rst,
    buf_addr,
    buf_request,
    buf_ravail,
    buf_raddr,
    buf_read,
    buf_write,
    buf_rdata,
    buf_wdata,
    buf_stall,
    buf_rdone,
    mem_addr,
    mem_read,
    mem_write,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    input          clk;
    input          rst;
    input          buf_request;
    input   [27:0] buf_addr;
    output         buf_ravail;
    output  [27:0] buf_raddr;
    input          buf_read;
    input          buf_write;
    output [127:0] buf_rdata;
    input  [127:0] buf_wdata;
    output         buf_stall;
    output         buf_rdone;
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
    parameter S_PRELOAD = 3'd3;
    parameter S_PREPARE = 3'd7;

//==== wire/reg definition ================================
    reg    [2:0] cont_read_counter_r, cont_read_counter_w;
    reg   [27:0] prev_addr_r, prev_addr_w;

    reg          buf_ravail_r, buf_ravail_w;
    reg   [27:0] buf_raddr_r, buf_raddr_w;
    reg  [127:0] buf_rdata_r, buf_rdata_w;
    reg          buf_stall_r, buf_stall_w;
    reg          buf_rdone_r, buf_rdone_w;
    reg   [27:0] mem_addr_r, mem_addr_w;
    reg          mem_read_r, mem_read_w;
    reg          mem_write_r, mem_write_w;
    reg  [127:0] mem_wdata_r, mem_wdata_w;

//==== combinational circuit ==============================
    assign buf_stall = buf_stall_r;
    assign buf_ravail = buf_ravail_r;
    assign buf_rdone = buf_rdone_r;
    assign buf_raddr = buf_raddr_r;
    assign buf_rdata = buf_rdata_r;
    assign mem_addr = mem_ready & (state == S_PRELOAD) ? mem_addr_w - 1 : mem_addr_w;
    assign mem_read = mem_read_w;
    assign mem_write = mem_write_w;
    assign mem_wdata = mem_wdata_w;

    always @ (*) begin
        buf_ravail_w = buf_ravail_r;
        buf_raddr_w = buf_raddr_r;
        buf_rdata_w = buf_rdata_r;
        buf_stall_w = buf_stall_r;
        buf_rdone_w = 1'b0;
        mem_addr_w = mem_addr_r;
        mem_read_w = mem_read_r;
        mem_write_w = mem_write_r;
        mem_wdata_w = mem_wdata_r;
        cont_read_counter_w = cont_read_counter_r;
        prev_addr_w = prev_addr_r;
        state_next = state;

        if (state == S_IDLE) begin
            if (buf_write) begin
                buf_ravail_w = 1'b0;
                buf_stall_w = 1'b1;
                mem_write_w = 1'b1;
                mem_addr_w = buf_addr;
                mem_wdata_w = buf_wdata;
                cont_read_counter_w = 3'd0;
                state_next = S_WRITE;
            end
            else if (buf_read) begin
                buf_stall_w = 1'b1;
                mem_read_w = 1'b1;
                mem_addr_w = buf_addr;
                prev_addr_w = mem_addr_r;
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
                buf_rdone_w = 1'b1;
                buf_ravail_w = 1'b1;
                buf_raddr_w = mem_addr_r;
                buf_rdata_w = mem_rdata;
                mem_read_w = 1'b0;
                if (mem_addr_r == prev_addr_r + 1) begin
                    if (cont_read_counter_r == 3'd3) begin
                        mem_read_w = 1'b1;
                        buf_stall_w = 1'b1;
                        prev_addr_w = mem_addr_r;
                        mem_addr_w = mem_addr_r + 1;
                        state_next = S_PRELOAD;
                    end
                    else begin
                        cont_read_counter_w = cont_read_counter_r + 1;
                        state_next = S_IDLE;
                    end
                end
                else begin
                    cont_read_counter_w = 3'd0;
                    state_next = S_IDLE;
                end
            end
        end
        else if (state == S_PRELOAD) begin
            if (mem_ready) begin
                mem_addr_w = mem_addr_r + 1;
                if (buf_request) begin
                    buf_stall_w = 1'b0;
                    mem_read_w = 1'b0;
                    state_next = S_IDLE;
                end
                else begin
                    buf_stall_w = 1'b1;
                    mem_read_w = 1'b1;
                end
                buf_ravail_w = 1'b1;
                buf_raddr_w = mem_addr_r;
                buf_rdata_w = mem_rdata;
            end
        end
        else if (state == S_PREPARE) begin
            if (mem_ready) begin
                buf_stall_w = 1'b0;
                buf_rdone_w = 1'b1;
                buf_ravail_w = 1'b1;
                buf_raddr_w = mem_addr_r;
                buf_rdata_w = mem_rdata;
                mem_read_w = 1'b0;
                state_next = S_IDLE;
            end
        end
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            buf_ravail_r <= 1'b0;
            buf_raddr_r <= 28'b0;
            buf_rdata_r <= 128'b0;
            buf_stall_r <= 1'b1;
            buf_rdone_r <= 1'b0;
            mem_addr_r <= 28'b0;
            mem_read_r <= 1'b1;
            mem_write_r <= 1'b0;
            mem_wdata_r <= 128'b0;
            cont_read_counter_r <= 3'd0;
            prev_addr_r <= 28'b0;
            state <= S_PREPARE;
        end
        else begin
            buf_ravail_r <= buf_ravail_w;
            buf_raddr_r <= buf_raddr_w;
            buf_rdata_r <= buf_rdata_w;
            buf_stall_r <= buf_stall_w;
            buf_rdone_r <= buf_rdone_w;
            mem_addr_r <= mem_addr_w;
            mem_read_r <= mem_read_w;
            mem_write_r <= mem_write_w;
            mem_wdata_r <= mem_wdata_w;
            cont_read_counter_r <= cont_read_counter_w;
            prev_addr_r <= prev_addr_w;
            state <= state_next;
        end
    end
endmodule
