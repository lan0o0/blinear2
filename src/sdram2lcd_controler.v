`include "mydefines.v"
`timescale 1ns / 1ps
module sdram2lcd_controler
			(
			clk_108m,
			rst_n,
			
			//interface with writing sdram
			source_width,
			source_height,
			
			target_width,
			target_height,
			vga_target_width,
			
			vertical_scaler,
			h_scaler_dec,
			
			wr_pic_number,
			rd_pic_number,
			
			//interface with the sdram controller
			rd_data,
			rd_data_enable,
			rd_data_end,
			
			rd_req,
			rd_data_length,
			rd_addr_base,
			
			//interface with the lcd
			pixel_clock50,
			h_synch,
			v_synch,
			DE,
			
			R,
			G,
			B
			);
/*********************************************\
Input & Output Port declare
\*********************************************/
input														clk_108m;
input														rst_n;
			
//interface with writing sdram
input[`IMGS_WIDTH  - 1 	 :0]		source_width;
input[`IMGS_HEIGHT - 1 	 :0]		source_height;
			
input[`IMGT_WIDTH - 1  :0]		target_width;
input[`IMGT_HEIGHT -1  :0]		target_height;
input[`IMGO_WIDTH-1:0] vga_target_width;
			                   
input[7								 	 :0]		vertical_scaler;
input[`H_SCALER_DEC_WIDTH-1:0] h_scaler_dec;
			
input [1								 :0]		wr_pic_number;
output[1								 :0]		rd_pic_number;
			
			//interface with the sdram controller
input	[`SDR_DQ_WIDTH-1 :0]  		rd_data;
input														rd_data_enable;
input														rd_data_end;
			
output													rd_req;
output[`BURST_LENGTH-1	  :0]		rd_data_length;
output[`BURST_ADD_LENGTH-1:0]		rd_addr_base;
			
			//interface with the lcd
input 													pixel_clock50;
output 													h_synch;
output 													v_synch;
output													DE;
 						
output[7								:0] 		R;
output[7								:0] 		G;
output[7								:0] 		B;

/**************************************************************\
Signal declare
\**************************************************************/
wire	[1:0]											buf_flag;
wire	[1:0]											buf_rd_rls;
wire	[1:0]											buf_wrls;

wire	[9:0]											bufa_wraddr;
wire	[9:0]											bufb_wraddr;
wire  [15:0]										bufa_wdata;
wire  [15:0]										bufb_wdata;

wire	[9:0]											buf_rdaddr;

wire  [15:0]										bufa_rdata;
wire  [15:0]										bufb_rdata;
//
wire	[15:0]										out_fifo_rd_data;
wire	[15:0]										out_fifo_wdata;
wire														out_fifo_rden;
//
wire	[15:0]										dout1;
wire	[15:0]										dout2;
wire	[7:0]											Kremain;

wire	[7:0]											data_out0;
wire	[7:0]											data_out1;
wire	[7:0]											data_out2;
wire	[9:0]  wrusedw;
wire wrfull;
wire[7:0] Y_out,Cb_out,Cr_out;
wire h_fifo_ren;
wire fifo_clr;
//
sdram_rd2buf U_sdram_rd2buf
			 			(
			 			//Global signal
			 			.clk_108m					( clk_108m 				  	),
			 			.rst_n						( rst_n						  	),
       			                                      	
			 			//parameter define                    	
			 			.source_width			( source_width		  	),
			 			.source_height		( source_height		  	),
       			               	                      	
			 			.target_width			( target_width		  	),
			 			.target_height		( target_height 	  	),
       			                                      	
			 			.vertical_scaler	( vertical_scaler	  	),
			 			//                                    	
			 			.wr_pic_number		( wr_pic_number		  	),
			 			.rd_pic_number		( rd_pic_number		  	),
       			                                      	
			 			//sdram read opreation                	
			 			.rd_data					( rd_data					  	),
			 			.rd_data_enable		( rd_data_enable	  	),
			 			.rd_data_end			( rd_data_end			  	),
       			                                      	
			 			.rd_req						( rd_req					  	),
			 			.rd_data_length		( rd_data_length	  	),
			 			.rd_addr_base			( rd_addr_base		  	),
       			                                      	
       			.v_synch					(	v_synch							),		                	                    
       			.fifo_clr(fifo_clr),
			 			.buf_flag					( buf_flag				  	),
			 			.bufa_wren				( bufa_wren				  	),
			 			.bufb_wren				( bufb_wren				  	),
			 			.buf_wrls					( buf_wrls				  	),
			 			.bufa_wraddr			( bufa_wraddr					),
			 			.bufb_wraddr			( bufb_wraddr					),
			 			.bufa_wdata				( bufa_wdata 			  	),
			 			.bufb_wdata				( bufb_wdata 			  	)
			 			);			                              	
//                                                	
vertical_scaler U_vertical_scaler                 	
						(                                     	
						.clk_108m					( clk_108m				  	),
						.rst_n						( rst_n					    	),
      			                                      	
						.buf_flag					( buf_flag				  	),
						.buf_rd_addr			( buf_rdaddr		  		),
						//.bufb_rd_addr			( bufb_rdaddr					),
						.buf_rd_rls				( buf_rd_rls			  	),
						.bufa_rd_data			( bufa_rdata		  		),
						.bufb_rd_data			( bufb_rdata		  		),
						.bufa_rden				( bufa_rden				  	),
      			//.bufb_rden				( bufb_rden				  	),                                      
						.out_fifo_alfull	( out_fifo_alfull   	),
						.buf_rden_delay		( buf_rden_delay			),
						.dout1						( dout1	 							),  
						.dout2						( dout2	 							),  
						.Kremain					( Kremain							),      			                                      
						//source_height,                      	
						.v_synch					(	v_synch							),
						.source_height		( source_height		  	),              
						.target_width			( target_width		  	),
						.target_height		( target_height	    	),
						.vertical_scaler	( vertical_scaler   	)
						);                                    	
//                                                	
bilin_insert U0_bilin_insertY                      	
						(                                     	
						.clk							( clk_108m						), 
						.rst							(	~rst_n							),
						.Kremain					( Kremain							), 
						.Din1							( dout1[15:8]		), 
						.Din2							( dout2[15:8]		), 
						.Dout							( data_out0						)
						);
//
bilin_insert U1_bilin_insertC 
						(
						.clk							( clk_108m						), 
						.Kremain					( Kremain							),
						.rst							(	~rst_n							), 
						.Din1							( dout1[7:0]	), 
						.Din2							( dout2[7:0]	), 
						.Dout							( data_out1						)
						);

//
wr_outfifo 	wr_outfifo
						(
						.rst_n						( rst_n								),
						.clk_108m					( clk_108m						),
						//
						.data_valid				(	buf_rden_delay			),
						.din0							(	data_out0						),
						.din1							( data_out1						),
						
						.out_fifo_wren		( out_fifo_wren				),
						.out_fifo_wdata		( out_fifo_wdata			)
						);                                                                        
                                 	
//                                              	
dpram_1024x16b U0_dpram_1024x16b(
	.data(bufa_wdata),
	.rdaddress(buf_rdaddr),
	.rdclock(clk_108m),
	.wraddress(bufa_wraddr),
	.wrclock(clk_108m),
	.wren(bufa_wren),
	.q(bufa_rdata));

dpram_1024x16b U1_dpram_1024x16b(
	.data(bufb_wdata),
	.rdaddress(buf_rdaddr),
	.rdclock(clk_108m),
	.wraddress(bufb_wraddr),
	.wrclock(clk_108m),
	.wren(bufb_wren),
	.q(bufb_rdata));	
//                                                 
buf_flag 	U_buf_flag                              
			 		(                                         
			 		.clk								( clk_108m				 		),
			 		.rst_n							( rst_n								),
			 		.rd_rls							( buf_rd_rls					),
			 		.wr_rls							( buf_wrls						),
			 		.buf_flag						(	buf_flag						)
			 		);	

fifo_asy_1024x16b U_fifo_asy_1024x16b(
	.aclr(fifo_clr),
	.data(out_fifo_wdata),
	.rdclk(clk_108m),
	.rdreq(h_fifo_ren),
	.wrclk(clk_108m),
	.wrreq(out_fifo_wren),
	.q(out_fifo_rd_data),
	.rdempty(out_fifo_empty),
	.wrfull(wrfull),
	.wrusedw(wrusedw));
assign out_fifo_alfull = wrusedw[9];

h_scaler U_h_scaler(
	//system
	.rst(!rst_n),
	.clk(clk_108m),	//system clock
	.pix_clk(pixel_clock50), //pixel clock 40MHz for 800x600
	//input data control
	.h_fifo_ren(h_fifo_ren),
	.Y_in(out_fifo_rd_data[15:8]),.C_in(out_fifo_rd_data[7:0]),
	//output data control
	.h_data_ren(out_fifo_rden),
	.Y_out(Y_out),.Cb_out(Cb_out),.Cr_out(Cr_out),
	.line_end(!out_fifo_rden),
	//config
	.source_width(source_width),
	.vga_target_width(vga_target_width),
	.h_scaler_dec(h_scaler_dec),
	.h_scaler_int()
		 );
		 
//                                                
vgatest 		U_vgatest                             
						(                                     
						.pixel_clock50		(	pixel_clock50		  	),
						.rst_n						(	rst_n						  	),
						.out_fifo_empty		(	1'b0			),
						.out_fifo_alempty	(	1'b0		),
						.out_fifo_rd_data	(	{Y_out,Cb_out,Cr_out}		),

						.out_fifo_rden		(	out_fifo_rden				),			
						.h_synch					(	h_synch							),
						.v_synch					(	v_synch							),
						.DE								( DE									),
						.R								(	R										),
						.G								(	G										),
						.B								(	B										)
						); 
endmodule