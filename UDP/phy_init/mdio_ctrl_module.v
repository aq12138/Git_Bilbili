//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:     yuqi
// 
// Create Date:  2023/04/06 19:47:03
// Design Name:  
// Module Name:  mdio_ctrl_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  mdio控制
// 
// Dependencies: 
// 
// Revision:     v0.1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mdio_ctrl_module(
    input               i_mdio_clk      ,
    input               i_mdio_rst      ,
    inout               io_mdio         ,

    input  [4 :0]       i_phy_addr      ,
    input  [4 :0]       i_reg_addr      ,
    input  [15:0]       i_reg_data      ,

    input  [1 :0]       i_op_cmd        ,
    input               i_op_valid      ,
    output              o_op_ready      ,

    output              o_phy_clk_ctrl  ,

    output [15:0]       o_read_data     ,
    output              o_read_valid        
);

/***************start*****************/

/***************parameter*************/
parameter       P_MDIO_SF   = 2'b01     ;
parameter       P_MDIO_W    = 2'b01     ;
parameter       P_MDIO_R    = 2'b10     ;


/***************port******************/             

/***************mechine***************/
reg  [7:0]      r_st_cnt                ;
reg             r_operation_start       ; 

/***************reg*******************/
reg             r_mdio_out              ;/*synthesis noprune*/
reg             r_mdio_ctrl             ;/*synthesis noprune*/
reg [4 :0]      r_phy_addr              ;
reg [4 :0]      r_reg_addr              ;
reg [15:0]      r_reg_data              ;
reg [15:0]      r_read_data             ;
reg             r_read_valid            ;
reg [62:0]      r_mdio_out_data_list    ;
reg [1 :0]      r_op_cmd                ;
reg             r_op_active             ;

/***************wire******************/
(* keep *)wire            w_mdio_input            ;
wire            w_op_active             ;

/***************assign****************/
assign          io_mdio      = r_mdio_ctrl ? r_mdio_out : 1'bz      ;
assign          w_mdio_input = r_mdio_ctrl ? 1'b0       : io_mdio   ;
assign          w_op_active  = i_op_valid & o_op_ready              ;
assign          o_read_data  = r_read_data                          ; 
assign          o_op_ready   = ~r_operation_start;
assign          o_read_valid = r_read_valid;
assign          o_phy_clk_ctrl = r_operation_start  ;

/***************component*************/

/***************always****************/
always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_op_active <= 'd0;
    else 
        r_op_active <= w_op_active;


always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
    begin
        r_phy_addr <= 'd0;
        r_reg_addr <= 'd0;
        r_reg_data <= 'd0;
        r_op_cmd   <= 'd0;
    end else if(w_op_active) begin
        r_phy_addr <= i_phy_addr;
        r_reg_addr <= i_reg_addr;
        r_reg_data <= i_reg_data;
        r_op_cmd   <= i_op_cmd  ;
    end else begin
        r_phy_addr <= r_phy_addr;
        r_reg_addr <= r_reg_addr;
        r_reg_data <= r_reg_data;
        r_op_cmd   <= r_op_cmd  ;
    end
    


always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_operation_start <= 'd0;
    else if(r_st_cnt == 65)
        r_operation_start <= 'd0;
    else if(r_op_active) 
        r_operation_start <= 'd1;
    else 
        r_operation_start <= r_operation_start;

always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_st_cnt <= 'd0;
    else if(r_st_cnt == 65)
        r_st_cnt <= 'd0;
    else if(r_operation_start)
        r_st_cnt <= r_st_cnt + 1;
    else 
        r_st_cnt <= r_st_cnt;

always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_mdio_ctrl <= 'd0;
    else if(r_op_cmd == P_MDIO_W &&  ((r_operation_start && r_st_cnt < 63) || (r_st_cnt == 0 && r_op_active)))
        r_mdio_ctrl <= 'd1;
    else if(r_op_cmd == P_MDIO_R &&  ((r_operation_start && r_st_cnt < 45)  || (r_st_cnt == 0 && r_op_active)))
        r_mdio_ctrl <= 'd1;
    else 
        r_mdio_ctrl <= 'd0;
    
always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_mdio_out <= 'd0;
    else if(r_op_active || r_operation_start )
        r_mdio_out <= r_mdio_out_data_list[62];
    else 
        r_mdio_out <= 'd0;

always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_mdio_out_data_list = 63'd0;
    else if(w_op_active)
        r_mdio_out_data_list = {{32{1'b1}},P_MDIO_SF,i_op_cmd,i_phy_addr,i_reg_addr,2'b10,r_reg_data};
    else if(r_operation_start)
        r_mdio_out_data_list <= r_mdio_out_data_list << 1;
    else 
        r_mdio_out_data_list = r_mdio_out_data_list;

always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_read_data <= 'd0;
    else if(r_op_cmd == P_MDIO_R && r_st_cnt >= 48 && r_st_cnt < 63)
        r_read_data <= {r_read_data[14:0],w_mdio_input};
    else 
        r_read_data <= r_read_data;

always@(posedge i_mdio_clk or posedge i_mdio_rst)
    if(i_mdio_rst)
        r_read_valid <= 'd0;
    else if(r_op_cmd == P_MDIO_R && r_st_cnt == 64)
        r_read_valid <= 'd1;
    else 
        r_read_valid <= 'd0;

endmodule