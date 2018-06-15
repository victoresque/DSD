# Pipelined MIPS Cheatsheet

## Required Instructions
    inst  op                           funct      description
-------------------------------------------------------------------------------------
  * ADD   0     rs   rt   rd    0      0x20       rs + rt  -> rd
  * ADDI  8     rs   rt   imm                     rs + imm -> rt
  * SUB   0     rs   rt   rd    0      0x22       rs - rt  -> rd
  * MULT  0     rs   rt                0x18       rs * rt -> {HI, LO}
  * DIV   0     rs   rt                0x1A       rs / rt -> {HI, LO} (HI: rs%rt, LO: rs//rt)
  * MFHI  0               rd           0x10       HI -> rd
  * MFLO  0               rd           0x12       LO -> rd
  * AND   0     rs   rt   rd    0      0x24       rs & rt  -> rd
  * ANDI  0xC   rs   rt   imm                     rs & imm -> rt
  * OR    0     rs   rt   rd    0      0x25       rs | rt  -> rd
  * ORI   0xD   rs   rt   imm                     rs | imm -> rt
  * XOR   0     rs   rt   rd    0      0x26       rs ^ rt  -> rd
  * XORI  0xE   rs   rt   imm                     rs ^ imm -> rt
  * NOR   0     rs   rt   rd    0      0x27       rs ~| rt -> rd
  * SLL   0     0    rt   rd    shamt  0          rt << shamt -> rd
  * SRA   0     0    rt   rd    shamt  3          rt >>> shamt -> rd
  * SRL   0     0    rt   rd    shamt  2          rt >> shamt -> rd
  * SLT   0     rs   rt   rd    0      0x2A       rs < rt -> rd
  * SLTI  0xA   rs   rt   imm                     rs < imm -> rt
  * BEQ   4     rs   rt   offs                    if rs==rt: pc + 4 + (offs << 2) -> pc
  * J     2     addr                              addr << 2 -> pc
  * JAL   3     addr                              addr << 2 -> pc; (pc + 4) >> 2 -> ra
  * JR    0     rs   0    0     0      8          rs << 2 -> pc
  * JALR  0     rs   0    rd    0      9          rs << 2 -> pc; (pc + 4) >> 2 -> rd
  * LW    0x23  rs   rt   offs                    mem[rs + offs] -> rt
  * SW    0x2B  rs   rt   offs                    rt -> mem[rs + offs]
  * NOP   0                                       (equivalent to 'SLL 0, 0, 0')
-------------------------------------------------------------------------------------
  - 'offs' is sign-extended


## MIPS Control Signals
-------------------------------------------------------------------------------------
  * MFHI          : MFHI
  * MFLO          : MFLO
  * Jump          : J, JR, JAL, JALR
  * JumpReg       : JR, JALR
  * Branch        : BEQ
  * ALUOp         : ADD: 0, SUB: 1, AND: 2, OR: 3, XOR: 4, 
                    NOR: 5, SLL: 6, SRL: 7, SRA: 8, SLT: 9, 
                    MULT: A, DIV: B
  * ALUSrcAShamt  : SLL, SRA, SRL
  * ALUSrcBImm    : ADDI, ANDI, ORI, XORI, SLTI, LW, SW
  * LinkRA        : JAL
  * LinkRD        : JALR
  * RegDstRD      : ADD, SUB, MFHI, MFLO, OR, XOR, NOR, SLL, SRA, SRL, SLT, JALR
  * MemWrite      : SW
  * MemRead       : LW
  * MemToReg      : LW
  * RegWrite      : All except BEQ, J, JR, SW, MULT, DIV
-------------------------------------------------------------------------------------


## Control Signals Table
-------------------------------------------------------------------------------------
  * ADD     0 0 0 0 0 0 0 0 0 0 1 0 0 0 1
  * ADDI    0 0 0 0 0 0 0 1 0 0 0 0 0 0 1
  * SUB     0 0 0 0 0 1 0 0 0 0 1 0 0 0 1
  * MULT    0 0 0 0 0 A 0 0 0 0 0 0 0 0 0
  * DIV     0 0 0 0 0 B 0 0 0 0 0 0 0 0 0
  * MFHI    1 0 0 0 0 0 0 0 0 0 1 0 0 0 1
  * MFLO    0 1 0 0 0 0 0 0 0 0 1 0 0 0 1
  * AND     0 0 0 0 0 2 0 0 0 0 1 0 0 0 1
  * ANDI    0 0 0 0 0 2 0 1 0 0 0 0 0 0 1
  * OR      0 0 0 0 0 3 0 0 0 0 1 0 0 0 1
  * ORI     0 0 0 0 0 3 0 1 0 0 0 0 0 0 1
  * XOR     0 0 0 0 0 4 0 0 0 0 1 0 0 0 1
  * XORI    0 0 0 0 0 4 0 1 0 0 0 0 0 0 1
  * NOR     0 0 0 0 0 5 0 0 0 0 1 0 0 0 1
  * SLL     0 0 0 0 0 6 1 0 0 0 1 0 0 0 1
  * SRA     0 0 0 0 0 8 1 0 0 0 1 0 0 0 1
  * SRL     0 0 0 0 0 7 1 0 0 0 1 0 0 0 1
  * SLT     0 0 0 0 0 9 0 0 0 0 1 0 0 0 1
  * SLTI    0 0 0 0 0 9 0 1 0 0 0 0 0 0 1
  * BEQ     0 0 0 0 1 0 0 0 0 0 0 0 0 0 0
  * J       0 0 1 0 0 0 0 0 0 0 0 0 0 0 0
  * JAL     0 0 1 0 0 0 0 0 1 0 0 0 0 0 1
  * JR      0 0 1 1 0 0 0 0 0 0 0 0 0 0 0
  * JALR    0 0 1 1 0 0 0 0 0 1 1 0 0 0 1
  * LW      0 0 0 0 0 0 0 1 0 0 0 0 1 1 1
  * SW      0 0 0 0 0 0 0 1 0 0 0 1 0 0 0
-------------------------------------------------------------------------------------

