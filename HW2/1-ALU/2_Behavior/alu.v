//Behavior �Vlevel (event-driven)
module alu(
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

    reg       carry;
    reg [7:0] out;

    always @ (*) begin
             if (ctrl == 4'b0000) {carry, out} = x + y;
        else if (ctrl == 4'b0001) {carry, out} = x - y;
        else if (ctrl == 4'b0010) {carry, out} = {1'b0, x & y};
        else if (ctrl == 4'b0011) {carry, out} = {1'b0, x | y} ;
        else if (ctrl == 4'b0100) {carry, out} = {1'b0, ~x};
        else if (ctrl == 4'b0101) {carry, out} = {1'b0, x ^ y};
        else if (ctrl == 4'b0110) {carry, out} = {1'b0, ~(x | y)};
        else if (ctrl == 4'b0111) {carry, out} = {1'b0, y << x[2:0]};
        else if (ctrl == 4'b1000) {carry, out} = {1'b0, y >> x[2:0]};
        else if (ctrl == 4'b1001) {carry, out} = {1'b0, {x[7], x[7:1]}};
        else if (ctrl == 4'b1010) {carry, out} = {1'b0, {x[6:0] , x[7]}};
        else if (ctrl == 4'b1011) {carry, out} = {1'b0, {x[0] , x[7:1]}};
        else if (ctrl == 4'b1100) {carry, out} = {1'b0, (x==y) ? 8'b01 : 8'b0};
        else                      {carry, out} = 9'b0;
    end
endmodule
