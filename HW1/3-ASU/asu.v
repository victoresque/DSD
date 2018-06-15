
module asu (x, y, mode, carry, out);
  input  [7:0] x, y;
  input        mode;
  output       carry;
  output [7:0] out;
  wire [7:0] w_1, w_2;
  
  adder          add0 (x, y, w_0, w_1);
  barrel_shifter shift0 (x, y[2:0], w_2);

  assign out   = mode ? w_1 : w_2;
  assign carry = mode ? w_0 : 1'b0;
endmodule
