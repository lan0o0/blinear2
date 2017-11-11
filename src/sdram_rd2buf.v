//*************************************************************************\
//Copyright (c) 2008, Lattice Semiconductor Co.,Ltd, All rights reserved
//
//                   File Name  :  xxx.v
//                Project Name  :  creator lattice
//                      Author  :  zhipeng
//                       Email  :  zhipeng.zhou@latticesemi.com
//                      Device  :  Lattice XP2 Family
//                     Company  :  Lattice Semiconductor Co.,Ltd
//==========================================================================
//   Description:  xxxx
//
//   Called by  :   XXXX.v
//==========================================================================
//   Revision History:
// Date    By   Revision Change Description
//--------------------------------------------------------------------------
//2008/5/30  zhipeng    0.5   Original
//*************************************************************************/
`include "mydefines.v"
`timescale 1ns / 1ps
module sdram_rd2buf
			 (
			 //Global signal
			 clk_108m,
			 rst_n,

			 //parameter define
			 source_width,
			 source_height,

			 target_width,
			 target_height,

			 vertical_scaler,
			 //
			 wr_pic_number,
			 rd_pic_number,

			 //sdram read opreation
			 rd_data,
			 rd_data_enable,
			 rd_data_end,

			 rd_req,
			 rd_data_length,
			 rd_addr_base,

			 v_synch,
			 fifo_clr,
			 //doual port ram		
			 buf_flag,
			 
			 bufa_wren,
			 bufb_wren,
			 buf_wrls,
			 bufa_wraddr,
			 bufb_wraddr,
			 bufa_wdata,
			 bufb_wdata
			 );
/********************************************\
Parameter Define
\********************************************/
parameter   									U_DLY										= 1;

parameter											FSM_IDLE								= 11'b000_0000_0001;
parameter											FSM_SENT_BANK0_RDREQ		= 11'b000_0000_0010;
parameter											FSM_RD_BANK0_DAT2BUF		= 11'b000_0000_0100;
parameter											FSM_SENT_BANK1_RDREQ		= 11'b000_0000_1000;
parameter											FSM_RD_BANK1_DAT2BUF		= 11'b000_0001_0000;
parameter											FSM_SENT_BANK2_RDREQ		= 11'b000_0010_0000;
parameter											FSM_RD_BANK2_DAT2BUF		= 11'b000_0100_0000;
parameter											FSM_SENT_BANK3_RDREQ		= 11'b000_1000_0000;
parameter											FSM_RD_BANK3_DAT2BUF		= 11'b001_0000_0000;
parameter											FSM_TURN_AROUND					= 11'b010_0000_0000;
parameter											FSM_TURN_AROUND0				= 11'b100_0000_0000;

/********************************************\
Port Declare
\********************************************/
//input	port
input													clk_108m;
input													rst_n;
input[`IMGS_WIDTH  - 1 	 :0]		source_width;
input[`IMGS_HEIGHT - 1 	 :0]		source_height;
input[`IMGT_WIDTH - 1  :0]		target_width;
input[`IMGT_HEIGHT -1  :0]		target_height;
input [7								 :0]  vertical_scaler;

input [1								 :0]  wr_pic_number;

input	[`SDR_DQ_WIDTH-1 :0]  	rd_data;
input													rd_data_enable;
input													rd_data_end;

input	[1:0]										buf_flag;
input													v_synch;
output												fifo_clr;
//output port
output[1								 :0]  rd_pic_number;
output											  rd_req;
output[8								 :0]  rd_data_length;
output[21								 :0]	rd_addr_base;

output												bufa_wren;
output												bufb_wren;
output[1								 :0]	buf_wrls;
output[9								 :0]  bufa_wraddr;
output[9								 :0]  bufb_wraddr;
output[15								 :0]	bufa_wdata;
output[15								 :0]	bufb_wdata;
/********************************************\
Signal Declare
\********************************************/
reg		[1								 :0] 	rd_pic_number;
reg														frame_end_flag;
reg														frame_switch_success;
reg		[10								 :0]	curr_state;
reg														rd_req;
reg		[8								 :0]  rd_data_length;
reg		[21								 :0]  rd_addr_base;

reg		[1								 :0]  buf_wrls;
//
reg		[9								 :0]  bufa_wraddr;
reg		[9								 :0]  bufb_wraddr;
reg		[15								 :0]  bufa_wdata;
reg		[15								 :0]  bufb_wdata;
reg														bufa_wren;
reg														bufb_wren;
//
reg		[9								 :0]  pic_row_cnt;
reg		[9								 :0]  pic_col_cnt;
reg		[9								 :0]  pic_col_cnt_dly0;
reg		[9								 :0]  pic_col_cnt_dly1;
reg														wr_ptr;
reg														v_synch_reg;
reg														v_synch_reg0;
reg														v_synch_posedge;

wire[1:0] rd_pic_number_int;
assign fifo_clr = v_synch_posedge;
always @( posedge  clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				v_synch_reg				<= 1'b0;
				v_synch_reg0			<= 1'b0;
				v_synch_posedge		<= 1'b0;
		end
		else
		begin
				v_synch_reg 	<= v_synch;
				v_synch_reg0 	<= v_synch_reg;
				if(( v_synch_reg0 == 1'b0 )&&( v_synch_reg == 1'b1 ))
				begin
						v_synch_posedge	<= 1'b1;
				end
				else
				begin
						v_synch_posedge		<= 1'b0;
				end
		end
end

	//rd_pic_number_int
	assign rd_pic_number_int[0] = pic_row_cnt[0];
	assign rd_pic_number_int[1] = rd_pic_number[1];
	//rd_pic_number
	always @ (posedge clk_108m or negedge rst_n) 
	begin
		if (~rst_n)
	 		begin
				rd_pic_number <= 2'b10;		//
			end
		else if(frame_end_flag == 1'b1)
			begin						
				rd_pic_number <= wr_pic_number+2'b10;
			end
	end
/*********************************************\
Generate frame_end_flag signal
\*********************************************/
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n)
		begin
				frame_end_flag  <= 1'b0;
		end
		else
		begin
				if( v_synch_posedge )
				begin
						frame_end_flag	<=#U_DLY 1'b1;
				end
				else
				begin
						frame_end_flag	<=#U_DLY 1'b0;
				end
		end
end
reg		frame_switch;
/*********************************************\
Read frame data from sdram
\*********************************************/
always @( posedge clk_108m or negedge rst_n )
begin
		if( ! rst_n )
		begin
				curr_state	  	<= FSM_IDLE;
				wr_ptr					<= 1'b0;
				rd_data_length	<= 9'h0;
				buf_wrls				<= 2'b0;
				rd_req					<= 1'b0;
				rd_addr_base		<= 22'b0;
				frame_switch		<= 1'b0;
		end
		else
		begin
				case( curr_state )
				FSM_IDLE:			//1
				begin
						buf_wrls							<= 2'b0;
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state						<= #U_DLY FSM_TURN_AROUND;
								wr_ptr								<= 1'b0;
								frame_switch					<= #U_DLY 1'b1;
						end
						else if( buf_flag[wr_ptr] == 1'b0 )//如果缓存准备好
						begin
								curr_state 				<= #U_DLY FSM_SENT_BANK0_RDREQ;
								rd_data_length 		<= #U_DLY 9'h100;
						end
				end
				FSM_SENT_BANK0_RDREQ: //2
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state						<= #U_DLY FSM_TURN_AROUND;
								frame_switch					<= #U_DLY 1'b1;
								wr_ptr								<= 1'b0;
						end
						else
						begin
								curr_state						<= #U_DLY FSM_RD_BANK0_DAT2BUF;
								rd_req								<= #U_DLY 1'b1;
								rd_addr_base					<= #U_DLY {rd_pic_number_int,pic_row_cnt[9:1],2'b00,8'b0};
						end
				end
				FSM_RD_BANK0_DAT2BUF:		//4
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state						<= #U_DLY	FSM_TURN_AROUND; 
								wr_ptr								<= 1'b0;
								rd_req								<= #U_DLY 1'b0;
								frame_switch					<= #U_DLY 1'b1;
						end
						else
						begin
								if( rd_data_enable == 1'b1 )
								begin
										rd_req						<= #U_DLY 1'b0;
								end
								if( pic_col_cnt == 10'hff )
								begin
										curr_state				<= #U_DLY	FSM_SENT_BANK1_RDREQ;
										rd_data_length 		<= #U_DLY 9'h100;
								end
						end
				end
				FSM_SENT_BANK1_RDREQ:	//8
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state				<= #U_DLY	FSM_TURN_AROUND;
								wr_ptr								<= 1'b0;
								frame_switch					<= #U_DLY 1'b1;
						end
						else
						begin
								rd_req								<= #U_DLY 1'b1;
								rd_addr_base					<= #U_DLY {rd_pic_number_int,pic_row_cnt[9:1],2'b01,8'b0};
								curr_state						<= #U_DLY FSM_RD_BANK1_DAT2BUF;
						end
				end
				//
				FSM_RD_BANK1_DAT2BUF:	//16
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state				<= #U_DLY	FSM_TURN_AROUND;
								rd_req						<= #U_DLY 1'b0;
								frame_switch					<= #U_DLY 1'b1;
								wr_ptr								<= 1'b0;
						end
						else
						begin
								if( rd_data_enable == 1'b1 )
								begin
										rd_req			<= #U_DLY 1'b0;
								end
								if( pic_col_cnt == 10'h1ff )
								begin
										if( target_width > 10'h200 && target_width < 10'h300 )
										begin
												rd_data_length 	<= #U_DLY target_width - 10'h200 ;
												curr_state	<= #U_DLY	FSM_SENT_BANK2_RDREQ;
										end
										else
										begin
												rd_data_length 	<= #U_DLY 9'h100;
												curr_state	<= #U_DLY	FSM_SENT_BANK2_RDREQ;
										end
								end
						end
				end
				FSM_SENT_BANK2_RDREQ:
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state				<= #U_DLY	FSM_TURN_AROUND;
								frame_switch					<= #U_DLY 1'b1; 
								wr_ptr								<= 1'b0;
						end
						else
						begin
								rd_req					<= #U_DLY 1'b1;
								rd_addr_base		<= #U_DLY {rd_pic_number_int,pic_row_cnt[9:1],2'b10,8'b0};
								curr_state			<= #U_DLY FSM_RD_BANK2_DAT2BUF;
						end
				end
				FSM_RD_BANK2_DAT2BUF:
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state				<= #U_DLY	FSM_TURN_AROUND;
								rd_req						<= #U_DLY 1'b0;
								frame_switch					<= #U_DLY 1'b1;
								wr_ptr								<= 1'b0;
						end
						else
						begin
								if( rd_data_enable == 1'b1 )
								begin
										rd_req					<= #U_DLY 1'b0;
								end
								if( pic_col_cnt == 10'h2ff && target_width > 10'h300 )
								begin
										curr_state			<= #U_DLY	FSM_SENT_BANK3_RDREQ;
										rd_data_length	<= #U_DLY target_width - 10'h300;
								end
								else if( pic_col_cnt == target_width - 1'b1 )
								begin
										rd_req					<= #U_DLY 1'b0;
										curr_state			<= #U_DLY FSM_TURN_AROUND;
								end
						end
				end
				FSM_SENT_BANK3_RDREQ:
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								rd_req					<= #U_DLY 1'b0;
								curr_state			<= #U_DLY FSM_TURN_AROUND;
								frame_switch					<= #U_DLY 1'b1;
								wr_ptr								<= 1'b0;
						end
						else
						begin
								rd_req					<= #U_DLY 1'b1;
								rd_addr_base		<= #U_DLY {rd_pic_number_int,pic_row_cnt[9:1],2'b11,8'b0};
								curr_state			<= #U_DLY FSM_RD_BANK3_DAT2BUF;
						end
				end
				FSM_RD_BANK3_DAT2BUF:
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								rd_req					<= #U_DLY 1'b0;
								curr_state			<= #U_DLY FSM_TURN_AROUND;
								frame_switch					<= #U_DLY 1'b1;
								wr_ptr								<= 1'b0;
						end
						else
						begin
								if( rd_data_enable == 1'b1 )
								begin
										rd_req			<= #U_DLY 1'b0;
								end
								if( pic_col_cnt == target_width - 1'b1 )
								begin
										curr_state	<= #U_DLY FSM_TURN_AROUND;
					  		end
					  end
				end
				FSM_TURN_AROUND:
				begin
						if( frame_switch == 1'b1 )
						begin
								wr_ptr					<= #U_DLY 1'b0;							
								frame_switch		<= #U_DLY 1'b0;
								buf_wrls				<= #U_DLY 2'b00;
						end
						else if( pic_row_cnt < source_height*2 - 1'b1 )
						begin
								wr_ptr					<= #U_DLY ~wr_ptr;
								buf_wrls[wr_ptr]<= #U_DLY 1'b1;
						end
						//else
						//begin
								//wr_ptr					<= #U_DLY ~wr_ptr;
								//buf_wrls				<= #U_DLY 2'b11;
						//end
						//
						if(  v_synch_posedge == 1'b1 )
						begin
								frame_switch	<= 1'b1;
						end
						else if( pic_row_cnt < source_height*2 - 1'b1)
						begin
								curr_state			<= #U_DLY FSM_IDLE;
						end
						else
						begin
								curr_state			<= #U_DLY FSM_TURN_AROUND0;
						end
				end
				FSM_TURN_AROUND0:
				begin						
						if( v_synch_posedge == 1'b1 )
						begin
								curr_state			<= #U_DLY FSM_IDLE;
								buf_wrls				<= #U_DLY 2'b00;
								wr_ptr					<= #U_DLY 1'b0;
						end
						else
						begin
								buf_wrls						<= #U_DLY 2'b0;
						end
				end
				//
				default:
				begin
						curr_state 	<=#U_DLY FSM_IDLE;
						rd_req			<=#U_DLY 1'b0;
				end
				endcase
		end
end
/***********************************************\
Generate the row counter
\***********************************************/
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~ rst_n )
		begin
				pic_row_cnt <= 10'h0;
		end
		else
		begin
				if( v_synch_posedge == 1'b1 )
				begin
						pic_row_cnt <=#U_DLY 10'h0;
				end
				else if(( curr_state == FSM_TURN_AROUND )&&( frame_switch == 1'b0 ))
				begin
						pic_row_cnt <=#U_DLY pic_row_cnt + 1'b1;
				end
		end
end
/***********************************************\
Generate the col counter
\***********************************************/
always @(posedge clk_108m or negedge rst_n )
begin
		if( ~ rst_n )
		begin
		    pic_col_cnt <= 10'b0;
		end
		else
		begin
				if((pic_col_cnt == target_width - 1'b1)||( v_synch_posedge == 1'b1 ))
				begin
				    pic_col_cnt <=#U_DLY 10'b0;
				end
				else if(( rd_data_enable == 1'b1)&&( curr_state == FSM_RD_BANK0_DAT2BUF
				        | curr_state == FSM_RD_BANK1_DAT2BUF | curr_state == FSM_RD_BANK2_DAT2BUF
				        | curr_state == FSM_RD_BANK3_DAT2BUF ))
				begin
						pic_col_cnt <=#U_DLY pic_col_cnt + 1'b1;
				end
		end
end
//
always @( posedge clk_108m or negedge rst_n)
begin
		if( ~ rst_n )
		begin
				pic_col_cnt_dly0	<= 10'b0;
				pic_col_cnt_dly1	<= 10'b0;
		end
		else
		begin
				pic_col_cnt_dly0	<= pic_col_cnt;
				pic_col_cnt_dly1	<= pic_col_cnt_dly0;
		end
end
/***********************************************\
Read data to buf
\***********************************************/
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~ rst_n )
		begin
				bufa_wraddr		<=	10'b0;
				bufb_wraddr		<=	10'b0;
				bufa_wren			<=  1'b0;
				bufb_wren			<=  1'b0;
				bufa_wdata		<=  16'b0;
				bufb_wdata		<=  16'b0;
		end
		else
		begin
		    if( curr_state == FSM_RD_BANK0_DAT2BUF
		    	| curr_state == FSM_RD_BANK1_DAT2BUF
		    	| curr_state == FSM_RD_BANK2_DAT2BUF
		    	| curr_state == FSM_RD_BANK3_DAT2BUF )
			  begin
			  		if( wr_ptr == 1'b0 )
			  		begin
			  				bufa_wraddr		<=#U_DLY	pic_col_cnt;
			  				bufa_wren			<=#U_DLY  rd_data_enable;
			  				bufa_wdata		<=#U_DLY  rd_data;
			  		end
			  		else
			  		begin
			  				bufb_wraddr		<=#U_DLY	pic_col_cnt;
			  				bufb_wren			<=#U_DLY  rd_data_enable;
			  				bufb_wdata		<=#U_DLY  rd_data;
			  		end
			  end
			  else
			  begin
			  		bufa_wren		<=#U_DLY 	1'b0;
			  		bufb_wren		<=#U_DLY 	1'b0;
			  end
		end
end
endmodule