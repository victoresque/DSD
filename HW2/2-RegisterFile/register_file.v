module register_file(
    Clk  ,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);
input        Clk, WEN;
input  [2:0] RW, RX, RY;
input  [7:0] busW;
output [7:0] busX, busY;
    
reg  [7:0] busX, busY;
reg  [7:0] r_w [0:7];
reg  [7:0] r_r [0:7];
integer i;

always @ (*) begin
    busX = r_r[RX];
    busY = r_r[RY];
end

always @ (*) begin
    r_r[0] = 8'b0;
    for (i=1; i<8; i=i+1) begin
        r_w[i] = r_r[i];
    end
    
    if (WEN) r_w[RW] = busW;
    else     r_w[RW] = r_r[RW];
end

always @ (posedge Clk) begin
    for (i=1; i<8; i=i+1) begin
        r_r[i] <= r_w[i];
    end
end	
endmodule
