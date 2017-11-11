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
module 	I2C_V_Config 
				(	
				//	Host Side
				iCLK,
				iRST_N,   // inter reset output
				mI2C_CTRL_CLK,
				//	I2C Side
				I2C_SCLK,
				I2C_SDAT	
				);

//	Host Side
input				iCLK;
input 			iRST_N;               // inter reset output

output 			mI2C_CTRL_CLK;
//	I2C Side
output			I2C_SCLK;
inout				I2C_SDAT;

//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;           //??? 2500 range counter only need 12-bits bregister with max 2^12=4096
reg	[15:0]	mI2C_Rst_DIV;
reg	[15:0]	mI2C_CLKO_DIV; 
reg	[23:0]	mI2C_DATA;              // 8-bits SLAVE_ADDR, 8-bits SUB_ADDR, 8-bits DATA
reg					mI2C_CTRL_CLK;
reg					mI2C_GO;
//reg			iRST_N;
wire				mI2C_END;
wire				mI2C_ACK;
reg					mI2C_CLKO;	   
reg	[15:0]	LUT_DATA;    // 8-bits SUB_ADDR, 8-bits DATA
reg	[5:0]		LUT_INDEX;   // range from 0 to 49 must with 6-bit register-max-64
reg	[3:0]		mSetup_ST;   //
//reg	[5:0]	tLUT_INDEX;          //????????

//	Clock Setting
parameter		CLK_Freq	=	50000000;	//???	50	MHz
parameter		I2C_Freq	=	80000;		//???	40	KHz 25Us
parameter		I2C_Thd		=	200000;		//???	5Us 200	KHz


//	LUT Data Number
parameter		LUT_SIZE	=	51;  //must initialize total register number is 50
      


//	Video Data Index
parameter		SET_VIDEO	=	0;   //  update



//assign iRST_N = 1;

/////////////////////	iRST_N 	////////////////////////
/*always@(posedge mI2C_CTRL_CLK )
begin
	if( mI2C_Rst_DIV	< 16'hffff )
	   begin 
		iRST_N <= 0;
		mI2C_Rst_DIV	<=	mI2C_Rst_DIV+1;
	   end
	else
		iRST_N <= 1;
end*/

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
  // 5000 times divide frequence of iCLK
  		if (!iRST_N)
  		begin
  			mI2C_CLK_DIV <= 0;
  			mI2C_CLKO <= 0;
  			mI2C_CTRL_CLK <= 0;
  		end
		else if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
		begin
		 		mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		 		if ((!mI2C_CTRL_CLK)&(mI2C_CLK_DIV < ((CLK_Freq/I2C_Freq)- (CLK_Freq/I2C_Thd))) )
					mI2C_CLKO <= 0;
		 		else
		 		  mI2C_CLKO <= 1;
		end
		else
		begin
				mI2C_CLK_DIV	<=	0;
				mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
end


////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	
								(	
								.CLOCK(mI2C_CTRL_CLK),		//	Controller Work Clock
								.Clk_O(mI2C_CLKO),
								.I2C_SCLK(I2C_SCLK),		//	I2C CLOCK
 	 	 	 	 	 			.I2C_SDAT(I2C_SDAT),		//	I2C DATA
								.I2C_DATA(mI2C_DATA),		//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
								.GO(mI2C_GO),      			//	GO transfor
								.END(mI2C_END),				//	END transfor 
								.ACK(mI2C_ACK),				//	ACK
								.RESET(iRST_N)	
								);
////////////////////////////////////////////////////////////////////


//////////////////////	Config Control	////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
		if(!iRST_N)
		begin
				LUT_INDEX	<=	0;
				mSetup_ST	<=	0;
				mI2C_GO		<=	0;
		end
		else
		begin
				if(LUT_INDEX<LUT_SIZE+1)    //total of initial register, LUT_SIZE	=50
				begin
						case(mSetup_ST)
						0:	
						begin   // active
								mI2C_DATA	<=	{8'h4A,LUT_DATA};   //8-bits slave address, 8-bits subaddress, 8-bits data
								mI2C_GO		<=	1;
								mSetup_ST	<=	1;
						end
						1:	
						begin
								if(mI2C_END)
								begin
//									if(!mI2C_ACK)
									mSetup_ST	<=	2;
//									else
//									mSetup_ST	<=	0;							
									mI2C_GO		<=	0;
								end
						end
						2:	
						begin
								LUT_INDEX	<=	LUT_INDEX+1;
								mSetup_ST	<=	0;
						end
						endcase
				end
				else
				mI2C_GO		<=	0;
		end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////	
always @( LUT_INDEX )
begin
		case(LUT_INDEX)
  	
  	
		//	Audio Config Data
		//SET_LIN_L	:	LUT_DATA	<=	16'h001A;
		//SET_LIN_R	:	LUT_DATA	<=	16'h021A;
		//SET_HEAD_L	:	LUT_DATA	<=	16'h047B;
		//SET_HEAD_R	:	LUT_DATA	<=	16'h067B;
		//A_PATH_CTRL	:	LUT_DATA	<=	16'h08F8;
		//D_PATH_CTRL	:	LUT_DATA	<=	16'h0A06;
		//POWER_ON	:	LUT_DATA	<=	16'h0C00;
		//SET_FORMAT	:	LUT_DATA	<=	16'h0E01;
		//SAMPLE_CTRL	:	LUT_DATA	<=	16'h1002;
		//SET_ACTIVE	:	LUT_DATA	<=	16'h1201;
  	
  	
  	
  	
  	
  	
		//	Video Config Data
/*
SET_VIDEO+0	:	LUT_DATA	<=	16'h0108;
SET_VIDEO+1	:	LUT_DATA	<=	16'h02c0;
SET_VIDEO+2	:	LUT_DATA	<=	16'h0320;
SET_VIDEO+3	:	LUT_DATA	<=	16'h0476;
SET_VIDEO+4	:	LUT_DATA	<=	16'h0576;
SET_VIDEO+5	:	LUT_DATA	<=	16'h06E9;
SET_VIDEO+6	:	LUT_DATA	<=	16'h070D;
SET_VIDEO+7	:	LUT_DATA	<=	16'h08D8;
SET_VIDEO+8	:	LUT_DATA	<=	16'h0900;
SET_VIDEO+9	:	LUT_DATA	<=	16'h0A80;
SET_VIDEO+10:	LUT_DATA	<=	16'h0B47;
SET_VIDEO+11:	LUT_DATA	<=	16'h0C40;
SET_VIDEO+12:	LUT_DATA	<=	16'h0D00;
SET_VIDEO+13:	LUT_DATA	<=	16'h0E05;
SET_VIDEO+14:	LUT_DATA	<=	16'h0F2A;
SET_VIDEO+15:	LUT_DATA	<=	16'h1000;
SET_VIDEO+16:	LUT_DATA	<=	16'h110D;
SET_VIDEO+17:	LUT_DATA	<=	16'h12A7;
SET_VIDEO+18:	LUT_DATA	<=	16'h1300;
SET_VIDEO+19:	LUT_DATA	<=	16'h1500;
SET_VIDEO+20:	LUT_DATA	<=	16'h1600;
SET_VIDEO+21:	LUT_DATA	<=	16'h1700;
SET_VIDEO+22:	LUT_DATA	<=	16'h4082;
SET_VIDEO+23:	LUT_DATA	<=	16'h41FF;
SET_VIDEO+24:	LUT_DATA	<=	16'h42FF;
SET_VIDEO+25:	LUT_DATA	<=	16'h43FF;
SET_VIDEO+26:	LUT_DATA	<=	16'h44FF;
SET_VIDEO+27:	LUT_DATA	<=	16'h45FF;
SET_VIDEO+28:	LUT_DATA	<=	16'h46FF;
SET_VIDEO+29:	LUT_DATA	<=	16'h47FF;
SET_VIDEO+30:	LUT_DATA	<=	16'h48FF;
SET_VIDEO+31:	LUT_DATA	<=	16'h49FF;
SET_VIDEO+32:	LUT_DATA	<=	16'h4AFF;
SET_VIDEO+33:	LUT_DATA	<=	16'h4BFF;
SET_VIDEO+34:	LUT_DATA	<=	16'h4CFF;
SET_VIDEO+35:	LUT_DATA	<=	16'h4DFF;
SET_VIDEO+36:	LUT_DATA	<=	16'h4EFF;
SET_VIDEO+37:	LUT_DATA	<=	16'h4FFF;
SET_VIDEO+38:	LUT_DATA	<=	16'h50FF;
SET_VIDEO+39:	LUT_DATA	<=	16'h51FF;
SET_VIDEO+40:	LUT_DATA	<=	16'h52FF;
SET_VIDEO+41:	LUT_DATA	<=	16'h53FF;
SET_VIDEO+42:	LUT_DATA	<=	16'h54FF;
SET_VIDEO+43:	LUT_DATA	<=	16'h55FF;
SET_VIDEO+44:	LUT_DATA	<=	16'h56FF;
SET_VIDEO+45:	LUT_DATA	<=	16'h57FF;
SET_VIDEO+46:	LUT_DATA	<=	16'h5840;
SET_VIDEO+47:	LUT_DATA	<=	16'h5954;
SET_VIDEO+48:	LUT_DATA	<=	16'h5A0A;
SET_VIDEO+49:	LUT_DATA	<=	16'h5B03;
SET_VIDEO+50:	LUT_DATA	<=	16'h5E00;
*/

		SET_VIDEO+0	:	LUT_DATA	<=	16'h0108;
		SET_VIDEO+1	:	LUT_DATA	<=	16'h02C3;//default C0
		SET_VIDEO+2	:	LUT_DATA	<=	16'h0333;//default 33
		SET_VIDEO+3	:	LUT_DATA	<=	16'h0400;//default 00
		SET_VIDEO+4	:	LUT_DATA	<=	16'h0500;//default 00
		SET_VIDEO+5	:	LUT_DATA	<=	16'h06e9;
		SET_VIDEO+6	:	LUT_DATA	<=	16'h070d;
		SET_VIDEO+7	:	LUT_DATA	<=	16'h0898;
		SET_VIDEO+8	:	LUT_DATA	<=	16'h0901;
		SET_VIDEO+9	:	LUT_DATA	<=	16'h0a80;
  	
		SET_VIDEO+10:	LUT_DATA	<=	16'h0b47;
		SET_VIDEO+11:	LUT_DATA	<=	16'h0c40;
		SET_VIDEO+12:	LUT_DATA	<=	16'h0d00;
		SET_VIDEO+13:	LUT_DATA	<=	16'h0e01;
		SET_VIDEO+14:	LUT_DATA	<=	16'h0f2a;
		SET_VIDEO+15:	LUT_DATA	<=	16'h1000;
		SET_VIDEO+16:	LUT_DATA	<=	16'h110c;
		SET_VIDEO+17:	LUT_DATA	<=	16'h1201;
		SET_VIDEO+18:	LUT_DATA	<=	16'h1300;
		SET_VIDEO+19:	LUT_DATA	<=	16'h1500;
  	
		SET_VIDEO+20:	LUT_DATA	<=	16'h1600;
		SET_VIDEO+21:	LUT_DATA	<=	16'h1700;
		SET_VIDEO+22:	LUT_DATA	<=	16'h4002;
		SET_VIDEO+23:	LUT_DATA	<=	16'h41ff;
		SET_VIDEO+24:	LUT_DATA	<=	16'h42ff;
		SET_VIDEO+25:	LUT_DATA	<=	16'h43ff;
		SET_VIDEO+26:	LUT_DATA	<=	16'h44ff;
		SET_VIDEO+27:	LUT_DATA	<=	16'h45ff;
		SET_VIDEO+28:	LUT_DATA	<=	16'h46ff;
		SET_VIDEO+29:	LUT_DATA	<=	16'h47ff;
  	
		SET_VIDEO+30:	LUT_DATA	<=	16'h48ff;
		SET_VIDEO+31:	LUT_DATA	<=	16'h49ff;
		SET_VIDEO+32:	LUT_DATA	<=	16'h4aff;
		SET_VIDEO+33:	LUT_DATA	<=	16'h4bff;
		SET_VIDEO+34:	LUT_DATA	<=	16'h4cff;
		SET_VIDEO+35:	LUT_DATA	<=	16'h4dff;
		SET_VIDEO+36:	LUT_DATA	<=	16'h4eff;
		SET_VIDEO+37:	LUT_DATA	<=	16'h4fff;
		SET_VIDEO+38:	LUT_DATA	<=	16'h50ff;
		SET_VIDEO+39:	LUT_DATA	<=	16'h51ff;
		SET_VIDEO+40:	LUT_DATA	<=	16'h52ff;
  	
		SET_VIDEO+41:	LUT_DATA	<=	16'h53ff;
		SET_VIDEO+42:	LUT_DATA	<=	16'h54ff;
		SET_VIDEO+43:	LUT_DATA	<=	16'h55ff;
		SET_VIDEO+44:	LUT_DATA	<=	16'h56ff;
		SET_VIDEO+45:	LUT_DATA	<=	16'h57ff;
		SET_VIDEO+46:	LUT_DATA	<=	16'h5800;
		SET_VIDEO+47:	LUT_DATA	<=	16'h5954;
		SET_VIDEO+48:	LUT_DATA	<=	16'h5a07;
		SET_VIDEO+49:	LUT_DATA	<=	16'h5b83;
		SET_VIDEO+50:	LUT_DATA	<=	16'h5e00;
 	
		endcase
end
////////////////////////////////////////////////////////////////////
endmodule
