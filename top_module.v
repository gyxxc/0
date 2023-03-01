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
wire	    sd_init_done   ;      //SD卡初始化完成信号
assign rstn=rst_n&locked;
pll_clk pll_clk_inst(
	.areset 	(1'b0),
	.inclk0 	(clk),
	.c0	 	(clk_ref),
	.c1	 	(clk_ref_180deg),
	.locked 	(locked)
);
//
data_gen data_gen_inst(
	.clk		(clk_ref),
	.rst_n		(rst_n),
	.sd_init_done	(sd_init_done),
	.wr_busy	(wr_busy),//写数据忙信号
	.wr_req 	(wr_req),
	.wr_start_en	(wr_start_en),
	.wr_sec_addr	(wr_sec_addr),
	.wr_data	(wr_data),
	.rd_val_en	(rd_val_en),
	.rd_val_data	(rd_val_data),
	.rd_start_en	(rd_start_en),
	.rd_sec_addr	(rd_sec_addr),
	.err_flag	(err_flag)
);
sd_ctrl_top sd_ctrl_top_inst(
	.clk_ref      	(clk_ref),  //时钟信号
    	.clk_ref_180deg	(clk_ref_180deg),  //时钟信号,与clk_ref相位相差180度
    	.rst_n         	(rst_n),  	//复位信号,低电平有效
    	//SDCard interface
    	.sd_miso       	(sd_miso),  //SD卡SPI串行输入数据信号
    	.sd_clk        	(sd_clk),  	//SD卡SPI时钟信号    
    	.sd_cs         	(sd_cs),  	//SD卡SPI片选信号
    	.sd_mosi       	(sd_mosi),  //SD卡SPI串行输出数据信号
    	//用户写SD卡接口
    	.wr_start_en   	(wr_start_en), //开始写SD卡数据信号
    	.wr_sec_addr   	(wr_sec_addr), //写数据扇区地址
    	.wr_data       	(wr_data),  	//写数据                  
    	.wr_busy       	(wr_busy),  	//写数据忙信号
    	.wr_req        	(wr_req),  		//写数据请求信号    
    	//用户读SD卡接口
    	.rd_start_en   	(rd_start_en),  //开始读SD卡数据信号
    	.rd_sec_addr   	(rd_sec_addr),  //读数据扇区地址
    	.rd_busy       	(rd_busy),  	 //读数据忙信号
    	.rd_val_en     	(rd_val_en),  	 //读数据有效信号
    	.rd_val_data   	(rd_val_data),  //读数据    
    
    	.sd_init_done    (sd_init_done)	 //SD卡初始化完成信号
);
endmodule
