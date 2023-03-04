module sd_sdram_size(
	input 				clk,
	input 				rst_n,
	output reg[23:0] 	sdram_max_addr,
	output reg[15:0] 	sd_sec_num
);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		sdram_max_addr	<=24'd0;
		sd_sec_num		<=16'd0;
	end
	else begin
		sdram_max_addr	<='d384000;//800*480
		sd_sec_num		<=16'd2250+1'b1;//800*480*3/512 + 1
	end
end
endmodule