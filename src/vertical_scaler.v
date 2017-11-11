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
module vertical_scaler
			(
			clk_108m,
			rst_n,

			buf_flag,
			buf_rd_addr,
			buf_rd_rls,
			bufa_rd_data,
			bufb_rd_data,
			bufa_rden,
			//bufb_rden,

			out_fifo_alfull,

			buf_rden_delay,

			dout1,
			dout2,
			Kremain,
			v_synch,

			source_height,
			target_width,
			target_height,
			vertical_scaler
			);
/*******************************************************\
Parameter	declare
\*******************************************************/
parameter	U_DLY								= 1;
parameter FSM_IDLE						=	5'd1;
parameter	FSM_RD_BUF					= 5'd2;
parameter	FSM_CALC_PARA				= 5'd4;
parameter	FSM_JUDGE_BUF				= 5'd8;
parameter	FSM_TURN_AROUND			= 5'd16;

/*******************************************************\
Port declare
\*******************************************************/
input											  						clk_108m;
input																	  rst_n;
//
input	[1							   :0]						buf_flag;
output[9							   :0]						buf_rd_addr;

output[1							   :0]						buf_rd_rls;
input	[15							   :0]						bufa_rd_data;
input	[15							   :0]						bufb_rd_data;
output																  bufa_rden;
//
input																		v_synch;
input																	  out_fifo_alfull;
//
input [`IMGT_WIDTH - 1 :0]						target_width;
input	[`IMGT_HEIGHT - 1:0]						target_height;
input	[`IMGS_HEIGHT - 1 	 :0]  					source_height;
input	[7								 :0]						vertical_scaler;

output[15								 :0]						dout1;
output[15								 :0]						dout2;
output[7								 :0]						Kremain;
output																	buf_rden_delay;
/*******************************************************\
Signal declare
\*******************************************************/
reg		[4								:0]							curr_state;
reg		[1								:0]							buf_rd_rls;
reg																			out_fifo_wren;
reg		[15								:0]							out_fifo_wdata;

reg																			rd_ptr;
reg		[9								:0]							rd_pixel_cnt;

reg		[9:0]															buf_rd_addr;
reg																	bufa_rden;
/*******************************************************\
Main state machine
\*******************************************************/
reg																			v_synch_reg;
reg																			v_synch_reg0;
reg																			v_synch_negedge;
reg[8:0]																alpha;
always @( posedge  clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				v_synch_reg				<= 1'b0;
				v_synch_negedge		<= 1'b0;
				v_synch_reg0			<= 1'b0;
		end
		else
		begin
				v_synch_reg <= v_synch;
				v_synch_reg0<= v_synch_reg;
				if(( v_synch_reg0 == 1'b1 )&&( v_synch_reg == 1'b0 ))
				begin
						v_synch_negedge	<= 1'b1;
				end
				else
				begin
						v_synch_negedge	<= 1'b0;
				end
		end
end
//
reg[1:0]			cnt;
reg[4:0]			state_next;
//curr_state
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				curr_state		 <= FSM_IDLE;
		end
		else
		begin
				curr_state		 <= state_next;
		end
end
//state_next
always @(*)
begin
		case( curr_state )
		FSM_IDLE:
		begin
				if( v_synch_reg == 1'b1 )
				begin
						state_next 	= FSM_TURN_AROUND;
				end
				else if(( buf_flag == 2'b11 )&&( out_fifo_alfull == 1'b0 ))
				begin
						state_next 	= FSM_RD_BUF;
				end
				else
				begin
						state_next = FSM_IDLE;
				end
		end
		FSM_RD_BUF:
		begin
				if( rd_pixel_cnt > target_width - 1'b1 )
				begin
						state_next 		= FSM_CALC_PARA;
				end
				else
				begin
						state_next = FSM_RD_BUF;
				end
		end
		FSM_CALC_PARA:
		begin
				state_next 				= FSM_JUDGE_BUF;
		end
		FSM_JUDGE_BUF:
		begin
				state_next				= FSM_IDLE;
		end
		FSM_TURN_AROUND:
		begin
				if( v_synch_negedge == 1'b1 )
				begin
						state_next		= FSM_IDLE;
				end
				else
				begin
						state_next = FSM_TURN_AROUND;
				end
		end
		default:
		begin
		    state_next			= FSM_IDLE;
		end
		endcase
end
//buf_rd_rls
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				buf_rd_rls		 <= 2'b0;
		end
		else
		begin
				if(( curr_state == FSM_IDLE )&&( v_synch_reg == 1'b1 ))
				begin
						buf_rd_rls<=#U_DLY 2'b11;
				end
				else if (( curr_state == FSM_JUDGE_BUF )&&( alpha[8] == 1'b1 ))
				begin
						buf_rd_rls[rd_ptr]<=#U_DLY 1'b1;
				end
				else
				begin
						buf_rd_rls<=#U_DLY 2'b0;
				end

		end
end
//rd_ptr
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				rd_ptr		 <= 1'b0;
		end
		else
		begin
				if(( curr_state == FSM_IDLE )&&( v_synch_reg == 1'b1 ))
				begin
						rd_ptr<=#U_DLY 1'b0;
				end
				else if (( curr_state == FSM_JUDGE_BUF )&&( alpha[8] == 1'b1 ))
				begin
						rd_ptr	<=#U_DLY ~rd_ptr;
				end
		end
end
//alpha
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				alpha		 <= 9'b0;
		end
		else
		begin
				if(( curr_state == FSM_IDLE )&&( v_synch_reg == 1'b1 ))
				begin
						alpha					<=#U_DLY 9'b0;
				end
				else if ( curr_state == FSM_CALC_PARA )
				begin
						alpha					<=#U_DLY alpha	+ vertical_scaler;
				end
				else if(( curr_state == FSM_JUDGE_BUF )&&(  alpha[8] == 1'b1 ))
				begin
						alpha[8]			<=#U_DLY 1'b0;
				end
		end
end
//buf_rd_addr
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				buf_rd_addr		 <= 10'b0;
		end
		else
		begin
				if( curr_state == FSM_RD_BUF )
				begin
						buf_rd_addr<=#U_DLY rd_pixel_cnt;
				end
		end
end
//bufa_rden
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				bufa_rden		 <= 1'b0;
		end
		else
		begin
				if(( curr_state == FSM_RD_BUF )&&( rd_pixel_cnt <= target_width - 1'b1 ))
				begin
						bufa_rden					<=#U_DLY 1'b1;
				end
				else
				begin
						bufa_rden		 			<= 1'b0;
				end
		end
end
//rd_pixel_cnt
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				rd_pixel_cnt	 <= 10'b0;
		end
		else
		begin
				if(( curr_state == FSM_RD_BUF )&&( rd_pixel_cnt <= target_width - 1'b1 ))
				begin
						rd_pixel_cnt	<=#U_DLY rd_pixel_cnt + 1'b1;
				end
				else
				begin
						rd_pixel_cnt	<=#U_DLY 10'b0;
				end
		end
end
//
reg						buf_rden;
reg						buf_rden_delay0;
reg						buf_rden_delay1;
reg						buf_rden_delay;
reg						buf_rden_delay2;
reg						buf_rden_delay3;
always @ ( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				buf_rden				<= 1'b0;
				buf_rden_delay0	<= 1'b0;
				buf_rden_delay1	<= 1'b0;
				buf_rden_delay	<= 1'b0;
				buf_rden_delay2	<= 1'b0;
				buf_rden_delay3	<= 1'b0;
		end
		else
		begin
				buf_rden				<=#U_DLY bufa_rden;
				buf_rden_delay0	<=#U_DLY buf_rden;
				buf_rden_delay1	<=#U_DLY buf_rden_delay0;
				buf_rden_delay2	<=#U_DLY buf_rden_delay1;
				buf_rden_delay3	<=#U_DLY buf_rden_delay2;
				buf_rden_delay	<=#U_DLY buf_rden_delay2;
		end
end
reg	[15:0]			dout1;
reg	[15:0]			dout2;
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				dout1	<= 16'b0;
				dout2 <= 16'b0;
		end
		else
		begin
				if( buf_rden == 1'b1 )
				begin
						if( rd_ptr == 1'b0 )
						begin
								dout1	<= #U_DLY bufa_rd_data;
								dout2	<= #U_DLY bufb_rd_data;
						end
						else
						begin
								dout1	<= #U_DLY bufb_rd_data;
								dout2	<= #U_DLY bufa_rd_data;
						end
				end
		end
end
//
reg	[7:0]	Kremain;
always @( posedge clk_108m or negedge rst_n )
begin
		if( ~rst_n )
		begin
				Kremain	<= 8'b0;
		end
		else
		begin
				if( v_synch_reg == 1'b1 )
				begin
						Kremain	<=#U_DLY 8'b0;
				end
				else if( curr_state == FSM_IDLE )
				begin
						Kremain	<=#U_DLY alpha[7:0];
				end
		end
end
endmodule