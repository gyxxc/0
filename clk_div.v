module clk_div(
	input			clk,
	input			rst_n,
	output reg 	lcd_pclk
);
//parameters
//wires
//registers
reg clk_25M;
//reg clk_12POINT5M;
reg div_4_cnt;
//时钟二分频输出25MHz时钟
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		clk_25M<='b0;
	else
		clk_25M<=~clk_25M;
end
//时钟四分频输出12.5MHz时钟
/*
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		div_4_cnt		<='b0;
		clk_12POINT5M	<='b0;
	end
	else begin
		div_4_cnt	<=div_4_cnt+'b1;
		if(div_4_cnt)
			clk_12POINT5M<=~clk_12POINT5M;
	end
end
*/
always @(*)begin
	lcd_pclk=clk_25M;
end
endmodule