import command_code::*;

module simple_alu
#( parameter reg_size = 8 )
(

	input logic clk, rst,
	input logic [ reg_size-1 : 0 ] operand_a, operand_b,
	input commandCode_e opcode,
	input logic carry_in,
	output logic [ reg_size-1 : 0 ] out_simple,
	output logic carry_out_simple, zero_out_simple, overflow_out_simple, sign_out_simple

);



	logic [ reg_size-1 : 0 ] operand_2;
	logic [ reg_size : 0 ] sum;
	logic [reg_size-1 : 0 ] result;



	always_ff @(posedge clk)
	begin


		if(rst) begin
			carry_out_simple <= 0;
			overflow_out_simple <= 0;
			result <= 0;
		end
		else begin



			//result
			case( opcode )

				ADD, ADC, SUB, SBB, CMP:
					result <= sum[ reg_size-1 : 0 ];

				OR:
					result <= operand_a | operand_b;

				AND, TEST:
					result <= operand_a & operand_b;

				XOR:
					result <= operand_a ^ operand_b;

				NOT:
					result <= ~operand_b;

				default:
					result <= operand_a;

			endcase //result op decode



			//overflow carry
			case(opcode)

				ADD, ADC, SUB, SBB, CMP:
				begin
					case({ operand_a[ reg_size-1 ], operand_2[ reg_size-1 ], sum[ reg_size-1 ] })
						3'b001, 3'b110:
							overflow_out_simple <= 1;
						default:
							overflow_out_simple <= 0;
					endcase

					carry_out_simple <= sum[reg_size];
				end

				default:
				begin
					overflow_out_simple <= 0;
					carry_out_simple <= 0;
				end

			endcase //overflow op decode



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

			ADC, SBB:
				sum = carry_in ? operand_a + operand_2 + 1 : operand_a + operand_2;
			SUB, CMP:
				sum = operand_a + operand_2 + 1;

			default:
				sum = operand_a + operand_2;

		endcase

	assign sign_out_simple = result[reg_size-1];
	assign zero_out_simple = result == 'b0;
	assign out_simple = result;


endmodule : simple_alu