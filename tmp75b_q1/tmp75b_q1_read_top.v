`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/04 09:17:11
// Design Name: 
// Module Name: tmp75b_q1_read_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tmp75b_q1_read_top(

    // iic part master
    inout I2C_SCL,
    inout I2C_SDA,
    
    // logic part
    //clock part
    input clk,
    input rst,
    
    input[2:0]addr,
    
    output[15:0] temprature
    );
    
    wire [31:0] delay_max;
    vio_i2c_temp_read vio_i2c_temp_read_inst (
    .clk(clk),                // input wire clk
    .probe_in0(temp[15:0]),    // input wire [7 : 0] probe_in0
    .probe_in1(temp[15:8]),    // input wire [7 : 0] probe_in0
    .probe_out0(delay_max)  // output wire [31 : 0] probe_out0
    );
    
    reg [15:0] temp,temp_reg;
//    (*mark_debug="true"*)
    reg [7:0]cnt = 0;
    reg [7:0]i2c_data_in;    //(*mark_debug="true"*)
    wire [7:0]i2c_data_out;  //(*mark_debug="true"*)
    reg i2c_data_in_valid=0; //(*mark_debug="true"*)
    wire  i2c_data_in_ready; //(*mark_debug="true"*)
    reg i2c_data_out_ready=0;//(*mark_debug="true"*)
    wire i2c_data_out_valid; //(*mark_debug="true"*)
    reg tbus = 0;            //(*mark_debug="true"*)
//    (*mark_debug="true"*)
    wire bus_busy;
//    (*mark_debug = "true"*)
    reg [31:0]wait_cnt;
//    (*mark_debug = "true"*)
    wire [3:0]debug_version ='d5; //加大div //增加间隔
    
    reg [7:0]next_st=0;
    reg [31:0]cnt_max=0;
    always@(posedge clk)begin
        if(rst)begin
            cnt<=0;
            
            tbus<=0;
            i2c_data_in_valid<=0;
            i2c_data_in      <=0;
            i2c_data_out_ready<=0;
            
            temp<=0;
            temp_reg <= 0;
            
        end
        else begin
        if(cnt == 0)begin
            tbus <= 1'b1;
            cnt <= 1;
            i2c_data_in_valid<=0;
            i2c_data_in      <=0;
            i2c_data_out_ready<=0;
            
        end
        else if(cnt == 1) //输出设备地址，外加读写
        begin
            if(i2c_data_in_valid & i2c_data_in_ready)begin
                i2c_data_in_valid<=1'b1;
                i2c_data_in <= 8'b0000_0000;
                cnt <= 2;
                
            end
            else begin
                i2c_data_in <= {4'b1001,addr,1'b0};
                i2c_data_in_valid<=1'b1;
//                cnt <= 1;//
            end
        end
        else  if(cnt == 2)begin
             if(i2c_data_in_valid & i2c_data_in_ready)begin //写入地址寄存器完成
                tbus <= 1'b0;
                
                i2c_data_in_valid<=0;
                i2c_data_in      <=0;
                i2c_data_out_ready<=0;
                cnt <=8; //进入倒计时等待约27ms后读取温度
                cnt_max <= delay_max;
                next_st <=3;
                wait_cnt<=0;
             end
            
        end
        else  if(cnt == 8)begin
            if(wait_cnt != 'hffffffff )begin
                wait_cnt <= wait_cnt +1 ;
            end
            if(wait_cnt == cnt_max)cnt <= next_st;
        end
        
        else if(cnt == 3 )begin//重新占据总线
            tbus <= 1'b1;
            cnt <= 4;
            i2c_data_in_valid<=0;
            i2c_data_in      <=0;
            i2c_data_out_ready<=0;
        end
        else if(cnt == 4)begin
             if(i2c_data_in_valid & i2c_data_in_ready)begin
                i2c_data_in_valid<=1'b0;
                i2c_data_in <= 8'b0000_0000;
                i2c_data_out_ready <= 1'b1;
                
                cnt <= 5;
                
            end
            else begin
                i2c_data_in <= {4'b1001,addr,1'b1};// 8'b10011_00_1;
                i2c_data_in_valid<=1'b1;
            end
            tbus <= 1'b1;
        end
        else if(cnt == 5)begin
            if(i2c_data_out_ready & i2c_data_out_valid )begin
                temp[15:8]<=i2c_data_out;
                cnt <= 6;
                
            end
            i2c_data_out_ready <= 1'b1;
            tbus <= 1'b1;
        end
        else if(cnt == 6)begin
            if(i2c_data_out_ready & i2c_data_out_valid )begin
                temp[7:0]<=i2c_data_out;
                i2c_data_out_ready <= 1'b0;
                tbus <= 1'b0;
//                cnt <= 7;
                cnt <=8;
                cnt_max <= 640;
                next_st <=7;
                wait_cnt<=0;
                
            end
            else begin
                i2c_data_out_ready <= 1'b1;
            end
        end
        else if(cnt == 7) begin
            cnt <= 0;
            temp_reg <= temp;
        end
        //else cnt<=0;
        end
    end
    
    
    wire scl_i;
    wire scl_o;
    wire scl_t;
    wire sda_i;
    wire sda_o;
    wire sda_t;
    i2c_master_ctrl tb(
     //clock part
      .clk(clk),
      .rst(rst),
      .div_of_clk(40), 
      
      .take_bus(tbus),
   
         .scl_i(scl_i),
         .scl_o(scl_o),
//         .scl_t(scl_t),
         .sda_i(sda_i),
         .sda_o(sda_o),
//         .sda_t(sda_t),
              
      .tx_data(i2c_data_in),
      .tx_valid(i2c_data_in_valid),
      .tx_ready(i2c_data_in_ready),
   
      .rx_data(i2c_data_out),
      .rx_valid(i2c_data_out_valid),
      .rx_ready(i2c_data_out_ready)
    //outside choose tx or rx
    
    //status singals
    ,.bus_busy() // scl out of ctrl?
    ,.ack_lost(bus_busy)
    
    );
    assign temprature = temp_reg;
    
//    assign sda_i   = I2C_SDA;
//    assign scl_i   = I2C_SCL;
//    assign I2C_SDA = ~sda_o ? 1'b0 : 1'bz ;
//    assign I2C_SCL = ~scl_o ? 1'b0 : 1'bz ;
    IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst_sda (
      .O(sda_i),     // Buffer output
      .IO(I2C_SDA),   // Buffer inout port (connect directly to top-level port)
      .I(sda_o),     // Buffer input
      .T(sda_o)      // 3-state enable input, high=input, low=output
   );
       IOBUF #(
      .DRIVE(12), // Specify the output drive strength
      .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
      .IOSTANDARD("DEFAULT"), // Specify the I/O standard
      .SLEW("SLOW") // Specify the output slew rate
   ) IOBUF_inst_scl (
      .O(scl_i),     // Buffer output
      .IO(I2C_SCL),   // Buffer inout port (connect directly to top-level port)
      .I(scl_o),     // Buffer input
      .T(scl_o)      // 3-state enable input, high=input, low=output
   );
   
    
  
    
endmodule
