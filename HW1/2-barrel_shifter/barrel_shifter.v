
module barrel_shifter (in, shift, out);
  input  [7:0] in;
  input  [2:0] shift;
  output [7:0] out;

  wire [7:0] l_0;
  wire [7:0] l_1;

  assign l_0 = shift[0] ? { in[6:0], 1'b0}  : in;
  assign l_1 = shift[1] ? {l_0[5:0], 2'b0} : l_0;
  assign out = shift[2] ? {l_1[3:0], 4'b0} : l_1;
endmodule
