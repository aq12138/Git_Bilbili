/**************************************************/
//模块：复位器
//作用：异步复位同步释放
//输出:
//
/**************************************************/
module arsf_module(
	input 	i_sysclk 	,
	input 	i_sysrst_n  ,
	output   o_rst_n     
);

reg r_rst_1b,r_rst_2b;

assign o_rst_n = r_rst_2b;

always@(posedge i_sysclk or negedge i_sysrst_n)
begin
	if(!i_sysrst_n) begin
		r_rst_1b <= 1'b0;
		r_rst_2b <= 1'b0;
	end else begin
		r_rst_1b <= 1'b1;
		r_rst_2b <= r_rst_1b;
	end
end


endmodule

/**************************************************/
//模块：同步器（快到慢）
//作用：快频率　＜３慢频率
//输出:
//
/**************************************************/
module sync_f2s_module(
	input  i_clk_a ,
	input  i_a     ,
	input  i_clk_b ,
	output o_b     
);

reg r_a1,r_a2,r_a3,r_a4;
wire w_a;
// assign w_a = i_a | r_a1 | r_a2 | r_a3 | r_a4; 
assign w_a = i_a | r_a1 | r_a2 ;

always@(posedge i_clk_a)
begin
	r_a1 <= i_a;
	r_a2 <= r_a1;
	r_a3 <= r_a2;
	r_a4 <= r_a3;
end

reg r_b1,r_b2;
assign o_b = r_b2;

always@(posedge i_clk_b)
begin
	r_b1 <= w_a;
	r_b2 <= r_b1;
end

endmodule

/**************************************************/
//模块：同步器（慢到快）
//作用：
//输出:
//
/**************************************************/
module sync_s2f_module(
	input  i_clk_a ,
	input  i_a     ,
	input  i_clk_b ,
	output o_b     
);

(*ASYNC_REG = "true"*)
reg r_b1,r_b2;
assign o_b = r_b2;

always@(posedge i_clk_b)
begin
	r_b1 <= i_a;
	r_b2 <= r_b1;
end

endmodule

/**************************************************/
//模块：延时器　１拍
//作用：
//输出:
//
/**************************************************/
module signal_delay_1b#(
	parameter P_WIDTH = 1
)
(
	input						i_sysclk			,
	input	[P_WIDTH - 1 :0]	i_signal			,
	output  [P_WIDTH - 1 :0]    o_signal   
);

reg [P_WIDTH - 1 :0]		r_signal ;

assign 		o_signal   = r_signal   ;

always@(posedge i_sysclk)
	r_signal <= i_signal;


endmodule

/**************************************************/
//模块：延时器　２拍
//作用：
//输出:
//
/**************************************************/
module signal_delay_2b#(
	parameter P_WIDTH = 1
)
(
	input						i_sysclk			,
	input	[P_WIDTH - 1 :0]	i_signal			,
	output  [P_WIDTH - 1 :0]    o_signal   
);

reg [P_WIDTH - 1 :0]			r_signal 	;
reg [P_WIDTH - 1 :0]        	r_signal_2b ;

assign 		o_signal   = r_signal_2b   ;

always@(posedge i_sysclk)
	r_signal <= i_signal;

always@(posedge i_sysclk)
	r_signal_2b <= r_signal;

endmodule

/**************************************************/
//模块：下降沿检测器
//作用：
//输出:
//
/**************************************************/
module signal_negedge
(
	input 		i_sysclk	,
	input		i_sysrst	,
	input 		i_signal    ,
	output      o_negedge
);

reg r_signal = 0  ;

assign o_negedge = (~i_signal & r_signal);

always@(posedge i_sysclk,posedge i_sysrst)
	if(i_sysrst)
		r_signal <= 'd0;
	else 	
		r_signal <= i_signal;

endmodule

/**************************************************/
//模块：上升沿检测器
//作用：
//输出:
//
/**************************************************/
module signal_posedge
(
	input 		i_sysclk	,
	input		i_sysrst	,
	input 		i_signal    ,
	output      o_posedge
);

reg r_signal  ;

assign o_posedge = ~r_signal & i_signal;

always@(posedge i_sysclk,posedge i_sysrst)
	r_signal <= i_sysrst ? 0 : i_signal ;

endmodule

/**************************************************/
//模块：数据比较器
//作用：
//输出:
//
/**************************************************/
module equal_chenck#(
	parameter 					P_WIDTH = 1		
)				
(				
	input 						i_sysclk		,
	input  [P_WIDTH - 1 :0 ]	i_data1			,
	input  [P_WIDTH - 1 :0 ]    i_data2		    ,
	input						i_en 		    ,
	output reg	   				o_error		
);

always@(posedge i_sysclk)
	if(i_en)
		o_error <= (i_data1 != i_data2) ? 'd1 : 'd0;
	else 
		o_error <= 'd0;

endmodule

/**************************************************/
//模块：计数器
//作用：
//输出:
//
/**************************************************/
module count_module#(
	parameter 		P_COUNT_WIDTH = 16
)(		
	input 							i_sysclk		,
	input							i_rst 			,
	input 							i_signal		,
	output [P_COUNT_WIDTH - 1 : 0]	o_count		
);

reg [16:0] r_count;

assign o_count = r_count	;

always@(posedge i_sysclk or posedge i_rst)
	if(i_rst)
		r_count <= 'd0;
	else if(i_signal)
		r_count <= r_count + 1'b1;
	else 
		r_count <= r_count;

endmodule

/**************************************************/
//模块：结绳器
//作用：
//输出:
//
/**************************************************/
module tie_module(
	input 	i_clk_a			,
	input   i_rst_a			,
	input   i_a_req			,
	
	input	i_clk_b			,
	input   i_rst_b         ,
	output	o_b_req
);

reg  r_a_req = 0			;

wire w_b_areq				;
reg  r_b_areq=0				;
wire w_b_req                ;

assign w_b_req = ~r_b_areq & w_b_areq;
assign o_b_req = w_b_req;



always@(posedge i_clk_a)
	if(i_rst_a)
		r_a_req <= 'd0;
	else if(i_a_req)
		r_a_req <= 'd1;
	else 
		r_a_req <= r_a_req;

sync_s2f_module sync_s2f_module_u0(
	.i_clk_a 		(i_clk_a	),
	.i_a     		(r_a_req	),
	.i_clk_b 		(i_clk_b	),
	.o_b     		(w_b_areq	)
);

always@(posedge i_clk_b)
	r_b_areq <= i_rst_b ? 'd0 : w_b_areq;

endmodule

/**************************************************/
//模块：自恢复结绳器结绳器
//作用：
//输出:
//
/**************************************************/
module tie2_module#(
	parameter P_F2S_WAIT_COUNT = 0
)(
	input 	i_clk_a			,
	input   i_rst_a			,
	input   i_a_req			,
	
	input	i_clk_b			,
	input   i_rst_b         ,
	output	o_b_req
);

reg  r_a_req = 0			;

wire w_b_areq				;
reg  r_b_areq=0				;
wire w_b_req                ;
reg [7:0] r_wait_cnt;

assign w_b_req = ~r_b_areq & w_b_areq;
assign o_b_req = w_b_req;



always@(posedge i_clk_a)
	if(i_rst_a || (r_wait_cnt && (r_wait_cnt == P_F2S_WAIT_COUNT * 3)))
		r_a_req <= 'd0;
	else if(i_a_req)
		r_a_req <= 'd1;
	else 
		r_a_req <= r_a_req;



always@(posedge i_clk_a)
	if(i_rst_a)
		r_wait_cnt <= 'd0;
	else if(i_a_req)
		r_wait_cnt <= 'd1;
	else if(r_wait_cnt)
		r_wait_cnt <= r_wait_cnt + 1;
	else 
		r_wait_cnt <= r_wait_cnt	;

sync_s2f_module sync_s2f_module_u0(
	.i_clk_a 		(i_clk_a	),
	.i_a     		(r_a_req	),
	.i_clk_b 		(i_clk_b	),
	.o_b     		(w_b_areq	)
);

always@(posedge i_clk_b)
	r_b_areq <= i_rst_b ? 'd0 : w_b_areq;

endmodule

/**************************************************/
//模块：结绳器跨时钟域处理
//作用：任意时钟的跨时钟域，在例化时需要设置P_F2S_NUMBER的值为快时钟频率/慢时钟频率
//输出:输出同步后的脉冲，使用周期３个慢速时钟
//
/**************************************************/
module sync_tie_module#(
	parameter P_F2S_NUMBER = 0  
)(
	input 	i_clk_a			,
	input   i_rst_a			,
	input   i_signal_a		,
	output  o_busy			,

	input	i_clk_b			,
	input   i_rst_b         ,
	output	o_signal_b
);

wire w_signal_a_pos			;
wire w_1_signal_a_pos		;
wire w_b_req				;
reg  r_b_req=0				;
reg  r_b_signal=0  			;

assign o_signal_b = r_b_signal;

wire w_a_req                ;
reg  r_a_signal=0				;
reg  r_a_status=0  			;

reg r_busy=0;
assign o_busy = r_busy		;


signal_posedge signal_posedge_u0
(
	.i_sysclk	(i_clk_a		),
	.i_signal   (r_a_signal		),
	.o_posedge	(w_signal_a_pos	)	
);

signal_posedge signal_posedge_u1
(
	.i_sysclk	(i_clk_a		),
	.i_signal   (i_signal_a		),
	.o_posedge	(w_1_signal_a_pos	)	
);

tie_module tie_module_u0(
	.i_clk_a	(i_clk_a		),
	.i_rst_a	(i_rst_a|w_a_req),
	.i_a_req	(w_signal_a_pos	),
	
	.i_clk_b	(i_clk_b		),
	.i_rst_b    (i_rst_b 		),
	.o_b_req    (w_b_req		)  
);

tie2_module#(
	.P_F2S_WAIT_COUNT(P_F2S_NUMBER)
)
tie2_module_u1
(
	.i_clk_a	(i_clk_b		),
	.i_rst_a	(i_rst_b|w_b_req),
	.i_a_req	(r_b_req		),

	.i_clk_b	(i_clk_a		),
	.i_rst_b    (i_rst_a		),
	.o_b_req    (w_a_req		)  
);


always@(posedge i_clk_b)
	r_b_req <= w_b_req;

always@(posedge i_clk_b)
	r_b_signal <= w_b_req ? r_a_signal : 'd0;

always@(posedge i_clk_a)
	if(i_rst_a || w_a_req)
		r_a_status <= 'd0;
	else if(w_1_signal_a_pos)
		r_a_status <= 'd1;
	else 
		r_a_status <= r_a_status;

always@(posedge i_clk_a)
	r_a_signal <= r_a_status ? r_a_signal : i_signal_a;

always@(posedge i_clk_a)
	if(w_a_req)
		r_busy <= 'd1;
	else 
		r_busy <= 'd0;

endmodule

/**************************************************/
//模块：产生一个高电平复位的脉冲复位信号
//作用：
//输出:
//
/**************************************************/
module rst_generate_module#(
	parameter P_RST_COUNT = 10	
)(
	input 	i_clk	,
	output  o_rst   
);

reg [7:0] r_cnt='d0;
reg r_rst=1;
assign o_rst = ~r_rst;

always@(posedge i_clk)
	if(r_cnt < P_RST_COUNT)
		r_cnt <= r_cnt + 1;
	else 
		r_cnt <= r_cnt;

always@(posedge i_clk)
	if(r_cnt <= P_RST_COUNT - 1)
		r_rst <= 'd0;
	else 
		r_rst <= 'd1;

endmodule

/**************************************************/
//模块：时钟分频器
//作用：
//输出:
//
/**************************************************/
module clk_div_module#(
	parameter P_CLK_CNT = 1000		
)(
	input 	i_sysclk	,
	input   i_sysrst	,

	output	o_divclk	 
);

localparam P_CNT_WIDTH = 16;

reg  [P_CNT_WIDTH - 1 : 0]	r_cnt = 0 			;
reg  r_clk									;

assign o_divclk = r_clk						;

always@(posedge i_sysclk,posedge i_sysrst)
	if(i_sysrst)
		r_cnt <= {P_CNT_WIDTH{1'b0}};
	else if(r_cnt == (P_CLK_CNT >> 1) - 1)
		r_cnt <= {P_CNT_WIDTH{1'b0}};
	else
		r_cnt <= r_cnt + 1; 

always@(posedge i_sysclk,posedge i_sysrst)
	if(i_sysrst)
		r_clk <= 'd0;
	else if(r_cnt == (P_CLK_CNT >> 1) - 1)
		r_clk <= ~r_clk;
	else 
		r_clk <= r_clk;

endmodule

/**************************************************/
//模块：MUX
//作用：
//输出:
//
/**************************************************/
module Mux_8_module#(
	parameter					P_SIGNAL_WIDTH = 1
)(
	input      [2 :0]						i_ch_sel			,

	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_1		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_2		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_3		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_4		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_5		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_6		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_7		,
	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal_8		,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal	 
);

always@(*)
	case(i_ch_sel)
		0			: o_out_signal = i_in_signal_1;
		1			: o_out_signal = i_in_signal_2;
		2			: o_out_signal = i_in_signal_3;
		3			: o_out_signal = i_in_signal_4;
		4			: o_out_signal = i_in_signal_5;
		5			: o_out_signal = i_in_signal_6;
		6			: o_out_signal = i_in_signal_7;
		7			: o_out_signal = i_in_signal_8;
		default		: o_out_signal = i_in_signal_1;
	endcase

endmodule

/**************************************************/
//模块：MUX_F
//作用：
//输出:
//
/**************************************************/
module Mux_F_8_module#(
	parameter					P_SIGNAL_WIDTH = 1
)(
	input      [2 :0]						i_ch_sel			,

	input      [P_SIGNAL_WIDTH - 1:0]		i_in_signal			,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_1	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_2	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_3	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_4	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_5	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_6	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_7	 	,
	output reg [P_SIGNAL_WIDTH - 1:0]		o_out_signal_8	 	
);

always@(*)
	case(i_ch_sel)
		0			:begin
			o_out_signal_1 = i_in_signal;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end
		1			:begin
			o_out_signal_1 = 0;o_out_signal_2 = i_in_signal;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
		2			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = i_in_signal;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
		3			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = i_in_signal;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
		4			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = i_in_signal;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
		5			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = i_in_signal;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
		6			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = i_in_signal;o_out_signal_8 = 0;
		end 
		7			:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = i_in_signal;
		end 
		default		:begin
			o_out_signal_1 = 0;o_out_signal_2 = 0;o_out_signal_3 = 0;o_out_signal_4 = 0;
			o_out_signal_5 = 0;o_out_signal_6 = 0;o_out_signal_7 = 0;o_out_signal_8 = 0;
		end 
	endcase

endmodule