`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:31:16 11/08/2014 
// Design Name: 
// Module Name:    data_projector 
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
module data_projector(
    input clk,
	input rst,
	input [31:0] record_num,
    input [31:0] column_flag,
	input column_data_fifo_empty,
    output reg column_data_fifo_out_en,
    input [31:0] dout0,
    input [31:0] dout1,
    input [31:0] dout2,
    input [31:0] dout3,
    input [31:0] dout4,
    input [31:0] dout5,
    input [31:0] dout6,
    input [31:0] dout7,
    input match,
    output  query_cmd_finish_fifo_empty,
    input query_cmd_finish_fifo_out_en,
    output  [127:0] query_cmd_finish_fifo_out,
    input query_data_fifo_out_en,
    output  [255:0] query_data_fifo_out
    );


	parameter IDLE           = 4'h0;
	parameter FETCHDATA      = 4'h1;
	parameter PROJECTION0    = 4'h2;
	parameter PROJECTION1    = 4'h3;
	parameter PROJECTION2    = 4'h4;
	parameter PROJECTION3    = 4'h5;
	parameter PROJECTION4    = 4'h6;
	parameter PROJECTION5    = 4'h7;
	parameter PROJECTION6    = 4'h8;
	parameter PROJECTION7    = 4'h9;
	parameter CHECKCNT       = 4'ha;
	parameter PAGETAIL       = 4'hb;
    parameter NEXTROW        = 4'hc;

	reg [3:0] state;
	reg [3:0] next;

always @ ( posedge clk or negedge rst)
begin
	if(!rst)
		state <= IDLE;
	else
		state <= next;
end

always @ (*)
begin
		count_rst = 1'b0;
		count_en = 1'b0;
		row_counter_en = 1'b0;
		row_counter_rst = 1'b0;
		query_finish_cmd_en = 1'b0;
		query_finish_cmd = 128'b0;
	case(state)
		IDLE       :	
        begin
			if(column_data_fifo_empty == 1'b0)
            begin
				if(match == 1'b1)
                begin
					casex (column_flag[7:0])
						8'bxxxx_xxx1:
							next = PROJECTION0;
						8'bxxxx_xx10:
							next = PROJECTION1;
						8'bxxxx_x100:
							next = PROJECTION2;
						8'bxxxx_1000:
							next = PROJECTION3;
						8'bxxx1_0000:
							next = PROJECTION4;
						8'bxx10_0000:
							next = PROJECTION5;
						8'bx100_0000:
							next = PROJECTION6;
						8'b1000_0000:
							next = PROJECTION7;
						default: next = CHECKCNT;
					endcase
                 end
				else 
					next = FETCHDATA;
            end
			else
				next = IDLE;
        end
		FETCHDATA  :
        begin
			row_counter_en = 1'b1;
			if(match == 1'b0)
				casex (column_flag[7:0])
					8'bxxxx_xxx1:
						next = PROJECTION0;
					8'bxxxx_xx10:
						next = PROJECTION1;
					8'bxxxx_x100:
						next = PROJECTION2;
					8'bxxxx_1000:
						next = PROJECTION3;
					8'bxxx1_0000:
						next = PROJECTION4;
					8'bxx10_0000:
						next = PROJECTION5;
					8'bx100_0000:
						next = PROJECTION6;
					8'b1000_0000:
						next = PROJECTION7;
					default: next = CHECKCNT;
				endcase
			else
				next = FETCHDATA;
        end
		PROJECTION0:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:1])
				7'bxxxx_xx1:
					next = PROJECTION1;
				7'bxxxx_x10:
					next = PROJECTION2;
				7'bxxxx_100:
					next = PROJECTION3;
				7'bxxx1_000:
					next = PROJECTION4;
				7'bxx10_000:
					next = PROJECTION5;
				7'bx100_000:
					next = PROJECTION6;
				7'b1000_000:
					next = PROJECTION7;
				default: next = CHECKCNT;
			endcase	
		end
		PROJECTION1:
		begin
			count_en  = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:2])
				6'bxxx_xx1:
					next = PROJECTION2;
				6'bxxx_x10:
					next = PROJECTION3;
				6'bxxx_100:
					next = PROJECTION4;
				6'bxx1_000:
					next = PROJECTION5;
				6'bx10_000:
					next = PROJECTION6;
				6'b100_000:
					next = PROJECTION7;
				default: next = CHECKCNT;
			endcase
		end
		PROJECTION2:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:3])
				5'bxxxx1:
					next = PROJECTION3;
				5'bxxx10:
					next = PROJECTION4;
				5'bxx100:
					next = PROJECTION5;
				5'bx1000:
					next = PROJECTION6;
				5'b10000:
					next = PROJECTION7;
				default: next = CHECKCNT;
			endcase
		end
		PROJECTION3:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:4])
				4'bxxx1:
					next = PROJECTION4;
				4'bxx10:
					next = PROJECTION5;
				4'bx100:
					next = PROJECTION6;
				4'b1000:
					next = PROJECTION7;
				default: next = CHECKCNT;
			endcase
		end
		PROJECTION4:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:5])
				3'bxx1:
					next = PROJECTION5;
				3'bx10:
					next = PROJECTION6;
				3'b100:
					next = PROJECTION7;
				default: next = CHECKCNT;
			endcase
		end
		PROJECTION5:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			casex (column_flag[7:6])
				2'bx1:
					next = PROJECTION6;
				2'b10:
					next = PROJECTION7;
				default: next = CHECKCNT;
             endcase
		end
		PROJECTION6:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			if (column_flag[7] == 1'b1)
				next = PROJECTION7;
			else
				next = CHECKCNT;
		end
		PROJECTION7:
		begin
			count_en = 1'b1;
			if(count%1024 == 0 && count != 0)
			begin
				query_finish_cmd = 128'h0; // TODO
				query_finish_cmd_en = 1'b1;
			end
			else
			begin
				query_finish_cmd = 128'h0; 
				query_finish_cmd_en = 1'b0;
			end
			next =CHECKCNT;
		end
		CHECKCNT   :
			if(row_counter == record_num)
			begin
				row_counter_rst = 1'b1;
				if(count%1024 == 0)
				begin
					count_rst = 1'b1;
					next = NEXTROW;
				end
				else
					next = PAGETAIL;
			end
			else
				next = NEXTROW;
		PAGETAIL   : 
			if(count%1024 == 0)
			begin
				count_rst = 1'b1;
				next = NEXTROW;
			end
			else
				next = PAGETAIL;
		NEXTROW:
			next = IDLE;
		default: next = IDLE;
	endcase
end

	reg [255:0] query_data;
	reg query_data_en;
	wire data_full;
	reg [127:0] query_finish_cmd;
	reg query_finish_cmd_en;
	wire cmd_full;

always @ (posedge clk or negedge rst)
begin
	if(!rst)
	begin
		column_data_fifo_out_en <= 1'b0;
		query_data_en <= 1'b0;
		query_data <= 32'b0;
	end
	else
	begin
		column_data_fifo_out_en <= 1'b1;
		query_data_en <= 1'b0;
		case(next)
			IDLE       : begin end
            FETCHDATA  :
				column_data_fifo_out_en <= 1'b1;
            PROJECTION0:
			begin
				query_data <= dout0;
				query_data_en <= 1'b1;
			end
			PROJECTION1:
			begin
				query_data <= dout1;
				query_data_en <= 1'b1;
			end
            PROJECTION2:
			begin
				query_data <= dout2;
				query_data_en <= 1'b1;
			end
            PROJECTION3:
			begin
				query_data <= dout3;
				query_data_en <= 1'b1;
			end
            PROJECTION4:
			begin
				query_data <= dout4;
				query_data_en <= 1'b1;
			end
            PROJECTION5:
			begin
				query_data <= dout5;
				query_data_en <= 1'b1;
			end
            PROJECTION6:
			begin
				query_data <= dout6;
				query_data_en <= 1'b1;
			end
            PROJECTION7:
			begin
				query_data <= dout7;
				query_data_en <= 1'b1;
			end
            CHECKCNT   : begin end
            PAGETAIL   :
            begin
				query_data <= 32'h45_4e_44_44 ; //ENDD ENDD
				query_data_en <= 1'b1;
            end
			NEXTROW    :
				column_data_fifo_out_en <= 1'b1;
		endcase
	end     
end         
	reg [34:0] count;
	reg count_en;
	reg count_rst;
            
	reg [31:0] row_counter;
	reg row_counter_en;
	reg row_counter_rst;
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

FilteredData query_data_fifo (
  .rst(rst), // input rst
  .wr_clk(clk), // input wr_clk
  .rd_clk(clk), // input rd_clk
  .din(query_din), // input [31 : 0] din
  .wr_en(query_data_en), // input wr_en
  .rd_en(query_data_fifo_out_en), // input rd_en
  .dout(query_data_fifo_out), // output [255 : 0] dout
  .full(data_full), // output full
  .empty(empty) // output empty
);

GeneratedReadCMD query_cmd_finish_fifo (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din(query_finish_cmd), // input [127 : 0] din TODO
  .wr_en(query_finish_cmd_en), // input wr_en
  .rd_en(query_cmd_finish_fifo_out_en), // input rd_en
  .dout(query_cmd_finish_fifo_out), // output [127 : 0] dout
  .full(cmd_full), // output full
  .empty(query_cmd_finish_fifo_empty) // output empty
);
endmodule
