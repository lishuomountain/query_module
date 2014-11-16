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
    output reg data_out_en,
    input [31:0] data_out,
    input data_fifo_empty,
    output reg data_fifo_full,
	//query_module
	input rd_en,
	output  one_empty,
	output reg [31:0] dout0,
	output reg [31:0] dout1,
	output reg [31:0] dout2,
	output reg [31:0] dout3,
	output reg [31:0] dout4,
	output reg [31:0] dout5,
	output reg [31:0] dout6,
	output reg [31:0] dout7,

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

	reg [31:0] din [0:7];
	reg wr_en;
	//reg rd_en [0:7];
	reg [31:0] dout [0:7];
	reg full [0:7];
    wire one_full;
	reg [7:0] empty;
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
			if(data_fifo_empty == 1'b0)
				next = READPAGEADDR ;
			else
				next = PAGEHIT ;
		READPAGEADDR :
			if(data_fifo_empty == 1'b0)
				next = READDATA;
			else
				next = WAITDATAVALID;
		WAITDATAVALID:
			if(data_fifo_empty == 1'b0)
				next = READDATA;
			else
				next = WAITDATAVALID;
		READDATA:
			if(row_counter == record_num)
				next = READDATATAIL;
			else if(count == 128)
				next = WAITDATA ;
			else if(data_fifo_empty == 1'b1)
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
		data_out_en <= 1'b0;
	end
	else
	begin
		wr_en <= 1'b0;
		count_en <= 1'b0;
		count_rst <= 1'b0;
		row_counter_rst <= 1'b0;
		row_counter_en <= 1'b0;
		read_page_cmd_en_others <= 1'b0;
		data_out_en <= 1'b0;
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
				data_out_en <= 1'b1;
				count_en <= 1'b1;
				read_page_cmd_others <= 128'b0; // TODO
				read_page_cmd_en_others <= 1'b1;
			end
			READDATA:
			begin
				data_out_en <= 1'b1;
				
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
					row_counter_en = 1'b1;
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
  .rst(rst), // input rst
  .din(din[0]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout0), // output [31 : 0] dout
  .full(full[0]), // output full
  .empty(empty[0]) // output empty
);
ColumnData col1 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[1]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout1), // output [31 : 0] dout
  .full(full[1]), // output full
  .empty(empty[1]) // output empty
);
ColumnData col2 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[2]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout2), // output [31 : 0] dout
  .full(full[2]), // output full
  .empty(empty[2]) // output empty
);
ColumnData col3 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[3]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout3), // output [31 : 0] dout
  .full(full[3]), // output full
  .empty(empty[3]) // output empty
);
ColumnData col4 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[4]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout4), // output [31 : 0] dout
  .full(full[4]), // output full
  .empty(empty[4]) // output empty
);
ColumnData col5 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[5]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout5), // output [31 : 0] dout
  .full(full[5]), // output full
  .empty(empty[5]) // output empty
);
ColumnData col6 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[6]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout6), // output [31 : 0] dout
  .full(full[6]), // output full
  .empty(empty[6]) // output empty
);
ColumnData col7 (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(din[7]), // input [31 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout7), // output [31 : 0] dout
  .full(full[7]), // output full
  .empty(empty[7]) // output empty
);
endmodule
