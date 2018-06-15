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
    op,
    A,
    B,
    out
);
    input   [3:0] op;
    input  [31:0] A;
    input  [31:0] B;
    output [31:0] out;

    reg  [31:0] out;
    wire [31:0] add_sub;
    wire [31:0] B_neg;
    wire  [4:0] shamt;

    assign B_neg = 1 + ~B;
    assign add_sub = A + ((op==4'b0) ? B : B_neg);
    assign shamt = A[4:0];

    always @ (*) begin
        case (op)
          4'd0: out = add_sub;              // ADD
          4'd1: out = add_sub;              // SUB
          4'd2: out = A & B;                // AND
          4'd3: out = A | B;                // OR
          4'd4: out = A ^ B;                // XOR
          4'd5: out = ~(A | B);             // NOR
          4'd6: out = B << shamt;           // SLL
          4'd7: out = B >> shamt;           // SRL
          4'd8: out = $signed(B) >>> shamt; // SRA 
          4'd9: out = {31'b0, add_sub[31]}; // SLT
          default: out = 32'b0;
        endcase
    end
endmodule