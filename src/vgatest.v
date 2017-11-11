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
`include "svga_defines.v"
`include "mydefines.v"
`timescale 1ns / 1ps
module vgatest 
			(
			pixel_clock50,
			rst_n,
			out_fifo_empty,
			out_fifo_alempty,
			out_fifo_rd_data,
			//pixel_clock,
			out_fifo_rden,			
			h_synch,
			v_synch,
			DE,
			R,
			G,
			B
			);
input 						pixel_clock50;	// pixel clock 
input 						rst_n;			// rst_n
output 						h_synch;	// horizontal synch for VGA connector
output 						v_synch;	// vertical synch for VGA connector
output  DE;	//data enable
output[`PRECISION-1:0] 			R,G,B;
//output						pixel_clock;

//
input							out_fifo_empty;
input							out_fifo_alempty;
input [23:0]	out_fifo_rd_data;

output reg						out_fifo_rden;
reg 	[9			:0]	line_count;		// counts the display lines
reg 	[10			:0]	pixel_count;	// counts the pixels in a line	
reg								h_synch;		// horizontal synch
reg								v_synch;		// vertical synch
reg		[`PRECISION-1	:0]	R,G,B;
reg		[`PRECISION-1	:0]	Y,Cb,Cr;
reg		h_blank;			// horizontal blanking
reg		v_blank;			// vertical blanking
reg		blank;			// composite blanking
reg		h_data_en,data_en;
wire DE_d;
wire		[`PRECISION-1	:0]	Rout,Gout,Bout;
// CREATE THE HORIZONTAL BLANKING SIGNAL
// the "-2" is used instead of "-1" because of the extra register delay
// for the composite blanking signal 

	defparam delayDE.WIDTH = 1;
	defparam delayDE.DELAYS = 8;
	ndelay delayDE(.clk(pixel_clock50),.dinput(!blank),.doutput(DE));
		
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin					// on reset
			h_blank <= 1'b0;	// remove the h_blank
		end

	else if (pixel_count == (`H_ACTIVE -2)) 
	  	begin					// start of HBI
			h_blank <= 1'b1;
		end
	
	else if (pixel_count == (`H_TOTAL -2))
 	 	begin					// end of HBI
			h_blank <= 1'b0;
		end
	end


// CREATE THE VERTICAL BLANKING SIGNAL
// the "-2" is used instead of "-1"  in the horizontal factor because of the extra
// register delay for the composite blanking signal 
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin						// on reset
			v_blank <= 1'b0;			// remove v_blank
		end

	else if ((line_count == (`V_ACTIVE - 1) &&
		   (pixel_count == `H_TOTAL - 2))) 
	  	begin						// start of VBI
			v_blank <= 1'b1;
		end
	
	else if ((line_count == (`V_TOTAL - 1)) &&
		   (pixel_count == (`H_TOTAL - 2)))
	 	begin						// end of VBI
			v_blank <= 1'b0;
		end
	end

//data enable
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin					// on reset
			h_data_en <= 1'b0;	// remove the h_blank
		end

	else if (pixel_count == (`H_ACTIVE -2)) 
	  	begin					// start of HBI
			h_data_en <= 1'b0;
		end
	
	else if (pixel_count == (`H_TOTAL -2))
 	 	begin					// end of HBI
			h_data_en <= 1'b1;
		end
	end

always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
		begin						// on reset
			data_en <= 1'b0;			// remove blank
		end
	else if (h_data_en && !v_blank)			// blank during HBI or VBI
		 begin
			data_en <= 1'b1;
		end
	else begin
			data_en <= 1'b0;			// active video do not blank
		end
	end
		
// CREATE THE COMPOSITE BANKING SIGNAL
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
		begin						// on reset
			blank <= 1'b0;			// remove blank
		end

	else if (h_blank || v_blank)			// blank during HBI or VBI
		 begin
			blank <= 1'b1;
		end
	else begin
			blank <= 1'b0;			// active video do not blank
		end
	end
	
// CREATE THE HORIZONTAL LINE PIXEL COUNTER
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin						// on rst_n set pixel counter to 0
			pixel_count <= 11'h000;
		end
	else if (pixel_count == (`H_TOTAL - 1))
 		begin							// last pixel in the line
			pixel_count <= 11'h000;		// rst_n pixel counter
		end

	else 	begin
			pixel_count <= pixel_count +1;		
		end
	end

// CREATE THE HORIZONTAL SYNCH PULSE
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin						// on rst_n
			h_synch <= 1'b0;		// remove h_synch
		end

	else if (pixel_count == (`H_ACTIVE + `H_FRONT_PORCH -1)) 
	  	begin					// start of h_synch
			h_synch <= 1'b1;
		end

	else if (pixel_count == (`H_TOTAL - `H_BACK_PORCH -1))
 	 	begin					// end of h_synch
			h_synch <= 1'b0;
		end
	end


// CREATE THE VERTICAL FRAME LINE COUNTER
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin							// on rst_n set line counter to 0
			line_count <= 10'h000;
		end

	else if ((line_count == (`V_TOTAL - 1))&& (pixel_count == (`H_TOTAL - 1)))
		begin							// last pixel in last line of frame 
			line_count <= 10'h000;		// rst_n line counter
		end

	else if ((pixel_count == (`H_TOTAL - 1)))
		begin							// last pixel but not last line
			line_count <= line_count + 1;// increment line counter
		end
	end

// CREATE THE VERTICAL SYNCH PULSE
always @ (posedge pixel_clock50 or negedge rst_n) begin
	if (!rst_n)
 		begin							// on rst_n
			v_synch = 1'b0;				// remove v_synch
		end

	else if ((line_count == (`V_ACTIVE + `V_FRONT_PORCH -1) &&
		   (pixel_count == `H_TOTAL - 1))) 
	  	begin							// start of v_synch
			v_synch = 1'b1;
		end
	
	else if ((line_count == (`V_TOTAL - `V_BACK_PORCH - 1))	&&
		   (pixel_count == (`H_TOTAL - 1)))
	 	begin							// end of v_synch
			v_synch = 1'b0;
		end
	end
//
reg[1:0]		state;
always @( posedge pixel_clock50 or negedge rst_n )
begin
		if( !rst_n )
		begin
				out_fifo_rden		<= 1'b0;
		end
		else
		begin
				if( data_en == 1'b1 )
				begin
						if( out_fifo_alempty == 1'b0 )
						begin
								out_fifo_rden	<= 1'b1;
						end
						else if( out_fifo_empty == 1'b0 )
						begin
								out_fifo_rden	<= ~ out_fifo_rden;
						end
						else
						begin
								out_fifo_rden	<= 1'b0;
						end
				end
				else
				begin
						out_fifo_rden	<= 1'b0;
				end
		end
end
reg		v_synch_posedge;
reg		v_synch_negedge;
reg		v_synch_reg;
always @( posedge pixel_clock50 or negedge rst_n )
begin
		if( ~rst_n )
		begin
				v_synch_posedge <= 1'b0; 
				v_synch_negedge <= 1'b0; 
				v_synch_reg			<= 1'b0;     
		end 
		else
		begin
				v_synch_reg <= v_synch;
				if(( v_synch_reg == 1'b0 )&&( v_synch == 1'b1 ))
				begin
						v_synch_posedge	<= 1'b1;
				end
				else if (( v_synch_reg == 1'b1 )&&( v_synch == 1'b0 ))
				begin
						v_synch_negedge		<= 1'b1;
				end
				else
				begin
						v_synch_negedge <= 1'b0; 
						v_synch_posedge	<= 1'b0; 
				end		
		end
end

always @( posedge pixel_clock50 or negedge rst_n )
begin
		if( ~rst_n )
		begin
				state		<= 2'b00;
		end
		else
		begin
				case( state )
				2'b00:
				begin
						state	<= 2'b01;
				end
				2'b01:
				begin
						if( v_synch_posedge == 1'b1 )
						begin
								state		<= 2'b10;	
						end
				end
				2'b10:
				begin
						if( v_synch_negedge == 1'b1)// | out_fifo_empty == 1'b1 )
						begin
								state		<= 2'b00;
						end
				end
				default:
				begin
						state		<= 2'b00;
				end
				endcase
		end

end

//Y Cb Cr
always @( posedge pixel_clock50 or negedge rst_n )
begin    
		if( !rst_n )
		begin
				Y <= 8'b0; 
				Cb <= 8'b0; 
				Cr <= 8'b0;
		end
		else
		begin 
				Y <= out_fifo_rd_data[23:16]; 
				Cb <= out_fifo_rd_data[15:8]; 
				Cr <= out_fifo_rd_data[7:0]; 
	  end     
end
//YUV to RGB
YCrCb2RGB U_VtoRGB( 
		.R(Bout), 
		.G(Gout), 
		.B(Rout), 
		.clk(pixel_clock50), 
		.rst(!rst_n), 
		.Y({Y,2'b00}), 
		.Cr({Cr,2'b00}), 
		.Cb({Cb,2'b00}) );
//
always @( posedge pixel_clock50 or negedge rst_n )
begin    
		if( !rst_n )
		begin
				R <= 8'b0; 
				G <= 8'b0; 
				B <= 8'b0;
		end
		else
		begin 
				if( DE )
				begin
						B <= Rout;
						G <= Gout;
						R <= Bout;
				end
				else
				begin
						R <= 8'b0; 
						G <= 8'b0; 
						B <= 8'b0;
				end 
	  end     
end

endmodule //SVGA_TIMING_GENERATION