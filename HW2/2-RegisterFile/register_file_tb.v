`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module register_file_tb;
    // port declaration for design-under-test
    reg        Clk, WEN;
    reg  [2:0] RW, RX, RY;
    reg  [7:0] busW;
    wire [7:0] busX, busY;
    
    // instantiate the design-under-test
    register_file rf(
        Clk  ,
        WEN  ,
        RW   ,
        busW ,
        RX   ,
        RY   ,
        busX ,
        busY
    );

    // initial begin
    //     $dumpfile("a.vcd");
    //     $dumpvars;
    // end

    // clock generation
    always #(`HCYCLE) Clk = ~Clk;

    // write your test pattern here
    integer i;
    integer err_count;
    reg       err_signal;
    reg [7:0] sim_reg [0:7];
    initial begin
        Clk = 1'b0;
        err_signal = 1'b0;
        err_count = 0;

        for (i=0; i<100000; i=i+1) begin
            #(`CYCLE * 0.2);
            RW = $urandom % 8;
            RX = $urandom % 8;
            RY = $urandom % 8;
            WEN = $urandom % 2;
            busW = $urandom % 256;
            
            if (WEN) sim_reg[RW] = busW;
            sim_reg[0] = 0;

            #(`CYCLE * 0.6);
            if (busX === sim_reg[RX] && busY === sim_reg[RY]) begin
                err_signal = 1'b0;
            end
            else begin
                $display(">> FAIL at case: %2d <<", i);
                $displayb(sim_reg[RX], " ", busX, " ", sim_reg[RY], " ", busY);
                err_count = err_count + 1;
                err_signal = 1'b1;
            end
            #(`CYCLE * 0.2);
        end

        if (err_count == 0) begin
            $display("******************************** ");
            $display(" register_file testbench passed");
            $display("******************************** ");
        end
        else begin
            $display("******************************** ");
            $display("              Failed ...        ");
            $display("        Total %5d Errors ...    ", err_count );
            $display("******************************** ");
        end

        #(`CYCLE) $finish;
    end
endmodule
