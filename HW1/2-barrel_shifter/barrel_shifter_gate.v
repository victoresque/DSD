`define SHIFTER_GATE_DELAY 1

module barrel_shifter_gate (in, shift, out);
  input  [7:0] in;
  input  [2:0] shift;
  output [7:0] out;
  wire [7:0] l1, l2;

  barrel_shift_gate_layer shift_l1 (in, {in[6:0], {1{1'b0}}}, shift[0], l1);
  barrel_shift_gate_layer shift_l2 (l1, {l1[5:0], {2{1'b0}}}, shift[1], l2);
  barrel_shift_gate_layer shift_l3 (l2, {l2[3:0], {4{1'b0}}}, shift[2], out);
endmodule

module barrel_shift_gate_layer (in0, in1, shift, out);
  input  [7:0] in0, in1;
  input        shift;
  output [7:0] out;

  mux mux0 (out[0], in0[0], in1[0], shift);
  mux mux1 (out[1], in0[1], in1[1], shift);
  mux mux2 (out[2], in0[2], in1[2], shift);
  mux mux3 (out[3], in0[3], in1[3], shift);
  mux mux4 (out[4], in0[4], in1[4], shift);
  mux mux5 (out[5], in0[5], in1[5], shift);
  mux mux6 (out[6], in0[6], in1[6], shift);
  mux mux7 (out[7], in0[7], in1[7], shift);
endmodule

module mux (x, a, b, sel);
  input  a, b, sel;
  output x;

  not #(`SHIFTER_GATE_DELAY) n0 (sel_i, sel);
  and #(`SHIFTER_GATE_DELAY) a1 (w1, a, sel_i);
  and #(`SHIFTER_GATE_DELAY) a2 (w2, b, sel);
  or  #(`SHIFTER_GATE_DELAY) o1 (x, w1, w2);
endmodule
