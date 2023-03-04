 module sd_read_photo(
	input					clk,
	input 				rst_n,
	input[23:0]			sdram_max_addr,
	input[15:0]			sd_sec_num,
					
	input					rd_busy,
	input					sd_rd_val_en,
	input[15:0]			sd_rd_val_data,
	
	output reg			rd_start_en,
	output reg[31:0]	rd_sec_addr,
	output reg			sdram_wr_en,
	output[15:0]		sdram_wr_data
);
//parameters
localparam 	CNT_1S_MAX				=26'd49_999_999;//50_000_000*20ns=1s
parameter 	PHOTO_SELECTION_ADDR0=32'd16448;//32'd
parameter 	PHOTO_SELECTION_ADDR1=32'd18752;//32'd
parameter 	BMP_HEAD_NUM		 	=6'd54;//.bmp
//registers
reg[1:0] 	rd_flow_cnt;//读数据流程控制计数器
reg[15:0]	rd_sec_cnt;	//读扇区次数计数器
reg			rd_addr_sw;	//读图片切换信号
reg[25:0]	delay_cnt;	//延时切换图片计数器
reg			rd_done;		//单张图片读取完成信号
reg			rd_busy_d0;
reg			rd_busy_d1;
reg[1:0]		val_en_cnt;
reg[15:0]	val_data_t;
reg[5:0]		bmp_head_cnt;
reg			bmp_head_flag;
reg[23:0]	rgb_data;
reg[23:0]	sdram_wr_cnt;
reg[1:0]		sdram_flow_cnt;
//wires
wire			rd_busy_n;//SDCard读忙信号下降沿
//main
assign rd_busy_n		=rd_busy_d1 & (~rd_busy_d0);
assign sdram_wr_data	={rgb_data[23:19],rgb_data[15:10],rgb_data[7:3]};
//
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_busy_d0<='b0;
		rd_busy_d1<='b0;
	end
	else begin
		rd_busy_d0<=rd_busy;
		rd_busy_d1<=rd_busy_d0;
	end
end
//循环读取SD卡中的两张图片
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_flow_cnt	<='d0;
		rd_addr_sw	<='b0;
		rd_sec_cnt	<='d0;
		rd_start_en	<='b0;
		rd_sec_addr	<='d0;
		rd_done		<='b0;
		delay_cnt	<=26'd0;
	end
	else begin 
		rd_start_en	<=1'b0;
		rd_done		<=1'b0;
		case(rd_flow_cnt)
			'd0:begin
				rd_flow_cnt	<=rd_flow_cnt+1'd1;
				rd_start_en	<='b1;
				rd_addr_sw	<=~rd_addr_sw;
				if(!rd_addr_sw)
					rd_sec_addr<=PHOTO_SELECTION_ADDR0;
				else
					rd_sec_addr<=PHOTO_SELECTION_ADDR1;
			end//
			'd1:begin
				if(rd_busy_n) begin
					rd_sec_cnt		<=rd_sec_cnt+1'd1;
					rd_sec_addr		<=rd_sec_addr+1'd1;
					if(rd_sec_cnt==sd_sec_num-'b1) begin
						rd_sec_cnt	<='d0;
						rd_flow_cnt	<=rd_flow_cnt+1'd1;
					end
					else	rd_start_en<='b1;
				end
			end//
			'd2:begin
				delay_cnt		<=delay_cnt+1'd1;
				if(delay_cnt==CNT_1S_MAX)begin
					delay_cnt	<=26'd0;
					rd_flow_cnt	<=2'd0;
				end
			end//
			default:;
		endcase
	end
end
//16bit dataflow to 24bit RGB24
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		val_en_cnt		<=2'd0;
		val_data_t		<=16'd0;
		bmp_head_cnt	<=6'd0;
		sdram_wr_en		<=1'b0;
		rgb_data			<=24'd0;
		sdram_wr_cnt	<=24'd0;
		sdram_flow_cnt	<=2'd0;
	end
	else begin
		sdram_wr_en <= 1'b0;
		case(sdram_flow_cnt)
			2'd0 : begin   //BMP首部         
				 if(sd_rd_val_en) begin
					  bmp_head_cnt <= bmp_head_cnt + 1'b1;
					  if(bmp_head_cnt == BMP_HEAD_NUM[5:1] - 1'b1) begin
							sdram_flow_cnt <= sdram_flow_cnt + 1'b1;
							bmp_head_cnt <= 6'd0;
					  end    
				 end   
			end                
			2'd1 : begin   //BMP有效数据
				 if(sd_rd_val_en) begin
					  val_en_cnt <= val_en_cnt + 1'b1;
					  val_data_t <= sd_rd_val_data;                
					  if(val_en_cnt == 2'd1) begin  //3个16位数据转成2个24位数据
							sdram_wr_en <= 1'b1;
							rgb_data <= {sd_rd_val_data[15:8],val_data_t[7:0],val_data_t[15:8]};
					  end
					  else if(val_en_cnt == 2'd2) begin
							sdram_wr_en <= 1'b1;
							rgb_data <= {sd_rd_val_data[7:0],sd_rd_val_data[15:8],val_data_t[7:0]};
							val_en_cnt <= 2'd0;
					  end   
				 end     
				 if(sdram_wr_en) begin
					  sdram_wr_cnt <= sdram_wr_cnt + 1'b1;
					  if(sdram_wr_cnt == sdram_max_addr - 1'b1) begin
							sdram_wr_cnt <= 24'd0;
							sdram_flow_cnt <= sdram_flow_cnt + 1'b1;
					  end
				 end
			end
			2'd2 : begin //等待单张BMP图片读取结束
				 if(rd_done)
					  sdram_flow_cnt <= 2'd0;
			end
			default :;
		endcase
	end
	
end
endmodule