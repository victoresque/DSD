
module adder (x, y, carry, out);
  input  [7:0] x, y;
  output       carry;
  output [7:0] out;

  assign {carry, out} = x + y;
endmodule
