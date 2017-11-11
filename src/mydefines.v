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
`timescale 1ns/100ps
//=======================
`define IMGS_WIDTH 10
`define IMGS_HEIGHT 9
`define IMGT_WIDTH 10
`define IMGT_HEIGHT 10
`define IMGO_WIDTH 11
`define IMGO_HEIGHT 11
`define	PRECISION 8
`define	BURST_LENGTH 9
`define	BURST_ADD_LENGTH 22
`define	BT656_DELAY_NUM 15                                
`define	VGA_DELAY_NUM 10
`define	IN_DATA_WIDTH 16
`define	OUT_DATA_WIDTH 16
`define	V_SCALER_DEC_WIDTH 8
`define	H_DATA_NUMBER 720
`define	H_SCALER_DEC_WIDTH 8
`define	H_SCALER_INT_WIDTH 4
//  
`define SDR_WIDTH                   22

//  SDRAM INTERFACE defines  
`define tRP  2 
`define tRC  7
`define tMRD 2
`define tRCD 2
`define tWR  2
`define CASn 2
`define BURST_LEN_WIDTH  9   //
`define BASE_ADDR_WIDTH  22  //  

`define OPCODE           {4'b0000, 3'b010, 1'b0, 3'b000}  //  burst length = 1; 
`define SDR_CLK_WIDTH    1      //
`define SDR_CKE_WIDTH    1      //
`define SDR_CSn_WIDTH    1      //
`define SDR_BA_WIDTH     2      //
`define SDR_A_WIDTH      12     //
//`define SDR_A_WIDTH_EQ11 1      //  SDR_A_WIDTH == 11  
`define SDR_DQM_WIDTH    2      //  
`define SDR_ROW_WIDTH    12     //
`define SDR_COL_WIDTH    8      // 

`define SDR_DQ_WIDTH     16     //
//  md_ref_buf 

