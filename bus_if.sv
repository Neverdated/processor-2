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
	logic [ mem_adr_size-1 : 0 ] addr_w_mem, addr_r_mem;
	logic [ cpu_adr_size-1 : 0 ] addr_w_cpu, addr_r_cpu;

	assign addr_w_mem = addr_w_cpu[ cpu_adr_size-1 : adr_dif ];
	assign addr_r_mem = addr_w_cpu[ cpu_adr_size-1 : adr_dif ];

	modport memory( input clk, read, write, datain, addr_w_mem, addr_r_mem, output dataout );
	modport cpu( output read, write, datain, addr_w_cpu, addr_r_cpu, input clk, rst, dataout );

endinterface : bus_if