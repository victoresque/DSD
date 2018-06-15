// For the instruction sequence used in this testbench, please see the end of this file

`timescale 1 ns/10 ps
`define	H_CYCLE 5
`define CYCLE 10

module SingleCycle_tb;

	reg clk;
	reg rst_n;
	wire [31:0] IR_addr;
	wire [31:0] IR;
	wire [31:0] RF_writedata;	
	wire [31:0] ReadDataMem;
	wire CEN;
	wire WEN;
	wire [6:0] A;
	wire [31:0] ReadData2;
	wire OEN;

	integer error_cnt;
	integer i;

	// Instruction memory
	ROM128x32 i_rom(
		.addr(IR_addr[8:2]),
		.data(IR)
	);

	SingleCycle_MIPS i_MIPS( 
		clk,
		rst_n,
		IR_addr,
		IR,
		RF_writedata,
		ReadDataMem,
		CEN,
		WEN,
		A,
		ReadData2,
		OEN
	);

	HSs18n_128x32 Data_memory(
		ReadDataMem,
		~clk,
		CEN,
		WEN,
		A,
		ReadData2,
		OEN
	);

	//initial begin
	//	$sdf_annotate("DSDHW3.sdf", i_MIPS);
	//end

// Initialize the data memory
	initial begin
		$readmemb ("initial_data.txt", Data_memory.mem);
		
		//$display("\nReading data memory......");
		//for ( i=0; i<5; i=i+1 )
		//begin
		//	$display("data_mem[%d] = %h", i, i_MIPS.Data_memory.mem[i]);
		//end
		
		$dumpfile("SingleCycleRTL.vcd");
		$dumpvars;
		//$fsdbDumpfile("SingleCycleRTL.fsdb");			
		//$fsdbDumpvars;								

		clk = 0;
		error_cnt = 0;

		rst_n = 1'b1;
		#(`CYCLE*0.2)rst_n = 1'b0;
		#(`CYCLE*1.5) rst_n = 1'b1;

		#(`CYCLE*0.8)
		if (IR_addr == 32'd0 && RF_writedata == 32'd15)
			$display("Your lw instruction is correct! ");
		else begin
			$display("Your lw instruction is incorrect! ");
			$display("     Expected IR_addr =  0,      Your IR_addr = %d", IR_addr);
			$display("Expected RF_writedata = 15, Your RF_writedata = %d", RF_writedata);
			error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr == 32'd4 && RF_writedata == 32'd20)
			$display("Your lw instruction is correct! ");
		else begin			
		 	$display("Your lw instruction is incorrect! ");
		 	$display("     Expected IR_addr =  4,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata = 20, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr ==  32'd8 && RF_writedata == 32'd30 )
			$display("Your add instruction is correct! ");
		else begin			
		 	$display("Your add instruction is incorrect! ");
		 	$display("     Expected IR_addr =  8,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata = 30, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr ==  32'd12 && RF_writedata == 32'd10 )
			$display("Your sub instruction is correct! ");
		else begin			
		 	$display("Your sub instruction is incorrect! ");
		 	$display("     Expected IR_addr = 12,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata = 10, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr ==  32'd16 && RF_writedata == 32'd20 )
			$display("Your and instruction is correct! ");
		else begin			
		 	$display("Your and instruction is incorrect! ");
		 	$display("     Expected IR_addr = 16,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata = 20, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		// IR_addr == 32'd20;

		#(`CYCLE)
		if (IR_addr ==  32'd24 && RF_writedata == 32'd30 )
		begin
			$display("Your beq instruction is correct! ");
			$display("Your or instruction is correct! ");
		end
		else begin			
		 	$display("Your or instruction is incorrect! ");
		 	$display("     Expected IR_addr = 24,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata = 30, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr ==  32'd28 && RF_writedata == 32'd1 )
			$display("Your slt instruction is correct! ");
		else begin			
		 	$display("Your slt instruction is incorrect! ");
		 	$display("     Expected IR_addr = 28,      Your IR_addr = %d", IR_addr);
		 	$display("Expected RF_writedata =  1, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		// IR_addr == 32'd32;

		#(`CYCLE)
		if (IR_addr ==  32'd36 && RF_writedata == 32'd30 )
			$display("Your sw instruction is correct! ");
		else begin			
			$display("Your sw instruction is incorrect! ");
			$display("     Expected IR_addr = 36,      Your IR_addr = %d", IR_addr);
			$display("Expected RF_writedata = 30, Your RF_writedata = %d", RF_writedata);
			error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		// IR_addr == 32'd40;
		
		
		#(`CYCLE)
		if (IR_addr ==  32'd52 && RF_writedata == 32'd40 )
			$display("Your jump instruction is correct! ");
		else begin
			$display("Your jump instruction is incorrect! ");
			$display("     Expected IR_addr = 52,      Your IR_addr = %d", IR_addr);
			$display("Expected RF_writedata = 40, Your RF_writedata = %d", RF_writedata);
			error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		// IR_addr == 32'd56;
		
		#(`CYCLE)
		if (IR_addr ==  32'd44 && RF_writedata == 32'd40 )
			$display("Your jal instruction is correct! ");
		else begin			
		 	$display("Your jal instruction is incorrect! ");
			$display("     Expected IR_addr = 44,      Your IR_addr = %d", IR_addr);
			$display("Expected RF_writedata = 40, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		// IR_addr == 32'd48;

		#(`CYCLE)
		if (IR_addr ==  32'd60 )
			$display("Your jr instruction is correct! ");
		else begin			
			$display("Your jr instruction is incorrect! ");
			$display("     Expected IR_addr = 60,      Your IR_addr = %d", IR_addr);
			error_cnt = error_cnt + 1;
		end

		#(`CYCLE)
		if (IR_addr ==  32'd72 && RF_writedata == 32'd80 )
			$display("Your beq instruction is correct! ");
		else begin			
		 	$display("Your beq instruction is incorrect! ");
		 	$display("     Expected IR_addr = 72,      Your IR_addr = %d", IR_addr);
			$display("Expected RF_writedata = 80, Your RF_writedata = %d", RF_writedata);
		 	error_cnt = error_cnt + 1;
		end

		if (error_cnt == 0)
		begin
			$display("\n-----------------------------------------------------------\n");
			$display("  Congratulations!! Your design has passed all the test!!");
			$display("\n-----------------------------------------------------------\n");
		end

		
		$finish;

	end

	always begin
		#`H_CYCLE clk = ~clk;
	end
endmodule

module ROM128x32 (
	addr,
	data
);
	input [6:0] addr;
	output [31:0] data;
	reg [31:0] data;
	reg [31:0] mem [0:127];
	
	integer i;
	initial begin
		// Initialize the instruction memory
		$readmemh ("instructions.txt", mem);
		$display("Reading instruction memory......");
		
		// for ( i=0; i<19; i=i+1 )
		// begin
		// 	$display("mem[%d] = %h", i, mem[i]);
		// end
	end	
	
	always @(addr) data = mem[addr];
	
endmodule

//  ------------------------------------------------------ 
/*	
	// Contents of initial data memory
	// addr		decimal
	// 0		15
	// 1 		20
	
	// Contents of instruction memory	
	// Note: test IR address at every cycle	
    //
    lw $t0, 0($zero)		# $t0 = 15
    lw $t1, 1($zero)		# $t1 = 20
		
	#test add
	add $t0, $t0, $t0	# $t0 = 30
			 
	#test sub
	sub $t2, $t0, $t1 # $t2 = 10
	  
	#test and
	and $t3, $t0, $t1  # $t3 = 20
	  
	# test beq
	beq $t0, $t2, beq_dest # not taken , test IR_addr	  
	  
	#test or
	or $t4, $t0, $t1	# $t4 = 30
	  
	#test slt
	slt $t5, $t3, $t4 # $t5 = 1

	#test sw
	sw $t4, 4($zero) 
	lw $s1, 4($zero)  # $s1 = 30
	
	#test j
	j JumpRegister # test IR addr
	
Jal_dest: 
	add $s2, $t3, $t3 # $s2 = 40
	jr $ra		# test IR_addr
		
	#test jr  
JumpRegister: 
	add $s3, $t3, $t3  # $s3 = 40 --> jump correct
	
	#test jal
	jal Jal_dest  # test IR_addr and RF_writedata
	beq $s2, $s3, beq_dest # taken, test IR_addr
	
	add $s2, $s1, $s0 # will not be executed
	add $s3, $s1, $s0 # will not be executed
	
beq_dest:	
	add $s4, $s3, $s2 # $s4 = 80
exit: 

*/
//  ------------------------------------------------------ 

