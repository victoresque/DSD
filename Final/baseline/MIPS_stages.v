module MIPS_IF (
    clk,
    rst_n,
    stall,
    BranchOrJump,
    branch_jump_addr,
    I_read,
    I_write,
    I_addr,
    I_stall,
    I_rdata,
    I_wdata,
    IF_stall,
    ID_pc,
    ID_inst
);
    input         clk;
    input         rst_n;
    input         stall;
    input         BranchOrJump;
    input  [31:0] branch_jump_addr;
    output        I_read;
    output        I_write;
    output [29:0] I_addr;
    input         I_stall;
    input  [31:0] I_rdata;
    output [31:0] I_wdata;
    output        IF_stall;
    output [31:0] ID_pc;
    output [31:0] ID_inst;

    reg  [31:0] pc, pc_next;
    wire [31:0] pc_4;
    reg  [31:0] ID_inst, ID_inst_next;
    reg  [31:0] branch_jump_addr_r, branch_jump_addr_w;

    reg         state, state_next;
    parameter S_NORMAL = 1'd0;
    parameter S_BJ_I_STALL = 1'd1;

    assign I_addr = pc[31:2];
    assign I_write = 1'b0;
    assign I_wdata = 32'b0;
    assign IF_stall = I_stall;
    assign ID_pc = pc;
    assign I_read = 1'b1;
    assign pc_4 = pc + 4;

    always @ (*) begin
        case(state) 
        S_NORMAL: begin
            case ({BranchOrJump, stall, I_stall})
                3'b000: begin
                    // normal
                    pc_next = pc_4;
                    ID_inst_next = I_rdata;
                    branch_jump_addr_w = branch_jump_addr_r;
                    state_next = state;
                end
                3'b001: begin
                    // I-cache stall, insert bubble, wait for I_stall==1'b0
                    pc_next = pc;
                    ID_inst_next = 32'b0;
                    branch_jump_addr_w = branch_jump_addr_r;
                    state_next = state;
                end
                3'b010: begin
                    // D-cache stall, remain same
                    pc_next = pc;
                    ID_inst_next = ID_inst;
                    branch_jump_addr_w = branch_jump_addr_r;
                    state_next = state;
                end
                3'b011: begin
                    // I-cache and D-cache stall, remain same
                    pc_next = pc;
                    ID_inst_next = ID_inst;
                    branch_jump_addr_w = branch_jump_addr_r;
                    state_next = state;
                end
                3'b100: begin
                    // Branch/Jump, no stall, insert bubble
                    pc_next = branch_jump_addr;
                    ID_inst_next = 32'b0;
                    branch_jump_addr_w = branch_jump_addr_r;
                    state_next = state;
                end
                3'b101: begin
                    // Branch/Jump, I-cache stall, wait for I_stall==1'b0, then branch_jump_addr -> pc
                    pc_next = pc;
                    branch_jump_addr_w = branch_jump_addr;
                    ID_inst_next = 32'b0;
                    state_next = S_BJ_I_STALL;
                end
                3'b110: begin
                    // Branch/Jump, D-cache stall, wait for D_stall==1'b0, then branch_jump_addr -> pc
                    pc_next = pc;
                    branch_jump_addr_w = branch_jump_addr;
                    ID_inst_next = ID_inst;
                    state_next = state;
                end
                3'b111: begin
                    // Branch/Jump, I-cache and D-cache stall, wait for both==1'b0, then branch_jump_addr -> pc
                    pc_next = pc;
                    branch_jump_addr_w = branch_jump_addr;
                    ID_inst_next = ID_inst;
                    state_next = state;
                end
            endcase
        end
        default: begin
            if (I_stall) begin
                pc_next = pc;
                ID_inst_next = 32'b0;
                branch_jump_addr_w = branch_jump_addr_r;
                state_next = S_BJ_I_STALL;
            end
            else begin
                pc_next = branch_jump_addr_r;
                ID_inst_next = 32'b0;
                branch_jump_addr_w = branch_jump_addr_r;
                state_next = S_NORMAL;
            end
        end
        endcase
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pc <= 32'b0;
            ID_inst <= 32'b0;
            branch_jump_addr_r <= 32'b0;
            state <= S_NORMAL;
        end
        else begin
            pc <= pc_next;
            ID_inst <= ID_inst_next;
            branch_jump_addr_r <= branch_jump_addr_w;
            state <= state_next;
        end
    end
endmodule


module MIPS_ID (
    clk,
    rst_n,
    ctrl,
    stall,
    bubble,
    pc,
    inst,
    IF_BranchOrJump,
    IF_branch_jump_addr,
    ForwardX,
    ForwardY,
    ForwardData_EX,
    ForwardData_MEM,
    ForwardData_WB,
    EX_ctrl,
    EX_busX,
    EX_busY,
    EX_inst,
    RegWrite,
    RW,
    busW
);
    input         clk;
    input         rst_n;
    input  [15:0] ctrl;
    input         stall;
    input         bubble;
    input  [31:0] pc;
    input  [31:0] inst;
    output        IF_BranchOrJump;
    output [31:0] IF_branch_jump_addr;
    input   [1:0] ForwardX;
    input   [1:0] ForwardY;
    input  [31:0] ForwardData_EX;
    input  [31:0] ForwardData_MEM;
    input  [31:0] ForwardData_WB;
    output [12:0] EX_ctrl;
    output [31:0] EX_busX;
    output [31:0] EX_busY;
    output [31:0] EX_inst;
    input         RegWrite;
    input   [4:0] RW;
    input  [31:0] busW;

    wire  [5:0] opcode;
    wire  [4:0] rs;
    wire  [4:0] rt;
    wire  [4:0] rd;
    wire [25:0] addr;
    wire [31:0] sign_ext;
    wire [31:0] busX;
    wire [31:0] busY;
    wire        reg_equal;
    reg  [12:0] EX_ctrl, EX_ctrl_next;
    reg  [31:0] EX_busX, EX_busX_next;
    reg  [31:0] EX_busY, EX_busY_next;
    reg  [31:0] EX_inst, EX_inst_next;
    reg  [31:0] ForwardDataX, ForwardDataY;
    wire [31:0] branch_addr;
    wire [31:0] jump_addr;
    wire        Jump, JumpReg, Branch, LinkRA, LinkRD;
    wire        Link;

    assign Jump = ctrl[15];
    assign JumpReg = ctrl[14];
    assign Branch = ctrl[13];
    assign LinkRA = ctrl[6];
    assign LinkRD = ctrl[5];
    assign Link = LinkRA | LinkRD;

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign addr = inst[25:0];
    assign sign_ext = {{16{inst[15]}}, inst[15:0]};
    assign reg_equal = ForwardDataX==ForwardDataY;
    assign branch_addr = pc + (sign_ext << 2);
    assign jump_addr = JumpReg ? (ForwardDataX << 2) : (addr << 2);
    assign IF_BranchOrJump = Jump | (Branch & reg_equal);
    assign IF_branch_jump_addr = (Branch & reg_equal) ? branch_addr : jump_addr;

    register_file rf_inst (
        .Clk(clk),
        .rst_n(rst_n),
        .WEN(RegWrite),
        .RW(RW),
        .busW(busW),
        .RX(rs),
        .RY(rt),
        .busX(busX),
        .busY(busY)
    );

    always @ (*) begin
        case (ForwardX)
            2'b00: ForwardDataX = busX;
            2'b01: ForwardDataX = ForwardData_EX;
            2'b10: ForwardDataX = ForwardData_MEM;
            2'b11: ForwardDataX = ForwardData_WB;
        endcase
        case (ForwardY)
            2'b00: ForwardDataY = busY;
            2'b01: ForwardDataY = ForwardData_EX;
            2'b10: ForwardDataY = ForwardData_MEM;
            2'b11: ForwardDataY = ForwardData_WB;
        endcase
    end
    
    always @ (*) begin
        if (~stall) begin
            EX_busX_next = Link ? pc >> 2 : ForwardDataX;
            EX_busY_next = Link ? 32'b0 : ForwardDataY;
            EX_ctrl_next = ctrl[12:0];
            EX_inst_next = inst;
        end
        else begin
            EX_busX_next = EX_busX;
            EX_busY_next = EX_busY;
            EX_inst_next = EX_inst;
            EX_ctrl_next = bubble ? 13'b0 : EX_ctrl;
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            EX_busX <= 32'b0;
            EX_busY <= 32'b0;
            EX_ctrl <= 13'b0;
            EX_inst <= 32'b0;
        end
        else begin
            EX_busX <= EX_busX_next;
            EX_busY <= EX_busY_next;
            EX_ctrl <= EX_ctrl_next;
            EX_inst <= EX_inst_next;
        end
    end
endmodule


module MIPS_EX (
    clk,
    rst_n,
    ctrl,
    stall,
    busX,
    busY,
    inst,
    MEM_ctrl,
    MEM_alu_out,
    MEM_wdata,
    MEM_RW,
    ForwardRW,
    ForwardData
);
    input         clk;
    input         rst_n;
    input  [12:0] ctrl;
    input         stall;
    input  [31:0] busX;
    input  [31:0] busY;
    input  [31:0] inst;
    output  [3:0] MEM_ctrl;
    output [31:0] MEM_alu_out;
    output [31:0] MEM_wdata;
    output  [4:0] MEM_RW;
    output  [4:0] ForwardRW;
    output [31:0] ForwardData;

    wire [31:0] alu_A;
    wire [31:0] alu_B;
    wire [31:0] alu_out;
    wire  [5:0] funct;
    wire [31:0] shamt;
    wire [31:0] sign_ext;
    wire  [4:0] RW;
    reg   [3:0] MEM_ctrl, MEM_ctrl_next;
    reg  [31:0] MEM_alu_out, MEM_alu_out_next;
    reg  [31:0] MEM_wdata, MEM_wdata_next;
    reg   [4:0] MEM_RW, MEM_RW_next;
    wire  [3:0] ALUOp;
    wire        ALUSrcAShamt, ALUSrcBImm, RegDstRD, LinkRA, LinkRD;

    assign ALUOp = ctrl[12:9];
    assign ALUSrcAShamt = ctrl[8];
    assign ALUSrcBImm = ctrl[7];
    assign RegDstRD = ctrl[4];
    assign LinkRA = ctrl[6];
    assign LinkRD = ctrl[5];

    assign funct = inst[5:0];
    assign shamt = {27'b0, inst[10:6]};
    assign sign_ext = {{16{inst[15]}}, inst[15:0]};
    assign alu_A = ALUSrcAShamt ? shamt : busX;
    assign alu_B = ALUSrcBImm ? sign_ext : busY;
    assign RW = (RegDstRD | LinkRD) ? inst[15:11] : LinkRA ? 5'd31 : inst[20:16];

    assign ForwardRW = RW;
    assign ForwardData = alu_out;

    ALU ALU_inst (
        .op(ALUOp),
        .A(alu_A),
        .B(alu_B),
        .out(alu_out)
    );

    always @ (*) begin
        if (~stall) begin
            MEM_ctrl_next = ctrl[3:0];
            MEM_alu_out_next = alu_out;
            MEM_wdata_next = busY;
            MEM_RW_next = RW;
        end
        else begin
            MEM_ctrl_next = MEM_ctrl;
            MEM_alu_out_next = MEM_alu_out;
            MEM_wdata_next = MEM_wdata;
            MEM_RW_next = MEM_RW;
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            MEM_ctrl <= 4'b0;
            MEM_alu_out <= 32'b0;
            MEM_wdata <= 32'b0;
            MEM_RW <= 5'b0;
        end
        else begin
            MEM_ctrl <= MEM_ctrl_next;
            MEM_alu_out <= MEM_alu_out_next;
            MEM_wdata <= MEM_wdata_next;
            MEM_RW <= MEM_RW_next;
        end
    end
endmodule


module MIPS_MEM (
    clk,
    rst_n,
    ctrl,
    stall,
    alu_out,
    wdata,
    RW,
    D_read,
    D_write,
    D_addr,
    D_wdata,
    D_stall,
    D_rdata,
    MEM_stall,
    WB_ctrl,
    WB_mem_data,
    WB_reg_data,
    WB_RW,
    ForwardData
);
    input         clk;
    input         rst_n;
    input   [3:0] ctrl;
    input         stall;
    input  [31:0] alu_out;
    input  [31:0] wdata;
    input   [4:0] RW;
    output        D_read;
    output        D_write;
    output [29:0] D_addr;
    output [31:0] D_wdata;
    input         D_stall;
    input  [31:0] D_rdata;
    output        MEM_stall;
    output  [1:0] WB_ctrl;
    output [31:0] WB_mem_data;
    output [31:0] WB_reg_data;
    output  [4:0] WB_RW;
    output [31:0] ForwardData;

    reg   [1:0] WB_ctrl, WB_ctrl_next;
    reg  [31:0] WB_mem_data, WB_mem_data_next;
    reg  [31:0] WB_reg_data, WB_reg_data_next;
    reg   [4:0] WB_RW, WB_RW_next;
    wire        MemToReg;
    wire        MemRead;
    wire        MemWrite;
    
    assign MemToReg = ctrl[1];
    assign MemRead = ctrl[2];
    assign MemWrite = ctrl[3];

    assign D_read = MemRead;
    assign D_write = MemWrite;
    assign D_addr = alu_out[31:2];
    assign D_wdata = wdata;
    assign ForwardData = MemToReg ? WB_mem_data_next : WB_reg_data_next;
    assign MEM_stall = D_stall & (MemRead | MemWrite);

    always @ (*) begin
        WB_reg_data_next = alu_out;
        WB_mem_data_next = D_rdata;
        WB_RW_next = RW;
        WB_ctrl_next = MEM_stall ? 2'b0 : ctrl[1:0];
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            WB_ctrl <= 2'b0;
            WB_mem_data <= 32'b0;
            WB_reg_data <= 32'b0;
            WB_RW <= 32'b0;
        end
        else begin
            WB_ctrl <= WB_ctrl_next;
            WB_mem_data <= WB_mem_data_next;
            WB_reg_data <= WB_reg_data_next;
            WB_RW <= WB_RW_next;
        end
    end
endmodule


module MIPS_WB (
    clk,
    rst_n,
    ctrl,
    stall,
    mem_data,
    reg_data,
    RW,
    ID_RegWrite,
    ID_busW,
    ID_RW
);
    input         clk;
    input         rst_n;
    input   [1:0] ctrl;
    input         stall;
    input  [31:0] mem_data;
    input  [31:0] reg_data;
    input   [4:0] RW;
    output        ID_RegWrite;
    output [31:0] ID_busW;
    output  [4:0] ID_RW;
    
    wire        MemToReg;

    assign MemToReg = ctrl[1];
    assign ID_RegWrite = ctrl[0];
    assign ID_busW = MemToReg ? mem_data : reg_data;
    assign ID_RW = RW;
endmodule
