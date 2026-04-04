import command_code::*;

module simple_alu
#( parameter reg_size = 8 )
(

	input logic clk, rst,
	input logic [ reg_size-1 : 0 ] operand_a, operand_b,
	input commandCode_e opcode,
	input logic carry_in,
	output logic [ reg_size-1 : 0 ] out,
	output logic carry_out, zero_out, overflow_out, sign_out

);



	logic [ reg_size-1 : 0 ] operand_2;
	logic [ reg_size : 0 ] sum;



	always_ff @(posedge clk)
	begin


		if(rst) begin
			out <= 0;
			carry_out <= 0;
			overflow_out <= 0;
			zero_out <= 0;
			sign_out <= 0;
		end
		else begin



			//out carry sign
			case( opcode )

				ADD, ADC, SUB, SBB:
				begin
					out <= sum[ reg_size-1 : 0 ];
					sign_out <= sum[ reg_size - 1 ];
				end

				OR:
				begin
					out <= operand_a | operand_b;
					sign_out <= operand_a[ reg_size-1 ] | operand_b[ reg_size-1 ];
				end

				AND:
				begin
					out <= operand_a & operand_b;
					sign_out <= operand_a[ reg_size-1 ] & operand_b[ reg_size-1 ];
				end

				XOR:
				begin
					out <= operand_a ^ operand_b;
					sign_out <= operand_a[ reg_size-1 ] ^ operand_b[ reg_size-1 ];
				end

				default:
				begin
					out <= operand_a;
					sign_out <= operand_a[ reg_size-1 ];
				end

			endcase //out op decode



			//overflow
			case(opcode)

				ADD, ADC, SUB, SBB, CMP:
				begin
					case({ operand_a[ reg_size-1 ], operand_b[ reg_size-1 ], sum[ reg_size-1 ] })
						001, 110:
							overflow_out <= 1;
						default:
							overflow_out <= 0;
					endcase

					carry_out <= sum[reg_size];
				end

				default:
				begin
					overflow_out <= 0;
					carry_out <= 0;
				end

			endcase //overflow op decode



			//zero
			case(opcode)

				ADD, ADC, SUB, SBB, CMP:
					zero_out <= sum == 0;

				OR:
					zero_out <= operand_a | operand_b == 0;

				AND:
					zero_out <= operand_a & operand_b == 0;

				XOR:
					zero_out <= operand_a ^ operand_b == 0;

				default:
					zero_out <= 0;		

			endcase //zero op decode



		end
	end //always



	//operand 2
	always_comb
		if( opcode == SUB || opcode == SBB || opcode == CMP )
			operand_2 = ~operand_b;
		else
			operand_2 = operand_b;



	//sum
	always_comb
		case(opcode)

			ADC:
				sum = operand_a + operand_2 + carry_in;

			SUB, CMP:
				sum = operand_a + operand_2 + 1;

			SBB:
				sum = operand_a + operand_2 + 1 + carry_in;
			
			default:
				sum = operand_a + operand_2;

		endcase



endmodule : simple_alu