module sdram_controller(
	input clk,
	input rst_n,
	input sdram_wr_req, 	//sdram 写请求
	input sdram_wr_ack, 	//sdram 写响应
	input sdram_wr_addr, 	//sdram 写地址
	.sdram_wr_burst,		    //写sdram时数据突发长度
	.sdram_din,    	//写入sdram中的数据
    
    //SDRAM 控制器读端口
	.sdram_rd_req, 	//sdram 读请求
	.sdram_rd_ack,		//sdram 读响应
	.sdram_rd_addr, 	//sdram 读地址
	.sdram_rd_burst,		    //读sdram时数据突发长度
	.sdram_dout,   	//从sdram中读出的数据
    
	.sdram_init_done,	//sdram 初始化完成标志

	//SDRAM 芯片接口
	.sdram_cke,		//SDRAM 时钟有效
	.sdram_cs_n,		//SDRAM 片选
	.sdram_ras_n,		//SDRAM 行有效	
	.sdram_cas_n,		//SDRAM 列有效
	.sdram_we_n,		//SDRAM 写有效
	.sdram_ba,			//SDRAM Bank地址
	.sdram_addr,		//SDRAM 行/列地址
	.sdram_data
);
//wires

//
sdram_ctrl sdram_ctrl_u(
	.clk,
	.rst_n,
	.sdram_wr_req,
	.sdram_rd_req,
	.sdram_wr_ack,
	.sdram_rd_ack,
	.sdram_wr_burst,
	.sdram_rd_burst,
	.sdram_init_done,
	.init_state,
	.work_state,
	.cnt_clk,
	.sdram_rd_wr
);
//
sdram_data sdram_data_u(
	.clk,
	.rst_n,
	.sdram_data_in,
	.sdram_data_out,
	.work_state,
	.cnt_clk,
	.sdram_data
);
sdram_cmd  sdram_cmd(

);
endmodule