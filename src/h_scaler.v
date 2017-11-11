//*************************************************************************\
//Copyright (c) 2008, Lattice Semiconductor Co.,Ltd, All rights reserved
//
//                   File Name  :  h_scaler.v
//                Project Name  :  PIP
//                      Author  :  cloud
//                       Email  :  ymjcloud@126.com
//                      Device  :  Altera Cyclone Family
//                     Company  :  BJTech Co.,Ltd
//==========================================================================
//   Description:  xxxx
//
//   Called by  :   XXXX.v
//==========================================================================
//   Revision History:
//	Date		  By			Revision	Change Description
//--------------------------------------------------------------------------
//2010/1/1	 Cloud		   1.0			Original
//*************************************************************************/
`include "mydefines.v"
module h_scaler(
	//system
	input rst,
	input clk,	//system clock
	input pix_clk, //pixel clock 40MHz for 800x600
	//input data control
	output h_fifo_ren,
	input[7:0] Y_in,C_in,
	//output data control
	input h_data_ren,
	output[7:0] Y_out,Cb_out,Cr_out,
	input line_end,
	//config
	input[`IMGS_WIDTH-1:0] source_width,
	input[`IMGO_WIDTH-1:0] vga_target_width,
	input[`H_SCALER_DEC_WIDTH-1:0] h_scaler_dec,
	input[`H_SCALER_INT_WIDTH-1:0] h_scaler_int
		 );

	parameter   IDLE        = 3'h1;
	parameter   READ   	= 3'h2;
	parameter   HOLD   	= 3'h4;

reg [`IMGO_WIDTH-1:0]		pixel_count;	// counts the pixels in a line
reg [`H_SCALER_DEC_WIDTH:0]		scaler_value;	// scaler_value
reg [`IMGS_WIDTH-1:0] read_pix_num;
reg[`IMGO_WIDTH-1:0] write_pix_num;
reg [2:0] state_cur,state_next;
reg scaler_c;
reg [7:0] Cb_in,Cb_in_d,Cb_in_d2,Cr_in,Cr_in_d,Y_in_d;
reg [7:0] Cb_in1,Cb_in1_d,Cr_in1,Y_in_d1,Y_in_d2,Y_in_d3;
reg wren;
reg line_end_d1,line_end_d2;
reg Cb_Crn;
reg read_en;

wire line_end_rising;
wire [23:0] data_out;
wire source_line_end;
wire read_req;
wire [7:0] Cbinsert_out,Crinsert_out,Yinsert_out;
wire [`H_SCALER_DEC_WIDTH-1:0] kremain;
wire [`IMGO_WIDTH-1:0] write_pix_num_d;
wire wren_d;
//==========================================
assign source_line_end = (read_pix_num >= source_width - 1'b1);
assign read_req = ((state_next!=IDLE || state_cur!=IDLE)  && scaler_c != scaler_value[`H_SCALER_DEC_WIDTH]);
assign h_fifo_ren = read_req;
//assign wren = (state_cur == READ);
assign Y_out = data_out[23:16];
assign Cb_out = data_out[15:8];
assign Cr_out = data_out[7:0];
//=====================================================
dpram_1024x24b U1_dpram_1024x24b(
	.data({Yinsert_out,Cbinsert_out,Crinsert_out}),
	.rdaddress(pixel_count[9:0]),
	.rdclock(pix_clk),
	.wraddress(write_pix_num_d),
	.wrclock(clk),
	.wren(wren_d),
	.q(data_out));
	
bilin_insert U1_bilin_insertY
						(
						.clk							( clk						), 
						.Kremain					( kremain		),
						.rst							(	rst							), 
						.Din1							( Y_in_d3	), 
						.Din2							( Y_in_d2	), 
						.Dout							( Yinsert_out						)
						);
bilin_insert U1_bilin_insertCb
						(
						.clk							( clk						), 
						.Kremain					( kremain		),
						.rst							(	rst							), 
						.Din1							( Cb_in1_d	), 
						.Din2							( Cb_in_d2	), 
						.Dout							( Cbinsert_out						)
						);
bilin_insert U1_bilin_insertCr
						(
						.clk							( clk						), 
						.Kremain					( kremain		),
						.rst							(	rst							), 
						.Din1							( Cr_in1	), 
						.Din2							( Cr_in_d	), 
						.Dout							( Crinsert_out						)
						);
//==========================================

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
	
	always @(*)
	begin
	    case(state_cur)
	    IDLE:
	        begin
	            if(line_end_rising == 1'b1)
	                begin
	                    state_next = READ;
	                end
	            else
	                begin
	                    state_next = IDLE;
	                end
	        end
	    READ:
	        begin
	            if(source_line_end == 1'b1)
	                begin
	                    state_next = IDLE;
	                end
	            else if(!read_req)
	                begin
	                    state_next = HOLD;
	                end
	            else
	                begin
	                    state_next = READ;
	                end
	        end
	    HOLD:
	        begin
	            if(source_line_end == 1'b1)
	            	begin
	                    state_next = IDLE;
	                end
	            else if(read_req)
	            		begin
	                    state_next = READ;
	                end
	            else
	                begin
	                    state_next = HOLD;
	                end
	        end
	    default:
	        begin
	            state_next = IDLE;
	        end
	    endcase
	end
	//==================================================================
	//line end rising detect
	assign line_end_rising = line_end_d1 & !line_end_d2;
	//ping pang write control
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin					// 
				line_end_d1 <= 0;
				line_end_d2 <= 0;
			end
		else
	 		begin					// 
				line_end_d1 <= line_end;		//
				line_end_d2 <= line_end_d1;
			end
	end
	
	//pixel_count
	always @ (posedge pix_clk or posedge rst) 
	begin
		if (rst)
	 		begin					// on reset set pixel counter to 0
				pixel_count <= 0;
			end
		else if (!h_data_ren)
	 		begin					// last pixel in the line
				pixel_count <= 0;		// reset pixel counter
			end
		else if(pixel_count <= vga_target_width)	
			begin
				pixel_count <= pixel_count +1;		
			end
	end
	
//read_pix_num
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				read_pix_num <= 0;		//
			end
		else if(read_req == 1'b1 && read_pix_num < source_width)
	 		begin						
				read_pix_num <= read_pix_num + 1'b1;	//
			end
		else if(source_line_end == 1'b1)
			begin						
				read_pix_num <= 0;	//
			end
	end
//write_pix_num
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				write_pix_num <= 0;		//
			end
		else if(state_cur != IDLE && write_pix_num < vga_target_width)
	 		begin						
				write_pix_num <= write_pix_num + 1'b1;	//
			end
		else if(source_line_end == 1'b1)
			begin						
				write_pix_num <= 0;	//
			end
	end
	//
	defparam delayWPN.WIDTH = `IMGO_WIDTH;
	defparam delayWPN.DELAYS = 7;
	ndelay delayWPN(.clk(clk),.dinput(write_pix_num),.doutput(write_pix_num_d));
// scaler_value
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				scaler_value <= 0;		//
			end
		else if(state_cur != IDLE)
	 		begin						
				scaler_value <= scaler_value + h_scaler_dec;	//
			end
		else
			begin						
				scaler_value <= 9'h000;	//
			end
	end
	//kremain
	defparam delayK.WIDTH = `H_SCALER_DEC_WIDTH;
	defparam delayK.DELAYS = 4;
	ndelay delayK(.clk(clk),.dinput(scaler_value[7:0]),.doutput(kremain));
	//scaler_c
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				scaler_c <= 0;		//
			end
		else if(state_cur == IDLE)
			begin
				scaler_c <= 1'b1;		//
			end
		else
	 		begin						
				scaler_c <= scaler_value[`H_SCALER_DEC_WIDTH];	//
			end
	end
	//Cb_Crn
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				Cb_Crn <= 0;		//
			end
		else if(state_next == READ)
	 		begin						
				Cb_Crn <= !Cb_Crn;	//
			end
		else if(state_next == IDLE)
			begin
				Cb_Crn <= 0;		//
			end
	end
	//Cb_in
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				Cb_in <= 8'h80;		//
				Cb_in1 <= 8'h80;
			end
		else if(state_cur == IDLE)
	 		begin						
				Cb_in <= 8'h80;		//
				Cb_in1 <= 8'h80;
			end
		else if(state_cur == READ && Cb_Crn)
	 		begin						
				Cb_in <= C_in;	//
				Cb_in1 <= Cb_in;
			end
	end
	//Cr_in;
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				Cr_in <= 8'h80;		//
				Cr_in1 <= 8'h80;
			end
		else if(state_cur == IDLE)
	 		begin						
				Cr_in <= 8'h80;		//
				Cr_in1 <= 8'h80;
			end
		else if(state_cur == READ && !Cb_Crn)
	 		begin						
				Cr_in <= C_in;	//
				Cr_in1 <= Cr_in;
			end
	end
	//Y_in_d
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				Y_in_d <= 0;		//
			end
		else if(state_cur == READ)
	 		begin						
				Y_in_d <= Y_in;	//
			end
	end

//reg [7:0] Cb_in1,Cr_in1,Y_in_d1;
//Cb_in_d2,Cr_in_d
always @ (posedge clk or posedge rst)
	begin
		if (rst)
	 		begin
				Y_in_d1 <= 0;
				Y_in_d2 <= 0;
				Y_in_d3 <= 0;
				Cb_in_d <= 0;
				Cb_in_d2 <= 0;
				Cb_in1_d <= 0;
				Cr_in_d <= 0;
			end
		else
	 		begin						
				Y_in_d1 <= Y_in_d;
				Y_in_d2 <= Y_in_d1;
				Y_in_d3 <= Y_in_d2;
				Cb_in_d <= Cb_in;
				Cb_in_d2 <= Cb_in_d;
				Cb_in1_d <= Cb_in1;
				Cr_in_d <= Cr_in;
			end
	end
//wren;
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				wren <= 0;		//
			end
		else if(state_cur != IDLE && state_next != IDLE)
	 		begin						
				wren <= 1'b1;	//
			end
		else
			begin						
				wren <= 0;	//
			end
	end
	defparam delayWE.WIDTH = 1;
	defparam delayWE.DELAYS = 6;
	ndelay delayWE(.clk(clk),.dinput(wren),.doutput(wren_d));
	//read_en
	always @ (posedge clk or posedge rst) 
	begin
		if (rst)
	 		begin
				read_en <= 0;		//
			end
		else if(state_cur == READ)
	 		begin						
				read_en <= 1'b1;	//
			end
		else
			begin
				read_en <= 0;		//
			end
	end
endmodule
