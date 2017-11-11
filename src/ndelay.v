//delay module : doutput delay n clks after idinput
//WIDTH AND DELAYS VALUE MUST BIGGER THAN 2
module ndelay(clk,dinput,doutput);
    parameter WIDTH = 8;
	parameter DELAYS = 2;
	input clk;
    input [WIDTH-1:0] dinput;
    output [WIDTH-1:0] doutput;

	reg[WIDTH-1:0] relay[DELAYS-1:0];
	integer i;

	assign doutput = relay[DELAYS-1];

	always @(posedge clk)
	begin
		relay[0] <= dinput;
		for(i=0;i<DELAYS-1;i=i+1)
		begin
			relay[i+1] <= relay[i];
		end
	end
endmodule