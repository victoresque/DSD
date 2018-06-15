`timescale 1ns/10ps
`define CYCLE 20.0
`define INFILE "in.pattern"
`define OUTFILE "out_golden.pattern" 

module adder_test;
parameter pattern_num = 10;
wire [7:0] out;
wire carry;
reg [7:0] x, y;
reg  clk;
reg  stop;
integer i, num, error;

reg [8:0] ans_out;
reg [8:0] adder_out;

reg [7:0] data_base1 [0:100];
reg [8:0] data_base2 [0:100];

adder A (x, y, carry, out);

initial begin
	$readmemh(`INFILE  , data_base1);
	$readmemh(`OUTFILE , data_base2);
	clk = 1'b1;
	error = 0;
	stop = 0;
	i=0;
end

always begin #(`CYCLE * 0.5) clk = ~clk;
end

initial begin
	x[7:0] = data_base1[0];
	y[7:0] = data_base1[1];
	
	for(num = 2; num < (pattern_num * 2); num = num + 2) begin
		@(posedge clk) begin
			x[7:0] = data_base1[num];
			y[7:0] = data_base1[num + 1];
		end
	end
end


always@(posedge clk) begin
	i <= i + 1;
	if (i >= pattern_num)
		stop <= 1;
end

always@(posedge clk ) begin
	adder_out <= {carry, out};
	ans_out <= data_base2[i];
	if(adder_out !== ans_out)begin
		error <= error + 1;
		$display("An ERROR occurs at no.%d pattern: {carry out, output} %h != answer %h.\n", i, adder_out, ans_out);
	end
end

initial begin
	@(posedge stop) begin
		if(error == 0) begin
			$display("==========================================\n");
			$display("======  Congratulation! You Pass!  =======\n");
			$display("==========================================\n");
		end
		else begin
			$display("===============================\n");
			$display("There are %d errors.", error);
			$display("===============================\n");
		end
		$finish;
	end
end

/*================Dumping Waveform files====================*/
initial begin
$dumpfile("adder.vcd");
$dumpvars;
/* 	$fsdbDumpfile("adder.fsdb");
	$fsdbDumpvars;  */
end

endmodule