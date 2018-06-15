//RTL (use continuous assignment)
module alu_rtl(
    ctrl,
    x,
    y,
    carry,
    out
);
    input  [3:0] ctrl;
    input  [7:0] x;
    input  [7:0] y;
    output       carry;
    output [7:0] out;

    assign {carry, out} =
        ctrl==4'b0000 ? x + y :
        ctrl==4'b0001 ? x - y :
        ctrl==4'b0010 ? {1'b0, x & y} :
        ctrl==4'b0011 ? {1'b0, x | y} :
        ctrl==4'b0100 ? {1'b0, ~x} :
        ctrl==4'b0101 ? {1'b0, x ^ y} :
        ctrl==4'b0110 ? {1'b0, ~(x | y)} :
        ctrl==4'b0111 ? {1'b0, y << x[2:0]} :
        ctrl==4'b1000 ? {1'b0, y >> x[2:0]} :
        ctrl==4'b1001 ? {1'b0, {x[7], x[7:1]}} :
        ctrl==4'b1010 ? {1'b0, {x[6:0], x[7]}} :
        ctrl==4'b1011 ? {1'b0, {x[0], x[7:1]}} :
        ctrl==4'b1100 ? {1'b0, (x==y) ? 8'b01 : 8'b0} : 9'b0;
endmodule
