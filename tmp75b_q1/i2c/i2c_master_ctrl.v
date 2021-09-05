`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 14:52:30
// Design Name: 
// Module Name: i2c_master_ctrl
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


module i2c_master_ctrl(
     //clock part
    input           clk,
    input           rst,
    input [31:0]    div_of_clk, 
    
    input           take_bus,
    
    (*mark_debug = "true"*)input  wire        scl_i,
    (*mark_debug = "true"*)output wire        scl_o,

    (*mark_debug = "true"*)input  wire        sda_i,
    (*mark_debug = "true"*)output wire        sda_o,

    
    input  [7:0]    tx_data,
    input           tx_valid,
    output          tx_ready,
    
    output [7:0]    rx_data,
    output          rx_valid,
    input           rx_ready
    //outside choose tx or rx
    
    //status singals
    ,output bus_busy // scl out of ctrl?
    ,output ack_lost
    );
    
    wire scl;                    //(*mark_debug = "true"*)
    wire scl_b;                  //(*mark_debug = "true"*)
    wire scl_en      ;//=1'b0;   //(*mark_debug = "true"*)
    wire read_en     ;//=0;      //(*mark_debug = "true"*)
    wire write_en    ;//=0;      //(*mark_debug = "true"*)
     i2c_scl_gen scl_gen_inst(
        .clk(clk),
        .scl_en(scl_en),
        .scl_o(scl),
        .scl_beat(scl_b),
        .div(div_of_clk)
    );
    
   wire sda_o_w;// (*mark_debug = "true"*)
   wire sda_o_r;// (*mark_debug = "true"*)
    reg sda_o_reg=1'b1;
    always@(posedge clk)begin
        if(rst)begin
            sda_o_reg <= 1'b1;
        end
        else if (~scl_b)begin // neg-0
            sda_o_reg <= (st==st_stop) ? 1'b1 : (st == st_start) ? 1'b0 : (st == st_send) ? sda_o_w : (st == st_recv) ? sda_o_r : scl? sda_o_reg :1'b1;
        end
    end
    assign sda_o = sda_o_reg;
    assign scl_o = scl;
    reg [7:0]tx_data_reg=0;
    i2c_read_bus i2c_read_inst(
        .clk      ( clk )
        ,.en      ( read_en )
        ,.data_out( rx_data )
        ,.scl_i   ( scl )
        ,.sda_i   ( sda_i )
        ,.sda_o   ( sda_o_r ) 
        
    );    
    i2c_write_bus i2c_write_inst(
        .clk      ( clk )
        ,.en      ( write_en )
        ,.data_in ( tx_data_reg )
        ,.scl_i   ( scl )
        ,.sda_i   ( sda_i )
        ,.sda_o   ( sda_o_w ) //
        
    );
    
    always@(posedge clk)
    begin
        tx_data_reg <= (tx_ready & tx_valid) ? tx_data : tx_data_reg;
    end
    
    reg scl_reg=1'b1;
    reg scl_b_reg=1'b1;
    always@(posedge clk)begin
         scl_reg    <= scl;
         scl_b_reg  <= scl_b;
    end
    wire scl_pos   =   scl    & ~scl_reg   ;
    wire scl_neg   =  ~scl    &  scl_reg   ;
    wire scl_b_pos =   scl_b  & ~scl_b_reg   ;
    wire scl_b_neg =  ~scl_b  &  scl_b_reg   ;
    
    
    //scl_en
    assign scl_en = read_en | write_en;
    //read_en
    assign read_en = (st == st_recv);
    //write_en
    assign write_en = (st == st_send);
    //tx_ready wire ? st-start-wait wire!
    assign tx_ready = (st == st_wait) & scl_b_pos;
//    reg tx_ready_reg = 0;
//    always@(posedge clk)begin
        
//    end
    
    
    wire rx_valid_tmp = (st == st_recv && cnt==8);
    reg rx_valid_tmp_d;
    always@(posedge clk)begin
        rx_valid_tmp_d<=rx_valid_tmp;
    end
    reg rx_valid_reg = 0;
    always@(posedge clk)begin
        if(rx_valid & rx_ready)begin
            rx_valid_reg <= 0;
        end
        else if((~rx_valid_tmp_d &  rx_valid_tmp))begin
            rx_valid_reg <= 1'b1;
        end
    end
    assign rx_valid = rx_valid_reg;
    
//    (*mark_debug = "true"*)
    reg [3:0]st = 0;
    parameter st_idle = 4'd0;
    parameter st_start = 4'd1; // scl_disable
    parameter st_wait = 4'd2;//scl_high wait 4 tx valid or rx ready
    parameter st_send = 4'd3;//scl_en
    parameter st_recv = 4'd4;//scl_en
    parameter st_stop = 4'd5;//scl_disable
    
//    (*mark_debug = "true"*)
    reg [3:0] cnt=0;
    //all sda changed in this mod is scl_o edge
    //stat change at scl_beat posedge?
 
    always@(posedge clk)begin
        if(rst)begin
            st <= st_idle;
        end
        else if(scl_b_pos) begin //or neg?
            case(st)
            st_idle:begin
                if(take_bus)begin
                    st <= st_start;
                end
            end
            st_start:begin
                st <= st_wait;
            end
            st_wait:begin
                if(~take_bus)begin
                    st <= st_stop;
                end
                else if(tx_valid)begin
                    st <= st_send;//要不要增加两个模块的done,加了cnt不加done
                end
                else if(rx_ready)begin
                    st <= st_recv;
                end
                cnt <= 0;
            end
            st_send:begin
                if(cnt < 8)begin
                    cnt <= cnt +1;
                    st <= st;
                end
                else begin
                    cnt <= cnt;
                    st <= st_wait;
                end
            end
            st_recv:begin
                 if(cnt < 8)begin
                    cnt <= cnt +1;
                    st <= st;
                end
                else begin
                    cnt <= cnt;
                    st <= st_wait;
                end
            end
            st_stop:begin
                st <= st_idle;
            end
            
            default:begin
                st <= st_idle;
            end
            endcase
        end
    end
    
    reg nack_reg=0;
    always@(posedge clk)begin
        if(scl_b_pos) nack_reg<=(cnt==8)& sda_i;
    end
    assign ack_lost = nack_reg;//(cnt==8) & scl_b_pos & sda_i;
    
endmodule
