module control_unit (
    opcode,
    funct,
    Jump,
    JumpReg,
    Branch,
    ALUOp,
    ALUSrcAShamt,
    ALUSrcBImm,
    LinkRA,
    LinkRD,
    MFHI,
    MFLO,
    RegDstRD,
    MemWrite,
    MemRead,
    MemToReg,
    RegWrite
);
    input  [5:0] opcode;
    input  [5:0] funct;
    // IF
    // ID
    output       Jump;
    output       JumpReg;
    output       Branch;
    // EX
    output [3:0] ALUOp;
    output       ALUSrcAShamt;
    output       ALUSrcBImm;
    output       LinkRA;
    output       LinkRD;
    output       MFHI;
    output       MFLO;
    output       RegDstRD;
    // MEM
    output       MemWrite;
    output       MemRead;
    // WB
    output       MemToReg;
    output       RegWrite;

    reg  [31:0] ctrl;
    assign {    MFHI,
                MFLO,
                Jump,
                JumpReg,
                Branch,
                ALUOp,
                ALUSrcAShamt,
                ALUSrcBImm,
                LinkRA,
                LinkRD,
                RegDstRD,
                MemWrite,
                MemRead,
                MemToReg,
                RegWrite    } = ctrl;
    
    always @ (*) begin
        ctrl = 32'b0;
        if (opcode == 0) begin
            if (funct == 6'h20) begin // ADD 0 0 0 0 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h22) begin // SUB 0 0 0 1 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h24) begin // AND 0 0 0 2 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd2,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h25) begin // OR 0 0 0 3 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd3,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h26) begin // XOR 0 0 0 4 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd4,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h27) begin // NOR 0 0 0 5 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd5,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h0) begin // SLL 0 0 0 6 1 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd6,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h3) begin // SRA 0 0 0 8 1 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd8,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h2) begin // SRL 0 0 0 7 1 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd7,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h2A) begin // SLT 0 0 0 9 0 0 0 0 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd9,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h8) begin // JR 1 1 0 0 0 0 0 0 0 0 0 0 0
                ctrl = {1'b0,1'b0,1'b1,1'b1,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
            end
            else if (funct == 6'h9) begin // JALR 1 1 0 0 0 0 0 1 1 0 0 0 1
                ctrl = {1'b0,1'b0,1'b1,1'b1,1'b0,4'd0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h18) begin // MULT
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd10,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
            end
            else if (funct == 6'h1A) begin // DIV
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd11,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
            end
            else if (funct == 6'h10) begin // MFHI
                ctrl = {1'b1,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else if (funct == 6'h12) begin // MFLO
                ctrl = {1'b0,1'b1,1'b0,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1};
            end
            else begin // NOP
                ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
            end
        end
        else if (opcode == 6'h8) begin // ADDI 0 0 0 0 0 1 0 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'hC) begin // ANDI 0 0 0 2 0 1 0 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd2,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'hD) begin // ORI 0 0 0 3 0 1 0 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd3,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'hE) begin // XORI 0 0 0 4 0 1 0 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd4,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'hA) begin // SLTI 0 0 0 9 0 1 0 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd9,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'h4) begin // BEQ 0 0 1 0 0 0 0 0 0 0 0 0 0
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b1,4'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
        end
        else if (opcode == 6'h2) begin // J 1 0 0 0 0 0 0 0 0 0 0 0 0
            ctrl = {1'b0,1'b0,1'b1,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
        end
        else if (opcode == 6'h3) begin // JAL 1 0 0 0 0 0 1 0 0 0 0 0 1
            ctrl = {1'b0,1'b0,1'b1,1'b0,1'b0,4'd0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1};
        end
        else if (opcode == 6'h23) begin // LW 0 0 0 0 0 1 0 0 0 0 1 1 1
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1,1'b1};
        end
        else if (opcode == 6'h2B) begin // SW 0 0 0 0 0 1 0 0 0 1 0 0 0
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0};
        end
        else begin // NOP
            ctrl = {1'b0,1'b0,1'b0,1'b0,1'b0,4'd0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
        end
    end
endmodule
