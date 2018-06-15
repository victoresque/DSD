`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module simple_calculator_tb;
    // port declaration for design-under-test
    reg        Clk;
    reg        WEN;
    reg  [2:0] RW, RX, RY;
    reg  [7:0] DataIn;
    reg        Sel;
    reg  [3:0] Ctrl;
    wire [7:0] busY;
    wire       Carry;
 
    // instantiate the design-under-test
    simple_calculator u_calc(
        .Clk    (Clk),
        .WEN    (WEN),
        .RW     (RW),
        .RX     (RX),
        .RY     (RY),
        .DataIn (DataIn),
        .Sel    (Sel),
        .Ctrl   (Ctrl),
        .busY   (busY),
        .Carry  (Carry)
    );

    // waveform dump
    initial begin
        $dumpfile("a.vcd");
        $dumpvars;
    end
    
    // clock generation
    always#(`HCYCLE) Clk = ~Clk;
    
    // test pattern
    parameter A = {4'd0,4'd13};
    parameter B = {4'd0,4'd12};
    parameter maskB0 = {8{B[0]}};
    parameter maskB1 = {8{B[1]}};
    parameter maskB2 = {8{B[2]}};
    parameter maskB3 = {8{B[3]}};
    parameter sum0 = A*B[0];
    parameter sum1 = A*B[1:0];
    parameter sum2 = A*B[2:0];
    parameter C = A*B;
    
    // simulation
    integer err_count;
    initial begin
        // initialization
        Clk = 1'b1;
        err_count = 0;
        
        // 4-bit x 4-bit unsigned multiplication
        $display("4-bit x 4-bit unsigned multiplication" );
        
        #(`CYCLE*0.2)
        $display("1: store multiplicand A=%2d in REG#1", A );
        $display("    [REG#1 = add %b REG#0]", A );        
        WEN = 1'b1; RW = 3'd1; RX = 3'd0; RY = 3'd0;
        Ctrl = 4'b0000; Sel = 1'b0; DataIn = A;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd1; RX = 3'd0; RY = 3'd1;
        Ctrl = 4'b0011; Sel = 1'b0; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==A )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, A );
        end
        #(`HCYCLE)
        
        #(`CYCLE*0.2)
        $display("2: store multiplier B=%2d in REG#2", B );
        $display("    [REG#2 = add %b REG#0]", B ); 
        WEN = 1'b1; RW = 3'd2; RX = 3'd0; RY = 3'd0;
        Ctrl = 4'b0000; Sel = 1'b0; DataIn = B;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd1; RX = 3'd0; RY = 3'd2;
        Ctrl = 4'b0011; Sel = 1'b0; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==B )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, B );
        end
        #(`HCYCLE)        
        
        #(`CYCLE*0.2)
        $display("3: set REG#3 = (B[0]==1)? 8'b11111111: 8'b00000000" );
        $display("    [REG#3 = and 0000_0001 REG#2]" ); 
        WEN = 1'b1; RW = 3'd3; RX = 3'd0; RY = 3'd2;
        Ctrl = 4'b0010; Sel = 1'b0; DataIn = 8'd1;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#3 = sub REG#0 REG#3]" ); 
        WEN = 1'b1; RW = 3'd3; RX = 3'd0; RY = 3'd3;
        Ctrl = 4'b0001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd3; RX = 3'd0; RY = 3'd3;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==maskB0 )$display("    .... passed." );
        else begin
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, maskB0 );
        end
        #(`HCYCLE)         

        #(`CYCLE*0.2)
        $display("4: set REG#4 = (B[1]==1)? 8'b11111111: 8'b00000000" );
        $display("    [REG#2 = sra REG#2]" ); 
        WEN = 1'b1; RW = 3'd2; RX = 3'd2; RY = 3'd2;
        Ctrl = 4'b1001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#4 = and 0000_0001 REG#2]" ); 
        WEN = 1'b1; RW = 3'd4; RX = 3'd0; RY = 3'd2;
        Ctrl = 4'b0010; Sel = 1'b0; DataIn = 8'd1;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#4 = sub REG#0 REG#4]" ); 
        WEN = 1'b1; RW = 3'd4; RX = 3'd0; RY = 3'd4;
        Ctrl = 4'b0001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd4; RX = 3'd0; RY = 3'd4;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==maskB1 )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, maskB1 );
        end
        #(`HCYCLE)  

        #(`CYCLE*0.2)
        $display("5: set REG#5 = (B[2]==1)? 8'b11111111: 8'b00000000" );
        $display("    [REG#2 = sra REG#2]" ); 
        WEN = 1'b1; RW = 3'd2; RX = 3'd2; RY = 3'd2;
        Ctrl = 4'b1001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#5 = and 0000_0001 REG#2]" ); 
        WEN = 1'b1; RW = 3'd5; RX = 3'd0; RY = 3'd2;
        Ctrl = 4'b0010; Sel = 1'b0; DataIn = 8'd1;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#5 = sub REG#0 REG#5]" ); 
        WEN = 1'b1; RW = 3'd5; RX = 3'd0; RY = 3'd5;
        Ctrl = 4'b0001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd5; RX = 3'd0; RY = 3'd5;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==maskB2 )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, maskB2 );
        end
        #(`HCYCLE) 
    
        #(`CYCLE*0.2)
        $display("6: set REG#6 = (B[3]==1)? 8'b11111111: 8'b00000000" );
        $display("    [REG#2 = sra REG#2]" ); 
        WEN = 1'b1; RW = 3'd2; RX = 3'd2; RY = 3'd2;
        Ctrl = 4'b1001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#6 = and 0000_0001 REG#2]" ); 
        WEN = 1'b1; RW = 3'd6; RX = 3'd0; RY = 3'd2;
        Ctrl = 4'b0010; Sel = 1'b0; DataIn = 8'd1;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#6 = sub REG#0 REG#6]" ); 
        WEN = 1'b1; RW = 3'd6; RX = 3'd0; RY = 3'd6;
        Ctrl = 4'b0001; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd6; RX = 3'd0; RY = 3'd6;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==maskB3 )$display("    .... passed." );
        else begin
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, maskB3 );
        end
        #(`HCYCLE) 
        
        $display("7: shift & summation, REG#7 = A*B[0]" );
        #(`CYCLE*0.2)
        $display("    [REG#3 = and REG#1 REG#3]" ); 
        WEN = 1'b1; RW = 3'd3; RX = 3'd1; RY = 3'd3;
        Ctrl = 4'b0010; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#7 = add REG#0 REG#3]" ); 
        WEN = 1'b1; RW = 3'd7; RX = 3'd0; RY = 3'd3;
        Ctrl = 4'b0000; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd7; RX = 3'd0; RY = 3'd7;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==sum0 )$display("    .... passed." );
        else begin
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, sum0 );
        end
        #(`HCYCLE)
        
        $display("8: shift & summation, REG#7 = A*B[1:0]" );
        #(`CYCLE*0.2)
        $display("    [REG#4 = and REG#1 REG#4]" );
        WEN = 1'b1; RW = 3'd4; RX = 3'd1; RY = 3'd4;
        Ctrl = 4'b0010; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#4 = sll 0000_0001 REG#4]" );
        WEN = 1'b1; RW = 3'd4; RX = 3'd0; RY = 3'd4;
        Ctrl = 4'b0111; Sel = 1'b0; DataIn = 8'd1;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#7 = add REG#7 REG#4]" ); 
        WEN = 1'b1; RW = 3'd7; RX = 3'd7; RY = 3'd4;
        Ctrl = 4'b0000; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd7; RX = 3'd0; RY = 3'd7;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==sum1 )$display("    .... passed." );
        else begin     
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, sum1 );
        end
        #(`HCYCLE)
        
        $display("9: shift & summation, REG#7 = A*B[2:0]" );
        #(`CYCLE*0.2)
        $display("    [REG#5 = and REG#1 REG#5]" );
        WEN = 1'b1; RW = 3'd5; RX = 3'd1; RY = 3'd5;
        Ctrl = 4'b0010; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#5 = sll 0000_0010 REG#5]" );
        WEN = 1'b1; RW = 3'd5; RX = 3'd0; RY = 3'd5;
        Ctrl = 4'b0111; Sel = 1'b0; DataIn = 8'd2;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#7 = add REG#7 REG#5]" ); 
        WEN = 1'b1; RW = 3'd7; RX = 3'd7; RY = 3'd5;
        Ctrl = 4'b0000; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd7; RX = 3'd0; RY = 3'd7;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==sum2 )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, sum2 );
        end
        #(`HCYCLE)
        
        $display("10:shift & summation, REG#7 = A*B" );
        #(`CYCLE*0.2)
        $display("    [REG#6 = and REG#1 REG#6]" );
        WEN = 1'b1; RW = 3'd6; RX = 3'd1; RY = 3'd6;
        Ctrl = 4'b0010; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#6 = sll 0000_0011 REG#6]" );
        WEN = 1'b1; RW = 3'd6; RX = 3'd0; RY = 3'd6;
        Ctrl = 4'b0111; Sel = 1'b0; DataIn = 8'd3;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        $display("    [REG#7 = add REG#7 REG#6]" ); 
        WEN = 1'b1; RW = 3'd7; RX = 3'd7; RY = 3'd6;
        Ctrl = 4'b0000; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.8)
        #(`CYCLE*0.2)
        WEN = 1'b0; RW = 3'd7; RX = 3'd0; RY = 3'd7;
        Ctrl = 4'b0011; Sel = 1'b1; DataIn = 8'd0;
        #(`CYCLE*0.3)
        if(busY==C )$display("    .... passed." );
        else begin 
            err_count = err_count+1;
            $display("    .... failed, design(%b) != expected(%b)", busY, C );
        end
        $display("Calculation restuls: %2d * %2d = %4d", A, B, busY );
        #(`HCYCLE)
        
        
        // show total results
        if(err_count==0 )begin
            $display("****************************        /|__/|");
            $display("**                        **      / O,O  |");
            $display("**   Congratulations !!   **    /_____   |");
            $display("** All Patterns Passed!!  **   /^ ^ ^ \\  |");
            $display("**                        **  |^ ^ ^ ^ |w|");
            $display("****************************   \\m___m__|_|");
        end
        else begin
            $display("**************************** ");
            $display("           Failed ...        ");
            $display("     Total %2d Errors ...     ", err_count );
            $display("**************************** ");
        end
        
        // finish tb
        #(`CYCLE) $finish;
    end
endmodule
