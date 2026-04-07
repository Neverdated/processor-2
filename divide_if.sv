import command_code::*;

interface divide_if
#( parameter reg_size = 8 )
( input bit	clk, rst );



	logic[ reg_size-1 :0 ] quotient;
	logic[ reg_size-1 :0 ] remainder;
	logic[ reg_size-1 :0 ] dividend_1, dividend_2;
	logic[ reg_size-1 :0 ] divider;
	logic done;
	logic data_valid;
	logic data_req;
	logic got_out;
	logic sign;
	
	

	modport master
	(
		output dividend_1, dividend_2, divider, data_valid, sign, got_out,
		input clk, rst, quotient, remainder, data_req, done
	);
	
	modport slave
	(
	
		input clk, rst, dividend_1, dividend_2, divider, data_valid, sign, got_out,
		output quotient, remainder, data_req, done
	
	);



endinterface : divide_if