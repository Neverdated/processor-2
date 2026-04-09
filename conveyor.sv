import command_code_st::*;
import command_code::*;
import operand_store::*;

module conveyor
#( parameter reg_size = 8, word_size = 32, mem_size = 256, gpr_number = 32 )
( bus_if.cpu bus );

	localparam mem_adr_size = $clog2( mem_size );
	localparam cpu_adr_size = $clog2( mem_size * word_size / reg_size );
	localparam adr_dif = cpu_adr_size - mem_adr_size;

	enum {

		COMMAND_FETCH_1,
		COMMAND_FETCH_2,
		OPERAND_1_FETCH_1,
		OPERAND_1_FETCH_2,
		OPERAND_2_FETCH_1,
		OPERAND_2_FETCH_2,
		EXECUTE_START,
		EXECUTE_WAIT,
		STORE_RESULT

	} state;

	logic [ reg_size-1 : 0 ] operand_a, operand_b;

	struct packed {

		commandCodeStore_e opcode_st;
		logic [ reg_size-1 : 0 ] address_a, address_b;

	} current_command_s;

	
	commandCode_e opcode;

	logic [ reg_size-1 : 0 ] gpr [ gpr_number-1 : 0 ];
	logic [ reg_size-1 : 0 ] flags;
	logic [ cpu_adr_size-1 : 0 ] stack_pointer;
	logic [ cpu_adr_size-1 : 0 ] command_pointer;
	logic [ cpu_adr_size-1 : 0 ] current_addr;

	logic clk, rst;
	logic carry_in, done_mult, done_div, got_out_div, got_out_mult, sign;
	logic data_valid_div, data_valid_mult, data_req_div, data_req_mult;
	logic carry_out_simple, zero_out_simple, overflow_out_simple, sign_out_simple;
	logic zero_out_mult, sign_out_mult;
	logic zero_out_div, overflow_out_div, sign_out_div;
	logic [ reg_size-1 : 0 ] dividend_1, dividend_2, divider;
	logic [ reg_size-1 : 0 ] quotient, remainder;
	logic [ reg_size-1 : 0 ] mult_out_1, mult_out_2;
	logic [ reg_size-1 : 0 ] out_simple;

	simple_alu #( reg_size ) simple_alu(.*);
	booth #( reg_size ) multiply(.*);
	divide #( reg_size ) divide(.*);



	always_ff @( posedge clk or posedge rst )
	begin

		if(rst)
		begin
			command_pointer <= 'b0;
			stack_pointer <= 'b0;
			flags <= 'b0;
			bus.datain <= 'b0;
			bus.read <= 0;
			bus.write <= 0;
			state <= COMMAND_FETCH_1;
			data_valid_div <= 0;
			data_valid_mult <= 0;
			got_out_div <= 0;
			got_out_mult <= 0;

			for( integer i = 0; i < gpr_number; i = i + 1 )
				gpr[i] <= 'b0;
		end
		else

		case( state )

			COMMAND_FETCH_1:
			begin
				bus.addr_r_cpu <= command_pointer;
				bus.read <= 1;
				bus.write <= 0;

				state <= COMMAND_FETCH_2;
			end

			COMMAND_FETCH_2:
			begin
				bus.read <= 0;
				command_pointer <= command_pointer + 'b100;
				current_command_s <= bus.dataout;

				state <= OPERAND_2_FETCH_1;
			end

			OPERAND_1_FETCH_1:
			begin
				case( current_command_s.opcode_st.store_a )

					REGISTER:
					begin
						operand_a <= gpr[ current_command_s.address_a ];
						state <= EXECUTE_START;
					end

					MEMORY:
					begin
						bus.addr_r_cpu <= { {adr_dif{1'b0}}, current_command_s.address_a };
						bus.read <= 1;

						state <= OPERAND_1_FETCH_2;
					end

					default:
					begin
						operand_a <= current_command_s.address_a;
						state <= EXECUTE_START;
					end

				endcase
			end

			OPERAND_1_FETCH_2:
			begin
				bus.read <= 0;
				current_addr <= bus.addr_r_cpu;
				operand_a <= bus.dataout[ reg_size*(current_addr+1)-1 : reg_size*current_addr ];

				state <= EXECUTE_START;
			end

			OPERAND_2_FETCH_1:
			begin
				case( current_command_s.opcode_st.store_b )

					REGISTER:
					begin
						operand_b <= gpr[ current_command_s.address_b ];
						state <= OPERAND_1_FETCH_1;
					end

					MEMORY:
					begin
						bus.addr_r_cpu <= current_command_s.address_b;
						bus.read <= 1;

						state <= OPERAND_2_FETCH_2;
					end

					default:
					begin
						operand_b <= current_command_s.address_b;
						state <= OPERAND_1_FETCH_1;
					end

				endcase
			end

			OPERAND_2_FETCH_2:
			begin
				bus.read <= 0;
				current_addr <= bus.addr_r_cpu;
				operand_b <= bus.dataout[ reg_size*(current_addr+1)-1 : reg_size*current_addr ];

				state <= OPERAND_1_FETCH_1;
			end

			EXECUTE_START:
				case( opcode )

					ADD, ADC, SUB, SBB, CMP, OR, AND, XOR:
						state <= STORE_RESULT;

					DIV, IDIV:
					begin
						got_out_div <= 0;
						data_valid_div <= 1;

						state <= data_req_div ? EXECUTE_WAIT : EXECUTE_START;
					end

				endcase

			EXECUTE_WAIT:
				state <= done_div ? STORE_RESULT : EXECUTE_WAIT;


			STORE_RESULT:
			begin

				got_out_div <= 0;
				got_out_mult <= 0;
						
				case( current_command_s.opcode_st.store_a )

					REGISTER:
					begin

						case( opcode )

							ADD, ADC, SUB, SBB, CMP, OR, AND, XOR:
								gpr[ current_command_s.address_a ] <= out_simple;

							DIV, IDIV:
								gpr[ current_command_s.address_a ] <= quotient;

						endcase
					end

					MEMORY:
					begin
						
						case( opcode )

							ADD, ADC, SUB, SBB, CMP, OR, AND, XOR:
							begin
								bus.datain <= out_simple;
								bus.addr_w_cpu <= { {adr_dif{1'b0}}, current_command_s.address_a };
								bus.write = 1;
							end

							DIV, IDIV:
							begin
								bus.datain <= quotient;
								bus.addr_w_cpu <= { {adr_dif{1'b0}}, current_command_s.address_a };
							
							end

						endcase

						bus.write <= 1;
					end

					default:
					begin
						
						case( opcode )

							ADD, ADC, SUB, SBB, CMP, OR, AND, XOR:
								gpr[0] <= out_simple;

							DIV, IDIV:
								gpr[0] <= quotient;

						endcase
					end

				endcase

				state <= COMMAND_FETCH_1;

			end

		endcase

	end



	assign clk = bus.clk;
	assign rst = bus.rst;
	assign carry_in = flags[ 'h1 ];
	assign opcode = current_command_s.opcode_st.opcode;
	assign sign = opcode == IDIV;
	assign dividend_1 = gpr[3];
	assign dividend_2 = operand_a;
	assign divider = operand_b;

endmodule