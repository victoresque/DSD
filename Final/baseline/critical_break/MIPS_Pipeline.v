/*
    Module:         Pipelined MIPS
    Author:         Victor Huang
    Description:
        Pipelined MIPS
*/

module MIPS_Pipeline (
    clk,
    rst_n,
    I_read,
    I_write,
    I_addr,
    I_wdata,
    I_stall,
    I_rdata,
    D_read,
    D_write,
    D_addr,
    D_wdata,
    D_stall,
    D_rdata
);
    input         clk;
    input         rst_n;
    output        I_read;
    output        I_write;
    output [29:0] I_addr;
    output [31:0] I_wdata;
    input         I_stall;
    input  [31:0] I_rdata;
    output        D_read;
    output        D_write;
    output [29:0] D_addr;
    output [31:0] D_wdata;
    input         D_stall;
    input  [31:0] D_rdata;

//======== reg/wire ===========================================
    wire        IF_BranchOrJump;
    wire [31:0] IF_branch_jump_addr;
    wire [15:0] ID_ctrl;
    wire [31:0] ID_pc;
    wire [31:0] ID_inst;
    wire        ID_RegWrite;
    wire  [4:0] ID_RW;
    wire [31:0] ID_busW;
    wire [12:0] EX_ctrl;
    wire [31:0] EX_busX;
    wire [31:0] EX_busY;
    wire [31:0] EX_inst;
    wire  [3:0] MEM_ctrl;
    wire [31:0] MEM_alu_out;
    wire [31:0] MEM_wdata;
    wire  [4:0] MEM_RW;
    wire  [1:0] WB_ctrl;
    wire [31:0] WB_mem_data;
    wire [31:0] WB_reg_data;
    wire  [4:0] WB_RW;
    wire  [1:0] ForwardX;
    wire  [1:0] ForwardY;
    wire [31:0] ForwardData_EX, FD_EX;
    wire [31:0] ForwardData_MEM, FD_MEM;
    wire [31:0] ForwardData_WB, FD_WB;
    wire  [4:0] ForwardRW_EX;
    wire        stall_icache;
    wire        stall_dcache;
    wire        stall_load_word;
    wire        stall_forward;
    wire        stall_IF;
    wire        stall_ID;
    wire        stall_EX;
    wire        stall_MEM;
    wire        stall_WB;
    wire        bubble_ID;

//======== Assignments ========================================

//======== Instances ==========================================
    control_unit control_unit_inst (
        .opcode(ID_inst[31:26]),
        .funct(ID_inst[5:0]),
        .Jump(ID_ctrl[15]),
        .JumpReg(ID_ctrl[14]),
        .Branch(ID_ctrl[13]),
        .ALUOp(ID_ctrl[12:9]),
        .ALUSrcAShamt(ID_ctrl[8]),
        .ALUSrcBImm(ID_ctrl[7]),
        .LinkRA(ID_ctrl[6]),
        .LinkRD(ID_ctrl[5]),
        .RegDstRD(ID_ctrl[4]),
        .MemWrite(ID_ctrl[3]),
        .MemRead(ID_ctrl[2]),
        .MemToReg(ID_ctrl[1]),
        .RegWrite(ID_ctrl[0])
    );
    forwarding_unit forwarding_unit_inst (
        .clk(clk),
        .rst_n(rst_n),
        .EX_RegWrite(EX_ctrl[0]),
        .EX_RW(ForwardRW_EX),
        .MEM_RegWrite(MEM_ctrl[0]),
        .MEM_RW(MEM_RW),
        .WB_RegWrite(WB_ctrl[0]),
        .WB_RW(WB_RW),
        .ID_RX(ID_inst[25:21]),
        .ID_RY(ID_inst[20:16]),
        .ForwardX(ForwardX),
        .ForwardY(ForwardY),
        .ForwardData_EX(ForwardData_EX),
        .ForwardData_MEM(ForwardData_MEM),
        .ForwardData_WB(ID_busW),
        .FD_EX(FD_EX),
        .FD_MEM(FD_MEM),
        .FD_WB(FD_WB),
        .stall_dcache(stall_dcache),
        .stall_load_word(stall_load_word),
        .stall_forward(stall_forward)
    );
    hazard_unit hazard_unit_inst (
        .EX_MemRead(EX_ctrl[2]),
        .EX_RT(EX_inst[20:16]),
        .ID_RS(ID_inst[25:21]),
        .ID_RT(ID_inst[20:16]),
        .stall(stall_load_word)
    );
    stall_aggregator stall_aggregator_inst (
        .stall_dcache(stall_dcache),
        .stall_icache(stall_icache),
        .stall_load_word(stall_load_word),
        .stall_forward(stall_forward),
        .stall_IF(stall_IF),
        .stall_ID(stall_ID),
        .bubble_ID(bubble_ID),
        .stall_EX(stall_EX),
        .stall_MEM(stall_MEM),
        .stall_WB(stall_WB)
    );
    MIPS_IF MIPS_IF_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_IF),
        .BranchOrJump(IF_BranchOrJump),
        .branch_jump_addr(IF_branch_jump_addr),
        .I_read(I_read),
        .I_write(I_write),
        .I_addr(I_addr),
        .I_stall(I_stall),
        .I_rdata(I_rdata),
        .I_wdata(I_wdata),
        .IF_stall(stall_icache),
        .ID_pc(ID_pc),
        .ID_inst(ID_inst)
    );
    MIPS_ID MIPS_ID_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ctrl(ID_ctrl),
        .stall(stall_ID),
        .bubble(bubble_ID),
        .pc(ID_pc),
        .inst(ID_inst),
        .IF_BranchOrJump(IF_BranchOrJump),
        .IF_branch_jump_addr(IF_branch_jump_addr),
        .ForwardX(ForwardX),
        .ForwardY(ForwardY),
        .ForwardData_EX(FD_EX),
        .ForwardData_MEM(FD_MEM),
        .ForwardData_WB(FD_WB),
        .EX_ctrl(EX_ctrl),
        .EX_busX(EX_busX),
        .EX_busY(EX_busY),
        .EX_inst(EX_inst),
        .RegWrite(ID_RegWrite),
        .RW(ID_RW),
        .busW(ID_busW)
    );
    MIPS_EX MIPS_EX_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ctrl(EX_ctrl),
        .stall(stall_EX),
        .busX(EX_busX),
        .busY(EX_busY),
        .inst(EX_inst),
        .MEM_ctrl(MEM_ctrl),
        .MEM_alu_out(MEM_alu_out),
        .MEM_wdata(MEM_wdata),
        .MEM_RW(MEM_RW),
        .ForwardRW(ForwardRW_EX),
        .ForwardData(ForwardData_EX)
    );
    MIPS_MEM MIPS_MEM_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ctrl(MEM_ctrl),
        .stall(stall_MEM), 
        .alu_out(MEM_alu_out),
        .wdata(MEM_wdata),
        .RW(MEM_RW),
        .D_read(D_read),
        .D_write(D_write),
        .D_addr(D_addr),
        .D_wdata(D_wdata),
        .D_stall(D_stall),
        .D_rdata(D_rdata),
        .MEM_stall(stall_dcache),
        .WB_ctrl(WB_ctrl),
        .WB_mem_data(WB_mem_data),
        .WB_reg_data(WB_reg_data),
        .WB_RW(WB_RW),
        .ForwardData(ForwardData_MEM)
    );
    MIPS_WB MIPS_WB_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ctrl(WB_ctrl),
        .stall(stall_WB),
        .mem_data(WB_mem_data),
        .reg_data(WB_reg_data),
        .RW(WB_RW),
        .ID_RegWrite(ID_RegWrite),
        .ID_busW(ID_busW),
        .ID_RW(ID_RW)
    );
endmodule


module forwarding_unit (
    clk,
    rst_n,
    EX_RegWrite,
    EX_RW,
    MEM_RegWrite,
    MEM_RW,
    WB_RegWrite,
    WB_RW,
    ID_RX,
    ID_RY,
    ForwardX,
    ForwardY,
    ForwardData_EX,
    ForwardData_MEM,
    ForwardData_WB,
    FD_EX,
    FD_MEM,
    FD_WB,
    stall_dcache,
    stall_load_word,
    stall_forward
);
    input         clk;
    input         rst_n;
    input         EX_RegWrite;
    input   [4:0] EX_RW;
    input         MEM_RegWrite;
    input   [4:0] MEM_RW;
    input         WB_RegWrite;
    input   [4:0] WB_RW;
    input   [4:0] ID_RX;
    input   [4:0] ID_RY;
    output  [1:0] ForwardX;
    output  [1:0] ForwardY;
    input  [31:0] ForwardData_EX, ForwardData_MEM, ForwardData_WB;
    output [31:0] FD_EX, FD_MEM, FD_WB;
    input         stall_dcache;
    input         stall_load_word;
    output        stall_forward;

    reg         state, state_next;
    parameter S_IDLE = 1'b0;
    parameter S_STALL = 1'b1;

    reg         Forward;
    wire        ForwardEX_X, ForwardMEM_X, ForwardWB_X;
    wire        ForwardEX_Y, ForwardMEM_Y, ForwardWB_Y;
    reg   [1:0] ForwardX, ForwardX_next; 
    reg   [1:0] ForwardY, ForwardY_next;
    reg  [31:0] FD_EX, FD_EX_next;
    reg  [31:0] FD_MEM, FD_MEM_next;
    reg  [31:0] FD_WB, FD_WB_next;
    reg         stall_forward_r, stall_forward_w;
    reg         stall_r, stall_w;

    assign ForwardEX_X = EX_RegWrite & (EX_RW!=0) & (EX_RW==ID_RX);
    assign ForwardEX_Y = EX_RegWrite & (EX_RW!=0) & (EX_RW==ID_RY);
    assign ForwardMEM_X = MEM_RegWrite & (MEM_RW!=0) & (MEM_RW==ID_RX);
    assign ForwardMEM_Y = MEM_RegWrite & (MEM_RW!=0) & (MEM_RW==ID_RY);
    assign ForwardWB_X = WB_RegWrite & (WB_RW!=0) & (WB_RW==ID_RX);
    assign ForwardWB_Y = WB_RegWrite & (WB_RW!=0) & (WB_RW==ID_RY);
    assign stall_forward = stall_forward_w | stall_r;

    always @ (*) begin
        Forward = ForwardEX_X|ForwardMEM_X|ForwardWB_X|ForwardEX_Y|ForwardMEM_Y|ForwardWB_Y;
        if (state == S_STALL) begin
            ForwardX_next = ForwardX;
            ForwardY_next = ForwardY;
        end
        else begin
            ForwardX_next = {ForwardMEM_X | ForwardWB_X, ForwardWB_X | ForwardEX_X};
            ForwardY_next = {ForwardMEM_Y | ForwardWB_Y, ForwardWB_Y | ForwardEX_Y};
        end
    end
    
    always @ (*) begin
        FD_EX_next = FD_EX;
        FD_MEM_next = FD_MEM;
        FD_WB_next = FD_WB;
        stall_forward_w = stall_forward_r;
        stall_w = stall_r;
        state_next = state;

        case (state)
        S_IDLE: begin
            if (Forward) begin
                FD_EX_next = ForwardData_EX;
                FD_MEM_next = ForwardData_MEM;
                FD_WB_next = ForwardData_WB;
                stall_forward_w = 1'b1;
                stall_w = 1'b1;
            end
            if (Forward & ~stall_load_word & ~stall_dcache) begin
                state_next = S_STALL;
            end
        end
        S_STALL: begin
            if (~stall_load_word & ~stall_dcache) begin
                stall_forward_w = 1'b0;
                stall_w = 1'b0;
                state_next = S_IDLE;
            end
        end
        endcase
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            ForwardX <= 2'b0;
            ForwardY <= 2'b0;
            FD_EX <= 32'b0;
            FD_MEM <= 32'b0;
            FD_WB <= 32'b0;
            stall_forward_r <= 1'b0;
            stall_r <= 1'b0;
            state <= S_IDLE;
        end
        else begin
            ForwardX <= ForwardX_next;
            ForwardY <= ForwardY_next;
            FD_EX <= FD_EX_next;
            FD_MEM <= FD_MEM_next;
            FD_WB <= FD_WB_next;
            stall_forward_r <= stall_forward_w;
            stall_r <= stall_w;
            state <= state_next;
        end
    end
endmodule


module hazard_unit (
    EX_MemRead,
    EX_RT,
    ID_RS,
    ID_RT,
    stall
);
    input        EX_MemRead;
    input  [4:0] EX_RT;
    input  [4:0] ID_RS;
    input  [4:0] ID_RT;
    output       stall;

    assign stall = EX_MemRead & ((EX_RT==ID_RS) | (EX_RT==ID_RT));
endmodule


module stall_aggregator (
    stall_dcache,
    stall_icache,
    stall_load_word,
    stall_forward,
    stall_IF,
    stall_ID,
    bubble_ID,
    stall_EX,
    stall_MEM,
    stall_WB
);
    input  stall_dcache;
    input  stall_icache;
    input  stall_load_word;
    input  stall_forward;
    output stall_IF;
    output stall_ID;
    output bubble_ID;
    output stall_EX;
    output stall_MEM;
    output stall_WB;

    reg  stall_IF;
    reg  stall_ID;
    reg  bubble_ID;
    reg  stall_EX;

    assign stall_MEM = 1'b0;
    assign stall_WB = 1'b0;

    always @ (*) begin
        if (stall_dcache) begin
            stall_IF = 1'b1;
            stall_ID = 1'b1;
            bubble_ID = 1'b0;
            stall_EX = 1'b1;
        end
        else if (stall_load_word | stall_forward) begin
            stall_IF = 1'b1;
            stall_ID = 1'b1;
            bubble_ID = 1'b1;
            stall_EX = 1'b0;
        end
        else begin
            stall_IF = 1'b0;
            stall_ID = 1'b0;
            bubble_ID = 1'b0;
            stall_EX = 1'b0;
        end
    end
endmodule
