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
module video_pro( 
	//system
	input rst,
	output rst_decoder,
	input clk50m,
	//video in
	input clk27min,		// 27 MHz
  input [7:0] din,	//bt656 data in
  input Hi,Vi,
  //VGA out
  output 					pixel_clock,
	output 					h_synch,
	output 					v_synch,
	output 					DE,
	 						
	output[`PRECISION-1:0] 		Rout,
	output[`PRECISION-1:0] 		Gout,
	output[`PRECISION-1:0] 		Bout,	
	//config
	//input[1:0] rd_pic_number,
	//output[1:0] wr_pic_number,
	//interface with the lcd
	
	//  sdram interface  
	output [`SDR_CLK_WIDTH-1   : 0]	SDRAM_CLK_o,
	output [`SDR_CKE_WIDTH-1   : 0]	SDRAM_CKE_o,
	output [`SDR_CSn_WIDTH-1   : 0]	SDRAM_CSn_o,
	output  	    SDRAM_RASn_o,
	output 				SDRAM_CASn_o,
	output 				SDRAM_WEn_o,
	output [`SDR_BA_WIDTH-1    : 0] SDRAM_BA_o,
	output [`SDR_A_WIDTH-1     : 0] SDRAM_A_o,
	output [`SDR_DQM_WIDTH-1   : 0] SDRAM_DQM_o,				
	inout  [`SDR_DQ_WIDTH-1    : 0]	SDRAM_DQ_io
	
		);

		//data out
	wire wr_hold;
	wire [`BURST_LENGTH-1:0] wr_burst_length;
	wire [`BURST_ADD_LENGTH-1:0] wr_burst_address;
	wire [`IN_DATA_WIDTH-1:0] wr_burst_data;
	wire  wr_holda;
	//data in
	wire rd_hold;
	wire [`BURST_LENGTH-1:0] rd_burst_length;
	wire [`BURST_ADD_LENGTH-1:0] rd_burst_address;
	wire [`IN_DATA_WIDTH-1:0] rd_burst_data;
	wire  rd_holda;
	//  sdram_200us  
	wire            INIT_WAIT_200; 
	//clock
	wire user_clk;
	wire clk4x;		// system clock 108-133m
	wire clk1x;		// 27 MHz
	//sync
	wire Hi_sel,Vi_sel;
	wire Ho,Vo,Fo;
	//CONFIG
	reg [`IMGS_WIDTH-1:0] source_width;
	reg[`IMGS_HEIGHT-1:0] source_height;
	reg[`IMGT_WIDTH-1:0] target_width;
	reg[`IMGT_HEIGHT-1:0] target_height;
	reg[`PRECISION-1:0] v_scaler_dec;
	reg [`BT656_DELAY_NUM-1:0] Hi_d,Vi_d;
	reg [`VGA_DELAY_NUM-1:0] Hsi_d,Vsi_d;
	reg[`IMGO_WIDTH-1:0] vga_target_width;
	reg[`H_SCALER_DEC_WIDTH-1:0] h_scaler_dec;

	//reg clk1_2x;// 13.5 MHz
	wire clk1_2x;
	//reg Hi_sel,Vi_sel;
	wire[1:0] rd_pic_number;
	wire[1:0] wr_pic_number;
	wire [9:0] YCrCb_out;
	wire [7:0] Y_out,C_out;
	wire [7:0] din_sel;
	
	/*
	assign Vin_sel = switch_in[2];
	assign Hi_sel = (Vin_sel == 0)?Hi_d[`BT656_DELAY_NUM-1]:Hsi_d[`VGA_DELAY_NUM-1];
	assign Vi_sel= (Vin_sel == 0)?Vi_d[`BT656_DELAY_NUM-1]:Vsi_d[`VGA_DELAY_NUM-1];
	assign Rin_sel = (Vin_sel == 0)?R:Rin;
	assign Gin_sel = (Vin_sel == 0)?G:Gin;
	assign Bin_sel = (Vin_sel == 0)?B:Bin;
	*/
	assign Hi_sel = Ho;//Hi_d[`BT656_DELAY_NUM-1];
	assign Vi_sel= Vo;//Vi_d[`BT656_DELAY_NUM-1];

	assign clk1x = clk27min;
	assign user_clk = clk27min;
	
	assign rst_decoder = INIT_WAIT_200;
	//PARAMETER UPDATE
	always @ (posedge user_clk or posedge rst) 
	begin
		if (rst)
	 		begin				// 
				source_width <= 720;
				source_height<= 240;
				target_width <= 720;
				target_height <= 600;
				vga_target_width<= 800;
				v_scaler_dec <= 8'hCC;
				h_scaler_dec <= 8'he6;
			end
	
		else
				  begin
						source_width <= 720;
						source_height<= 240;
						target_width <= 720;
						target_height <= 600;
						vga_target_width<= 800;
						v_scaler_dec <= 8'hCC;
						h_scaler_dec <= 8'he6;
				  end
	end

//	wire [9:0] POUT_o;
//	assign din_sel = POUT_o[9:2];
//
//colorbars U_PG 
//					(
//    			.clk(clk27min),
//    			.rst(rst),
//    			.ce(1'b1),
//    			.q(POUT_o),
//    			.h_sync(),
//    			.v_sync(),
//    			.field()
//					);

	assign din_sel = din;
	lf_decode U_detect(
		.rst(rst),           // Reset and Clock input
		.clk(clk1x),           // 27Mhz for SDTV
		
		.YCrCb_in({din_sel,2'b00}),      // data from the input video stream
		
		.YCrCb_out(YCrCb_out),     // data delayed by pipe length
		
		.NTSC_out(NTSC_out),      // high = NTSC format detected
		
		.Fo(Fo),            // high = field one (even)
		.Vo(Vo),            // high = vertical blank
		.Ho(Ho)            // low = active video
		);

	vin_pro U_vin_pro(
	//system
	.rst(rst),
	.user_clk(user_clk),	//27MHz
	.sys_clk(clk4x),	//100-133M
	//video in BT.601 in
	.data_in(YCrCb_out[9:2]),
	.Hi(Hi_sel),
	.Vi(Vi_sel),
	.Fi(Fo),
	//data out
	.hold(wr_hold),
	.burst_length(wr_burst_length),
	.burst_address(wr_burst_address),
	.burst_data(wr_burst_data),
	.holda(wr_holda),
	//config
	.source_width(source_width),
	.source_height(source_height),
	.target_width(target_width),
	.target_height(target_height),
	.rd_pic_number(rd_pic_number),
	.wr_pic_number(wr_pic_number)
	
		 );

	//-----------------------------------
	sdram2lcd_controler U_sdram2lcd_controler
			(
			.clk_108m											( clk4x				),
			.rst_n												( !rst						),

			//interface with writing sdram
			.source_width									( source_width		),
			.source_height								( source_height 	),

			.target_width									( target_width		),
			.target_height								( target_height  ),
			.vga_target_width(vga_target_width),

			.vertical_scaler							( v_scaler_dec ),
			.h_scaler_dec(h_scaler_dec),

			.wr_pic_number								( wr_pic_number		),
			.rd_pic_number								( rd_pic_number	),

			//interface with the sdram controller
			.rd_data											( rd_burst_data				),
			.rd_data_enable								( rd_holda		),
			.rd_data_end									( 		),

			.rd_req												( rd_hold					),
			.rd_data_length								( rd_burst_length		),
			.rd_addr_base									( rd_burst_address	),

			//interface with the lcd
			.pixel_clock50								( pixel_clock	),
			.h_synch											( h_synch			 		),
			.v_synch											( v_synch			 		),
			.DE														( DE							),
			.R														( Rout						),
			.G														( Gout						),
			.B														( Bout						)
			);
	//-----------------------------------------------  port map      
	sdram_if U_SDR(	
                //  system  			
				.RST(rst),
				.CLK(clk4x),
				
				//  initial 
				.INIT_WAIT_200_i(INIT_WAIT_200), 
				//  write 
				.WR_RQ_i       (wr_hold       ),	//  write request 		                     
				.WR_DATA_i     (wr_burst_data   ),    //  write data                           
				.WR_DATA_LEN_i (wr_burst_length ),    //  write data length, ahead of WR_RQ_i  
				.WR_ADDR_BASE_i(wr_burst_address),    //  write base address of sdram write buffer   
				.WR_DATA_RQ_o  (wr_holda  ),    //  wrtie data request, 2 clock ahead               
				.WR_DATA_EN_o  (  ),    //  write data enable now                      
				.WR_DATA_END_o ( ),    //  write data is end   
                //  read 
				.RD_RQ_i       (rd_hold       ),    //  read request 	                       
				.RD_DATA_LEN_i (rd_burst_length ),    //  read data length(), ahead of RD_RQ_i  	
				.RD_ADDR_BASE_i(rd_burst_address),    //  read base address of sdram read buffer    
				.RD_DATA_o     (rd_burst_data    ),    //  read data to internal                
				.RD_DATA_EN_o  (rd_holda ),    //  read data enable (valid)             
				.RD_DATA_END_o ( ),	//  read data is end 
				                    
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
	//-----------------------------------------------  sdram_200us 
	sdram_200us U_sdram_200us(
                //  system clock & reset 
				.CLK(clk4x),
				.RST(rst),
							
				//  
				.INIT_WAIT_200_o(INIT_WAIT_200) 	 
			
				);
	/*
	//Xilinx
	pll_1 U7_pll (.CLK( clk27min), 
		.RESET( rst), 
		.CLKOP(clk4x ), 
		.CLKOS( clk1x), 
		.CLKOK(clk1_2x ), 
		.LOCK( ));
	*/
	//Lattice
	/*
	pll_2 U_pll (
    .CLKIN_IN(clk27min), 
    .RST_IN(rst), 
    .CLKDV_OUT(clk1_2x), 
    .CLKFX_OUT(clk4x), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(clk1x)
    );
  */  
  //altera  
/*
  pll1	U_pll1 (
	.areset ( 1'b0 ),
	.inclk0 ( clk27min ),
	.c0 ( clk1x ),
	.c1 ( clk1_2x )
	);
	*/
/*
	pll1	U_pll2 (
	.areset ( rst ),
	.inclk0 ( clk50m ),
	.c0 ( clk4x ),
	.c1 ( pixel_clock )
	);
	*/
	
	pll2	U_pll2 (
	.areset ( rst ),
	.inclk0 ( clk50m ),
	.c0 ( clk4x ),
	.c1 ( pixel_clock )
	);
	
	//-----------------------------------

endmodule
