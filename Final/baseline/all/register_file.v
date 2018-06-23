/*
    Module:         Register File
    Author:         Victor Huang
    Description:
        32 x 32b register file for MIPS
*/

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

        if (WEN) begin
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
        else begin
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
        end
    end

    always @ (posedge Clk or negedge rst_n) begin
        if (~rst_n) begin
            r_r0 <= 32'b0;
            r_r1 <= 32'b0;
            r_r2 <= 32'b0;
            r_r3 <= 32'b0;
            r_r4 <= 32'b0;
            r_r5 <= 32'b0;
            r_r6 <= 32'b0;
            r_r7 <= 32'b0;
            r_r8 <= 32'b0;
            r_r9 <= 32'b0;
            r_r10 <= 32'b0;
            r_r11 <= 32'b0;
            r_r12 <= 32'b0;
            r_r13 <= 32'b0;
            r_r14 <= 32'b0;
            r_r15 <= 32'b0;
            r_r16 <= 32'b0;
            r_r17 <= 32'b0;
            r_r18 <= 32'b0;
            r_r19 <= 32'b0;
            r_r20 <= 32'b0;
            r_r21 <= 32'b0;
            r_r22 <= 32'b0;
            r_r23 <= 32'b0;
            r_r24 <= 32'b0;
            r_r25 <= 32'b0;
            r_r26 <= 32'b0;
            r_r27 <= 32'b0;
            r_r28 <= 32'b0;
            r_r29 <= 32'b0;
            r_r30 <= 32'b0;
            r_r31 <= 32'b0;
        end
        else begin
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
    end
endmodule
