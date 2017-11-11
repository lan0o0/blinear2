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

`timescale 1ns/1ps 
`include "mydefines.v" 


module sdram_200us (
                //  system clock & reset 
				input  CLK,
				input  RST,
							
				//  
				output INIT_WAIT_200_o 	 
			
				); 
	

//=================================================================================================  SIGNAL DEFINITION 
reg    [15 : 0] init_cnt;   //  counter 


//=================================================================================================  IMPLEMENTATION  
//-----------------------------------------------  init_cnt
always @(posedge CLK or posedge RST) 
begin 
	if (RST) 
		init_cnt <= 0; 
	else if (~init_cnt[15])    
		init_cnt <= init_cnt + 1;
end 

//-----------------------------------------------  INIT_WAIT_200_o
assign INIT_WAIT_200_o = init_cnt[15];   //   


endmodule 

