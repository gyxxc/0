module sd_write(
	input clk_ref,
	input clk_ref_180deg,
	input rstn,
	//SDCard interface
	input sd_miso,
	output reg sd_cs,
	output reg sd_mosi,
	//user interface
	input wr_start_en,
	input[31:0] wr_sec_addr,
	input[15:0] wr_data,
	output reg wr_busy,
	output reg wr_req
);
parameter HEAD_BYTE=8'hfe;
//registers
reg 		wr_en_d0;
reg 		wr_en_d1;
reg 		res_en;
reg[7:0] 	res_data;
reg 		res_flag;
reg[5:0] 	res_bit_cnt;
reg[3:0] 	wr_ctrl_cnt;
reg[47:0] 	cmd_wr;

reg[3:0] 	bit_cnt;
reg[8:0] 	data_cnt;
reg[15:0] 	wr_data_t;
reg 		detection_done_flag;
reg[7:0] 	detected_data;
//wires
wire pos_wr_en;
//clock
assign pos_wr_en=(~wr_en_d1)&wr_en_d0;
always@(posedge clk_ref or negedge rstn) begin
	if(!rstn) begin
		wr_en_d0<='b0;
		wr_en_d1<='b0;
	end
	else begin
		wr_en_d0<=wr_start_en;
		wr_en_d1<=wr_en_d0;
	end
end
//
always@(posedge clk_ref_180deg or negedge rstn) begin
	if(!rstn) begin
		res_en<='b0;
		res_data<='d0;
		res_flag<='b0;
		res_bit_cnt<='d0;
	end
	else begin
		//kick-off if sd_miso=0
		if(sd_miso=='b0 && res_flag=='b0) begin
			res_flag<='b1;
			res_data<={res_data[6:0],sd_miso};
			res_bit_cnt<=res_bit_cnt+'d1;
			res_en<='b0;
		end
		else if(res_flag) begin
			res_data<={res_data[6:0],sd_miso};
			res_bit_cnt<=res_bit_cnt+'d1;
			if(res_bit_cnt=='d7) begin
				res_flag<='b0;
				res_bit_cnt<='d0;
				res_en<='b1;
			end
		end
		else	res_en<='b0;
	end
end
//
always@(posedge clk_ref or negedge rstn) begin
	if(!rstn)	detected_data<='d0;
	else if(detection_done_flag)
		detected_data<={detected_data[6:0],sd_miso};
	else	detected_data<='d0;
end
//SDCard write-in
endmodule
