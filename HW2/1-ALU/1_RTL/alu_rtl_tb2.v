`timescale 1ns/10ps
`define CYCLE   10
`define HCYCLE  5

module alu_rtl_tb;
    reg  [3:0] ctrl;
    reg  [7:0] x;
    reg  [7:0] y;
    wire       carry;
    wire [7:0] out;
    
    alu_rtl alu1(
        ctrl     ,
        x        ,
        y        ,
        carry    ,
        out  
    );

    initial begin
        $dumpfile("a.vcd");
        $dumpvars;
    end

    initial begin
        #(`CYCLE);

        ctrl = 4'b0000; // 0000 add
        x = 8'b11111111;
        y = 8'b00000001;
        #(`HCYCLE);
        if({carry, out} == 9'b100000000) $display("PASS: 0000 add");
        else $display(">>> FAIL: 0000 add <<<");

        ctrl = 4'b0001; // 0001 sub
        x = 8'b10101011; // 85
        y = 8'b10101100; // 86
        
        #(`HCYCLE);
        if({carry, out} == 9'b111111111) $display("PASS: 0001 sub");
        else $display(">>> FAIL: 0001 sub <<<");

        ctrl =  4'b0010; // 0010 and
        x = 8'b10101010;
        y = 8'b11001100;
        #(`HCYCLE);
        if(out == 8'b10001000 )$display("PASS: 0010 and");
        else $display(">>> FAIL: 0010 and<<<");

        ctrl =  4'b0011; // 0011 or
        x = 8'b10101010;
        y = 8'b11001100;
        #(`HCYCLE);
        if(out == 8'b11101110 )$display("PASS: 0011 or");
        else $display(">>> FAIL: 0011 or<<<");

        ctrl = 4'b0100; // 0100 not
        x = 8'b10101010;
        #(`HCYCLE);
        if(out == 8'b01010101 )$display("PASS: 0100 not" );
        else $display(">>> FAIL: 0100 not <<<");

        ctrl =  4'b0101; // 0101 xor
        x = 8'b10101010;
        y = 8'b11001100;
        #(`HCYCLE);
        if(out == 8'b01100110 )$display("PASS: 0101 xor");
        else $display(">>> FAIL: 0101 xor<<<");

        ctrl =  4'b0110; // 0110 nor
        x = 8'b10101010;
        y = 8'b11001100;
        #(`HCYCLE);
        if(out == 8'b00010001 )$display("PASS: 0110 nor");
        else $display(">>> FAIL: 0110 nor<<<");

        ctrl =  4'b0111; // 0111 shl
        x = 8'b00000011;
        y = 8'b11010010;
        #(`HCYCLE);
        if(out == 8'b10010000 )$display("PASS: 0111 shl");
        else $display(">>> FAIL: 0111 shl<<<");

        ctrl =  4'b1000; // 1000 shr
        x = 8'b00000010;
        y = 8'b11010010;
        #(`HCYCLE);
        if(out == 8'b00110100 )$display("PASS: 1000 shr");
        else $display(">>> FAIL: 1000 shr<<<");

        ctrl =  4'b1001; // 1001 shr (arithmetic)
        x = 8'b11010010;
        #(`HCYCLE);
        if(out == 8'b11101001 )$display("PASS: 1001 shr (arithmetic)");
        else $display(">>> FAIL: 1001 shr (arithmetic)<<<");

        ctrl =  4'b1010; // 1010 rotl
        x = 8'b11010010;
        #(`HCYCLE);
        if(out == 8'b10100101 )$display("PASS: 1010 rotl");
        else $display(">>> FAIL: 1010 rotl<<<");

        ctrl =  4'b1011; // 1011 rotr
        x = 8'b11010010;
        #(`HCYCLE);
        if(out == 8'b01101001 )$display("PASS: 1011 rotr");
        else $display(">>> FAIL: 1011 rotr<<<");

        ctrl =  4'b1100; // 1100 eql
        x = 8'b10110100;
        y = 8'b10110100;
        #(`HCYCLE);
        if(out == 8'b00000001 )$display("PASS: 1100 eql");
        else $display(">>> FAIL: 1100 eql<<<");

        ctrl =  4'b1100; // 1100 eql
        x = 8'b10110100;
        y = 8'b10111100;
        #(`HCYCLE);
        if(out == 8'b00000000 )$display("PASS: 1100 eql");
        else $display(">>> FAIL: 1100 eql<<<");

        // finish tb
        #(`CYCLE) $finish;
    end

endmodule
