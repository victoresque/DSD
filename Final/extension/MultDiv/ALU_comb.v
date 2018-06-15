/*
    Module:         ALU
    Author:         Victor Huang
    Description:
        An arithmetic logic unit that supports:
            1.  Addition
            2.  Subtraction
            3.  AND
            4.  OR
            5.  XOR
            6.  NOR
            7.  SLL
            8.  SRL
            9.  SRA
            10. SLT
*/

module ALU(
    clk,
    rst_n,
    op,
    A,
    B,
    HI,
    LO,
    out,
    stall
);
    input         clk;
    input         rst_n;
    input   [3:0] op;
    input  [31:0] A;
    input  [31:0] B;
    output [31:0] HI;
    output [31:0] LO;
    output [31:0] out;
    output        stall;

    reg  [31:0] out;
    wire [31:0] add_sub;
    wire [31:0] B_neg;
    wire  [4:0] shamt;
    reg signed [31:0] rem;
    reg signed [31:0] HI, HI_next; 
    reg signed [31:0] LO, LO_next;

    assign B_neg = 1 + ~B;
    assign add_sub = A + ((op==4'b0) ? B : B_neg);
    assign shamt = A[4:0];

    assign stall = 1'b0;

    always @ (*) begin
        case (op)
            4'h0: out = add_sub;              // ADD
            4'h1: out = add_sub;              // SUB
            4'h2: out = A & B;                // AND
            4'h3: out = A | B;                // OR
            4'h4: out = A ^ B;                // XOR
            4'h5: out = ~(A | B);             // NOR
            4'h6: out = B << shamt;           // SLL
            4'h7: out = B >> shamt;           // SRL
            4'h8: out = $signed(B) >>> shamt; // SRA 
            4'h9: out = {31'b0, add_sub[31]}; // SLT
            default: out = 32'b0;
        endcase

        rem = $signed(A)/$signed(B);
        case (op)
            4'hA: {HI_next, LO_next} = $signed(A) * $signed(B);
            4'hB: {HI_next, LO_next} = {$signed(A) % $signed(B), rem[31] ? (B[31] ? rem - B : rem + B) : rem};
            default: {HI_next, LO_next} = {HI, LO};
        endcase
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            HI <= 32'b0;
            LO <= 32'b0;
        end
        else begin
            HI <= HI_next;
            LO <= LO_next;
        end
    end
endmodule