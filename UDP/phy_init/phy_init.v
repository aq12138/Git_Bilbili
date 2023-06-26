module phy_init(
    input           i_sysclk            ,//5MHZ
    input           i_sysrst            ,//高有效
    output          o_phy_mdc           ,
    inout           io_phy_mdio         ,

    output          o_phy_speed         ,//1:1G 0:100M
    output          o_phy_link           //1:LINK 0:NO LINK
);
/***************start*****************/

/***************parameter*************/
parameter       P_ST_IDLE        = 0    ,
                P_ST_SPEED_REG   = 1    ,
                P_ST_SPEED_WAIT  = 2    ,
                P_ST_MID_WAIT    = 3    ,
                P_ST_LINK_REG    = 4    ,
                P_ST_LINK_WAIT   = 5    ,
                P_ST_WAIT        = 6    ;

parameter       P_MDIO_W         = 2'b01;
parameter       P_MDIO_R         = 2'b10;
parameter       P_PHY_ADDR       = 5'b00001     ;
parameter       P_SPEED_REG_ADDR = 5'b00000    ;
parameter       P_LINK_REG_ADDR  = 5'b00001    ;
parameter       P_SPEED_REG_WID  = 13   ;
parameter       P_LINK_REG_WID   = 2    ;
parameter       P_REG_NUMBER     = 2    ;

/***************port******************/             

/***************mechine***************/
reg [7 :0] r_st_current                 ;
reg [7 :0] r_st_next                    ; 

/***************reg*******************/
reg [7 :0]  r_st_cnt                    ;
reg [4 :0]  r_phy_addr                  ;
reg [4 :0]  r_reg_addr                  ;
reg [15:0]  r_reg_data                  ;
reg [1 :0]  r_op_cmd                    ;
reg         r_op_valid                  ;
reg [1 :0]  r_phy_speed                 ;
reg         r_phy_link                  ;
reg [7 :0]  r_read_cnt                  ;

/***************wire******************/
wire        w_op_ready                  ;
(* keep *)wire [15:0] w_read_data /*synthesis keep*/                ;
(* keep *)wire        w_read_valid /*synthesis keep*/               ;
(* keep *)wire        w_mdio_clk                  ;
(* keep *)wire        w_phy_mdc                   ;
wire        w_mdio_rst                  ;
wire        w_phy_clk_ctrl              ;

/***************assign****************/
assign      o_phy_mdc  = ~w_mdio_clk ;
assign      o_phy_link = r_phy_link     ;
assign      o_phy_speed = r_phy_speed == 2'b10 ? 1'b1 : 1'b0 ;

/***************component*************/
clk_div_module#(
	.P_CLK_CNT          (100	        )
)
clk_div_module_u0
(
	.i_sysclk	        (i_sysclk ),
	.i_sysrst	        (i_sysrst ),
	.o_divclk	        (w_mdio_clk)   
);

// arsf_module arsf_module_u0(
// 	.i_sysclk 	        (w_mdio_clk ),
// 	.i_sysrst_n         (i_sysrst   ),
// 	.o_rst_n            (w_mdio_rst )
// );

mdio_ctrl_module mdio_ctrl_module_u0(
    .i_mdio_clk         (w_mdio_clk    ),
    .i_mdio_rst         (i_sysrst      ),
    .io_mdio            (io_phy_mdio   ),

    .i_phy_addr         (r_phy_addr    ),
    .i_reg_addr         (r_reg_addr    ),
    .i_reg_data         (r_reg_data    ),

    .i_op_cmd           (r_op_cmd      ),
    .i_op_valid         (r_op_valid    ),
    .o_op_ready         (w_op_ready    ),
    .o_phy_clk_ctrl     (w_phy_clk_ctrl),

    .o_read_data        (w_read_data   ),
    .o_read_valid       (w_read_valid  )   
);   



/***************always****************/
always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)
        r_st_current <= P_ST_IDLE ;
    else 
        r_st_current <= r_st_next ;

always@(*)
    case(r_st_current)
        P_ST_IDLE       :r_st_next = r_st_cnt == 100 ? P_ST_SPEED_REG : P_ST_IDLE ;
        P_ST_SPEED_REG  :r_st_next = P_ST_SPEED_WAIT ;
        P_ST_SPEED_WAIT :r_st_next = r_st_cnt > 2 && w_op_ready ? P_ST_MID_WAIT : P_ST_SPEED_WAIT;
        P_ST_MID_WAIT   :r_st_next = r_st_cnt == 100 ? P_ST_LINK_REG :P_ST_MID_WAIT ;
        P_ST_LINK_REG   :r_st_next = P_ST_LINK_WAIT ;
        P_ST_LINK_WAIT  :r_st_next = r_st_cnt > 2 && w_op_ready ? P_ST_WAIT : P_ST_LINK_WAIT; 
        P_ST_WAIT       :r_st_next = r_st_cnt == 200 ? P_ST_IDLE :P_ST_WAIT ;
        default         :r_st_next = P_ST_IDLE ;
    endcase

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)
        r_st_cnt <= 'd0;
    else if(r_st_current != r_st_next)
        r_st_cnt <= 'd0;
    else 
        r_st_cnt <= r_st_cnt + 1;

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)begin
        r_phy_addr <= 'd0;
        r_reg_addr <= 'd0;
        r_reg_data <= 'd0;
        r_op_cmd   <= 'd0;
    end else if(r_st_current == P_ST_SPEED_REG)begin
        r_phy_addr <= P_PHY_ADDR;
        r_reg_addr <= P_SPEED_REG_ADDR;
        r_reg_data <= 'd0;
        r_op_cmd   <= P_MDIO_R;
    end else if(r_st_current == P_ST_LINK_REG)begin
        r_phy_addr <= P_PHY_ADDR;
        r_reg_addr <= P_LINK_REG_ADDR;
        r_reg_data <= 'd0;
        r_op_cmd   <= P_MDIO_R;
    end else  begin
        r_phy_addr <= r_phy_addr;
        r_reg_addr <= r_reg_addr;
        r_reg_data <= r_reg_data;
        r_op_cmd   <= r_op_cmd  ;
    end

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)
        r_op_valid <= 'd0;
    else if(r_st_current == P_ST_SPEED_REG && w_op_ready)
        r_op_valid <= 'd1;
    else if(r_st_current == P_ST_LINK_REG  && w_op_ready)
        r_op_valid <= 'd1;
    else 
        r_op_valid <= 'd0;

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)
        r_read_cnt <= 'd0;
    else if(r_read_cnt == P_REG_NUMBER - 1)
        r_read_cnt <= 'd0;
    else if(w_read_valid)
        r_read_cnt <= r_read_cnt + 1;
    else 
        r_read_cnt <= r_read_cnt;

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst) begin 
        r_phy_speed <= 'd0;
    end else if(w_read_valid && r_st_current == P_ST_SPEED_WAIT) begin
        r_phy_speed[0] <= w_read_data[13];
        r_phy_speed[1] <= w_read_data[6];
    end else begin   
        r_phy_speed <= r_phy_speed;
    end

always@(posedge w_mdio_clk or posedge i_sysrst)
    if(i_sysrst)
        r_phy_link <= 'd0;
    else if(w_read_valid && r_st_current == P_ST_LINK_WAIT)
        r_phy_link <= w_read_data[2];
    else 
        r_phy_link <= r_phy_link;

endmodule