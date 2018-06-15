module simple_calculator(
    Clk,
    WEN,
    RW,
    RX,
    RY,
    DataIn,
    Sel,
    Ctrl,
    busY,
    Carry
);
    input        Clk;
    input        WEN;
    input  [2:0] RW, RX, RY;
    input  [7:0] DataIn;
    input        Sel;
    input  [3:0] Ctrl;
    output [7:0] busY;
    output       Carry;

    reg  [7:0] alu_x;
    wire [7:0] busX;
    wire [7:0] busW;
    wire [7:0] alu_out;

    register_file register_file_inst(.Clk(Clk), .WEN(WEN), .RW(RW), .RX(RX), .RY(RY), 
                                     .busX(busX), .busY(busY), .busW(alu_out));
    alu           alu_inst(.ctrl(Ctrl), .x(alu_x), .y(busY), .carry(Carry), .out(alu_out));

    always @ (*) begin
        alu_x = Sel ? busX : DataIn;
    end
endmodule
