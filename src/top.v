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
module top
	(
		input pixel_clk,key,
		input[7:0] vda,
		input cosc,
		output dclk,dpen,dhs,dvs,
		output[7:0] dre,dge,dbe,
		//I2C interface
		output					i2c_sclk,
		inout					i2c_sdat,
		//  sdram interface  
		output [`SDR_CLK_WIDTH-1   : 0]	SDRAM_CLK_o,
		//output [`SDR_CKE_WIDTH-1   : 0]	SDRAM_CKE_o,
		//output [`SDR_CSn_WIDTH-1   : 0]	SDRAM_CSn_o,
		output  	                SDRAM_RASn_o,
		output 				SDRAM_CASn_o,
		output 				SDRAM_WEn_o,
		output [`SDR_BA_WIDTH-1    : 0] SDRAM_BA_o,
		output [`SDR_A_WIDTH-1     : 0] SDRAM_A_o,
		//output [`SDR_DQM_WIDTH-1   : 0] SDRAM_DQM_o,				
		inout  [`SDR_DQ_WIDTH-1    : 0]	SDRAM_DQ_io,
		//dsp connect
		output eclk
	);
	
	// Wire Declaration
	wire daclk,data;
	wire rst;
	wire pix_clk;
	// Integer Declaration
	// Concurrent Assignment
	
	// Always Construct
	assign rst = !key;
	//assign rst7180 = !rst;
	//assign rst7180 = 1'b1;
	//assign dpen = 1'b1;
	assign dclk = !pix_clk;
	//assign dhs = pixel_hs;
	//assign dvs = pixel_vs;
	//assign dre = gre;
	//assign dge = gge;
	//assign dbe = gbe;
	//assign dre = (!pixel_hs)?8'hff:8'h00;
	//assign dge = (!pixel_hs)?8'hff:8'h00;
	//assign dbe = (!pixel_hs)?8'hff:8'h00;
	wire [`SDR_CKE_WIDTH-1   : 0]	SDRAM_CKE_o;
	wire [`SDR_CSn_WIDTH-1   : 0]	SDRAM_CSn_o;
	wire [`SDR_DQM_WIDTH-1   : 0] SDRAM_DQM_o;
	//dsp
	assign eclk = SDRAM_CLK_o;
	video_pro	UUT
				(
				//system
				.rst(rst),
				.rst_decoder(),
				.clk50m(cosc),
				//video in
				.clk27min(pixel_clk),		// 27 MHz
				
				//video in
				.din(vda),	//bt656 data in
	  			.Hi(pixel_hs),
	  			.Vi(pixel_vs),

				//interface with the lcd
				.pixel_clock(pix_clk),
				.h_synch(dhs),
				.v_synch(dvs),
				.DE(dpen),
  			
				.Rout(dre),
				.Gout(dge),
				.Bout(dbe),
				//  sdram interface
				.SDRAM_CLK_o (SDRAM_CLK_o ),
				.SDRAM_CKE_o (SDRAM_CKE_o ),
				.SDRAM_CSn_o (SDRAM_CSn_o ),
				.SDRAM_RASn_o(SDRAM_RASn_o),
				.SDRAM_CASn_o(SDRAM_CASn_o),
				.SDRAM_WEn_o (SDRAM_WEn_o ),
				.SDRAM_BA_o  (SDRAM_BA_o  ),
				.SDRAM_A_o   (SDRAM_A_o   ),
				.SDRAM_DQM_o (SDRAM_DQM_o),
				.SDRAM_DQ_io (SDRAM_DQ_io )
				);
	 
	I2C_V_Config I2C_AV_Config
						(	//	Host Side
						.iCLK			( cosc			),
						.iRST_N		(	~rst			),
						.mI2C_CTRL_CLK(				),
						//	I2C Side        	
						.I2C_SCLK	( i2c_sclk	),
						.I2C_SDAT	(	i2c_sdat	)	
						);
    
	
endmodule
