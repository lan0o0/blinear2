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
module vin_pro(
	//system
	input rst,
	input user_clk,	//27MHz
	input sys_clk,	//100-133M
	//video in BT.601 in
	input[`PRECISION-1:0] data_in,
	input Hi,Vi,Fi,
	//data out
	output hold,
	output [`BURST_LENGTH-1:0] burst_length,
	output [`BURST_ADD_LENGTH-1:0] burst_address,
	output [`IN_DATA_WIDTH-1:0] burst_data,
	input  holda,
	//config
	input[`IMGS_WIDTH-1:0] source_width,
	input[`IMGS_HEIGHT-1:0] source_height,
	input[`IMGT_WIDTH-1:0] target_width,
	input[`IMGT_HEIGHT-1:0] target_height,
	input[1:0] rd_pic_number,
	output[1:0] wr_pic_number
	
		 );
	//variable
	wire H_rising;
	wire fifo_ren;
	wire [`IN_DATA_WIDTH-1:0]   fifo_rdata1,buf_data;
	wire burst_req;
	wire [`IMGS_WIDTH-1:0]data_address;
	wire [`BURST_LENGTH-1:0] fifo_burst_length;
	wire [`BURST_ADD_LENGTH-1:0] fifo_burst_address;
	wire fifo_burst_ack;
	wire data_ack;


	//burst_control
	
	reg Hi_d1,Hi_d2;
	reg line_finish;
	reg [`IMGS_WIDTH:0]		pixel_count;	// counts the pixels in a line
	
	//constant assign
	assign buf_data = fifo_rdata1;

	//components altera
	dpe_1r1w_2048x8_1024x16b U_buf1 (
	.data(data_in),
	.rdaddress(data_address),
	.rdclock(sys_clk),
	.wraddress(pixel_count),
	.wrclock(user_clk),
	.wren(!Hi),
	.q(fifo_rdata1));
	//components lattice
	/*
   dpe_1r1w_2048x8_1024x16b U_buf1 (
	   .WrAddress(pixel_count ), 
	   .RdAddress(data_address ), 
	   .Data(data_in ), 
	   .RdClock(sys_clk ), 
	   .RdClockEn(1'b1 ), 
	   .Reset(rst ), 
	   .WrClock(user_clk ), 
	   .WrClockEn(1'b1 ), 
	   .WE(!Hi ), 
	   .Q(fifo_rdata1 )
   );
*/
    
wr_add_man U_wr_add_man(
	//system
	.rst(rst),
	.clk(sys_clk),	//100-133M
	//data in
	.data_req(line_finish),
	.data_ack(data_ack),
	.data_ren(),
	.data_address(data_address),
	.datain_frame_end(Vi),
	.ev_odd(Fi),
	//burst_control
	.burst_req(burst_req),
	.burst_length(fifo_burst_length),
	.burst_address(fifo_burst_address),
	.burst_ack(fifo_burst_ack),
	.burst_holda(fifo_ren),
	//config
	.rd_pic_number(rd_pic_number),
	.wr_pic_number(wr_pic_number),
	.source_height(source_height),
	.target_width(target_width)
		 );

	wr_burst_control U_wr_burst_control(
	//system
	.rst(rst),
	.clk(sys_clk),	//100-133M
	//fifo control
	.fifo_ren   (fifo_ren),
	.fifo_rdata (buf_data),
	.fifo_empty (!burst_req),
	.fifo_afull (),
	//burst_control
	.fifo_burst_length(fifo_burst_length),
	.fifo_burst_address(fifo_burst_address),
	.fifo_burst_ack(fifo_burst_ack),
	//ram controller
	.hold(hold),
	.burst_length(burst_length),
	.burst_address(burst_address),
	.burst_data(burst_data),
	.holda(holda),
	//debug
	.error()
		 );

//=======================================================
	//always block
	// CREATE THE HORIZONTAL LINE PIXEL COUNTER
	always @ (posedge user_clk or posedge rst) 
	begin
		if (rst)
	 		begin					// on reset set pixel counter to 0
				pixel_count <= 0;
			end
	
		else if (Hi)
	 		begin					// last pixel in the line
				pixel_count <= 0;		// reset pixel counter
			end
	
		else if(pixel_count <= source_width*2)	
			begin
				pixel_count <= pixel_count +1;		
			end
	end
	//H delay
	always @ (posedge sys_clk or posedge rst) 
	begin
		if (rst)
	 		begin				// 
				Hi_d1 <= 0;
				Hi_d2 <= 0;
			end
		else
	 		begin				// 
				Hi_d1 <= Hi;		// 
				Hi_d2 <= Hi_d1;
			end
	end
	//rising detect
	assign H_rising = Hi_d1 & !Hi_d2;
	// Line store finish
	always @ (posedge sys_clk or posedge rst) 
	begin
		if (rst)
	 		begin					// 
				line_finish <= 0;
			end
	
		else if(H_rising)
	 		begin					// 
				line_finish <= 1;		//
			end
		else if(data_ack)
			begin					// 
				line_finish <= 0;
			end
	end
endmodule

