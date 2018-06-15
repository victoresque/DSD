`timescale 1 ns/10 ps

`define	TestPort1	30'h0 
`define	TestPort2	30'h1  
`define	TestPort3	30'h2  
`define	TestPort4	30'h3  

`define	answer1	32'h00000005
`define	answer2	32'h00000004
`define	answer3	32'h00000004
`define	answer4	32'h00000004

`define	CheckNum	6'd3

module	TestBed(
	clk,
	rst,
	addr,
	data,
	wen,
	error_num,
	duration,
	finish
);
	input			clk, rst;
	input	[29:0]	addr;
	input	[31:0]	data;
	input			wen;
	output	[7:0]	error_num;
	output	[15:0]	duration;
	output			finish;
	reg		[7:0]	error_num;
	reg		[15:0]	duration;
	reg				finish;
	
	reg		[1:0]	curstate;
	reg		[1:0]	nxtstate;
	reg		[5:0]	curaddr;
	reg		[5:0]	nxtaddr;
	reg		[15:0]	nxtduration;
	reg		[7:0]	nxt_error_num;
	reg				state,state_next;
		
	parameter	state_idle 	= 2'b00;
	parameter	state_check= 2'b01;
	parameter	state_report= 2'b10;	
		
	always@( posedge clk or negedge rst )						// State-DFF
	begin
		if( ~rst )
		begin
			curstate <= state_idle;
			curaddr  <= 0;
			duration <= 0;
			error_num <= 8'd255;
			
			state <= 0;
		end
		else
		begin
			curstate <= nxtstate;
			curaddr  <= nxtaddr;
			duration <= nxtduration;
			error_num <= nxt_error_num;
			
			state <= state_next;
		end
	end
			
	always@( curstate or curaddr or addr or data or wen or duration or error_num  )	// FSM for test
	begin
		finish = 1'b0;
		case( curstate )
		state_idle: 	begin
							nxtaddr = 0;
							nxtduration = 0;
							nxt_error_num = 255;	
							if( addr==`TestPort1 && data==`answer1 && wen )
							begin
								nxt_error_num = 0;
								nxtstate = state_check;
							end	 	
							else nxtstate = state_idle;
						end
		state_check:	begin
							nxtduration = duration + 1;
							nxtaddr = curaddr;						
							nxt_error_num = error_num;	
							if( addr==`TestPort2 && wen && state==0 )
							begin
								nxtaddr = curaddr + 1;
								if( data != `answer2 )
									nxt_error_num = error_num + 8'd1;
							end
							else if( addr==`TestPort3 && wen && state==0 )
							begin
								nxtaddr = curaddr + 1;
								if( data != `answer3 )
									nxt_error_num = error_num + 8'd1;
							end
							else if( addr==`TestPort4 && wen && state==0 )
							begin
								nxtaddr = curaddr + 1;
								if( data != `answer4 )
									nxt_error_num = error_num + 8'd1;
							end

							nxtstate = curstate;
							if( curaddr==`CheckNum )	
								nxtstate = state_report;
						end
		state_report:	begin
							finish = 1'b1;
							nxtaddr = curaddr;
							nxtstate = curstate;		
							nxtduration = duration;
							nxt_error_num = error_num;	
						end						
		endcase	
	end
	
	always@(*)begin//sub-FSM (avoid the Dcache stall condition)
		case(state)
			1'b0:begin
				if(wen)
					state_next=1;
				else
					state_next=state;				
			end
			1'b1:begin
				if(!wen)
					state_next=0;
				else
					state_next=state;	
			end
		endcase
	end

	always@( negedge clk )						
	begin
		if(curstate == state_report) begin
			$display("--------------------------- Simulation FINISH !!---------------------------");
			if (error_num) begin 
				$display("============================================================================");
				$display("\n (T_T) FAIL!! The simulation result is FAIL!!! there were %d errors at all.\n", error_num);
				$display("============================================================================");
			end
			 else begin 
				$display("============================================================================");
				$display("\n \\(^o^)/ CONGRATULATIONS!!  The simulation result is PASS!!!\n");
				$display("============================================================================");
			end
		end
	end
endmodule
