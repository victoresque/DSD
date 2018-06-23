/*
    Module:         ALU
    Author:         Victor Huang
    Description:
        An arithmetic logic unit that supports:
            1.  Addition
            2.  Subtraction
            3.  AND
            4.  OR
            5.  XOR
            6.  NOR
            7.  SLL
            8.  SRL
            9.  SRA
            10. SLT
*/

module ALU(
    clk,
    rst_n,
    op,
    A,
    B,
    HI,
    LO,
    out,
    stall
);
    input         clk;
    input         rst_n;
    input   [3:0] op;
    input  [31:0] A;
    input  [31:0] B;
    output [31:0] HI;
    output [31:0] LO;
    output [31:0] out;
    output        stall;

    reg  [31:0] out;
    wire [31:0] add_sub;
    wire [31:0] B_neg;
    wire  [4:0] shamt;
    reg  [31:0] HI, HI_next; 
    reg  [31:0] LO, LO_next;

    reg   [1:0] state, state_next;
    reg         stall_r, stall_w;
    parameter S_NORMAL = 2'd0;
    parameter S_MULT = 2'd1;
    parameter S_DIV = 2'd2;
    assign stall = stall_w;

    reg   [1:0] prev_op, prev_op_next;
    parameter PREV_NONE = 2'd0;
    parameter PREV_MULT = 2'd1;
    parameter PREV_DIV = 2'd2;

    reg         mult_start, mult_start_next;
    wire        mult_done;
    reg  [31:0] mult_A, mult_A_next; 
    reg  [31:0] mult_B, mult_B_next;
    wire [63:0] mult_prod;
    reg         div_start, div_start_next;
    wire        div_done;
    reg  [31:0] div_A, div_A_next;
    reg  [31:0] div_B, div_B_next;
    wire [31:0] div_quo, div_rem;
    reg         same, duplicated;

    always @ (*) begin
        same = (A == div_A) & (B == div_B);
        if (prev_op == PREV_MULT)     duplicated = same & (op == 4'hA);
        else if (prev_op == PREV_DIV) duplicated = same & (op == 4'hB);
        else                          duplicated = 1'b0;
    end

    Multiplier Multiplier_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(mult_start),
        .done(mult_done),
        .multiplicand(mult_A),
        .multiplier(mult_B),
        .product(mult_prod)
    );

    Divider Divider_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(div_start),
        .done(div_done),
        .dividend(div_A),
        .divisor(div_B),
        .quotient(div_quo),
        .remainder(div_rem)
    );

    assign B_neg = 1 + ~B;
    assign add_sub = A + ((op==4'b0) ? B : B_neg);
    assign shamt = A[4:0];

    always @ (*) begin
        case (op)
            4'h0: out = add_sub;              // ADD
            4'h1: out = add_sub;              // SUB
            4'h2: out = A & B;                // AND
            4'h3: out = A | B;                // OR
            4'h4: out = A ^ B;                // XOR
            4'h5: out = ~(A | B);             // NOR
            4'h6: out = B << shamt;           // SLL
            4'h7: out = B >> shamt;           // SRL
            4'h8: out = $signed(B) >>> shamt; // SRA 
            4'h9: out = {31'b0, add_sub[31]}; // SLT
            default: out = 32'b0;
        endcase
    end

    always @ (*) begin
        HI_next = HI;
        LO_next = LO;
        stall_w = stall_r;
        mult_start_next = mult_start;
        mult_A_next = mult_A;
        mult_B_next = mult_B;
        div_start_next = div_start;
        div_A_next = div_A;
        div_B_next = div_B;
        prev_op_next = prev_op;
        state_next = state;

        if (state == S_NORMAL) begin
            if (~duplicated) begin
                if (op == 4'hA) begin
                    stall_w = 1'b1;
                    mult_start_next = 1'b1;
                    mult_A_next = A;
                    mult_B_next = B;
                    prev_op_next = PREV_MULT;
                    state_next = S_MULT;
                end
                else if (op == 4'hB) begin
                    stall_w = 1'b1;
                    div_start_next = 1'b1;
                    div_A_next = A;
                    div_B_next = B;
                    prev_op_next = PREV_DIV;
                    state_next = S_DIV;
                end
            end
        end
        else if (state == S_MULT) begin
            mult_start_next = 1'b0;
            if (mult_done) begin
                stall_w = 1'b0;                
                {HI_next, LO_next} = mult_prod;
                state_next = S_NORMAL;
            end
        end
        else if (state == S_DIV) begin
            div_start_next = 1'b0;
            if (div_done) begin
                stall_w = 1'b0;
                {HI_next, LO_next} = {div_rem, div_quo};
                state_next = S_NORMAL;
            end
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            HI <= 32'b0;
            LO <= 32'b0;
            stall_r <= 1'b0;
            mult_start <= 1'b0;
            mult_A <= 32'b0;
            mult_B <= 32'b0;
            div_start <= 1'b0;
            div_A <= 32'b0;
            div_B <= 32'b0;
            prev_op <= PREV_NONE;
            state <= S_NORMAL;
        end
        else begin
            HI <= HI_next;
            LO <= LO_next;
            stall_r <= stall_w;
            mult_start <= mult_start_next;
            mult_A <= mult_A_next;
            mult_B <= mult_B_next;
            div_start <= div_start_next;
            div_A <= div_A_next;
            div_B <= div_B_next;
            prev_op <= prev_op_next;
            state <= state_next;
        end
    end
endmodule


module Multiplier (
    clk,
    rst_n,
    start,
    done,
    multiplicand,
    multiplier,
    product
);
    input         clk;
    input         rst_n;
    input         start;
    output        done;
    input  [31:0] multiplicand;
    input  [31:0] multiplier;
    output [63:0] product;

    reg   [1:0] state, state_next;
    reg   [5:0] counter, counter_next;
    reg         done, done_next;
    reg  [63:0] product, product_next;
    parameter S_IDLE = 2'd0;
    parameter S_CALC = 2'd1;

    always @ (*) begin
        state_next = state;
        done_next = 1'b0;
        product_next = product;
        if (state == S_IDLE) begin
            counter_next = 6'd0;
            if (start) begin
                product_next = {32'b0, multiplier};
                state_next = S_CALC;
            end
        end
        else begin
            counter_next = counter + 1;
            if (counter == 6'd32) begin
                done_next = 1'b1;
                product_next = product;
                state_next = S_IDLE;
            end
            else begin
                if (product[0]) begin
                    if (counter != 6'd31) product_next = {product[63:32] + multiplicand, product[31:0]} >> 1;
                    else product_next = {product[63:32] - multiplicand, product[31:0]} >> 1;
                    product_next[63] = product_next[62];
                end
                else begin
                    product_next = product >> 1'b1;
                    product_next[63] = product_next[62];
                end
            end
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            done <= 1'b0;
            counter <= 6'b0;
            product <= 64'b0;
            state <= S_IDLE;
        end
        else begin
            done <= done_next;
            counter <= counter_next;
            product <= product_next;
            state <= state_next;
        end
    end
endmodule


module Divider (
    clk,
    rst_n,
    start,
    done,
    dividend,
    divisor,
    quotient,
    remainder
);
    // dividend / divisor = quotient ... remainder
    input         clk;
    input         rst_n;
    input         start;
    output        done;
    input  [31:0] dividend;
    input  [31:0] divisor;
    output [31:0] quotient;
    output [31:0] remainder;

    reg   [1:0] state, state_next;
    parameter S_IDLE = 2'd0;
    parameter S_CALC = 2'd1;

    reg   [5:0] counter, counter_next;
    reg         done, done_next;
    reg  [31:0] quotient, quotient_next;
    reg  [31:0] remainder, remainder_next;
    reg  [63:0] data, data_next;
    reg  [31:0] diff;
    wire [31:0] dividend_sign, divisor_sign;
    wire        dividend_neg, divisor_neg;

    assign dividend_neg = dividend[31];
    assign divisor_neg = divisor[31];
    assign dividend_sign = dividend_neg ? (~dividend + 1'b1) : dividend;
    assign divisor_sign = divisor_neg ? (~divisor + 1'b1) : divisor;

    always @ (*) begin
        state_next = state;
        done_next = 1'b0;
        data_next = data;
        remainder_next = (dividend_neg) ? (~data[63:32] + 1'b1) : data[63:32];
        quotient_next = (dividend_neg!=divisor_neg) ? (~data[31:0] + 1'b1) : data[31:0];
        if (state == S_IDLE) begin
            counter_next = 6'd0;
            if (start) begin
                data_next = {32'b0, dividend_sign};
                state_next = S_CALC;
            end
        end
        else begin
            counter_next = counter + 1;
            if (counter == 6'd32) begin
                data_next = data;
                done_next = 1'b1;
                state_next = S_IDLE;
            end
            else begin
                data_next = data << 1;
                diff = data_next[63:32] - divisor_sign;
                if (~diff[31]) data_next = {diff, data[30:0], 1'b1};
            end
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            done <= 1'b0;
            counter <= 6'b0;
            quotient <= 32'b0;
            remainder <= 32'b0;
            data <= 64'b0;
            state <= S_IDLE;
        end
        else begin
            done <= done_next;
            counter <= counter_next;
            quotient <= quotient_next;
            remainder <= remainder_next;
            data <= data_next;
            state <= state_next;
        end
    end
endmodule
