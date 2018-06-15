`timescale 1ns/10ps
`define CYCLE 20
`define INFILE "Bin.pattern"
`define OUTFILE "Bout_golden.pattern" 

module barrel_test;
parameter pattern_num = 8;
wire [7:0] out;
wire carry;
reg [7:0] x, y;
reg  clk;
reg  stop;
integer i, num, error;

reg [7:0] ans_out;
reg [7:0] barrel_out;

reg [7:0] data_base1 [0:100];
reg [7:0] data_base2 [0:100];

barrel_shifter B (x, y[2:0], out);

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
	barrel_out <= out;
	ans_out <= data_base2[i];
	if(barrel_out !== ans_out) begin
		error <= error + 1;
		$display("An ERROR occurs at no.%d pattern: Output %b != answer %b.\n", i, barrel_out, ans_out);
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
$dumpfile("barrel.vcd");
$dumpvars;
/* 	$fsdbDumpfile("barrel.fsdb");
	$fsdbDumpvars;  */
end

endmodule