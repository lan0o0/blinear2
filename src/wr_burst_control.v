//*************************************************************************\
//Copyright (c) 2010, BJTech Co.,Ltd, All rights reserved
//
//                   File Name  :  xxx.v
//                Project Name  :  XZ8000
//                      Author  :  cloud
//                       Email  :  BJTech@126.com
//                      Device  :  Altera Cyclone Family
//                     Company  :  BJTech Co.,Ltd,
//==========================================================================
//   Description:  xxxx
//
//   Called by  :   XXXX.v
//==========================================================================
//   Revision History:
//	Date		  By			Revision	Change Description
//--------------------------------------------------------------------------
//2010/3/12	 Cloud		   1.0			Original
//*************************************************************************/
`include "mydefines.v"
module wr_burst_control(
	//system
	input rst,
	input clk,	//100-133M
	//fifo control
	output 		fifo_ren   ,
	input [`IN_DATA_WIDTH-1:0]   fifo_rdata ,
	input          fifo_empty ,
	input          fifo_afull ,
	//burst_control
	input [`BURST_LENGTH-1:0] fifo_burst_length,
	input [`BURST_ADD_LENGTH-1:0] fifo_burst_address,
	output reg fifo_burst_ack,
	//ram controller
	output reg hold,
	output reg [`BURST_LENGTH-1:0] burst_length,
	output reg [`BURST_ADD_LENGTH-1:0] burst_address,
	output reg [`SDR_DQ_WIDTH-1:0]	burst_data,
	input  holda,
	//debug
	output error
		 );
	parameter   IDLE        = 3'h1;
	parameter   REQ   	= 3'h2;
	parameter   BURST   	= 3'h4;


	//variable
	wire burst_finish;
	reg [2:0] state_cur,state_next;


	//components

	//constant assign
	assign burst_finish = (burst_length == 1);
	assign fifo_ren = (state_next == BURST)||(state_cur == BURST);
	//=====================================================
	//state machine
	always @(posedge clk or posedge rst)
	begin
	    if(rst == 1'b1)
	        begin
	            state_cur <= IDLE;
	        end
	    else
	        begin
	            state_cur <= state_next;
	        end
	end
	
	always @(state_cur
	    or fifo_empty
	    or burst_finish
	    or holda
		)
	begin
	    case(state_cur)
	    IDLE:
	        begin
	            if(fifo_empty == 1'b0)
	                begin
	                    state_next = REQ;
	                end
	            else
	                begin
	                    state_next = IDLE;
	                end
	        end
	    REQ:
	        begin
	            if(holda == 1'b1)
	                begin
	                    state_next = BURST;
	                end
	            else
	                begin
	                    state_next = REQ;
	                end
	        end
	    BURST:
	        begin
	            if(burst_finish == 1'b1)
	            	begin
	                    state_next = IDLE;
	                end
	            else
	                begin
	                    state_next = BURST;
	                end
	        end
	    default:
	        begin
	            state_next = IDLE;
	        end
	    endcase
	end
	//==================================================================
	//always block
	//burst_length 
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_length <= 0;		//
			end
		else if(state_cur == IDLE)
	 		begin						
				burst_length <= fifo_burst_length;	//
			end
		else if(state_next == BURST || state_cur == BURST)
			begin						
				burst_length <= burst_length - 1;	//
			end
	end
	//burst_address 
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_address <= 0;		//
			end
		else if(state_cur == IDLE)
	 		begin						
				burst_address <= fifo_burst_address;	//
			end
	end
	//burst_data
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_data <= 0;		//
			end
		else
	 		begin						
				burst_data <= fifo_rdata[`SDR_DQ_WIDTH-1:0];	//
			end
	end
	//hold
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				hold <= 0;		//
			end
		else if(state_next == REQ)
	 		begin						
				hold <= 1'b1;	//
			end
		else if(state_next == IDLE || holda == 1'b0)
	 		begin						
				hold <= 1'b0;	//
			end
	end
	//fifo_burst_ack
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				fifo_burst_ack <= 0;		//
			end
		else if(state_cur == IDLE && state_next == REQ)
	 		begin						
				fifo_burst_ack <= 1'b1;	//
			end
		else
	 		begin						
				fifo_burst_ack <= 1'b0;	//
			end
	end
endmodule
