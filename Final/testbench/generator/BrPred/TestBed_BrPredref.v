`timescale 1 ns/10 ps

`define	TestPort	30'd0 
`define	answer	32'd60

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
	parameter	state_pass= 2'b01;	
		
	always@( posedge clk or negedge rst )						// State-DFF
	begin
		if( ~rst )
		begin
			curstate <= state_idle;
			curaddr  <= 0;
			duration <= 0;
			
			state <= 0;
		end
		else
		begin
			curstate <= nxtstate;
			curaddr  <= nxtaddr;
			duration <= nxtduration;
			
			state <= state_next;
		end
	end
			
	always@( curstate or curaddr or addr or data or wen or duration )	// FSM for test
	begin
		finish = 1'b0;
		case( curstate )
		state_idle: 	begin
							nxtaddr = 0;
							nxtduration = 0;
	
							if( addr==`TestPort && data==`answer && wen )
							begin
								nxtstate = state_pass;
							end	 	
							else nxtstate = state_idle;
						end
		state_pass:	begin
							finish = 1'b1;
							nxtaddr = curaddr;
							nxtstate = curstate;		
							nxtduration = duration;
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
		if(curstate == state_pass) begin
			$display("============================================================================");
			$display("\n \\(^o^)/ CONGRATULATIONS!!  The simulation result is PASS!!!\n");
			$display("============================================================================");
		end
	end
endmodule
