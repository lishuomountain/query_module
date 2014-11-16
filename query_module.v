`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:59:11 11/06/2014 
// Design Name: 
// Module Name:    query_module 
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
module query_module(
	input clk,
	input rst,
	// comunication with ftl_top 
    input pcie_cmd_rec_fifo_empty,
    output reg pcie_cmd_rec_fifo_en,
    output reg pcie_data_rec_fifo_out_en,
    input [255:0] pcie_data_rec_fifo_out,
	// comunication with chack_cache
    input read_page_cmd_fifo_out_en,
    output reg read_page_cmd_fifo_empty,
    output reg [127:0] read_page_cmd_fifo_out,
	//comunication with check_command_fifo
    input [31:0] read_page_addr,
    output page_hit,
    input data_valid,
    input [255:0] data_in,
    output data_fifo_full,
    output  query_cmd_finish_fifo_empty,
    output  [127:0] query_cmd_finish_fifo_out,
    input query_cmd_finish_fifo_out_en,
    input query_data_fifo_out_en,
    output  [255:0] query_data_fifo_out
    );

	// query_parameter_configure
	parameter WAITQUERYCMD = 4'h0;
	parameter READPARA0	   = 4'h1;
	parameter READPARA1	   = 4'h2;
	parameter READPARA2	   = 4'h3;
	parameter READPARA3	   = 4'h4;
	parameter READPARA4	   = 4'h5;
	parameter READPARA5	   = 4'h6;
	parameter READPARA6	   = 4'h7;
	parameter READPARA7	   = 4'h8;
	parameter READPARA8	   = 4'h9;
	parameter READPARA9	   = 4'ha;
	parameter READPARAA	   = 4'hb;
	parameter READPARAB	   = 4'hc;
	parameter READPARAC	   = 4'hd;
	parameter READPARATAIL = 4'he;
	parameter DONE         = 4'hf;

	reg [3:0] state;
	reg [3:0] next;
	reg [31:0] first_page_addr;
	reg [31:0] column_num;
	reg [31:0] record_num;
	reg [31:0] column_flag;
	reg [15:0] column_size[0:31];
	reg [7:0] predicate_num;
	reg [7:0] predicate_op[0:7];
	reg [7:0] predicate_col[0:7];
	reg [31:0] predicate_value[0:7];

	reg wea;
	reg [2:0] addra;
	reg [31:0] dina;
	reg [7:0] addrb;
	reg doutb;

	reg [9:0] count;
	reg count_en;
	reg count_rst;

	reg query_para_config_done;
	reg read_page_cmd;
	reg read_page_cmd_en;

	reg [31:0] target_page_addr;
    wire [31:0] data_out;
    wire data_out_en;
    wire data_fifo_empty;
// read back data
fifo_256in_32out  read_back_data(
  .rst(rst), // input rst
  .wr_clk(clk), // input wr_clk
  .rd_clk(clk), // input rd_clk
  .din(data_in), // input [255 : 0] din
  .wr_en(data_valid), // input wr_en
  .rd_en(data_out_en), // input rd_en
  .dout(data_out), // output [31 : 0] dout
  .full(data_fifo_full), // output full
  .empty(data_fifo_empty) // output empty
);

// sequential state logic (1st always) 
always @ (posedge clk or negedge rst)
begin
	if(!rst)
		state <= WAITQUERYCMD;
	else
		state <= next;
end

// combinational next logic (2nd always)
always @ (*)
begin
	case(next)
		WAITQUERYCMD: 
			if(pcie_cmd_rec_fifo_empty != 1'b1)
				next = READPARA0;
			else
				next = WAITQUERYCMD;
		READPARA0: next = READPARA1;
		READPARA1: next = READPARA2;
		READPARA2: next = READPARA3;
		READPARA3: next = READPARA4;
		READPARA4: next = READPARA5;
		READPARA5: next = READPARA6;
		READPARA6: next = READPARA7;
		READPARA7: next = READPARA8;
		READPARA8: next = READPARA9;
		READPARA9: next = READPARAA;
		READPARAA: next = READPARAB;
		READPARAB: next = READPARAC;
		READPARAC: next = READPARATAIL;
		READPARATAIL:
		begin
			if(count == 128)
				next = DONE;
			else 
				next = READPARATAIL;
		end
		DONE: next = WAITQUERYCMD;
		default: next = WAITQUERYCMD;
	endcase
end

// sequential output logic (3rd always)
always @ (posedge clk or negedge rst)
begin
	if(!rst)
	begin
		query_para_config_done <= 1'b0;
		pcie_data_rec_fifo_out_en <= 1'b0;
		wea <= 1'b0;
		dina <= 128'h0;
		addra <= 3'b0;
		count_rst <= 1'b0;
		count_en <= 1'b0;
		pcie_cmd_rec_fifo_en <= 1'b0;
		// query parameter registers
		first_page_addr <= 32'b0;
		column_num <= 32'b0;
		column_flag <= 32'b0;
		record_num <= 32'b0;
		column_size[0] <= 16'h0;                  
        column_size[1] <= 16'h0;
        column_size[2] <= 16'h0;
        column_size[3] <= 16'h0;
        column_size[4] <= 16'h0;
        column_size[5] <= 16'h0;
        column_size[6] <= 16'h0;
        column_size[7] <= 16'h0;
        column_size[8] <= 16'h0;
        column_size[9] <= 16'h0;
        column_size[10] <=16'h0;
        column_size[11] <=16'h0;
        column_size[12] <=16'h0;
        column_size[13] <=16'h0;
        column_size[14] <=16'h0;
        column_size[15] <=16'h0;
        column_size[16] <=16'h0;
        column_size[17] <=16'h0;
        column_size[18] <=16'h0;
        column_size[19] <=16'h0;
        column_size[20] <=16'h0;
        column_size[21] <=16'h0;
        column_size[22] <=16'h0;
        column_size[23] <=16'h0;
        column_size[24] <=16'h0;
        column_size[25] <=16'h0;
        column_size[26] <=16'h0;
        column_size[27] <=16'h0;
        column_size[28] <=16'h0;
        column_size[29] <=16'h0;
        column_size[30] <=16'h0;
        column_size[31] <=16'h0;
		predicate_op[0]    <='h0; 
        predicate_col[0]   <='h0; 
        predicate_value[0] <='h0; 
        predicate_op[1]    <='h0; 
        predicate_col[1]   <='h0; 
        predicate_value[1] <='h0; 
        predicate_op[2]    <='h0; 
        predicate_col[2]   <='h0; 
        predicate_value[2] <='h0; 
        predicate_op[3]    <='h0; 
        predicate_col[3]   <='h0; 
        predicate_value[3] <='h0; 
        predicate_op[4]    <='h0; 
        predicate_col[4]   <='h0; 
        predicate_value[4] <='h0; 
        predicate_op[5]    <='h0; 
        predicate_col[5]   <='h0; 
        predicate_value[5] <='h0; 
        predicate_op[6]    <='h0; 
        predicate_col[6]   <='h0; 
        predicate_value[6] <='h0; 
        predicate_op[7]    <='h0; 
        predicate_col[7]   <='h0; 
        predicate_value[7] <='h0; 
        predicate_num      <='h0; 
		read_page_cmd      <=128'h0;
		read_page_cmd_en   <=1'b0;
	end                   
	else                  
		begin                  
		pcie_data_rec_fifo_out_en <= 1'b0;
		wea <= 1'b0;
		count_rst <= 1'b0;
		count_en <= 1'b0;
		pcie_cmd_rec_fifo_en <= 1'b0;
		read_page_cmd_en <= 1'b0;
		case(next)
			WAITQUERYCMD: 
				count_rst <= 1'b1;
			READPARA0:
			begin
				query_para_config_done <= 1'b0;
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				target_page_addr <= pcie_data_rec_fifo_out[31:0];
                
				column_num <= pcie_data_rec_fifo_out['hb*8-1:'h8*8];
				record_num <= pcie_data_rec_fifo_out['hf*8-1:'hc*8];
				column_flag <= pcie_data_rec_fifo_out['h13*8-1:'h10*8];
			end	
			READPARA1:
			begin
				read_page_cmd <= 128'b0; // TODO
				read_page_cmd_en <= 1'b1;
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				column_size[0] <= pcie_data_rec_fifo_out[15:0];
				column_size[1] <= pcie_data_rec_fifo_out[2*16-1:16];
				column_size[2] <= pcie_data_rec_fifo_out[3*16-1:2*16];
				column_size[3] <= pcie_data_rec_fifo_out[4*16-1:3*16];
				column_size[4] <= pcie_data_rec_fifo_out[5*16-1:4*16];
				column_size[5] <= pcie_data_rec_fifo_out[6*16-1:5*16];
				column_size[6] <= pcie_data_rec_fifo_out[7*16-1:6*16];
				column_size[7] <= pcie_data_rec_fifo_out[8*16-1:7*16];
				column_size[8] <= pcie_data_rec_fifo_out[9*16-1:8*16];
				column_size[9] <= pcie_data_rec_fifo_out[10*16-1:9*16];
				column_size[10] <= pcie_data_rec_fifo_out[11*16-1:10*16];
				column_size[11] <= pcie_data_rec_fifo_out[12*16-1:11*16];
				column_size[12] <= pcie_data_rec_fifo_out[13*16-1:12*16];
				column_size[13] <= pcie_data_rec_fifo_out[14*16-1:13*16];
				column_size[14] <= pcie_data_rec_fifo_out[15*16-1:14*16];
				column_size[15] <= pcie_data_rec_fifo_out[16*16-1:15*16];
			end
			READPARA2:
			begin
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				column_size[16] <= pcie_data_rec_fifo_out[15:0];
				column_size[17] <= pcie_data_rec_fifo_out[2*16-1:16];
				column_size[18] <= pcie_data_rec_fifo_out[3*16-1:2*16];
				column_size[19] <= pcie_data_rec_fifo_out[4*16-1:3*16];
				column_size[20] <= pcie_data_rec_fifo_out[5*16-1:4*16];
				column_size[21] <= pcie_data_rec_fifo_out[6*16-1:5*16];
				column_size[22] <= pcie_data_rec_fifo_out[7*16-1:6*16];
				column_size[23] <= pcie_data_rec_fifo_out[8*16-1:7*16];
				column_size[24] <= pcie_data_rec_fifo_out[9*16-1:8*16];
				column_size[25] <= pcie_data_rec_fifo_out[10*16-1:9*16];
				column_size[26] <= pcie_data_rec_fifo_out[11*16-1:10*16];
				column_size[27] <= pcie_data_rec_fifo_out[12*16-1:11*16];
				column_size[28] <= pcie_data_rec_fifo_out[13*16-1:12*16];
				column_size[29] <= pcie_data_rec_fifo_out[14*16-1:13*16];
				column_size[30] <= pcie_data_rec_fifo_out[15*16-1:14*16];
				column_size[31] <= pcie_data_rec_fifo_out[16*16-1:15*16];
			end
			READPARA3:
			begin
				wea <= 1'b1;
				addra <= 3'h0;
				dina <= pcie_data_rec_fifo_out[31:0];
			end
			READPARA4:
			begin
				wea <= 1'b1;
				addra <= 3'b1;
				dina <= pcie_data_rec_fifo_out[2*32-1:1*32];
			end
			READPARA5:
			begin
				wea <= 1'b1;
				addra <= 3'h2;
				dina <= pcie_data_rec_fifo_out[3*32-1:2*32];
			end
			READPARA6:
			begin
				wea <= 1'b1;
				addra <= 3'h3;
				dina <= pcie_data_rec_fifo_out[4*32-1:3*32];
			end
			READPARA7:
			begin
				wea <= 1'b1;
				addra <= 3'h4;
				dina <= pcie_data_rec_fifo_out[5*32-1:4*32];
			end
			READPARA8:
			begin
				wea <= 1'b1;
				addra <= 3'h5;
				dina <= pcie_data_rec_fifo_out[6*32-1:5*32];
			end
			READPARA9:
			begin
				wea <= 1'b1;
				addra <= 3'h6;
				dina <= pcie_data_rec_fifo_out[7*32-1:6*32];
			end
			READPARAA:
			begin
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				wea <= 1'b1;
				addra <= 3'h7;
				dina <= pcie_data_rec_fifo_out[8*32-1:7*32];
			end
			READPARAB:
			begin
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				predicate_op[0]    <= pcie_data_rec_fifo_out[7:0];
				predicate_col[0]   <= pcie_data_rec_fifo_out[15:8];
				predicate_value[0] <= pcie_data_rec_fifo_out[47:16];
				predicate_op[1]    <= pcie_data_rec_fifo_out[1*48+7:1*48];
				predicate_col[1]   <= pcie_data_rec_fifo_out[1*48+15:1*48+8];
				predicate_value[1] <= pcie_data_rec_fifo_out[2*48-1:1*48+16];
				predicate_op[2]    <= pcie_data_rec_fifo_out[2*48+7:2*48];
				predicate_col[2]   <= pcie_data_rec_fifo_out[2*48+15:2*48+8];
				predicate_value[2] <= pcie_data_rec_fifo_out[3*48-1:2*48+16];
				predicate_op[3]    <= pcie_data_rec_fifo_out[3*48+7:3*48];
				predicate_col[3]   <= pcie_data_rec_fifo_out[3*48+15:3*48+8];
				predicate_value[3] <= pcie_data_rec_fifo_out[4*48-1:3*48+16];
				predicate_op[4]    <= pcie_data_rec_fifo_out[4*48+7:4*48];
				predicate_col[4]   <= pcie_data_rec_fifo_out[4*48+15:4*48+8];
				predicate_value[4] <= pcie_data_rec_fifo_out[5*48-1:4*48+16];
				predicate_op[5]    <= pcie_data_rec_fifo_out[5*48+7:5*48];
				predicate_col[5]   <= pcie_data_rec_fifo_out[5*48+15:5*48+8];
			end
			READPARAC:
			begin
				pcie_data_rec_fifo_out_en <= 1'b1;
				count_en <= 1'b1;
				predicate_value[5] <= pcie_data_rec_fifo_out[31:0];
				predicate_op[6]    <= pcie_data_rec_fifo_out[39:32];
				predicate_col[6]   <= pcie_data_rec_fifo_out[47:40];
				predicate_value[6] <= pcie_data_rec_fifo_out[1*48+31:1*48];
				predicate_op[7]    <= pcie_data_rec_fifo_out[1*48+39:1*48+32];
				predicate_col[7]   <= pcie_data_rec_fifo_out[1*40+47:1*48+40];
				predicate_value[7] <= pcie_data_rec_fifo_out[2*48+31:2*48];
				predicate_num      <= pcie_data_rec_fifo_out[2*48+39:2*48+32];			
            end
			READPARATAIL:
			begin
					pcie_data_rec_fifo_out_en <= 1'b1;
					count_en <= 1'b1;
			end
			DONE:
			begin
				query_para_config_done <= 1'b1;
				pcie_cmd_rec_fifo_en <= 1'b1;
			end
		endcase
     end
end

// counter
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

// Instantiate data_parser module
reg [31:0] dout [0:7];
data_parser data_parser_inst(
    .clk(clk),
    .rst(rst),
	//send read page cmd to check cache module
	.read_page_cmd_others(read_page_cmd_others),
	.read_page_cmd_en_others(read_page_cmd_en_others),

	.target_page_addr(target_page_addr),
	.record_num(record_num),
    .read_page_addr(read_page_addr), 
    .page_hit(page_hit), 
    .data_out_en(data_out_en), 
    .data_out(data_out), 
    .data_fifo_empty(data_fifo_empty),
	.rd_en(column_data_fifo_out_en),
	.one_empty(column_data_fifo_empty),
	.dout0(dout[0]),
	.dout1(dout[1]),
	.dout2(dout[2]),
	.dout3(dout[3]),
	.dout4(dout[4]),
	.dout5(dout[5]),
	.dout6(dout[6]),
	.dout7(dout[7]),
    .table_scan_done(table_scan_done)
    );

// read page cmd fifo interface with check cache module
GeneratedReadCMD read_page_cmd_fifo (
  .clk(clk), // input clk
  .rst(rst), // input rst
  .din((query_para_config_done == 1'b1 )? read_page_cmd_others : read_page_cmd), // input [127 : 0] din TODO
  .wr_en((query_para_config_done == 1'b1)? read_page_cmd_en_others : read_page_cmd_en), // input wr_en
  .rd_en(read_page_cmd_fifo_out_en), // input rd_en
  .dout(read_page_cmd_fifo_out), // output [127 : 0] dout
  .full(cmd_full), // output full
  .empty(read_page_cmd_fifo_empty) // output empty
);

// data selection module
always @ (*)
begin
		case(predicate_col[0])
			32'h0:	addrb[0] = compare(dout[0],predicate_op[0],predicate_value[0]);
			32'h1:	addrb[0] = compare(dout[1],predicate_op[0],predicate_value[0]);
			32'h2:	addrb[0] = compare(dout[2],predicate_op[0],predicate_value[0]);
			32'h3:	addrb[0] = compare(dout[3],predicate_op[0],predicate_value[0]);
			32'h4:	addrb[0] = compare(dout[4],predicate_op[0],predicate_value[0]);
			32'h5:	addrb[0] = compare(dout[5],predicate_op[0],predicate_value[0]);
			32'h6:	addrb[0] = compare(dout[6],predicate_op[0],predicate_value[0]);
			32'h7:	addrb[0] = compare(dout[7],predicate_op[0],predicate_value[0]);
			default: addrb[0] = 0;
		endcase
		case(predicate_col[1])
			32'h0:	addrb[1] = compare(dout[0],predicate_op[1],predicate_value[1]);
			32'h1:	addrb[1] = compare(dout[1],predicate_op[1],predicate_value[1]);
			32'h2:	addrb[1] = compare(dout[2],predicate_op[1],predicate_value[1]);
			32'h3:	addrb[1] = compare(dout[3],predicate_op[1],predicate_value[1]);
			32'h4:	addrb[1] = compare(dout[4],predicate_op[1],predicate_value[1]);
			32'h5:	addrb[1] = compare(dout[5],predicate_op[1],predicate_value[1]);
			32'h6:	addrb[1] = compare(dout[6],predicate_op[1],predicate_value[1]);
			32'h7:	addrb[1] = compare(dout[7],predicate_op[1],predicate_value[1]);
			default: addrb[1] = 0;
		endcase
		case(predicate_col[2])
			32'h0:	addrb[2] = compare(dout[0],predicate_op[2],predicate_value[2]);
			32'h1:	addrb[2] = compare(dout[1],predicate_op[2],predicate_value[2]);
			32'h2:	addrb[2] = compare(dout[2],predicate_op[2],predicate_value[2]);
			32'h3:	addrb[2] = compare(dout[3],predicate_op[2],predicate_value[2]);
			32'h4:	addrb[2] = compare(dout[4],predicate_op[2],predicate_value[2]);
			32'h5:	addrb[2] = compare(dout[5],predicate_op[2],predicate_value[2]);
			32'h6:	addrb[2] = compare(dout[6],predicate_op[2],predicate_value[2]);
			32'h7:	addrb[2] = compare(dout[7],predicate_op[2],predicate_value[2]);
			default: addrb[2] = 0;
		endcase
		case(predicate_col[3])
			32'h0:	addrb[3] = compare(dout[0],predicate_op[3],predicate_value[3]);
			32'h1:	addrb[3] = compare(dout[1],predicate_op[3],predicate_value[3]);
			32'h2:	addrb[3] = compare(dout[2],predicate_op[3],predicate_value[3]);
			32'h3:	addrb[3] = compare(dout[3],predicate_op[3],predicate_value[3]);
			32'h4:	addrb[3] = compare(dout[4],predicate_op[3],predicate_value[3]);
			32'h5:	addrb[3] = compare(dout[5],predicate_op[3],predicate_value[3]);
			32'h6:	addrb[3] = compare(dout[6],predicate_op[3],predicate_value[3]);
			32'h7:	addrb[3] = compare(dout[7],predicate_op[3],predicate_value[3]);
			default: addrb[3] = 0;
		endcase

		case(predicate_col[4])
			32'h0:	addrb[4] = compare(dout[0],predicate_op[4],predicate_value[4]);
			32'h1:	addrb[4] = compare(dout[1],predicate_op[4],predicate_value[4]);
			32'h2:	addrb[4] = compare(dout[2],predicate_op[4],predicate_value[4]);
			32'h3:	addrb[4] = compare(dout[3],predicate_op[4],predicate_value[4]);
			32'h4:	addrb[4] = compare(dout[4],predicate_op[4],predicate_value[4]);
			32'h5:	addrb[4] = compare(dout[5],predicate_op[4],predicate_value[4]);
			32'h6:	addrb[4] = compare(dout[6],predicate_op[4],predicate_value[4]);
			32'h7:	addrb[4] = compare(dout[7],predicate_op[4],predicate_value[4]);
			default: addrb[4] = 0;
		endcase
		case(predicate_col[5])
			32'h0:	addrb[5] = compare(dout[0],predicate_op[5],predicate_value[5]);
			32'h1:	addrb[5] = compare(dout[1],predicate_op[5],predicate_value[5]);
			32'h2:	addrb[5] = compare(dout[2],predicate_op[5],predicate_value[5]);
			32'h3:	addrb[5] = compare(dout[3],predicate_op[5],predicate_value[5]);
			32'h4:	addrb[5] = compare(dout[4],predicate_op[5],predicate_value[5]);
			32'h5:	addrb[5] = compare(dout[5],predicate_op[5],predicate_value[5]);
			32'h6:	addrb[5] = compare(dout[6],predicate_op[5],predicate_value[5]);
			32'h7:	addrb[5] = compare(dout[7],predicate_op[5],predicate_value[5]);
			default: addrb[5] = 0;
		endcase
		case(predicate_col[6])
			32'h0:	addrb[6] = compare(dout[0],predicate_op[6],predicate_value[6]);
			32'h1:	addrb[6] = compare(dout[1],predicate_op[6],predicate_value[6]);
			32'h2:	addrb[6] = compare(dout[2],predicate_op[6],predicate_value[6]);
			32'h3:	addrb[6] = compare(dout[3],predicate_op[6],predicate_value[6]);
			32'h4:	addrb[6] = compare(dout[4],predicate_op[6],predicate_value[6]);
			32'h5:	addrb[6] = compare(dout[5],predicate_op[6],predicate_value[6]);
			32'h6:	addrb[6] = compare(dout[6],predicate_op[6],predicate_value[6]);
			32'h7:	addrb[6] = compare(dout[7],predicate_op[6],predicate_value[6]);
			default: addrb[6] = 0;
		endcase
		case(predicate_col[7])
			32'h0:	addrb[7] = compare(dout[0],predicate_op[7],predicate_value[7]);
			32'h1:	addrb[7] = compare(dout[1],predicate_op[7],predicate_value[7]);
			32'h2:	addrb[7] = compare(dout[2],predicate_op[7],predicate_value[7]);
			32'h3:	addrb[7] = compare(dout[3],predicate_op[7],predicate_value[7]);
			32'h4:	addrb[7] = compare(dout[4],predicate_op[7],predicate_value[7]);
			32'h5:	addrb[7] = compare(dout[5],predicate_op[7],predicate_value[7]);
			32'h6:	addrb[7] = compare(dout[6],predicate_op[7],predicate_value[7]);
			32'h7:	addrb[7] = compare(dout[7],predicate_op[7],predicate_value[7]);
			default: addrb[7] = 0;
		endcase
end

function compare;
input [31:0] col_val;
input [7:0] op;
input [31:0] value;
begin
	case(op)
		8'h0: compare = (col_val == value)? 1:0;
		8'h1: compare = (col_val != value)? 1:0;
		8'h2: compare = (col_val < value)? 1:0;
		8'h3: compare = (col_val > value)? 1:0;
		8'h4: compare = (col_val <= value)? 1:0;
		8'h5: compare = (col_val >= value)? 1:0;
        default: compare = 0;
	endcase
end
endfunction		

// 256bits truth table
RAM256Bits truth_table (
  .clka(clk), // input clka
  .wea(wea), // input [0 : 0] wea
  .addra(addra), // input [2 : 0] addra
  .dina(dina), // input [31 : 0] dina
  .clkb(clk), // input clkb
  .addrb(addrb), // input [7 : 0] addrb
  .doutb(match) // output [0 : 0] doutb
);

// Instantiate the data_projector module
data_projector data_projector_inst (
	.clk(clk),
	.rst(rst),
	.record_num(record_num),
    .column_flag(column_flag),
    .column_data_fifo_empty(column_data_fifo_empty), 
    .column_data_fifo_out_en(column_data_fifo_out_en), 
    .dout0(dout[0]), 
    .dout1(dout[1]), 
    .dout2(dout[2]), 
    .dout3(dout[3]), 
    .dout4(dout[4]), 
    .dout5(dout[5]), 
    .dout6(dout[6]), 
    .dout7(dout[7]), 
    .match(match), 
    .query_cmd_finish_fifo_empty(query_cmd_finish_fifo_empty), 
    .query_cmd_finish_fifo_out_en(query_cmd_finish_fifo_out_en), 
    .query_cmd_finish_fifo_out(query_cmd_finish_fifo_out), 
    .query_data_fifo_out_en(query_data_fifo_out_en), 
    .query_data_fifo_out(query_data_fifo_out)
    );

endmodule
