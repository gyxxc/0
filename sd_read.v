module sd_read(
     input       	clk_ref,
     input     	clk_ref_180deg,
     input     	rst_n,
    //SDCard interface
     input        sd_miso,
     output reg   rd_sd_cs,
     output reg   rd_sd_mosi,    
    //SD卡初始化完成之后响应读操作
     input			rd_start_en,  
     input[31:0]	rd_sec_addr,
     input[15:0]	rd_busy,
     output reg	rd_val_en,
     output reg 	rd_val_data
);
endmodule