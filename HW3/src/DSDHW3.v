//==== specification ======================================
// 1. Register file size:   32 x 32 bits
// 2. Program counter size:  1 x 32 bits
// 3. The functionality of 11 required instructions are 
//          the same as specified in MIPS instruction set

//==== design compiler synthesis script ===================
// read_verilog DSDHW3.v
// set cycle 4
// set iodelay 3
// create_clock -name CLK -period $cycle [get_ports clk]
// set_dont_touch_network      [get_clocks CLK]
// set_fix_hold                [get_clocks CLK]
// set_input_delay  -clock CLK -max $iodelay [get_ports ReadDataMem]
// set_output_delay -clock CLK -max $iodelay [get_ports CEN]
// set_output_delay -clock CLK -max $iodelay [get_ports WEN]
// set_output_delay -clock CLK -max $iodelay [get_ports OEN]
// set_output_delay -clock CLK -max 3.101 [get_ports A]
// set_output_delay -clock CLK -max $iodelay [get_ports ReadData2]
// set_input_delay  -clock CLK -max 0.1 [get_ports IR]
// set_operating_conditions -min_library fast -min fast -max_library slow -max slow
// set_max_area 0
// compile_ultra -gate_clock
// optimize_netlist -area
// optimize_netlist -area
// optimize_netlist -area
// compile_ultra -incremental
// optimize_netlist -area
// optimize_netlist -area
// optimize_netlist -area
// optimize_netlist -area
// optimize_netlist -area
// optimize_netlist -area
// write_sdf -version 2.1 DSDHW3.sdf
// write -format verilog -hier -output DSDHW3.vg
// write -format ddc     -hier -output DSDHW3.ddc


module SingleCycle_MIPS(
    clk,
    rst_n,
    IR_addr,
    IR,
    RF_writedata,
    ReadDataMem,
    CEN,
    WEN,
    A,
    ReadData2,
    OEN
);

//==== in/out declaration =================================
    input         clk, rst_n;
    input  [31:0] IR;
    output [31:0] IR_addr;
    output [31:0] RF_writedata;
    input  [31:0] ReadDataMem;  // read_data from memory
    output        CEN;          // chip_enable, 0 when you read/write data from/to memory
    output        WEN;          // write_enable, 0 when you write data into SRAM & 1 when you read
    output  [6:0] A;            // address
    output [31:0] ReadData2;    // write_data to memory
    output        OEN;          // output_enable, 0

//==== reg/wire declaration ===============================
    // control signals
    wire        RegDst;
    wire        RegWrite;
    wire        ALUSrc;
    wire        ALUOp;
    wire        MemWrite;
    wire        MemRead;
    wire        MemToReg;
    wire        Branch;
    wire        Jump;
    wire        PCSrc;
    wire        WriteRA;
    // wiring
    wire  [4:0] reg_w;
    wire [31:0] alu_y;
    wire        alu_zero;
    wire [31:0] reg_bus_w;
    wire [31:0] reg_bus_x;
    wire [31:0] reg_bus_y;
    wire [31:0] alu_out;
    wire [31:0] branch_addr;
    wire [31:0] jump_addr;
    wire [31:0] sign_extend;
    wire  [2:0] alu_ctrl;
    // alu
    wire  [5:0] opcode;
    wire  [5:0] funct;
    // bypass (additional adder for sw and lw)
    wire  [8:0] sl_bypass;
    // program counter
    wire [31:0] pc_w, pc_4;
    reg  [31:0] pc_r;
//==== instance declarations ==============================
    wire reg_WEN;
    register_file rf_inst(
        .Clk(clk),
        .rst_n(rst_n),
        .WEN(reg_WEN),
        .RW(reg_w),
        .busW(reg_bus_w),
        .RX(IR[25:21]),
        .RY(IR[20:16]),
        .busX(reg_bus_x),
        .busY(reg_bus_y)
    );
    alu alu_inst(
        .ctrl(alu_ctrl),
        .x(reg_bus_x),
        .y(alu_y),
        .out(alu_out),
        .zero(alu_zero)
    );
    alu_ctrl_unit alu_ctrl_unit_inst(
        .ALUOp(ALUOp),
        .funct(IR[5:0]),
        .alu_ctrl(alu_ctrl),
        .PCSrc(PCSrc)
    );
    ctrl_unit ctrl_unit_inst(
        .opcode(IR[31:26]),
        .RegDst(RegDst),
        .Jump(Jump),
        .Branch(Branch),
        .MemToReg(MemToReg),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .WriteRA(WriteRA)
    );

//==== combinational part =================================
    assign reg_WEN = RegWrite & ~PCSrc;
    assign reg_w = WriteRA ? 5'd31 : RegDst ? IR[15:11] : IR[20:16];
    assign reg_bus_w = WriteRA ? {2'b0, pc_4[31:2]} : ~MemToReg ? alu_out : ReadDataMem;

    assign CEN = ~(MemWrite | MemRead);
    assign WEN = ~MemWrite;
    assign OEN = 1'b0;
    assign A = sl_bypass[8:2];
    assign RF_writedata = reg_bus_w;
    assign ReadData2 = reg_bus_y;

    assign alu_y = reg_bus_y;
    assign IR_addr = pc_r;
    assign pc_4 = pc_r + 4;
    assign sign_extend = {{16{IR[15]}}, IR[15:0]};
    assign jump_addr = {pc_4[31:28], {IR[25:0], 2'b0}};
    assign sl_bypass = sign_extend[8:0] + reg_bus_x[8:0];
    assign pc_w = PCSrc ? {reg_bus_x[29:0], 2'b0} : Jump ? jump_addr : branch_addr;
    assign branch_addr = (Branch & alu_zero) ? pc_4 + {sign_extend[29:0], 2'b0} : pc_4;
//==== sequential part ====================================
    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) pc_r <= 32'b0;
        else        pc_r <= pc_w;
    end
endmodule

//==== Control ============================================
module ctrl_unit(
    opcode,
    RegDst,
    Jump,
    Branch,
    MemToReg,
    MemWrite,
    MemRead,
    ALUOp,
    ALUSrc,
    RegWrite,
    WriteRA
);
    input  [5:0] opcode;
    output       RegDst;
    output       Jump;
    output       Branch;
    output       MemToReg;
    output       MemWrite;
    output       MemRead;
    output       ALUOp;
    output       ALUSrc;
    output       RegWrite;
    output       WriteRA;

    reg       RegDst;
    reg       Jump;
    reg       Branch;
    reg       MemToReg;
    reg       MemWrite;
    reg       MemRead;
    reg       ALUOp;
    reg       ALUSrc;
    reg       RegWrite;
    reg       WriteRA;

    always @ (*) begin
        /*              ALUOp
            0   000000  1
            2   000010  0
            3   000011  0
            4   000100  3
            35  100011  2
            43  101011  2 */

        // add (0/32), sub (0/34), and (0/36), or (0/37), slt (0/42), jr (0/8)
        RegDst = ~(opcode[2] | opcode[1] | opcode[0]);
        // sw (43)
        MemWrite = opcode[5] & opcode[3];
        // lw (35)
        MemRead = opcode[5] & ~opcode[3];
        MemToReg = opcode[5] & ~opcode[3];
        // sw, lw
        ALUSrc = 1'b0; //opcode[5];
        // opcode == 0, 35, 3
        RegWrite = ~((opcode[3] ^ opcode[2]) | (opcode[1] ^ opcode[0]));
        // jal (3)
        WriteRA = opcode[1] & opcode[0] & ~opcode[5];
        // j (2), jal (3)
        Jump = ~opcode[5] & ~opcode[3] & ~opcode[2] & opcode[1];
        // beq (4)
        Branch = opcode[2];
        // ALUOp
        ALUOp = opcode[2] | opcode[1] | opcode[0];
    end
endmodule

module alu_ctrl_unit(
    ALUOp,
    funct,
    alu_ctrl,
    PCSrc
);
    input        ALUOp;
    input  [5:0] funct;
    output [2:0] alu_ctrl;
    output       PCSrc;

    reg  [2:0] alu_ctrl;
    reg        PCSrc;
    reg  [4:0] op;

    always @ (*) begin
        /*  add (0/32), sub (0/34), and (0/36), or (0/37), slt (0/42), jr (0/8)

            add 32  100000
            sub 34  100010
            and 36  100100
            or  37  100101
            slt 42  101010
            jr  8   001000 */

        op = {ALUOp, funct[3:0]};
        PCSrc = ~ALUOp & ~funct[5] & funct[3];
        case (op)
            5'b00000: alu_ctrl = 3'b000;
            5'b00010: alu_ctrl = 3'b001;
            5'b00100: alu_ctrl = 3'b010;
            5'b00101: alu_ctrl = 3'b110;
            5'b01010: alu_ctrl = 3'b101;
            default:  alu_ctrl = 3'b001;
        endcase
    end
endmodule

//==== ALU ================================================
module alu(
    ctrl,
    x,
    y,
    carry,
    out,
    zero
);
    input   [2:0] ctrl;
    input  [31:0] x;
    input  [31:0] y;
    output        carry;
    output [31:0] out;
    output        zero;

    wire [32:0] add;
    wire [32:0] sub;
    wire [31:0] _y;
    reg         carry;
    reg  [31:0] out;

    assign _y = 1 + ~y;
    assign add = x + (ctrl[0] ? _y : y);
    assign zero = ~|out;

    always @ (*) begin
        case (ctrl[2:1])
          2'b01: {carry, out} = {1'b0, x & y};
          2'b11: {carry, out} = {1'b0, x | y};
          2'b10: {carry, out} = {31'b0, add[31]};
          2'b00: {carry, out} = add;
        endcase
    end
endmodule

//==== Register file ======================================
module register_file(
    Clk  ,
    rst_n,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);
input         Clk, WEN, rst_n;
input   [4:0] RW, RX, RY;
input  [31:0] busW;
output [31:0] busX, busY;

reg  [31:0] busX, busY;

reg [31:0] r_r0, r_w0;
reg [31:0] r_r1, r_w1;
reg [31:0] r_r2, r_w2;
reg [31:0] r_r3, r_w3;
reg [31:0] r_r4, r_w4;
reg [31:0] r_r5, r_w5;
reg [31:0] r_r6, r_w6;
reg [31:0] r_r7, r_w7;
reg [31:0] r_r8, r_w8;
reg [31:0] r_r9, r_w9;
reg [31:0] r_r10, r_w10;
reg [31:0] r_r11, r_w11;
reg [31:0] r_r12, r_w12;
reg [31:0] r_r13, r_w13;
reg [31:0] r_r14, r_w14;
reg [31:0] r_r15, r_w15;
reg [31:0] r_r16, r_w16;
reg [31:0] r_r17, r_w17;
reg [31:0] r_r18, r_w18;
reg [31:0] r_r19, r_w19;
reg [31:0] r_r20, r_w20;
reg [31:0] r_r21, r_w21;
reg [31:0] r_r22, r_w22;
reg [31:0] r_r23, r_w23;
reg [31:0] r_r24, r_w24;
reg [31:0] r_r25, r_w25;
reg [31:0] r_r26, r_w26;
reg [31:0] r_r27, r_w27;
reg [31:0] r_r28, r_w28;
reg [31:0] r_r29, r_w29;
reg [31:0] r_r30, r_w30;
reg [31:0] r_r31, r_w31;

always @ (*) begin
    case (RX)
        5'd0: busX = r_r0;
        5'd1: busX = r_r1;
        5'd2: busX = r_r2;
        5'd3: busX = r_r3;
        5'd4: busX = r_r4;
        5'd5: busX = r_r5;
        5'd6: busX = r_r6;
        5'd7: busX = r_r7;
        5'd8: busX = r_r8;
        5'd9: busX = r_r9;
        5'd10: busX = r_r10;
        5'd11: busX = r_r11;
        5'd12: busX = r_r12;
        5'd13: busX = r_r13;
        5'd14: busX = r_r14;
        5'd15: busX = r_r15;
        5'd16: busX = r_r16;
        5'd17: busX = r_r17;
        5'd18: busX = r_r18;
        5'd19: busX = r_r19;
        5'd20: busX = r_r20;
        5'd21: busX = r_r21;
        5'd22: busX = r_r22;
        5'd23: busX = r_r23;
        5'd24: busX = r_r24;
        5'd25: busX = r_r25;
        5'd26: busX = r_r26;
        5'd27: busX = r_r27;
        5'd28: busX = r_r28;
        5'd29: busX = r_r29;
        5'd30: busX = r_r30;
        5'd31: busX = r_r31;
    endcase

    case (RY)
        5'd0: busY = r_r0;
        5'd1: busY = r_r1;
        5'd2: busY = r_r2;
        5'd3: busY = r_r3;
        5'd4: busY = r_r4;
        5'd5: busY = r_r5;
        5'd6: busY = r_r6;
        5'd7: busY = r_r7;
        5'd8: busY = r_r8;
        5'd9: busY = r_r9;
        5'd10: busY = r_r10;
        5'd11: busY = r_r11;
        5'd12: busY = r_r12;
        5'd13: busY = r_r13;
        5'd14: busY = r_r14;
        5'd15: busY = r_r15;
        5'd16: busY = r_r16;
        5'd17: busY = r_r17;
        5'd18: busY = r_r18;
        5'd19: busY = r_r19;
        5'd20: busY = r_r20;
        5'd21: busY = r_r21;
        5'd22: busY = r_r22;
        5'd23: busY = r_r23;
        5'd24: busY = r_r24;
        5'd25: busY = r_r25;
        5'd26: busY = r_r26;
        5'd27: busY = r_r27;
        5'd28: busY = r_r28;
        5'd29: busY = r_r29;
        5'd30: busY = r_r30;
        5'd31: busY = r_r31;
    endcase

    r_w0 = 32'b0;
    r_w1 = r_r1;
    r_w2 = r_r2;
    r_w3 = r_r3;
    r_w4 = r_r4;
    r_w5 = r_r5;
    r_w6 = r_r6;
    r_w7 = r_r7;
    r_w8 = r_r8;
    r_w9 = r_r9;
    r_w10 = r_r10;
    r_w11 = r_r11;
    r_w12 = r_r12;
    r_w13 = r_r13;
    r_w14 = r_r14;
    r_w15 = r_r15;
    r_w16 = r_r16;
    r_w17 = r_r17;
    r_w18 = r_r18;
    r_w19 = r_r19;
    r_w20 = r_r20;
    r_w21 = r_r21;
    r_w22 = r_r22;
    r_w23 = r_r23;
    r_w24 = r_r24;
    r_w25 = r_r25;
    r_w26 = r_r26;
    r_w27 = r_r27;
    r_w28 = r_r28;
    r_w29 = r_r29;
    r_w30 = r_r30;
    r_w31 = r_r31;

    if (WEN) begin
        case (RW)
            5'd0: r_w0 = 32'b0;
            5'd1: r_w1 = busW;
            5'd2: r_w2 = busW;
            5'd3: r_w3 = busW;
            5'd4: r_w4 = busW;
            5'd5: r_w5 = busW;
            5'd6: r_w6 = busW;
            5'd7: r_w7 = busW;
            5'd8: r_w8 = busW;
            5'd9: r_w9 = busW;
            5'd10: r_w10 = busW;
            5'd11: r_w11 = busW;
            5'd12: r_w12 = busW;
            5'd13: r_w13 = busW;
            5'd14: r_w14 = busW;
            5'd15: r_w15 = busW;
            5'd16: r_w16 = busW;
            5'd17: r_w17 = busW;
            5'd18: r_w18 = busW;
            5'd19: r_w19 = busW;
            5'd20: r_w20 = busW;
            5'd21: r_w21 = busW;
            5'd22: r_w22 = busW;
            5'd23: r_w23 = busW;
            5'd24: r_w24 = busW;
            5'd25: r_w25 = busW;
            5'd26: r_w26 = busW;
            5'd27: r_w27 = busW;
            5'd28: r_w28 = busW;
            5'd29: r_w29 = busW;
            5'd30: r_w30 = busW;
            5'd31: r_w31 = busW;
        endcase
    end
end

always @ (posedge Clk) begin
    r_r0 <= r_w0;
    r_r1 <= r_w1;
    r_r2 <= r_w2;
    r_r3 <= r_w3;
    r_r4 <= r_w4;
    r_r5 <= r_w5;
    r_r6 <= r_w6;
    r_r7 <= r_w7;
    r_r8 <= r_w8;
    r_r9 <= r_w9;
    r_r10 <= r_w10;
    r_r11 <= r_w11;
    r_r12 <= r_w12;
    r_r13 <= r_w13;
    r_r14 <= r_w14;
    r_r15 <= r_w15;
    r_r16 <= r_w16;
    r_r17 <= r_w17;
    r_r18 <= r_w18;
    r_r19 <= r_w19;
    r_r20 <= r_w20;
    r_r21 <= r_w21;
    r_r22 <= r_w22;
    r_r23 <= r_w23;
    r_r24 <= r_w24;
    r_r25 <= r_w25;
    r_r26 <= r_w26;
    r_r27 <= r_w27;
    r_r28 <= r_w28;
    r_r29 <= r_w29;
    r_r30 <= r_w30;
    r_r31 <= r_w31;
end
endmodule
