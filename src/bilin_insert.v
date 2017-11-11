//*************************************************************************\
//Copyright (c) 2008, Lattice Semiconductor Co.,Ltd, All rights reserved
//
//                   File Name  :  bilin_insert.v
//                Project Name  :  creator lattice
//                      Author  :  cloud
//                       Email  :  cloud.yu@latticesemi.com
//                      Device  :  Lattice XP2 Family
//                     Company  :  Lattice Semiconductor Co.,Ltd
//==========================================================================
//   Description:  xxxx
//
//   Called by  :   XXXX.v
//==========================================================================
//   Revision History:
//	Date		  By			Revision	Change Description
//--------------------------------------------------------------------------
//2008/5/30	 Cloud		   0.5			Original
//*************************************************************************/

module bilin_insert 
			(
			clk, 
			Kremain, 
			Din1, 
			Din2, 
			Dout,
			rst
			);

input 				clk,rst;
input [7:0] 	Kremain, Din1, Din2;
output[7:0] 	Dout;

//}} End of automatically maintained section
reg		[7:0] 	Kremain1;
wire		[7:0] 	vdif;
reg 	[8:0]		vdif0,vdif1;
reg 	[8:0]		Dout1;
reg 	[7:0]		Din1_e,Din2_e;
reg		[15:0] 	insertv;
// -- Enter your statements here -- //
assign 				Dout = Dout1[7:0];
assign vdif = vdif0[8]?vdif1[7:0]:vdif0[7:0];
//wire[8:0]			vdif_wire = ~ vdif + 1'b1;
reg						sign;
//base value, different value
always @( posedge clk )
begin
		if( rst )
		begin
		    Din1_e		<= 8'b0;
		   	Din2_e  	<= 8'b0;
		   	Kremain1	<= 8'b0;
		   	vdif0     <= 9'b0;
		   	vdif1			<= 9'b0;
		   	sign			<= 1'b0;
		   	insertv		<= 16'b0;
		   	Dout1			<= 9'b0;
		end
		else
		begin
				Din1_e		<= Din1;
				Din2_e		<= Din1_e;
				Kremain1	<= Kremain;
				vdif0			<= {1'b0,Din2} - {1'b0,Din1};
				vdif1			<= {1'b0,Din1} - {1'b0,Din2};
				sign			<= vdif0[8];
				insertv	<= vdif * Kremain1;
				
				if( sign )
				begin
						Dout1		<= {1'b0,Din2_e} - {1'b0,insertv[15:8]};
				end
				else
				begin
						Dout1		<= {1'b0,Din2_e} + {1'b0,insertv[15:8]};
				end
		end
end


endmodule 
