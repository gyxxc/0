module top_module(
	input 	clk,
	input 	sys_rst_n,
	//SDCard interface
	input 	sd_miso,
	output 	sd_clk,
	output 	sd_cs,
	output 	sd_mosi,
	//SDRAM interface
	output			sdram_clk,
	output			sdram_clk_en,
	output			sdram_cs_n,
	output			sdram_row_n,
	output			sdram_col_n,
	output			sdram_we_n,
	output[1:0]		sdram_bank,
	output[1:0]		sdram_dqm,
	output[12:0]	sdram_addr,
	output[15:0]	sdram_data,
	//LCD interface
	output			lcd_hs,
	output			lcd_vs,
	output			lcd_de,
	inout[15:0]		lcd_rgb,
	output			lcd_blk,
	output			lcd_rst,
	output			lcd_clk
);
//parameters

//wires
wire 			clk_50M;
wire			clk_50M_180deg;
wire			clk_100M;
wire			clk_100M_shift;
wire			rst_n;
wire			locked;
wire			sys_init_done	;
wire[23:0]	sdram_max_addr	;
wire[15:0]	sd_sec_num		;//SD卡读扇区个数
wire 			sd_rd_start_en	;//开始写SD卡数据信号
wire[31:0]	sd_rd_sec_addr	;//读数据扇区地址
wire			sd_rd_busy		;//读忙信号
wire			sd_rd_val_en	;//数据读取有效使能信号
wire[15:0]	sd_rd_val_data	;//读数据
wire			sdram_wr_n		;
wire[15:0]	sdram_wr_data	;
wire			wr_en				;//SDRAM控制器模块写使能
wire 			rd_en				;//SDRAM控制器模块读使能
wire[15:0] 	rd_data;

wire        wr_start_en    ;      //开始写SD卡数据信号
wire[31:0]  wr_sec_addr    ;      //写数据扇区地址    
wire[15:0]  wr_data        ;      //写数据        
wire        error_flag     ;      //SD卡读写错误的标志
wire        wr_busy        ;      //写数据忙信号
wire        wr_req         ;      //写数据请求信号
wire			sd_init_done   ;      //SD卡初始化完成信号
wire			sdram_init_done;
//待时钟锁定后产生复位信号
assign rst_n			=sys_rst_n&locked;
assign sys_init_done	=sd_init_done&sdram_init_done;
assign wr_en			=sdram_wr_n;
assign wr_data			=sdram_wr_data;
//IP cores
pll_clk pll_clk_inst(
	.areset (1'b0),
	.inclk0 (clk),
	.c0	  (clk_100M),
	.c1	  (clk_100M_shift),
	.c2	  (clk_50M),
	.c3	  (clk_50M_180deg),
	.locked (locked)
);
//
sd_sdram_size sd_sdram_size_u(
	.clk					(clk_50M),
	.rst_n				(rst_n),
	
	.sdram_max_addr	(sdram_max_addr),
	.sd_sec_num			(sd_sec_num)
);
//读取SD卡图片文件
sd_read_photo sd_read_photo_u(
	.clk					(clk_50M),
	.rst_n				(rst_n&sys_init_done),
	.sdram_max_addr	(sdram_max_addr),
	.sd_sec_num			(sd_sec_num),
	
	.rd_busy				(sd_rd_busy),
	.sd_rd_val_en		(sd_rd_val_en),
	.sd_rd_val_data	(sd_rd_val_data),
	
	.rd_start_en		(sd_rd_start_en),
	.rd_sec_addr		(sd_rd_sec_addr),
	.sdram_wr_en		(sdram_wr_n),
	.sdram_wr_data		(sdram_wr_data)
);
//SD卡控制模块
sd_ctrl_top sd_ctrl_top_u(
    .clk_ref      	(clk_50M),  //时钟信号
    .clk_ref_180deg	(clk_50M_180deg),  //时钟信号,与clk_ref相位相差180度
    .rst_n         	(rst_n),  	//复位信号,低电平有效
    //SDCard interface
    .sd_miso       	(sd_miso),  //SD卡SPI串行输入数据信号
    .sd_clk        	(sd_clk),  	//SD卡SPI时钟信号    
    .sd_cs         	(sd_cs),  	//SD卡SPI片选信号
    .sd_mosi       	(sd_mosi),  //SD卡SPI串行输出数据信号
    //用户写SD卡接口
    .wr_start_en   	(1'b0), 			//开始写SD卡数据信号
    .wr_sec_addr   	(32'b0), 		//写数据扇区地址
    .wr_data       	(16'b0),  		//写数据                  
    .wr_busy       	(),  				//写数据忙信号
    .wr_req        	(),  				//写数据请求信号    
    //用户读SD卡接口
    .rd_start_en   	(sd_rd_start_en),  //开始读SD卡数据信号
    .rd_sec_addr   	(sd_rd_sec_addr),  //读数据扇区地址
    .rd_busy       	(sd_rd_busy),  	 //读数据忙信号
    .rd_val_en     	(sd_rd_val_en),  	 //读数据有效信号
    .rd_val_data   	(sd_rd_val_data),  //读数据    
    
    .sd_init_done    (sd_init_done)	 //SD卡初始化完成信号
);
//SDRAM_controller addr:{bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top sdram_top_u(
	.rst_n				(rst_n),
	.ref_clk				(clk_100M),                  //sdram 控制器参考时钟
	.out_clk				(clk_100M_shift),                  //用于输出的相位偏移时钟
	
    //用户写端口			
	.wr_clk				(clk_50M),                   //写端口FIFO: 写时钟
	.wr_en				(wr_en),                    //写端口FIFO: 写使能
	.wr_data				(wr_data),                  //写端口FIFO: 写数据
	.wr_min_addr		(24'd0),              		//写SDRAM的起始地址
	.wr_max_addr		(sdram_max_addr),              //写SDRAM的结束地址
	.wr_len				('d512),                   //写SDRAM时的数据突发长度
	.wr_load				(~rst_n),                  //写端口复位: 复位写地址,清空写FIFO
    
    //用户读端口
	.rd_clk				(lcd_clk),                   		//读端口FIFO: 读时钟
	.rd_en				(rd_en),                   //读端口FIFO: 读使能
	.rd_data				(rd_data),                 //读端口FIFO: 读数据
	.rd_min_addr		(24'd0),              			//读SDRAM的起始地址
	.rd_max_addr		(sdram_max_addr),              //读SDRAM的结束地址
	.rd_len				('d512),                   //从SDRAM中读数据时的突发长度
	.rd_load				(~rst_n),                   //读端口复位: 复位读地址,清空读FIFO
    //用户控制端口  
	.sdram_read_valid	('b1),         				 //SDRAM 读使能
	.sdram_init_done	(sdram_init_done),          //SDRAM 初始化完成标志
    
	//SDRAM 芯片接口
	.sdram_clk			(sdram_clk),                //SDRAM 芯片时钟
	.sdram_cke			(sdram_clk_en),             //SDRAM 时钟有效
	.sdram_cs_n			(sdram_cs_n),               //SDRAM 片选
	.sdram_ras_n		(sdram_row_n),              //SDRAM 行有效
	.sdram_cas_n		(sdram_col_n),              //SDRAM 列有效
	.sdram_we_n			(sdram_we_n),               //SDRAM 写有效
	.sdram_ba			(sdram_bank),               //SDRAM Bank地址
	.sdram_addr			(sdram_addr),               //SDRAM 行/列地址
	.sdram_data			(sdram_data),               //SDRAM 数据
	.sdram_dqm			(sdram_dqm)                 //SDRAM 数据掩码
);
lcd_top lcd_top_u(
	.clk					(clk_50M),
	.rst_n				(rst_n),
	
	.lcd_hs				(lcd_hs),
	.lcd_vs				(lcd_vs),
	.lcd_de				(lcd_de),
	.lcd_rgb				(lcd_rgb),
	.lcd_blk				(lcd_blk),
	.lcd_rst				(lcd_rst),
	.lcd_clk				(lcd_clk),
	.pixel_data			(rd_data),
	.data_req			(rd_en),
	.pixel_hpos			(),
	.pixel_vpos			()
);
endmodule