`define ADDER_GATE_DELAY 1

/*
  - Kogge-Stone parallel prefix adder
  References: 
  [1] http://www.syssec.ethz.ch/content/dam/ethz/special-interest/infk/inst-infsec/system-security-group-dam/education/Digitaltechnik_14/13_AdvancedAdders.pdf
  [2] http://users.encs.concordia.ca/~asim/COEN_6501/Lecture_Notes/Parallel%20prefix%20adders%20presentation.pdf
*/
module ks_adder_gate_8 (x, y, carry, out);
  input  [7:0] x, y;
  output       carry;
  output [7:0] out;
  wire [7:0] p, g, c, s0;

  half_adder_pg ha0 (x[0], y[0], out[0], g[0]);
  half_adder_pg ha1 (x[1], y[1], p[1], g[1]);
  half_adder_pg ha2 (x[2], y[2], p[2], g[2]);
  half_adder_pg ha3 (x[3], y[3], p[3], g[3]);
  half_adder_pg ha4 (x[4], y[4], p[4], g[4]);
  half_adder_pg ha5 (x[5], y[5], p[5], g[5]);
  half_adder_pg ha6 (x[6], y[6], p[6], g[6]);
  half_adder_pg ha7 (x[7], y[7], p[7], g[7]);
  ks_parallel_prefix_logic_8 ksppl0 (g, p, {carry, c});
  xor #`ADDER_GATE_DELAY xor1 (out[1], p[1], c[1]);
  xor #`ADDER_GATE_DELAY xor2 (out[2], p[2], c[2]);
  xor #`ADDER_GATE_DELAY xor3 (out[3], p[3], c[3]);
  xor #`ADDER_GATE_DELAY xor4 (out[4], p[4], c[4]);
  xor #`ADDER_GATE_DELAY xor5 (out[5], p[5], c[5]);
  xor #`ADDER_GATE_DELAY xor6 (out[6], p[6], c[6]);
  xor #`ADDER_GATE_DELAY xor7 (out[7], p[7], c[7]);
endmodule

module ks_parallel_prefix_logic_8 (g, p, co);
  input  [7:0] g, p;
  output [8:0] co;
  wire [7:0] g1, p1, g2, p2, p3;
  wire [6:0] g3;

  ks_parallel_prefix_logic_8_layer ksppl_l1 (g, p, {g[6:0], {1{1'b0}}}, {p[6:0], {1{1'b1}}}, g1, p1);
  ks_parallel_prefix_logic_8_layer ksppl_l2 (g1, p1, {g1[5:0], {2{1'b0}}}, {p1[5:0], {2{1'b1}}}, g2, p2);
  ks_parallel_prefix_logic_8_layer ksppl_l3 (g2, p2, {g2[4:0], {4{1'b0}}}, {p2[4:0], {4{1'b1}}}, co[8:1], p3);
endmodule

module ks_parallel_prefix_logic_8_layer (gi1, pi1, gi2, pi2, go, po);
  input  [7:0] gi1, pi1, pi2, gi2;
  output [7:0] go, po;

  and #`ADDER_GATE_DELAY and00 (w0, gi2[0], pi1[0]);
  or  #`ADDER_GATE_DELAY or0   (go[0], w0, gi1[0]);
  and #`ADDER_GATE_DELAY and01 (po[0], pi1[0], pi2[0]);
  and #`ADDER_GATE_DELAY and10 (w1, gi2[1], pi1[1]);
  or  #`ADDER_GATE_DELAY or1   (go[1], w1, gi1[1]);
  and #`ADDER_GATE_DELAY and11 (po[1], pi1[1], pi2[1]);
  and #`ADDER_GATE_DELAY and20 (w2, gi2[2], pi1[2]);
  or  #`ADDER_GATE_DELAY or2   (go[2], w2, gi1[2]);
  and #`ADDER_GATE_DELAY and21 (po[2], pi1[2], pi2[2]);
  and #`ADDER_GATE_DELAY and30 (w3, gi2[3], pi1[3]);
  or  #`ADDER_GATE_DELAY or3   (go[3], w3, gi1[3]);
  and #`ADDER_GATE_DELAY and31 (po[3], pi1[3], pi2[3]);
  and #`ADDER_GATE_DELAY and40 (w4, gi2[4], pi1[4]);
  or  #`ADDER_GATE_DELAY or4   (go[4], w4, gi1[4]);
  and #`ADDER_GATE_DELAY and41 (po[4], pi1[4], pi2[4]);
  and #`ADDER_GATE_DELAY and50 (w5, gi2[5], pi1[5]);
  or  #`ADDER_GATE_DELAY or5   (go[5], w5, gi1[5]);
  and #`ADDER_GATE_DELAY and51 (po[5], pi1[5], pi2[5]);
  and #`ADDER_GATE_DELAY and60 (w6, gi2[6], pi1[6]);
  or  #`ADDER_GATE_DELAY or6   (go[6], w6, gi1[6]);
  and #`ADDER_GATE_DELAY and61 (po[6], pi1[6], pi2[6]);
  and #`ADDER_GATE_DELAY and70 (w7, gi2[7], pi1[7]);
  or  #`ADDER_GATE_DELAY or7   (go[7], w7, gi1[7]);
  and #`ADDER_GATE_DELAY and71 (po[7], pi1[7], pi2[7]);
endmodule

/*
  - Carry lookahead adder
  References: 
  [1] http://www.eng.ucy.ac.cy/theocharides/Courses/ECE210/Carrylookahead_supp4.pdf
*/
module carry_lookahead_adder_gate_8 (x, y, carry, out);
  input  [7:0] x, y;
  output       carry;
  output [7:0] out;
  // wire       cin; // cin = 1'b0;

  carry_lookahead_adder_gate_4 cla4_0 (x[3:0], y[3:0], 1'b0, out[3:0], p3_0, g3_0);
  carry_lookahead_adder_gate_4 cla4_1 (x[7:4], y[7:4], c3_0, out[7:4], p7_4, g7_4);

  and #`ADDER_GATE_DELAY and00 (w00, p3_0, 1'b0);
  or  #`ADDER_GATE_DELAY or0   (c3_0, g3_0, w00);
  and #`ADDER_GATE_DELAY and10 (w10, p7_4, g3_0);
  and #`ADDER_GATE_DELAY and11 (w11, p7_4, p3_0, 1'b0);
  or  #`ADDER_GATE_DELAY or1   (carry, g7_4, w10, w11);
endmodule

module carry_lookahead_adder_gate_4 (x, y, c0, out, po, go);
  input        c0;
  input  [3:0] x, y;
  output       po, go;
  output [3:0] out;

  full_adder_pg fa0 (x[0], y[0], c0, out[0], p0, g0);
  full_adder_pg fa1 (x[1], y[1], c1, out[1], p1, g1);
  full_adder_pg fa2 (x[2], y[2], c2, out[2], p2, g2);
  full_adder_pg fa3 (x[3], y[3], c3, out[3], p3, g3);
  lookahead_gate_4 lg0 (c0, 
                        {p3, p2, p1, p0}, 
                        {g3, g2, g1, g0},
                        {c3, c2, c1, c0}, 
                        po, go);
endmodule

module lookahead_gate_4 (c0, p, g, co, po, go);
  input        c0;
  input  [3:0] p, g;
  output [3:0] co;
  output       po, go;

  and #`ADDER_GATE_DELAY and00 (w00, p[0], c0);
  or  #`ADDER_GATE_DELAY or0   (co[1], g[0], w00);
  and #`ADDER_GATE_DELAY and10 (w10, p[1], g[0]);
  and #`ADDER_GATE_DELAY and11 (w11, p[1], p[0], c0);
  or  #`ADDER_GATE_DELAY or1   (co[2], g[1], w10, w11);
  and #`ADDER_GATE_DELAY and20 (w20, p[2], g[1]);
  and #`ADDER_GATE_DELAY and21 (w21, p[2], p[1], g[0]);
  and #`ADDER_GATE_DELAY and22 (w22, p[2], p[1], p[0], c0);
  or  #`ADDER_GATE_DELAY or2   (co[3], g[2], w20, w21, w22);
  and #`ADDER_GATE_DELAY and30 (po, p[3], p[2], p[1], p[0]);
  and #`ADDER_GATE_DELAY and31 (w31, p[3], g[2]);
  and #`ADDER_GATE_DELAY and32 (w32, p[3], p[2], g[1]);
  and #`ADDER_GATE_DELAY and33 (w33, p[3], p[2], p[1], g[0]);
  or  #`ADDER_GATE_DELAY or3   (go, g[3], w31, w32, w33);
endmodule

// Carry ripple adder
module adder_gate (x, y, carry, out);
  input  [7:0] x, y;
  output       carry;
  output [7:0] out;

  full_adder fa0 (x[0], y[0], 1'b0, out[0], c0);
  full_adder fa1 (x[1], y[1], c0, out[1], c1);
  full_adder fa2 (x[2], y[2], c1, out[2], c2);
  full_adder fa3 (x[3], y[3], c2, out[3], c3);
  full_adder fa4 (x[4], y[4], c3, out[4], c4);
  full_adder fa5 (x[5], y[5], c4, out[5], c5);
  full_adder fa6 (x[6], y[6], c5, out[6], c6);
  full_adder fa7 (x[7], y[7], c6, out[7], carry);
endmodule

module full_adder (x, y, cin, sum, cout);
  input  x, y, cin;
  output sum, cout;

  xor #`ADDER_GATE_DELAY xor0 (w0, x, y);
  xor #`ADDER_GATE_DELAY xor1 (sum, cin, w0);
  and #`ADDER_GATE_DELAY and0 (w1, x, y);
  and #`ADDER_GATE_DELAY and1 (w2, cin, w0);
  or  #`ADDER_GATE_DELAY or0  (cout, w1, w2);
endmodule

module full_adder_pg (x, y, cin, sum, p, g);
  input  x, y, cin;
  output sum, p, g;

  xor #`ADDER_GATE_DELAY xor0 (p, x, y);
  xor #`ADDER_GATE_DELAY xor1 (sum, cin, p);
  and #`ADDER_GATE_DELAY and0 (g, x, y);
endmodule

module half_adder_pg (x, y, p, g);
  input  x, y;
  output p, g;

  xor #`ADDER_GATE_DELAY xor0 (p, x, y);
  and #`ADDER_GATE_DELAY and0 (g, x, y);
endmodule
