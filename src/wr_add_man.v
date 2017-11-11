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
module wr_add_man(
	//system
	input rst,
	input clk,	//100-133M
	//data in
	input data_req,
	output reg data_ack,
	output data_ren,
	output [`IMGT_WIDTH-1:0] data_address,
	input datain_frame_end,
	input ev_odd,
	//burst_control
	output reg burst_req,
	output reg [`BURST_LENGTH-1:0] burst_length,
	output [`BURST_ADD_LENGTH-1:0] burst_address,
	input burst_ack,
	input burst_holda,
	//config
	input[1:0] rd_pic_number,
	output reg[1:0] wr_pic_number,
	input[`IMGS_HEIGHT-1:0] source_height,
	input[`IMGT_WIDTH-1:0] target_width
		 );
	parameter   IDLE         = 3'h1;
	parameter   BURST_REQ   = 3'h2;
	parameter   BURST_DATA   = 3'h4;

	//variable
	wire process_finish;
	wire [2:0] burst_time;
	wire datain_frame_end_rising;
	wire field_falling;

	reg [2:0] state_cur,state_next;
	reg [`IMGS_WIDTH-1:0] source_num;
	reg [2:0] burst_num;
	reg [`IMGS_HEIGHT-1:0] burst_line_num;
	reg burst_ack_d1;
	reg [`IMGT_WIDTH-1:0] data_address_pre;
	reg datain_frame_end_d1,datain_frame_end_d2;
	reg field_d1,field_d2;
	//components

	//constant assign
	assign data_address = (burst_holda)?data_address_pre+1'b1:data_address_pre;
	assign burst_time = target_width[9:8]+1'b1;
	assign process_finish = (burst_num >=burst_time)?1'b1:1'b0;
	assign burst_address = {1'b0,wr_pic_number,burst_line_num,burst_num[1:0],8'h00};
	assign data_ren = burst_holda;

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
	    or data_req
	    or burst_ack
	    or process_finish
		)
	begin
	    case(state_cur)
	    IDLE:
	        begin
	            if(data_req == 1'b1)
	                begin
	                    state_next = BURST_REQ;
	                end
	            else
	                begin
	                    state_next = IDLE;
	                end
	        end
	    BURST_REQ:
	        begin
	        	if(burst_ack == 1'b1)
	                begin
	                    state_next = BURST_DATA;
	                end
	            else
	                begin
	                    state_next = BURST_REQ;
	                end
	        end
	    BURST_DATA:
	        begin
	            if(process_finish == 1'b1)
	                begin
	                    state_next = IDLE;
	                end
	            else
	                begin
	                    state_next = BURST_DATA;
	                end
	        end
	    default:
	        begin
	            state_next = IDLE;
	        end
	    endcase
	end
	//always block
	//data_ack 
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				data_ack <= 0;		//
			end
		else if(state_cur == IDLE && state_next == BURST_REQ)
	 		begin						
				data_ack <= 1'b1;	//
			end
		else
			begin						
				data_ack <= 1'b0;	//
			end
	end
	//burst_req
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_req <= 0;		//
			end
		else if(state_cur == BURST_REQ)
	 		begin						
				burst_req <= 1'b1;
			end
		else if(process_finish == 1'b1)
	 		begin						
				burst_req <= 1'b0;
			end
	end
	//data_address_pre
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				data_address_pre <= 0;		//
			end
		else if(burst_holda)
	 		begin						
				data_address_pre <= data_address_pre + 1'b1;
			end
		else if(state_cur == BURST_REQ)
	 		begin						
				data_address_pre <= 0;
			end
	end

	//burst_num
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_num <= 0;		//
			end
		else if(burst_ack == 1'b1)
	 		begin						
				burst_num <= burst_num + 1;	//
			end
		else if(burst_num >=burst_time)
			begin						
				burst_num <= 0;	//
			end
	end
	
	//wr_pic_number
	/*
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				wr_pic_number <= 0;		//
			end
		else if(datain_frame_end_rising == 1'b1 && wr_pic_number != rd_pic_number + 2'b11)
			begin						
				wr_pic_number <= wr_pic_number + 2'b01;	//
			end
	end
	*/
	
	//wr_pic_number
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				wr_pic_number[0] <= 0;		//
			end
		else
			begin						
				wr_pic_number[0] <= ev_odd;	//
			end
	end
  always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				wr_pic_number[1] <= 0;		//
			end
		else if(field_falling == 1'b1)
			begin						
				wr_pic_number[1] <= !wr_pic_number[1];	//
			end
	end
	//burst_line_num
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_line_num <= 0;		//
			end
		else if(burst_ack_d1 == 1 && burst_num >=burst_time && burst_line_num <= source_height)
	 		begin						
				burst_line_num <= burst_line_num + 1'b1;	//
			end
		else if(datain_frame_end_d2)
			begin						
				burst_line_num <= 0;	//
			end
	end

	//burst_length
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_length <= 9'h100;		//
			end
		else if(burst_ack_d1 == 1)
	 		begin						
				burst_length <= (burst_num>=burst_time-1)?{1'b0,target_width[7:0]}:9'h100;	//
			end
	end
	//burst_ack_d1
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				burst_ack_d1 <= 0;		//
			end
		else if(burst_ack == 1)
	 		begin						
				burst_ack_d1 <= burst_ack;
			end
	end
	//frame end rising detect
	assign datain_frame_end_rising = datain_frame_end_d1 & !datain_frame_end_d2;
	//ping pang write control
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin					// 
				datain_frame_end_d1 <= 0;
				datain_frame_end_d2 <= 0;
			end
		else
	 		begin					// 
				datain_frame_end_d1 <= datain_frame_end;		//
				datain_frame_end_d2 <= datain_frame_end_d1;
			end
	end
	assign field_falling = field_d2 & !field_d1;
	//field_d1,field_d2
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin					// 
				field_d1 <= 0;
				field_d2 <= 0;
			end
		else
	 		begin					// 
				field_d1 <= ev_odd;		//
				field_d2 <= field_d1;
			end
	end
endmodule
