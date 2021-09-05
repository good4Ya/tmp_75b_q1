`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 11:22:33
// Design Name: 
// Module Name: i2c_read_bus
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


module i2c_read_bus(
    input clk,
    input en, //在scl高电平的时候是能en；
    output [7:0] data_out,
    
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
    reg [7:0]data;
    reg sda_o_reg=1'b1;
    always@(posedge clk)begin
        if(data_cnt[3:3]==0)begin
            if(scl_i_pos)data[~data_cnt[2:0]] <= sda_i;
        end
        if(scl_i_neg)begin //neg!!!!!
            if(data_cnt==8)sda_o_reg <= 0;
            else sda_o_reg <= 1'b1;
        end
    end
    assign data_out = data;
    assign sda_o = sda_o_reg;
    
endmodule
