/*
    Module:         Cache
    Author:         Victor Huang
    Description:
        32 words (8 blocks x 4 words) cache
        Placement:              direct mapped 
        Write policy:           write back + write buffer
*/

module cache_dummy(
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
    parameter S_READ = 3'd1;
    parameter S_PREREAD = 3'd2;
    parameter S_WRITE = 3'd3;

//==== wire/reg definition ================================
    reg   [24:0] proc_tag;
    reg    [2:0] proc_index;
    reg    [1:0] proc_offset;

    reg  [127:0] proc_new_data;
    reg   [31:0] mem_rdata_word;

    wire         proc_stall;
    reg          proc_stall_r, proc_stall_w;
    wire  [31:0] proc_rdata;
    reg   [31:0] proc_rdata_r, proc_rdata_w;

    reg   [27:0] mem_addr_r, mem_addr_w;
    reg  [127:0] mem_wdata_r, mem_wdata_w;
    reg          mem_read_r, mem_read_w;
    reg          mem_write_r, mem_write_w;

    assign mem_addr = mem_addr_r;
    assign mem_wdata = mem_wdata_r;
    assign mem_read = mem_read_r;
    assign mem_write = mem_write_r;

//==== combinational circuit ==============================
    assign proc_stall = proc_stall_w;
    assign proc_rdata = proc_rdata_w;

    always @ (*) begin
        proc_tag = proc_addr[29:5];
        proc_index = proc_addr[4:2];
        proc_offset = proc_addr[1:0];

        case (proc_offset)
            2'd0: begin
                proc_new_data = {mem_rdata[127:32], proc_wdata};
                mem_rdata_word = mem_rdata[31:0];
            end
            2'd1: begin
                proc_new_data = {mem_rdata[127:64], proc_wdata, mem_rdata[31:0]};
                mem_rdata_word = mem_rdata[63:32];
            end
            2'd2: begin
                proc_new_data = {mem_rdata[127:96], proc_wdata, mem_rdata[63:0]};
                mem_rdata_word = mem_rdata[95:64];
            end
            2'd3: begin
                proc_new_data = {proc_wdata, mem_rdata[95:0]};
                mem_rdata_word = mem_rdata[127:96];
            end
        endcase
    end

    always @ (*) begin
        mem_read_w = mem_read_r;
        mem_write_w = mem_write_r;
        mem_addr_w = mem_addr_r;
        mem_wdata_w = mem_wdata_r;
        proc_rdata_w = proc_rdata_r;
        proc_stall_w = proc_stall_r;
        state_next = state;

        case (state)
        S_IDLE: begin
            if (proc_read) begin
                mem_read_w = 1'b1;
                mem_write_w = 1'b0;
                mem_addr_w = proc_addr[29:2];
                proc_stall_w = 1'b1;
                state_next = S_READ;
            end
            else if (proc_write) begin
                mem_read_w = 1'b1;
                mem_write_w = 1'b0;
                mem_addr_w = proc_addr[29:2];
                proc_stall_w = 1'b1;
                state_next = S_PREREAD;
            end
        end
        S_READ: begin
            if (mem_ready) begin
                mem_read_w = 1'b0;
                mem_write_w = 1'b0;
                proc_rdata_w = mem_rdata_word;
                proc_stall_w = 1'b0;
                state_next = S_IDLE;
            end
        end
        S_PREREAD: begin
            if (mem_ready) begin
                mem_read_w = 1'b0;
                mem_write_w = 1'b1;
                mem_wdata_w = proc_new_data;
                state_next = S_WRITE;
            end
        end
        S_WRITE: begin
            if (mem_ready) begin
                mem_read_w = 1'b0;
                mem_write_w = 1'b0;
                proc_stall_w = 1'b0;
                state_next = S_IDLE;
            end
        end
        endcase
    end

//==== sequential circuit =================================
    always @ (posedge clk or posedge proc_reset) begin
        if(proc_reset) begin
            proc_stall_r <= 1'b0;
            proc_rdata_r <= 32'b0;
            mem_addr_r <= 28'b0;
            mem_wdata_r <= 128'b0;
            mem_write_r <= 1'b0;
            mem_read_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            proc_stall_r <= proc_stall_w;
            proc_rdata_r <= proc_rdata_w;
            mem_addr_r <= mem_addr_w;
            mem_wdata_r <= mem_wdata_w;
            mem_write_r <= mem_write_w;
            mem_read_r <= mem_read_w;
            state <= state_next;
        end
    end
endmodule
