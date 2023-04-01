module ov5640_dri(
	 input           clk             ,  //时钟
    input           rst_n           ,  //复位信号,低电平有效
    //摄像头接口 
    input           cam_pclk        ,  //cmos 数据像素时钟
    input           cam_vsync       ,  //cmos 场同步信号
    input           cam_href        ,  //cmos 行同步信号
    input    [7:0]  cam_data        ,  //cmos 数据  
    output          cam_rstn       ,  //cmos 复位信号，低电平有效
    output          cam_pwdn        ,  //cmos 电源休眠模式选择信号
    output          cam_scl         ,  //cmos SCCB_SCL线
    inout           cam_sda         ,  //cmos SCCB_SDA线   
    //摄像头分辨率配置接口
    input    [12:0] cmos_hpixel    ,  //水平方向分辨率
    input    [12:0] cmos_vpixel    ,  //垂直方向分辨率
    input    [12:0] total_hpixel   ,  //水平总像素大小
    input    [12:0] total_vpixel   ,  //垂直总像素大小
    input           capture_start   ,  //图像采集开始信号
    output          cam_init_done   ,  //摄像头初始化完成
    
    //用户接口
    output          cmos_frame_vsync,  //帧有效信号    
    output          cmos_frame_href ,  //行有效信号
    output          cmos_frame_valid,  //数据有效使能信号
    output  [15:0]  cmos_frame_data    //有效数据  
);
//parameters
parameter SLAVE_ADDR =7'h3c;
parameter BIT_CTRL	=1'b1;
parameter CLK_FREQ	=27'd50_000_000;
parameter IIC_FREQ	=18'd250_000;
//wires
wire	 		iic_exec;
wire[23:0]	iic_data;
wire			iic_done;
wire			iic_dri_clk;
wire[7:0]	iic_data_r;
wire			iic_rh_wl;

assign cam_pwdn=1'b0;
assign cam_rstn=1'b1;
i2c_ov5640_rgb565_cfg u_iic_cfg(
    .clk                (iic_dri_clk),
    .rst_n              (rst_n&capture_start),
            
    .i2c_exec           (iic_exec),
    .i2c_data           (iic_data),
    .i2c_rh_wl          (iic_rh_wl),        //iic读写控制信号
    .i2c_done           (iic_done), 
    .i2c_data_r         (iic_data_r),   
                
    .cmos_h_pixel       (cmos_hpixel),     //CMOS水平方向像素个数
    .cmos_v_pixel       (cmos_vpixel) ,    //CMOS垂直方向像素个数
    .total_h_pixel      (total_hpixel),    //水平总像素大小
    .total_v_pixel      (total_vpixel),    //垂直总像素大小
        
    .init_done          (cam_init_done) 
);    
iic_dri #(
	.SLAVE_ADDR	(SLAVE_ADDR),
	.CLK_FREQ	(CLK_FREQ),
	.IIC_FREQ	(IIC_FREQ)
)iic_dri_u(
	.clk			(clk),
	.rst_n		(rst_n & capture_start),
	.iic_exec	(iic_exec),
	.bit_ctrl	(BIT_CTRL),
	.iic_rh_wl	(iic_rh_wl),
	.iic_addr	(iic_data[23:8]),
	.iic_data_w	(iic_data[7:0]),
	.iic_data_r	(iic_data_r),
	.iic_done	(iic_done),
	.scl			(cam_scl),
	.sda			(cam_sda),
	.dri_clk		(iic_dri_clk)
);

OV5640_capture_data cmos_capture_data_u(
	 .rst_n              (rst_n & capture_start),
    
    .cam_pclk           (cam_pclk),
    .cam_vsync          (cam_vsync),
    .cam_href           (cam_href),
    .cam_data           (cam_data),         
    
    .cmos_frame_vsync   (cmos_frame_vsync),
    .cmos_frame_href    (cmos_frame_href ),
    .cmos_frame_valid   (cmos_frame_valid), //数据有效使能信号
    .cmos_frame_data    (cmos_frame_data )  //有效数据 
);
endmodule