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
//2010/3/19	 Cloud		   1.1			Original
//*************************************************************************/

`timescale 1ns/1ps	//for simulation
`include "mydefines.v"	//sdram parameters
module sdram_if	//sdram controller
				(
        //  system
				input  													RST,	//reset signal,high for reset
				input  													CLK,	//clock 80-133MHz

				//  initial
				input                           INIT_WAIT_200_i,	//200us delay for initial
				//  write
				input  			  	WR_RQ_i,		 //  write request
				input  [`SDR_DQ_WIDTH-1    : 0] WR_DATA_i,       //  write data
				//input  													WR_DATA_EN_i,    //  write data enable
				input  [`BURST_LEN_WIDTH-1 : 0] WR_DATA_LEN_i,   //  write data length, ahead of WR_RQ_i
				input  [`BASE_ADDR_WIDTH-1 : 0] WR_ADDR_BASE_i,  //  write base address of sdram write buffer
				output 			WR_DATA_RQ_o,    //  wrtie data request, 2 clock ahead
				output reg 		WR_DATA_EN_o,    //  write data enable now
				output  		WR_DATA_END_o,   //  write data is end
                //  read
				input                           RD_RQ_i,		 //  read request
				input  [`BURST_LEN_WIDTH-1 : 0] RD_DATA_LEN_i,   //  read data length, ahead of RD_RQ_i
				input  [`BASE_ADDR_WIDTH-1 : 0] RD_ADDR_BASE_i,  //  read base address of sdram read buffer
				output [`SDR_DQ_WIDTH-1    : 0] RD_DATA_o,       //  read data to internal
				output 			                		RD_DATA_EN_o,    //  read data enable (valid)
				output 			                		RD_DATA_END_o,	 //  read data is end

                //  sdram interface
				output [`SDR_CLK_WIDTH-1   : 0]	SDRAM_CLK_o,	//sdram chip clock
				output [`SDR_CKE_WIDTH-1   : 0]	SDRAM_CKE_o,	//clock enable
				output [`SDR_CSn_WIDTH-1   : 0]	SDRAM_CSn_o,	//chip select
				output  	                    	SDRAM_RASn_o,	//row select
				output 													SDRAM_CASn_o,	//colum select
				output 													SDRAM_WEn_o,	//write enable 
				output [`SDR_BA_WIDTH-1    : 0] SDRAM_BA_o,	//bank address
				output [`SDR_A_WIDTH-1     : 0] SDRAM_A_o,	//address
				output [`SDR_DQM_WIDTH-1   : 0] SDRAM_DQM_o,	//data mask
				inout  [`SDR_DQ_WIDTH-1    : 0]	SDRAM_DQ_io	//data
				);

//===============================================================  signal declaration
//  WR/RD request latch
reg            																	WR_RQ_i_latch;	//wirite request signal latch
reg            																	RD_RQ_i_latch;	//read request signal latch

//  sdram initialization opcode
wire  [`SDR_A_WIDTH-1    : 0] 									opcode;	//sdram initial peration code
//  sdram initialization time 200us     				
wire           																	init_wait_200;//200us delay for initial
//  sdram initialization autorefresh 8 t				imes
reg   [ 3 : 0] 																	init_ref_cnt;//sdram refresh count
                                        				
//  time gap for sdram operation        				
reg   [ 2 : 0] 																	time_tRP_cnt;	//prechard counter
reg   [ 2 : 0] 																	time_tRC_cnt;	//colum delay counter
reg   [ 2 : 0] 																	time_tMRD_cnt;	//mode register write counter
reg   [ 2 : 0] 																	time_tRCD_cnt;	//read colum delay counter
// reg   [ 2 : 0] time_tWR_cnt;         				
wire		   																			time_is_tRP;	//tRP arrive
wire 		   																			time_is_tRC;	//tRP arrive
wire 	  	   																		time_is_tMRD;		//tMRD arrive
wire 		   																			time_is_tRCD;	//tRCD arrive
// wire 		   time_is_tWR;             				
wire           																	ref_8_times;	//repeat 8 times
                                        				
//  actural burst length                				
reg  [`BURST_LEN_WIDTH-1 : 0] 										wr_bst_acu_len;//  actural burst length  
reg  [`BURST_LEN_WIDTH-1 : 0] 										rd_bst_acu_len;//  actural burst length  
//  counter for number of WR/RD         				
reg   [`BURST_LEN_WIDTH-1 : 0] 										wr_bst_len_cnt;//  count burst length
reg   [`BURST_LEN_WIDTH-1 : 0] 										rd_bst_len_cnt;//  count burst length

//  counting to LENGTH
wire           																	wr_cnt_is_LEN;	//write counter
wire           																	rd_cnt_is_LEN;	//read counter
reg            																	wr_cnt_is_LEN_latch;	//write counter latch
reg            																	rd_cnt_is_LEN_latch;	//read counter latch
//  sdram page end
wire           																	page_end;	//sdram one page end

//  sdram IF signals
reg   [`BASE_ADDR_WIDTH-`SDR_COL_WIDTH-1: 0] 		sdr_row_addr;	//row address
reg   [`SDR_COL_WIDTH-1  : 0] 									sdr_col_addr;	//colum address
reg   [`SDR_COL_WIDTH-1  : 0] 									sdr_col_addr_d;	//colum address delay 1 clock
reg   [`SDR_COL_WIDTH-1  : 0] 									sdr_col_addr_d2;//colum address delay 2 clock

wire  [`SDR_CLK_WIDTH-1  : 0] 									sdr_CLK;	//sdram clock
reg            				  												sdr_A10;	//sdram A10 control
wire  [`SDR_CKE_WIDTH-1  : 0] 									sdr_CKE;	//clock enable
wire  [`SDR_CSn_WIDTH-1  : 0] 									sdr_CSn;	//chip select
reg            				  												sdr_RASn;	//row select
reg            			 	  												sdr_CASn;	//colum select
reg            				  												sdr_WEn;	//write enable
wire  [`SDR_BA_WIDTH-1   : 0] 									sdr_BA;	//bank address
reg   [`SDR_A_WIDTH-1    : 0] 									sdr_A;	//address
wire  [`SDR_DQ_WIDTH-1   : 0] 									sdr_DQ;	//data


//  delay signal for SDRAM IF data
reg            																	sdr_wr_en_d;
reg            																	sdr_rd_en_d;
reg            																	sdr_rd_en_d2;
reg            																	sdr_rd_en_d3;
reg            																	sdr_rd_en_d4;


//  write/read frame end latch
reg            																	wr_data_end_latch;
reg            																	rd_data_end_latch;

//  delay of RD_DATA_EN_o / WR_DATA_RQ_o
reg           																	WR_DATA_RQ_o_d;
reg           																	RD_DATA_EN_o_d;



//  SDRAM IF state machine code
parameter S_IDLE     	 		= 'h00001;	//no operation
parameter S_INIT_PRE     	= 'h00002;		//prepare initial
parameter S_INIT_PRE_NOP 	= 'h00004;		//nop time
parameter S_INIT_REF 	 		= 'h00008;	//init refesh operation
parameter S_INIT_REF_NOP 	= 'h00010;		//nop after refesh
parameter S_MRS      	 		= 'h00020;	//mode register load
parameter S_MRS_NOP  	 		= 'h00040;	//nop after load
parameter S_IDLE_REF 	 		= 'h00080;	//IDLE after refresh
parameter S_IDLE_REF_NOP 	= 'h00100;		//nop operation
parameter S_WR_ACT   	 		= 'h00200;	//write active bank
parameter S_WR_ACT_NOP   	= 'h00400;		//nop after active
parameter S_RD_ACT   	 		= 'h00800;	//read active
parameter S_RD_ACT_NOP  	= 'h01000;		//nop after read
parameter S_WR_COL   	 		= 'h02000;	//write colum address
parameter S_RD_COL   	 		= 'h04000;	//read colum address
parameter S_WR_END   	 		= 'h08000;	//write finish
parameter S_PRE      	 		= 'h10000;	//prepare
parameter S_PRE_NOP  	 		= 'h20000;	//nop after prepare

//  state machine delay, wr_data_rq is 1 clock ahead,
//  wr_data from outside shoule be valid 2 clock later
reg   [17 : 0] 						sdr_state;
reg   [17 : 0] 						sdr_state_d;
reg   [17 : 0] 						sdr_state_d2;


//===============================================================  implementation
//-----------------------------------------------  opcode
assign opcode = `OPCODE;//operation code load to sdram mode register
reg		priority_judge0;
reg		priority_judge1;
//-----------------------------------------------  sdr_state
always @(posedge CLK or posedge RST)
begin
		if (RST)	//wait reset
		begin
				sdr_state 			<= S_IDLE;	//idle after power up
				//priority_judge0	<=	1'b1;
				//priority_judge1 <= 	1'b0;
		end
		else
		begin
				case ( sdr_state )
				S_IDLE :
				begin
						if (init_wait_200)	//wait 200us
							sdr_state <= S_INIT_PRE;
						else
							sdr_state <= S_IDLE;
				end
				//  initialization precharge
				S_INIT_PRE :
				begin
					 	sdr_state <= S_INIT_PRE_NOP;
				end
				S_INIT_PRE_NOP :	//refresh some time
				begin
						if (time_is_tRP)
							sdr_state <= S_INIT_REF;
						else
							sdr_state <= S_INIT_PRE_NOP;
				end
				//  initialization autorefresh 8 times
				S_INIT_REF :
				begin
						sdr_state <= S_INIT_REF_NOP;
				end
				S_INIT_REF_NOP :
				begin
						if (time_is_tRC & ref_8_times)
							sdr_state <= S_MRS;
						else if (time_is_tRC)
							sdr_state <= S_INIT_REF;
						else
							sdr_state <= S_INIT_REF_NOP;
				end
				//  initialization mode register set
				S_MRS :
				begin
						sdr_state <= S_MRS_NOP;
				end
				S_MRS_NOP :
				begin
						if (time_is_tMRD)
							sdr_state <= S_IDLE_REF;
						else
							sdr_state <= S_MRS_NOP;
				end
				//  normal autorefresh
				S_IDLE_REF :
				begin
						sdr_state <= S_IDLE_REF_NOP;
				end
				S_IDLE_REF_NOP :	//idle for read and write
				begin
						if (time_is_tRC & WR_RQ_i_latch )
						begin
								sdr_state 			<= S_WR_ACT;
								//priority_judge0	<= ~ priority_judge0;
						end 
						else if (time_is_tRC & RD_RQ_i_latch)
						begin
								sdr_state 			<= S_RD_ACT;
								//priority_judge0	<= ~ priority_judge0;
						end 
						else if (time_is_tRC)
							sdr_state <= S_IDLE_REF;
						else
						begin
								sdr_state <= S_IDLE_REF_NOP;
								//priority_judge0	<= ~ priority_judge0;
						end
				end
				//  write active
				S_WR_ACT :
				begin
						sdr_state <= S_WR_ACT_NOP;
				end
				//  read active
				S_RD_ACT :
				begin
						sdr_state <= S_RD_ACT_NOP;
				end
				S_WR_ACT_NOP :
				begin
						if (time_is_tRCD)
							sdr_state <= S_WR_COL;
						else
							sdr_state <= S_WR_ACT_NOP;
				end
				S_RD_ACT_NOP :
				begin
						if (time_is_tRCD)
							sdr_state <= S_RD_COL;
						else
							sdr_state <= S_RD_ACT_NOP;
				end
				//  write column address
				S_WR_COL :
				begin
						if (wr_cnt_is_LEN | page_end)
							sdr_state <= S_WR_END;
						else
							sdr_state <= S_WR_COL;
				end
				//  read column address
				S_RD_COL :
				begin
						if (rd_cnt_is_LEN | page_end)
							sdr_state <= S_PRE;
						else
							sdr_state <= S_RD_COL;
				end
				S_WR_END :
				begin
						sdr_state <= S_PRE;
				end
				//  page_end or w/r end precharge
				S_PRE :
				begin
						sdr_state <= S_PRE_NOP;
				end
				S_PRE_NOP :
				begin
						if (time_is_tRP & (rd_cnt_is_LEN_latch|wr_cnt_is_LEN_latch))
							sdr_state <= S_IDLE_REF;
						else if(WR_RQ_i_latch )
						begin
								sdr_state 			<= S_WR_ACT;
								//priority_judge1	<= ~ priority_judge1;
						end
						else if(RD_RQ_i_latch )
						begin
								sdr_state 			<= S_RD_ACT;
								//priority_judge1	<= ~ priority_judge1;
						end
						else
						begin
								//priority_judge1	<= ~ priority_judge1;
								sdr_state 			<= S_PRE_NOP;
						end
				end
				default :
					sdr_state <= S_IDLE;
				endcase
		end
end

//-----------------------------------------------   delay sdr_state
always @(posedge CLK or posedge RST)
begin
		if (RST) 
		begin
				sdr_state_d  <= 0;
				sdr_state_d2 <= 0;
		end
		else 
		begin
				sdr_state_d  <= sdr_state;
				sdr_state_d2 <= sdr_state_d;
		end
end

//-----------------------------------------------  init_ref_cnt
always @(posedge CLK or posedge RST)
begin
		if (RST)
			init_ref_cnt <= 0;
		else if (~ref_8_times & sdr_state == S_INIT_REF)
			init_ref_cnt <= init_ref_cnt + 1;
end

//-----------------------------------------------  init_wait_200
assign init_wait_200 = INIT_WAIT_200_i;

//-----------------------------------------------  ref_8_times
assign ref_8_times   = init_ref_cnt[3];


//-----------------------------------------------  WR_RQ_i_latch
always @(posedge CLK or posedge RST)
begin
		if (RST)
			WR_RQ_i_latch <= 0;
		else
			if (wr_cnt_is_LEN_latch & sdr_state == S_PRE)
				WR_RQ_i_latch <= 0;
			else if (WR_RQ_i && sdr_state == S_IDLE_REF)
				WR_RQ_i_latch <= 1;
end

//-----------------------------------------------  RD_RQ_i_latch
always @(posedge CLK or posedge RST)
begin
		if (RST)
			RD_RQ_i_latch <= 0;
		else
			if (rd_cnt_is_LEN_latch & sdr_state == S_PRE)
				RD_RQ_i_latch <= 0;
			else if (RD_RQ_i && sdr_state == S_IDLE_REF)
				RD_RQ_i_latch <= 1;
end


/////////////////////////////////////////////////////////////////
//-----------------------------------------------  time_tRP_cnt (precharge)
always @(posedge CLK or posedge RST)
begin
	if (RST)
		time_tRP_cnt <= 0;
	else
		if (time_is_tRP)
			 time_tRP_cnt <= 0;
		else if (sdr_state == S_INIT_PRE || sdr_state == S_INIT_PRE_NOP ||
		         sdr_state == S_PRE || sdr_state == S_PRE_NOP)
			time_tRP_cnt <= time_tRP_cnt + 1;
end

assign time_is_tRP = (time_tRP_cnt == `tRP-1);

//-----------------------------------------------  time_tRC_cnt (refresh)
always @(posedge CLK or posedge RST)
begin
		if (RST)
			time_tRC_cnt <= 0;
		else
			if (time_is_tRC)
				time_tRC_cnt <= 0;
			else if (sdr_state == S_INIT_REF || sdr_state == S_INIT_REF_NOP ||
					 sdr_state == S_IDLE_REF || sdr_state == S_IDLE_REF_NOP)
				time_tRC_cnt <= time_tRC_cnt + 1;
end

assign time_is_tRC = (time_tRC_cnt == `tRC-1);

//-----------------------------------------------  time_tMRD_cnt (mode set)
always @(posedge CLK or posedge RST)
begin
	if (RST)
		time_tMRD_cnt <= 0;
	else
		if (time_is_tMRD)
			time_tMRD_cnt <= 0;
		else if (sdr_state == S_MRS || sdr_state == S_MRS_NOP)
			time_tMRD_cnt <= time_tMRD_cnt + 1;
end

assign time_is_tMRD = (time_tMRD_cnt == `tMRD-1);

//-----------------------------------------------  time_tRCD_cnt (active)
always @(posedge CLK or posedge RST)
begin
	if (RST)
		time_tRCD_cnt <= 0;
	else
		if (time_is_tRCD)
			time_tRCD_cnt <= 0;
		else if (sdr_state == S_WR_ACT || sdr_state == S_WR_ACT_NOP ||
		         sdr_state == S_RD_ACT || sdr_state == S_RD_ACT_NOP)
			time_tRCD_cnt <= time_tRCD_cnt + 1;
end

assign time_is_tRCD = (time_tRCD_cnt == `tRCD-1);

//-----------------------------------------------  time_tWR_cnt
// always @(posedge CLK or posedge RST)
// begin
// 	if (RST)
// 		time_tWR_cnt <= 0;
// 	else
// 		if (time_is_tWR)
// 			time_tWR_cnt <= 0;
// 		else if (sdr_state == S_WR_END)
// 			time_tWR_cnt <= time_tWR_cnt + 1;
// end

// assign time_is_tWR = (time_tWR_cnt == `tWR-1);


//----------------------------------------------- wr_bst_len_cnt
always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_bst_len_cnt <= 0;
	else
		if (wr_cnt_is_LEN)
			wr_bst_len_cnt <= 0;
		else if (sdr_state == S_WR_COL)
			wr_bst_len_cnt <= wr_bst_len_cnt + 1;
end
//-----------------------------------------------	rd_bst_len_cnt
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_bst_len_cnt <= 0;
	else
		if (rd_cnt_is_LEN)
			rd_bst_len_cnt <= 0;
		else if (sdr_state == S_RD_COL)
			rd_bst_len_cnt <= rd_bst_len_cnt + 1'b1;
end

//-----------------------------------------------  bst_acu_len
//assign bst_acu_len = WR_DATA_LEN_i - 1;
//assign wr_bst_acu_len = WR_DATA_LEN_i - 1'b1;
always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_bst_acu_len <= 0;
	else
		if (sdr_state == S_WR_ACT)
			wr_bst_acu_len <= WR_DATA_LEN_i - 1'b1;
end
//assign rd_bst_acu_len =	RD_DATA_LEN_i - 1'b1;
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_bst_acu_len <= 0;
	else
		if (sdr_state == S_RD_ACT)
			rd_bst_acu_len <= RD_DATA_LEN_i - 1'b1;
end
//-----------------------------------------------  cnt_is_LEN
// always @(posedge CLK or posedge RST)
// begin
// 	if (RST)
// 		cnt_is_LEN <= 0;
// 	else
// 		if (bst_len_cnt == bst_acu_len)
// 			cnt_is_LEN <= 1;
// 		else
// 			cnt_is_LEN <= 0;
// end

assign wr_cnt_is_LEN = (wr_bst_len_cnt == wr_bst_acu_len) & WR_RQ_i_latch ;
assign rd_cnt_is_LEN = (rd_bst_len_cnt == rd_bst_acu_len) & RD_RQ_i_latch ;

//----------------------------------------------- wr_cnt_is_LEN_latch
always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_cnt_is_LEN_latch <= 0;
	else
		if (sdr_state == S_PRE_NOP & wr_cnt_is_LEN_latch)
			wr_cnt_is_LEN_latch <= 0;
		else if (wr_cnt_is_LEN)
			wr_cnt_is_LEN_latch <= 1;
end
//----------------------------------------------- rd_cnt_is_LEN_latch
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_cnt_is_LEN_latch <= 0;
	else
		if (sdr_state == S_PRE_NOP & rd_cnt_is_LEN_latch)
			rd_cnt_is_LEN_latch <= 0;
		else if (rd_cnt_is_LEN)
			rd_cnt_is_LEN_latch <= 1;
end
/////////////////////////////////////////////////////////////////
//-----------------------------------------------  sdr_col_addr
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_col_addr <= 0;
	else
		if (WR_RQ_i && (sdr_state == S_WR_ACT))
			sdr_col_addr <= WR_ADDR_BASE_i[`SDR_COL_WIDTH-1 : 0];
		else if (RD_RQ_i && (sdr_state == S_RD_ACT))
			sdr_col_addr <= RD_ADDR_BASE_i[`SDR_COL_WIDTH-1 : 0];
		else if (sdr_state == S_WR_COL | sdr_state == S_RD_COL)
			sdr_col_addr <= sdr_col_addr + 1;
end

//-----------------------------------------------  page_end
assign page_end = sdr_col_addr == (`SDR_COL_WIDTH'hff);

//-----------------------------------------------  sdr_col_addr_d
always @(posedge CLK or posedge RST)
begin
		if (RST) 
		begin
				sdr_col_addr_d  <= 0;
				sdr_col_addr_d2 <= 0;
		end
		else 
		begin
				sdr_col_addr_d  <= sdr_col_addr;
				sdr_col_addr_d2 <= sdr_col_addr_d;
		end
end


//-----------------------------------------------  sdr_row_addr
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_row_addr <= 0;
	else
		if (WR_RQ_i & (sdr_state == S_WR_ACT))
			sdr_row_addr <= WR_ADDR_BASE_i[`BASE_ADDR_WIDTH-1 : `SDR_COL_WIDTH ];
		else if (RD_RQ_i &(sdr_state == S_RD_ACT) )
			sdr_row_addr <= RD_ADDR_BASE_i[`BASE_ADDR_WIDTH-1 : `SDR_COL_WIDTH ];
		//else if (page_end)
		//	sdr_row_addr <= sdr_row_addr + 1;
end

//-----------------------------------------------   sdr_BA
assign sdr_BA = sdr_row_addr[`SDR_BA_WIDTH-1 : 0];

//-----------------------------------------------   sdr_A
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_A <= 0;
	else
		case ({sdr_state_d2 == S_MRS, sdr_state_d2 == S_WR_COL | sdr_state_d2 == S_RD_COL})
			2'b10 : sdr_A <= opcode[`SDR_A_WIDTH-1 : 0];
			2'b01 : sdr_A <= {{(`SDR_A_WIDTH-`SDR_COL_WIDTH){1'b0}}, sdr_col_addr_d2};
			2'b00 : sdr_A <= sdr_row_addr[`SDR_A_WIDTH + 1 : `SDR_BA_WIDTH];
			default : sdr_A <= 0;
		endcase
end

//assign sdr_A = (go_mrs) ? ((go_col == 1) ? sdr_col_addr : sdr_row_addr) : opcode;

//-----------------------------------------------   sdr_CKE
assign sdr_CKE = {`SDR_CKE_WIDTH{1'b1}};

//-----------------------------------------------   sdr_CSn
assign sdr_CSn = {`SDR_CSn_WIDTH{1'b0}};

//-----------------------------------------------   sdr_RASn
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_RASn <= 1;
	else
		if (sdr_state_d2 == S_MRS | sdr_state_d2 == S_WR_ACT | sdr_state_d2 == S_RD_ACT |
		    sdr_state_d2 == S_INIT_PRE | sdr_state_d2 == S_PRE | sdr_state_d2 == S_INIT_REF |
		    sdr_state_d2 == S_IDLE_REF)
			sdr_RASn <= 0;
		else
			sdr_RASn <= 1;
end

//-----------------------------------------------   sdr_CASn
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_CASn <= 1;
	else
		if (sdr_state_d2 == S_MRS | sdr_state_d2 == S_WR_COL | sdr_state_d2 == S_RD_COL |
		    sdr_state_d2 == S_INIT_REF | sdr_state_d2 == S_IDLE_REF)
			sdr_CASn <= 0;
		else
			sdr_CASn <= 1;
end

//-----------------------------------------------   sdr_WEn
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_WEn <= 1;
	else
		if (sdr_state_d2 == S_MRS | sdr_state_d2 == S_WR_COL | sdr_state_d2 == S_INIT_PRE |
		    sdr_state_d2 == S_PRE)
			sdr_WEn <= 0;
		else
			sdr_WEn <= 1;
end

//-----------------------------------------------   sdr_A10
always @(posedge CLK or posedge RST)
begin
	if (RST)
		sdr_A10 <= 1'b0;
	else
		if (sdr_state_d2 == S_WR_COL | sdr_state_d2 == S_RD_COL)
			sdr_A10 <= 1'b0;
		else if (sdr_state_d2 == S_INIT_PRE | sdr_state_d2 == S_PRE)
			sdr_A10 <= 1'b1;
		else if (sdr_state_d2 == S_MRS)
			sdr_A10 <= opcode[10];
		else
			sdr_A10 <= sdr_row_addr[12];
end

//-----------------------------------------------  sdr_DQ
assign sdr_DQ 	= WR_DATA_i;
assign sdr_CLK  = {`SDR_CLK_WIDTH{CLK}};

//---------------------------------------------------------------  sdram interface
assign SDRAM_CLK_o  = sdr_CLK;
assign #2 SDRAM_CKE_o  = sdr_CKE;
assign #2 SDRAM_CSn_o  = sdr_CSn;
assign #2 SDRAM_RASn_o = sdr_RASn;
assign #2 SDRAM_CASn_o = sdr_CASn;
assign #2 SDRAM_WEn_o  = sdr_WEn;
assign #2 SDRAM_BA_o   = sdr_BA;
`ifdef SDR_A_WIDTH_EQ11
assign #2 SDRAM_A_o    = {sdr_A10, sdr_A[9 : 0]};
`else
//assign #2 SDRAM_A_o    = {sdr_A[`SDR_A_WIDTH-1+`SDR_BA_WIDTH : 11], sdr_A10, sdr_A[9 : 2]};
assign #2 SDRAM_A_o    = {sdr_A[`SDR_A_WIDTH-1 : 11], sdr_A10, sdr_A[9 : 0]};
`endif
assign #2 SDRAM_DQM_o  = 0;
assign #2 SDRAM_DQ_io  = (sdr_wr_en_d) ? sdr_DQ : {`SDR_DQ_WIDTH{1'bz}};


/////////////////////////////////////////////////////////////////  module interface

reg 													wr_data_rq;
reg 													rd_data_en;
reg [`SDR_DQ_WIDTH-1    : 0] 	rd_data;
reg 													wr_data_end;
reg 													rd_data_end;

//-----------------------------------------------   WR_DATA_RQ_o

always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_data_rq <= 0;
	else
		if (sdr_state_d == S_WR_COL)
			wr_data_rq <= 1;
		else
			wr_data_rq <= 0;
end

//-----------------------------------------------  WR_DATA_RQ_o
assign WR_DATA_RQ_o = wr_data_rq;

//-----------------------------------------------  WR_DATA_EN_o
//assign WR_DATA_EN_o = sdr_state_d2 == S_WR_COL;
always @(posedge CLK or posedge RST)
begin
	if (RST)
		WR_DATA_EN_o <= 0;
	else
		if (sdr_state_d2 == S_WR_COL)
			WR_DATA_EN_o <= 1;
		else
			WR_DATA_EN_o <= 0;
end
//-----------------------------------------------   delays
always @(posedge CLK or posedge RST)
begin
		if (RST) 
		begin
				sdr_wr_en_d  <= 0;
				sdr_rd_en_d  <= 0;
				sdr_rd_en_d2 <= 0;
				sdr_rd_en_d3 <= 0;
				sdr_rd_en_d4 <= 0;
		end
		else 
		begin
				sdr_wr_en_d  <= sdr_state_d2 == S_WR_COL;
				sdr_rd_en_d  <= sdr_state_d2 == S_RD_COL;
				sdr_rd_en_d2 <= sdr_rd_en_d;
				sdr_rd_en_d3 <= sdr_rd_en_d2;
				sdr_rd_en_d4 <= sdr_rd_en_d3;
		end
end


//-----------------------------------------------   RD_DATA_EN_o
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_data_en <= 0;
	else
		case (`CASn)
			2 :
				if (sdr_rd_en_d3)
					rd_data_en <= 1;
				else
					rd_data_en <= 0;
			3 :
				if (sdr_rd_en_d4)
					rd_data_en <= 1;
				else
					rd_data_en <= 0;
			default :
				rd_data_en <= 0;
		endcase
end

//-----------------------------------------------  RD_DATA_EN_o
assign RD_DATA_EN_o = rd_data_en;


//-----------------------------------------------   rd_data
always @(posedge CLK or posedge RST)
begin
		if (RST)
			rd_data <= 0;
		else
			rd_data <= SDRAM_DQ_io;
end

//-----------------------------------------------  RD_DATA_o
assign RD_DATA_o = rd_data;


/////////////////////////////////////////////////////////////////////  WR_DATA_END_o

//-----------------------------------------------  WR_DATA_RQ_o_d
always @(posedge CLK or posedge RST)
begin
		if (RST)
			WR_DATA_RQ_o_d <= 0;
		else
			WR_DATA_RQ_o_d <= WR_DATA_RQ_o;
end

//-----------------------------------------------  wr_data_end_latch
always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_data_end_latch <= 0;
	else
		if (WR_DATA_END_o)
			wr_data_end_latch <= 0;
		else if (wr_cnt_is_LEN & WR_RQ_i_latch)
	    	wr_data_end_latch <= 1;
end


//-----------------------------------------------  wr_data_end
always @(posedge CLK or posedge RST)
begin
	if (RST)
		wr_data_end <= 0;
	else
		wr_data_end <= wr_data_end_latch & ~WR_DATA_RQ_o & WR_DATA_RQ_o_d;
end

//-----------------------------------------------  WR_DATA_END_o
assign WR_DATA_END_o = wr_data_end;

/////////////////////////////////////////////////////////////////////  RD_DATA_END_o

//-----------------------------------------------  RD_DATA_EN_o_d
always @(posedge CLK or posedge RST)
begin
	if (RST)
		RD_DATA_EN_o_d <= 0;
	else
		RD_DATA_EN_o_d <= RD_DATA_EN_o;
end

//-----------------------------------------------  rd_data_end_latch
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_data_end_latch <= 0;
	else
		if (RD_DATA_END_o)
			rd_data_end_latch <= 0;
		else if (rd_cnt_is_LEN & RD_RQ_i_latch)
	    	rd_data_end_latch <= 1;
end


//-----------------------------------------------  rd_data_end
always @(posedge CLK or posedge RST)
begin
	if (RST)
		rd_data_end <= 0;
	else
		rd_data_end <= rd_data_end_latch & ~RD_DATA_EN_o & RD_DATA_EN_o_d;
end

//-----------------------------------------------  RD_DATA_END_o
assign RD_DATA_END_o = rd_data_end;

endmodule



