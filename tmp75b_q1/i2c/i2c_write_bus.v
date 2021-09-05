`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 10:47:13
// Design Name: 
// Module Name: i2c_write_bus
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


module i2c_write_bus(
    input clk,
    input en, //在scl高电平的时候是能en；
    input [7:0] data_in,
    
    input scl_i,
    input sda_i,
    output sda_o
    );
    reg scl_i_reg=1'b1;
    always@(posedge clk)begin
        scl_i_reg <= scl_i;
    end
    wire scl_i_pos = ~scl_i_reg & scl_i;
    wire scl_i_neg = scl_i_reg & ~scl_i;
    
    reg [3:0]data_cnt=0;
    always@(posedge clk)begin
        if(en)begin
            if(scl_i_pos) data_cnt <= data_cnt + 1;
            else data_cnt <= data_cnt;
        end
        else begin
            data_cnt <= 0;
        end
    end
    assign sda_o = (data_cnt[3:3]!=0) ? 1'b1 : data_in[~data_cnt[2:0]];
    
endmodule
