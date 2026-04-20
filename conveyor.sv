import command_code_st::*;
import command_code::*;
import operand_store::*;

module conveyor
#( parameter reg_size = 8, word_size = 32, mem_size = 256, gpr_number = 32 )
( bus_if.cpu bus );

	localparam mem_adr_size = $clog2( mem_size );
	localparam regs_in_word = word_size / reg_size;
	localparam cpu_adr_size = $clog2( mem_size ) + $clog2( regs_in_word ) ;
	localparam adr_dif = cpu_adr_size - mem_adr_size;

	enum {

		COMMAND_FETCH_1,
		COMMAND_FETCH_2,
		COMMAND_FETCH_3,
		OPERAND_1_FETCH_1,
		OPERAND_1_FETCH_2,
		OPERAND_1_FETCH_3,
		OPERAND_2_FETCH_1,
		OPERAND_2_FETCH_2,
		OPERAND_2_FETCH_3,
		DIVIDEND_FETCH_1,
		DIVIDEND_FETCH_2,
		DIVIDEND_FETCH_3,
		EXECUTE_START,
		EXECUTE_WAIT,
		STORE_RESULT,
		STORE_EXTRA_1,
		STORE_EXTRA_2

	} state;

	logic [ reg_size-1 : 0 ] operand_a, operand_b;

	struct packed {

		commandCodeStore_e opcode_st;
		logic [ reg_size-1 : 0 ] address_a, address_b;

	} current_command_s;

	
	commandCode_e opcode;

	logic [ 15 : 0 ] flags;
	logic [ cpu_adr_size-1 : 0 ] stack_pointer;
	logic [ mem_adr_size-1 : 0 ] command_pointer;

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
	logic gpr_read, gpr_write;
	logic [ $clog2(gpr_number) - 1 : 0] gpr_addr_w, gpr_addr_r;
	logic [ reg_size-1 : 0 ] gpr_datain, gpr_dataout;
	logic [ reg_size-1 : 0 ] result_to_store;

	simple_alu #( reg_size ) simple_alu(.*);
	booth #( reg_size ) multiply(.*);
	divide #( reg_size ) divide(.*);
	general_purpose_registers #( reg_size, gpr_number ) gpr (.*);



	always_ff @( posedge clk or posedge rst )
	begin

		if(rst)
		begin
			command_pointer <= 'b0;
			stack_pointer <= 'b0;
			flags <= 16'b0000_0000_0000_0010;
			bus.datain <= 'b0;
			bus.read <= 0;
			bus.write <= 0;
			bus.addr_r <= 0;
			state <= COMMAND_FETCH_1;
			data_valid_div <= 0;
			data_valid_mult <= 0;
			got_out_div <= 0;
			got_out_mult <= 0;
			gpr_read <= 0;
			gpr_write <= 0;
		end
		else

		case( state )

			COMMAND_FETCH_1:
			begin
				bus.addr_r <= command_pointer;
				bus.read <= 1;
				bus.write <= 0;
				gpr_write <= 0;

				state <= COMMAND_FETCH_2;
			end

			COMMAND_FETCH_2:
			begin
				state <= COMMAND_FETCH_3;
			end

			COMMAND_FETCH_3:
			begin
				bus.read <= 0;
				command_pointer <= command_pointer + 'd1;
				current_command_s <= bus.dataout[reg_size*2+4+4:0];

				state <= OPERAND_2_FETCH_1;
			end

			OPERAND_1_FETCH_1:
			begin
				case( current_command_s.opcode_st.store_a )

					REGISTER:
					begin
						gpr_read <= 1;
						gpr_addr_r <= current_command_s.address_a;

						state <= OPERAND_1_FETCH_2;
					end

					MEMORY:
					begin
						bus.addr_r <= current_command_s.address_a[reg_size-1:adr_dif];
						bus.read <= 1;

						state <= OPERAND_1_FETCH_2;
					end

					default:
					begin
						operand_a <= current_command_s.address_a;
						state <= opcode == MUL || opcode == IMUL ||
						 opcode == DIV || opcode == IDIV ? DIVIDEND_FETCH_1 : EXECUTE_START;
					end

				endcase
			end

			OPERAND_1_FETCH_2:
				state <= OPERAND_1_FETCH_3;

			OPERAND_1_FETCH_3:
			begin
				case( current_command_s.opcode_st.store_a )

					REGISTER:
					begin
						operand_a <= gpr_dataout;
						gpr_read <= 0;
					end

					MEMORY:
					begin
						operand_a <= bus.dataout[ word_size-reg_size-reg_size*current_command_s.address_a[ adr_dif-1:0 ] +: reg_size ];
						bus.read <= 0;
					end

				endcase

				state <= opcode == MUL || opcode == IMUL ||
				 opcode == DIV || opcode == IDIV ? DIVIDEND_FETCH_1 : EXECUTE_START;
			end

			OPERAND_2_FETCH_1:
			begin
				case( current_command_s.opcode_st.store_b )

					REGISTER:
					begin
						gpr_read <= 1;
						gpr_addr_r <= current_command_s.address_b;

						state <= OPERAND_2_FETCH_2;
					end

					MEMORY:
					begin
						bus.addr_r <= current_command_s.address_b[reg_size-1:adr_dif];
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
				state <= OPERAND_2_FETCH_3;

			OPERAND_2_FETCH_3:
			begin
				case( current_command_s.opcode_st.store_b )

					REGISTER:
					begin
						operand_b <= gpr_dataout;
						gpr_read <= 0;
					end

					MEMORY:
					begin
						operand_b <= bus.dataout[ word_size-reg_size-reg_size*current_command_s.address_b[ adr_dif-1:0 ] +: reg_size ];
						bus.read <= 0;
					end

				endcase

				state <= OPERAND_1_FETCH_1;
			end

			DIVIDEND_FETCH_1:
			begin
				gpr_read <= 1;
				gpr_addr_r <= 'd3;

				state <= DIVIDEND_FETCH_2;
			end

			DIVIDEND_FETCH_2:
				state <= DIVIDEND_FETCH_3;

			DIVIDEND_FETCH_3:
			begin
				gpr_read <= 0;
				dividend_1 <= gpr_dataout;

				state <= EXECUTE_START;
			end

			EXECUTE_START:
				case( opcode )

					DIV, IDIV:
					begin
						got_out_div <= 0;
						data_valid_div <= 1;

						state <= data_req_div ? EXECUTE_WAIT : EXECUTE_START;
					end

					MUL, IMUL:
					begin
						got_out_mult <= 0;
						data_valid_mult <= 1;

						state <= data_req_mult ? EXECUTE_WAIT : EXECUTE_START;
					end

					default:
						state <= STORE_RESULT;

				endcase

			EXECUTE_WAIT:
				case( opcode )

					DIV, IDIV:
					begin
						got_out_div <= done_div;
						data_valid_div <= 0;

						state <= done_div ? STORE_RESULT : EXECUTE_WAIT;
					end

					MUL, IMUL:
					begin
						got_out_mult <= done_mult;
						data_valid_mult <= 0;

						state <= done_mult ? STORE_RESULT : EXECUTE_WAIT;
					end

					default:
						state <= STORE_RESULT;

				endcase
				
				


			STORE_RESULT:
			begin

				got_out_div <= 0;
				got_out_mult <= 0;

				case(opcode)

					ADD, ADC, SUB, SBB, CMP, OR, AND, XOR, CMP, TEST:
					begin
						flags[0] <= carry_out_simple;
						flags[6] <= zero_out_simple;
						flags[7] <= sign_out_simple;
						flags[11] <= overflow_out_simple;
					end

					CLC:
						flags[0] <= 0;

					STC:
						flags[0] <= 1;

					CLD:
						flags[10] <= 0;

					STD:
						flags[10] <= 1;

					CLI:
						flags[9] <= 0;

					STI:
						flags[9] <= 1;

					CMC:
						flags[0] <= ~carry_in;

					DIV, IDIV:
					begin
						flags[0] <= 0;		//carry
						flags[6] <= zero_out_div;
						flags[7] <= sign_out_div;
						flags[11] <= overflow_out_div;
					end

					MUL, IMUL:
					begin
						flags[0] <= 0;		//carry
						flags[6] <= zero_out_mult;
						flags[7] <= sign_out_mult;
						flags[11] <= 0;		//overflow
					end

				endcase


				case(opcode)

					JA:
						if( ~flags[0] & ~flags[6] )
							command_pointer <= operand_a;

					JNC:
						if( ~flags[0] )
							command_pointer <= operand_a;

					JC:
						if( flags[0] )
							command_pointer <= operand_a;

					JBE:
						if( flags[0] | flags[6] )
							command_pointer <= operand_a;

					JZ:
						if( flags[6] )
							command_pointer <= operand_a;

					JG:
						if( ~flags[6] & flags[7] == flags[11] )
							command_pointer <= operand_a;

					JGE:
						if( flags[7] == flags[11] )
							command_pointer <= operand_a;

					JL:
						if( flags[7] != flags[11] )
							command_pointer <= operand_a;

					JLE:
						if( flags[6] | flags[7] != flags[11] )
							command_pointer <= operand_a;

					JMP:
						command_pointer <= operand_a;

					JNG:
						if( flags[6] & flags[7] != flags[11] )
							command_pointer <= operand_a;

					JNLE:
						if( ~flags[6] & flags[7] == flags[11] )
							command_pointer <= operand_a;

					JNO:
						if( ~flags[11] )
							command_pointer <= operand_a;

					JNS:
						if( ~flags[7] )
							command_pointer <= operand_a;

					JNZ:
						if( flags[6] )
							command_pointer <= operand_a;

					JS:
						if( ~flags[0] & ~flags[6] )
							command_pointer <= operand_a;

					JZ:
						if( ~flags[0] & ~flags[6] )
							command_pointer <= operand_a;

					ADD, OR, ADC, SBB, AND, SUB, XOR, NOT, DIV, IDIV, MUL, IMUL, MOV:
						case( current_command_s.opcode_st.store_a )

							REGISTER:
							begin
								gpr_datain <= result_to_store;
								gpr_addr_w <= current_command_s.address_a;
								gpr_write <= 1;
							end

							MEMORY:
							begin
								
								for( integer i = 0; i < regs_in_word; i = i + 1 )
									if( i == current_command_s.address_a[ adr_dif-1:0] )
										bus.datain[  word_size-reg_size-reg_size*i +:reg_size ] <= result_to_store;
									else
										bus.datain[ word_size-reg_size-reg_size*i +:reg_size ] <=
											bus.dataout[ word_size-reg_size-reg_size*i +:reg_size ];

								bus.addr_w <= current_command_s.address_a[ reg_size-1 : adr_dif ];
								bus.write <= 1;
							end

							default:
							begin

								gpr_datain <= result_to_store;
								gpr_addr_w <= 'd0;
								gpr_write <= 1;
							end

						endcase

				endcase


				if( current_command_s.opcode_st.store_a == REGISTER &&
				 ( opcode == DIV || opcode == IDIV || opcode == MUL || opcode == IMUL ) )
					state <= STORE_EXTRA_1;
				else
				begin
					case(opcode)

						DIV, IDIV:
						begin
							gpr_datain <= remainder;
							gpr_addr_w <= 'd2;
							gpr_write <= 1;
						end

						MUL, IMUL:
						begin
							gpr_datain <= mult_out_1;
							gpr_addr_w <= 'd1;
							gpr_write <= 1;
						end

					endcase

					state <= COMMAND_FETCH_1;
				end

			end

			STORE_EXTRA_1:
			begin
				gpr_write <= 0;
				state <= STORE_EXTRA_2;
			end

			STORE_EXTRA_2:
			begin
				case(opcode)

					DIV, IDIV:
					begin
						gpr_datain <= remainder;
						gpr_addr_w <= 'd2;
						gpr_write <= 1;
					end

					MUL, IMUL:
					begin
						gpr_datain <= mult_out_1;
						gpr_addr_w <= 'd1;
						gpr_write <= 1;
					end

				endcase

				state <= COMMAND_FETCH_1;
			end

			

		endcase

	end



	always_comb
		case(opcode)
			ADD, ADC, SUB, SBB, CMP, OR, AND, XOR, NOT, CMP, TEST:
				result_to_store = out_simple;

			DIV, IDIV:
				result_to_store = quotient;

			MUL, IMUL:
				result_to_store = mult_out_2;
			
			default:
				result_to_store = operand_b;
		endcase



	assign clk = bus.clk;
	assign rst = bus.rst;
	assign carry_in = flags[0];
	assign opcode = current_command_s.opcode_st.opcode;
	assign sign = opcode == IDIV || opcode == IMUL;
	assign dividend_2 = operand_a;
	assign divider = operand_b;

endmodule