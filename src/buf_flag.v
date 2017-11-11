
`timescale 1ns / 1ps
module buf_flag
			 (
			 clk,
			 rst_n,
			 rd_rls,
			 wr_rls,
			 buf_flag
			 );
input	[1:0]		rd_rls;
input	[1:0]		wr_rls;
input					clk;
input					rst_n;
output[1:0] 	buf_flag;
//
reg		[1:0]		buf_flag;
always @( posedge clk or negedge rst_n )
begin
		if( ~rst_n )
		begin
				buf_flag[0] <= 1'b0;
		end
		else
		begin
				case( buf_flag[0] )
				1'b0:
				begin
						if( wr_rls[0] == 1'b1 )
						begin
								buf_flag[0] <= 1'b1;
						end
				end
				1'b1:
				begin
						if( rd_rls[0] == 1'b1 )
						begin
								buf_flag[0] <= 1'b0;
						end
				end
				default:
				begin
						buf_flag[0] <= 1'b0;
				end
				endcase
		end
end		
//
always @( posedge clk or negedge rst_n )
begin
		if( ~rst_n )
		begin
				buf_flag[1] <= 1'b0;
		end
		else
		begin
				case( buf_flag[1] )
				1'b0:
				begin
						if( wr_rls[1] == 1'b1 )
						begin
								buf_flag[1] <= 1'b1;
						end
				end
				1'b1:
				begin
						if( rd_rls[1] == 1'b1 )
						begin
								buf_flag[1] <= 1'b0;
						end
				end
				default:
				begin
						buf_flag[1] <= 1'b0;
				end
				endcase
		end
end
endmodule