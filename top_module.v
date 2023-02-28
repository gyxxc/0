module top_module(
	input 	clk,
	input 	rst_n,
	//SDCard interface
	input 	sd_miso,
	output 	sd_clk,
	output 	sd_cs,
	output 	sd_mosi,
	//LED
	output[3:0] led
);
//wires
wire 			clk_ref;
wire			clk_ref_180deg;
wire			rstn;
wire			locked;
wire        wr_start_en    ;      //开始写SD卡数据信号
wire[31:0]  wr_sec_addr    ;      //写数据扇区地址    
wire[15:0]  wr_data        ;      //写数据            
wire        rd_start_en    ;      //开始写SD卡数据信号
wire[31:0]  rd_sec_addr    ;      //读数据扇区地址    
wire        error_flag     ;      //SD卡读写错误的标志
wire        wr_busy        ;      //写数据忙信号
wire        wr_req         ;      //写数据请求信号
wire        rd_busy        ;      //读忙信号
wire        rd_val_en      ;      //数据读取有效使能信号
wire[15:0]  rd_val_data    ;      //读数据
wire			sd_init_done   ;      //SD卡初始化完成信号
assign rstn=rst_n&locked;
pll_clk pll_clk_inst(
	.areset (1'b0),
	.inclk0 (clk),
	.c0	  (clk_ref),
	.c1	  (clk_ref_180deg),
	.locked (locked)
);
//
data_gen data_gen_inst(
	.clk				(clk_ref),
	.rst_n			(rst_n),
	.sd_init_done	(sd_init_done),
	.wr_busy			(wr_busy),//写数据忙信号
	.wr_req 			(wr_req),
	.wr_start_en	(wr_start_en),
	.wr_sec_addr	(wr_sec_addr),
	.wr_data			(wr_data),
	.rd_val_en		(rd_val_en),
	.rd_val_data	(rd_val_data),
	.rd_start_en	(rd_start_en),
	.rd_sec_addr	(rd_sec_addr),
	.err_flag		(err_flag)
);
endmodule