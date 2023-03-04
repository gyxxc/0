module lcd_driver(
	input 				lcd_pclk,
	input 				rst_n,
	input[15:0] 		pixel_data,
	output[15:0]		lcd_rgb,
	output reg 			lcd_blk,
	output reg 			lcd_rst,
	output reg[10:0] 	pixel_hpos,
	output reg[10:0] 	pixel_vpos,
	output 				lcd_clk,
	output 				lcd_hs,
	output 				lcd_vs,
	output 				lcd_de,
	output 				data_req,
	output[10:0]		pixel_xpos,
	output[10:0]		pixel_ypos
);
//parameters

// 7' 800*480   
parameter  H_SYNC_7084   =  11'd128;    //行同步
parameter  H_BACK_7084   =  11'd88;     //行显示后沿
parameter  H_DISP_7084   =  11'd800;    //行有效数据
parameter  H_FRONT_7084  =  11'd40;     //行显示前沿
parameter  H_TOTAL_7084  =  11'd1056;   //行扫描周期
   
parameter  V_SYNC_7084   =  11'd2;      //场同步
parameter  V_BACK_7084   =  11'd33;     //场显示后沿
parameter  V_DISP_7084   =  11'd480;    //场有效数据
parameter  V_FRONT_7084  =  11'd10;     //场显示前沿
parameter  V_TOTAL_7084  =  11'd525;    //场扫描周期       
//registers
reg[10:0] h_sync;
reg[10:0] h_back;
reg[10:0] h_total;
reg[10:0] v_sync;
reg[10:0] v_back;
reg[10:0] v_total;
reg[10:0] h_cnt;
reg[10:0] v_cnt;
//wires
wire lcd_en;
//
assign lcd_hs	=1'b1;
assign lcd_vs	=1'b1;
assign lcd_clk	=lcd_pclk;
assign lcd_de	=lcd_en;
//enable RGB565 data output

assign data_req=((h_cnt >= h_sync + h_back - 1'b1) && (h_cnt < h_sync + h_back + pixel_hpos - 1'b1)&& (v_cnt >= v_sync + v_back)&& (v_cnt < v_sync + v_back + pixel_vpos)) ? 1'b1 : 1'b0;//
assign lcd_en	=((h_cnt>=h_sync+h_back)&&(h_cnt<h_sync + h_back+pixel_hpos)&&(v_cnt>=v_sync+v_back)&&(v_cnt<v_sync + v_back+pixel_vpos))? 1'b1: 1'b0;
assign pixel_xpos	=data_req ? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
assign pixel_ypos	=data_req ? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;
//RG585
assign lcd_rgb= lcd_en? pixel_data: 16'd0;//
//行场时序参数
always@(posedge lcd_pclk)begin
	h_sync  		<= H_SYNC_7084; 
  	h_back  		<= H_BACK_7084; 
	pixel_hpos  <= H_DISP_7084; 
	h_total 		<= H_TOTAL_7084;
	v_sync  		<= V_SYNC_7084; 
 	v_back  		<= V_BACK_7084; 	
 	pixel_vpos  <= V_DISP_7084; 
 	v_total 		<= V_TOTAL_7084;        
end
//行计数器对像素时钟计数
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) 
        h_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1)
            h_cnt <= 11'd0;
        else
            h_cnt <= h_cnt + 1'b1;           
    end
end

//场计数器对行计数
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) 
        v_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1) begin
            if(v_cnt == v_total - 1'b1)
                v_cnt <= 11'd0;
            else
                v_cnt <= v_cnt + 1'b1;    
        end
    end    
end

//控制LCD复位信号和背光信号
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)begin 
        lcd_rst <= 0;
        lcd_blk <= 0;
    end
    else begin
        lcd_rst <= 1;
        lcd_blk <= 1;
    end
end
endmodule