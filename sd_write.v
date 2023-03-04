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
reg 			wr_en_d0;
reg 			wr_en_d1;
reg 			res_en;
reg[7:0] 	res_data;
reg 			res_flag;
reg[5:0] 	res_bit_cnt;
reg[3:0] 	wr_ctrl_cnt;
reg[47:0] 	cmd_wr;
reg[5:0]		cmd_bit_cnt;
reg[3:0] 	bit_cnt;
reg[8:0] 	data_cnt;
reg[15:0] 	wr_data_t;
reg 			detection_done_flag;
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
			res_bit_cnt<=res_bit_cnt+1'd1;
			res_en<='b0;
		end
		else if(res_flag) begin
			res_data<={res_data[6:0],sd_miso};
			res_bit_cnt<=res_bit_cnt+1'd1;
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
	else			detected_data<='d0;
end
//SDCard write-in
always @(posedge clk_ref or negedge rstn) begin
    if(!rstn) begin
        sd_cs <= 1'b1;
        sd_mosi <= 1'b1; 
        wr_ctrl_cnt <= 4'd0;
        wr_busy <= 1'b0;
        cmd_wr <= 48'd0;
        cmd_bit_cnt <= 6'd0;
        bit_cnt <= 4'd0;
        wr_data_t <= 16'd0;
        data_cnt <= 9'd0;
        wr_req <= 1'b0;
        detection_done_flag <= 1'b0;
    end
    else begin
        wr_req <= 1'b0;
        case(wr_ctrl_cnt)
            4'd0 : begin
                wr_busy <= 1'b0;                            //写空闲
                sd_cs <= 1'b1;                                 
                sd_mosi <= 1'b1;                               
                if(pos_wr_en) begin                            
                    cmd_wr <= {8'h58,wr_sec_addr,8'hff};    //写入单个命令块CMD24
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      //控制计数器加1
                    //开始执行写入数据,拉高写忙信号
                    wr_busy <= 1'b1;                      
                end                                            
            end   
            4'd1 : begin
                if(cmd_bit_cnt <= 6'd47) begin              //开始按位发送写命令
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;
                    sd_cs <= 1'b0;
                    sd_mosi <= cmd_wr[6'd47 - cmd_bit_cnt]; //先发送高字节                 
                end    
                else begin
                    sd_mosi <= 1'b1;
                    if(res_en) begin                        //SD卡响应
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //控制计数器加1 
                        cmd_bit_cnt <= 6'd0;
                        bit_cnt <= 4'd1;
                    end    
                end     
            end                                                                                                     
            4'd2 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;     
                //bit_cnt = 0~7 等待8个时钟周期
                //bit_cnt = 8~15,写入数据头8'hfe        
                if(bit_cnt>=4'd8 && bit_cnt <= 4'd15) begin
                    sd_mosi <= HEAD_BYTE[4'd15-bit_cnt];    //先发送高字节
                    if(bit_cnt == 4'd14)                       
                        wr_req <= 1'b1;                   //提前拉高写数据请求信号
                    else if(bit_cnt == 4'd15)                  
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;  //控制计数器加1   
                end                                            
            end                                                
            4'd3 : begin                                    //写入数据
                bit_cnt <= bit_cnt + 4'd1;                     
                if(bit_cnt == 4'd0) begin                      
                    sd_mosi <= wr_data[4'd15-bit_cnt];      //先发送数据高位     
                    wr_data_t <= wr_data;                   //寄存数据   
                end                                            
                else                                           
                    sd_mosi <= wr_data_t[4'd15-bit_cnt];    //先发送数据高位
                if((bit_cnt == 4'd14) && (data_cnt <= 9'd255)) 
                    wr_req <= 1'b1;                          
                if(bit_cnt == 4'd15) begin                     
                    data_cnt <= data_cnt + 9'd1;  
                    //写入单个BLOCK共512个字节 = 256 * 16bit             
                    if(data_cnt == 9'd255) begin
                        data_cnt <= 9'd0;            
                        //写入数据完成,控制计数器加1          
                        wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;      
                    end                                        
                end                                            
            end       
            //写入2个字节CRC校验,由于SPI模式下不检测校验值,此处写入两个字节的8'hff                                         
            4'd4 : begin                                       
                bit_cnt <= bit_cnt + 4'd1;                  
                sd_mosi <= 1'b1;                 
                //crc写入完成,控制计数器加1              
                if(bit_cnt == 4'd15)                           
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;            
            end                                                
            4'd5 : begin                                    
                if(res_en)                                  //SD卡响应   
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
            end                                                
            4'd6 : begin                                    //等待写完成           
                detection_done_flag <= 1'b1;                   
                //detect_data = 8'hff时,SD卡写入完成,进入空闲状态
                if(detected_data == 8'hff) begin              
                    wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;         
                    detection_done_flag <= 1'b0;                  
                end         
            end    
            default : begin
                //进入空闲状态后,拉高片选信号,等待8个时钟周期
                sd_cs <= 1'b1;   
                wr_ctrl_cnt <= wr_ctrl_cnt + 4'd1;
            end     
        endcase
    end
end            

endmodule