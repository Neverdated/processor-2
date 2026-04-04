import command_code::*;

interface booth_if
#( parameter reg_size = 8 )
( input bit	clk, rst );



	logic[ reg_size-1 :0 ] out_data_1;
	logic[ reg_size-1 :0 ] out_data_2;
	logic done;
	logic[ reg_size-1 :0 ] operand_1;
	logic[ reg_size-1 :0 ] operand_2;
	logic data_valid;
	logic data_req;
	logic got_out;
	logic sign;
	
	

	modport master
	(
		output operand_1, operand_2, data_valid, sign, got_out,
		input clk, rst, out_data_1, out_data_2, data_req, done
	);
	
	modport slave
	(
	
		input clk, rst, operand_1, operand_2, sign, data_valid, got_out,
		output out_data_1, out_data_2, data_req, done
	
	);



endinterface: booth_if