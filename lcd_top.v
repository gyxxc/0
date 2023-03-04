module lcd_top(
	input			clk,
	input 		rst_n,
	//LCD interface
	output		lcd_de,
	output		lcd_hs,
	output		lcd_vs,
	output		lcd_clk,//clock for pixels
	inout[15:0]	lcd_rgb,
	output		lcd_rst,
	output		lcd_blk,
	input[15:0]	pixel_data,
	output[10:0]pixel_hpos,
	output[10:0]pixel_vpos,
	output		data_req
);
//wires
wire lcd_pclk;
wire[10:0]	pixel_xpos;
wire[10:0]	pixel_ypos;
wire[15:0]	lcd_rgb_o;
wire[15:0]	lcd_rgb_i;
//
assign lcd_rgb= lcd_de? lcd_rgb_o: {16{1'bz}};//
clk_div clk_div_u(
	.clk		(clk),
	.rst_n	(rst_n),
	.lcd_pclk(lcd_pclk)
);
lcd_driver lcd_driver_u(
	.lcd_pclk      (lcd_pclk  ),
	.rst_n         (rst_n     ),
	
	.pixel_data    (pixel_data),
	.pixel_xpos    (pixel_xpos),
	.pixel_ypos    (pixel_ypos),
	.pixel_hpos    (pixel_hpos),
	.pixel_vpos    (pixel_vpos),
	.data_req      (data_req  ),
	
	.lcd_de        (lcd_de    ),
	.lcd_hs        (lcd_hs    ),
	.lcd_vs        (lcd_vs    ),   
	.lcd_clk       (lcd_clk   ),
	.lcd_rgb       (lcd_rgb_o ),
	.lcd_rst       (lcd_rst   ),
	.lcd_blk       (lcd_blk)
);
endmodule