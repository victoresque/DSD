`define MODE_MUX_DELAY 2.5

module asu_gate (x, y, mode, carry, out);
  input  [7:0] x, y;
  input        mode;
  output       carry;
  output [7:0] out;
  wire [7:0] w_1, w_2;

//  ks_adder_gate_8     add0 (x, y, w_0, w_1);
  adder_gate          add0 (x, y, w_0, w_1);
  barrel_shifter_gate shift0 (x, y[2:0], w_2);

  assign #(`MODE_MUX_DELAY) out   = mode ? w_1 : w_2;
  assign #(`MODE_MUX_DELAY) carry = mode ? w_0 : 1'b0;
endmodule
