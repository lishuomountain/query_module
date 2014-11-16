`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:07:41 11/07/2014 
// Design Name: 
// Module Name:    data_parser 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module data_parser(
    input clk,
    input rst,
	// send read page cmd to fifo
	output reg [127:0] read_page_cmd_others,
	output reg read_page_cmd_en_others,
	// parameter
	input [31:0] target_page_addr,
	input [31:0] record_num,
	//check_command_fifo 
    input [31:0] read_page_addr,
    output reg page_hit,
    input data_valid,
    input [255:0] data_in,
	//query_module
	input rd_en,
	output  one_empty,
	output  [31:0] dout0,
	output  [31:0] dout1,
	output  [31:0] dout2,
	output  [31:0] dout3,
	output  [31:0] dout4,
	output  [31:0] dout5,
	output  [31:0] dout6,
	output  [31:0] dout7,
	output  [31:0] dout8,
	output  [31:0] dout9,
	output  [31:0] dout10,
	output  [31:0] dout11,
	output  [31:0] dout12,
	output  [31:0] dout13,
	output  [31:0] dout14,
	output  [31:0] dout15,
	output  [31:0] dout16,
	output  [31:0] dout17,
	output  [31:0] dout18,
	output  [31:0] dout19,
	output  [31:0] dout20,
	output  [31:0] dout21,
	output  [31:0] dout22,
	output  [31:0] dout23,
	output  [31:0] dout24,
	output  [31:0] dout25,
	output  [31:0] dout26,
	output  [31:0] dout27,
	output  [31:0] dout28,
	output  [31:0] dout29,
	output  [31:0] dout30,
	output  [31:0] dout31,
	output  [31:0] dout32,
	output  [31:0] dout33,
	output  [31:0] dout34,
	output  [31:0] dout35,
	output  [31:0] dout36,
	output  [31:0] dout37,
	output  [31:0] dout38,
	output  [31:0] dout39,
	
    output reg table_scan_done
    );

	parameter  WAITDATA     =3'h0; 
	parameter  PAGEHIT      =3'h1;
	parameter  READPAGEADDR =3'h2;
	parameter  READDATA     =3'h3;
	parameter  WAITDATAVALID=3'h4;
	parameter  READDATATAIL =3'h5;
	
	reg [2:0] state;
	reg [2:0] next;
    
	reg page_scan_done;

	reg [31:0] din [0:39];
	reg wr_en;
	//reg rd_en [0:7];
	//reg [31:0] dout [0:7];
	wire [39:0] full ;
   wire one_full;
	wire [39:0] empty ;
	wire one_empty;
	reg [9:0] count;
	reg count_en;
	reg count_rst;
     
	reg [31:0] row_counter;
	reg row_counter_en;
	reg row_counter_rst;

    reg [31:0]  next_page_addr;
      
always @ (posedge clk or negedge rst)
begin
	if(!rst)
		state <= WAITDATA ;
	else
		state <= next;
end

always @ (*)
begin
	case(state)
		WAITDATA : 
			if(read_page_addr == target_page_addr || read_page_addr == next_page_addr)
				next = PAGEHIT ;
			else
				next = WAITDATA ;
		PAGEHIT :
			if(data_valid == 1'b1)
				next = READPAGEADDR ;
			else
				next = PAGEHIT ;
		READPAGEADDR :
			if(data_valid == 1'b1)
				next = READDATA;
			else
				next = WAITDATAVALID;
		WAITDATAVALID:
			if(data_valid == 1'b1)
				next = READDATA;
			else
				next = WAITDATAVALID;
		READDATA:
			if(row_counter == record_num)
				next = READDATATAIL;
			else if(count == 128)
				next = WAITDATA ;
			else if(data_valid == 1'b0)
				next = WAITDATAVALID;
			else
				next = READDATA;
		READDATATAIL:
		begin
			if(count == 128)
				next = WAITDATA ;
			else
				next = READDATATAIL;	
        end
	endcase
end

always @ (posedge clk or negedge rst)
begin
	if(!rst)
	begin
        page_hit <= 1'b0;
		next_page_addr <= 32'b0;
        table_scan_done <= 1'b0;
		wr_en <= 1'b0;
		din[0] <= 32'h0; 
        din[1] <= 32'h0;
        din[2] <= 32'h0;
        din[3] <= 32'h0;
        din[4] <= 32'h0;
        din[5] <= 32'h0;
        din[6] <= 32'h0;
        din[7] <= 32'h0;
		count_rst <= 1'b0;
		count_en <= 1'b0;
		row_counter_en <= 1'b0;
		row_counter_rst <= 1'b0;
		read_page_cmd_en_others <= 1'b0;
		read_page_cmd_others <= 128'b0;
	end
	else
	begin
		wr_en <= 1'b0;
		count_en <= 1'b0;
		count_rst <= 1'b0;
		row_counter_rst <= 1'b0;
		row_counter_en <= 1'b0;
		read_page_cmd_en_others <= 1'b0;
		case(next)
			WAITDATA :
             begin
				page_hit <= 1'b0;
				count_rst <= 1'b1;
             end
			PAGEHIT :
			begin
				page_hit <= 1'b1;
			end
			READPAGEADDR :
			begin
				next_page_addr <= data_in[31:0];
				count_en <= 1'b1;
				read_page_cmd_others <= 128'b0; // TODO
				read_page_cmd_en_others <= 1'b1;
			end
			READDATA:
			begin
				if(one_full != 1'b1)
				begin
					wr_en <= 1'b1;
					din[0] <= data_in[31:0];
					din[1] <= data_in[2*32-1:1*32];
					din[2] <= data_in[3*32-1:2*32];
					din[3] <= data_in[4*32-1:3*32];
					din[4] <= data_in[5*32-1:4*32];
					din[5] <= data_in[6*32-1:5*32];
					din[6] <= data_in[7*32-1:6*32];
					din[7] <= data_in[8*32-1:7*32];
					row_counter_en <= 1'b1;
					count_en <= 1'b1;
				end
			end
			WAITDATAVALID: 	
			begin

			end
			READDATATAIL:
			begin
				table_scan_done <=1'b1;
				row_counter_rst <= 1'b1;
			end
		endcase
	end
end

//counter
always @ (posedge clk or negedge rst)
begin
	if(!rst)
		count <= 0;
	else if(count_rst)
		count <= 0;
	else if(count_en)
		count <= count + 1;
	else
		count <= count;	
end
// row_counter 
always @ (posedge clk or negedge rst)
begin
	if(!rst)
		row_counter <= 0;
	else if(row_counter_rst)
		row_counter <= 0;
	else if(row_counter_en)
		row_counter <= row_counter + 1;
	else
		row_counter <= row_counter;	
end
assign one_empty = empty[0] || empty[1] || empty[2] || empty[3] || empty[4] || empty[5] || empty[6] || empty[7] ; 
assign one_full = full[0] ||  full[1] ||  full[2] ||  full[3] ||  full[4] ||  full[5] ||  full[6] ||  full[7] ;

ColumnData col0 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[0]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout0), // output [31 : 0] dout
  .full(full[0]), // output full
  .empty(empty[0]) // output empty
);
ColumnData col1 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[1]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout1), // output [31 : 0] dout
  .full(full[1]), // output full
  .empty(empty[1]) // output empty
);
ColumnData col2 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[2]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout2), // output [31 : 0] dout
  .full(full[2]), // output full
  .empty(empty[2]) // output empty
);
ColumnData col3 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[3]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout3), // output [31 : 0] dout
  .full(full[3]), // output full
  .empty(empty[3]) // output empty
);
ColumnData col4 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[4]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout4), // output [31 : 0] dout
  .full(full[4]), // output full
  .empty(empty[4]) // output empty
);
ColumnData col5 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[5]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout5), // output [31 : 0] dout
  .full(full[5]), // output full
  .empty(empty[5]) // output empty
);
ColumnData col6 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[6]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout6), // output [31 : 0] dout
  .full(full[6]), // output full
  .empty(empty[6]) // output empty
);
ColumnData col7 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[7]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout7), // output [31 : 0] dout
  .full(full[7]), // output full
  .empty(empty[7]) // output empty
);
ColumnData col8 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[8]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout8), // output [31 : 0] dout
  .full(full[8]), // output full
  .empty(empty[8]) // output empty
);
ColumnData col9 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[9]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout9), // output [31 : 0] dout
  .full(full[9]), // output full
  .empty(empty[9]) // output empty
);
// 10-19
ColumnData col10 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[10]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout10), // output [31 : 0] dout
  .full(full[10]), // output full
  .empty(empty[10]) // output empty
);
ColumnData col11 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[11]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout11), // output [31 : 0] dout
  .full(full[11]), // output full
  .empty(empty[11]) // output empty
);
ColumnData col12 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[12]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout12), // output [31 : 0] dout
  .full(full[12]), // output full
  .empty(empty[12]) // output empty
);
ColumnData col13 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[13]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout13), // output [31 : 0] dout
  .full(full[13]), // output full
  .empty(empty[13]) // output empty
);
ColumnData col14 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[14]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout14), // output [31 : 0] dout
  .full(full[14]), // output full
  .empty(empty[14]) // output empty
);
ColumnData col15 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[15]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout15), // output [31 : 0] dout
  .full(full[15]), // output full
  .empty(empty[15]) // output empty
);
ColumnData col16 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[16]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout16), // output [31 : 0] dout
  .full(full[16]), // output full
  .empty(empty[16]) // output empty
);
ColumnData col17 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[17]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout17), // output [31 : 0] dout
  .full(full[17]), // output full
  .empty(empty[17]) // output empty
);
ColumnData col18 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[18]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout18), // output [31 : 0] dout
  .full(full[18]), // output full
  .empty(empty[18]) // output empty
);
ColumnData col19 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[19]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout19), // output [31 : 0] dout
  .full(full[19]), // output full
  .empty(empty[19]) // output empty
);
//20-29
ColumnData col20 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[20]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout20), // output [31 : 0] dout
  .full(full[20]), // output full
  .empty(empty[20]) // output empty
);
ColumnData col21 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[21]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout21), // output [31 : 0] dout
  .full(full[21]), // output full
  .empty(empty[21]) // output empty
);
ColumnData col22 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[22]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout22), // output [31 : 0] dout
  .full(full[22]), // output full
  .empty(empty[22]) // output empty
);
ColumnData col23 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[23]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout23), // output [31 : 0] dout
  .full(full[23]), // output full
  .empty(empty[23]) // output empty
);
ColumnData col24 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[24]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout24), // output [31 : 0] dout
  .full(full[24]), // output full
  .empty(empty[24]) // output empty
);
ColumnData col25 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[25]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout25), // output [31 : 0] dout
  .full(full[25]), // output full
  .empty(empty[25]) // output empty
);
ColumnData col26 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[26]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout26), // output [31 : 0] dout
  .full(full[26]), // output full
  .empty(empty[26]) // output empty
);
ColumnData col27 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[27]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout27), // output [31 : 0] dout
  .full(full[27]), // output full
  .empty(empty[27]) // output empty
);
ColumnData col28 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[28]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout28), // output [31 : 0] dout
  .full(full[28]), // output full
  .empty(empty[28]) // output empty
);
ColumnData col29 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[29]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout29), // output [31 : 0] dout
  .full(full[29]), // output full
  .empty(empty[29]) // output empty
);
//30-39
ColumnData col30 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[30]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout30), // output [31 : 0] dout
  .full(full[30]), // output full
  .empty(empty[30]) // output empty
);
ColumnData col31 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[31]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout31), // output [31 : 0] dout
  .full(full[31]), // output full
  .empty(empty[31]) // output empty
);
ColumnData col32 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[32]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout32), // output [31 : 0] dout
  .full(full[32]), // output full
  .empty(empty[32]) // output empty
);
ColumnData col33 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[33]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout33), // output [31 : 0] dout
  .full(full[33]), // output full
  .empty(empty[33]) // output empty
);
ColumnData col34 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[34]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout34), // output [31 : 0] dout
  .full(full[34]), // output full
  .empty(empty[34]) // output empty
);
ColumnData col35 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[35]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout35), // output [31 : 0] dout
  .full(full[35]), // output full
  .empty(empty[35]) // output empty
);
ColumnData col36 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[36]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout36), // output [31 : 0] dout
  .full(full[36]), // output full
  .empty(empty[36]) // output empty
);
ColumnData col37 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[37]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout37), // output [31 : 0] dout
  .full(full[37]), // output full
  .empty(empty[37]) // output empty
);
ColumnData col38 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[38]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout38), // output [31 : 0] dout
  .full(full[38]), // output full
  .empty(empty[38]) // output empty
);
ColumnData col39 (
  .clk(clk), // input clk
  .rst(!rst), // input rst
  .din(din[39]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout39), // output [31 : 0] dout
  .full(full[39]), // output full
  .empty(empty[39]) // output empty
);
endmodule
