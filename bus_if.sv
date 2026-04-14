interface bus_if
#( parameter reg_size = 8, word_size = 32, mem_size = 256 )
(
	input logic clk, rst
);

	localparam mem_adr_size = $clog2( mem_size );
	localparam cpu_adr_size = $clog2( mem_size * word_size / reg_size );
	localparam adr_dif = cpu_adr_size - mem_adr_size;

	logic read, write;
	logic [ word_size-1 : 0 ] datain, dataout;
	logic [ mem_adr_size-1 : 0 ] addr_w, addr_r;

	modport memory( input clk, read, write, datain, addr_w, addr_r, output dataout );
	modport cpu( output read, write, datain, addr_w, addr_r, input clk, rst, dataout );

endinterface : bus_if