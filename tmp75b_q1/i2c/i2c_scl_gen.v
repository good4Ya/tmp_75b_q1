`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 13:55:37
// Design Name: 
// Module Name: i2c_scl_gen
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


module i2c_scl_gen(
    input clk,
    input [31:0]div,
    
    input scl_en, //en->0 scl->不下降，因此en要在scl_pos 为中心变化,en在scl-high 变化
    output scl_o,
    output scl_beat
    );
    reg [31:0]cnt = 0;
    always@(posedge clk)begin
        if(cnt == div-1)begin
            cnt <= 0;
        end
        else begin
            cnt <= cnt + 1;
        end        
    end
    reg scl_reg=1'b1;
    always@(posedge clk)begin
        if(cnt == 0) scl_reg <= 1'b1;
        else if(cnt == {1'b0,div[31:1]}-1) scl_reg <= 1'b0;
        else scl_reg <= scl_reg;
    end
    
    reg scl_o_reg=1'b1;
    always@(posedge clk)begin
        if(cnt == 0) scl_o_reg <= 1'b1;
        else if(cnt == {1'b0,div[31:1]}-1 && scl_en) scl_o_reg <= 1'b0;
        else scl_o_reg <= scl_o_reg;
    end
    
    assign scl_o = scl_o_reg;
    assign scl_beat = scl_reg;
    
    
endmodule
