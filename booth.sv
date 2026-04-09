import command_code::*;

module booth
#( parameter integer reg_size = 8 )
( 	

	input clk, rst,
	input logic[ reg_size-1 : 0 ] operand_a, operand_b,
	input logic data_valid_mult, got_out_mult, sign,
	output logic[ reg_size-1 : 0 ] mult_out_1, mult_out_2,
	output logic done_mult, data_req_mult, sign_out_mult, zero_out_mult

);



	localparam iter_count = reg_size / 2;

	logic [ reg_size-1 : 0 ] r1, r2, r3;
	logic [ reg_size+1 : 0 ] ra, rb, rc, sum;
	logic [ $clog2( (reg_size / 2) + 1 ) - 1 : 0 ] iterator;
	logic bt, add_1_trg;
	
	enum
	{
	
		ZERO_DATA,
		GOT_DATA,
		CHECK_TRIGGERS,
		ADD_SINGLE,
		SUB_SINGLE,
		ADD_DOUBLE,
		SUB_DOUBLE,
		NOTHING,
		SHIFT,
		RETURN_TO_REG,
		COMPENSATION_1,
		COMPENSATION_2,
		DONE
		//GOT_MORE
	
	} state;



	always_ff @( posedge clk or posedge rst )
	if(rst)
	begin
		state <= ZERO_DATA;
		data_req_mult <= 1;
		done_mult <= 0;

		mult_out_1 <= 'b0;
		mult_out_2 <= 'b0;

		rc <= 'b0;
		r2 <= 'b0;
	end
	else
	
		unique case(state)
		
			ZERO_DATA:
				state <= data_valid_mult ? GOT_DATA : ZERO_DATA;
					
			GOT_DATA:
			begin

				data_req_mult <= 0;

				r1 <= operand_a;
				r2 <= operand_b;
				rb <= 'b0;
				rc[ reg_size+1 : reg_size-1 ] <= 2'b00;
				bt <= 0;
				iterator <= iter_count;

				state <= CHECK_TRIGGERS;

			end
			
			CHECK_TRIGGERS:
			case({ r2[1:0], bt })

				3'b001, 3'b010:
					state <= ADD_SINGLE;

				3'b011:
					state <= ADD_DOUBLE;

				3'b100:
					state <= SUB_DOUBLE;

				3'b101, 3'b110:
					state <= SUB_SINGLE;

				default:
					state <= NOTHING;

			endcase

			ADD_SINGLE:
			begin
				ra <= { sign & r1[ reg_size-1 ], sign & r1[ reg_size-1 ], r1 };
				add_1_trg <= 0;
				state <= SHIFT;
			end

			ADD_DOUBLE:
			begin
				ra <= { sign & r1[ reg_size-1 ], r1, 1'b0 };
				add_1_trg <= 0;
				state <= SHIFT;
			end

			SUB_SINGLE:
			begin
				ra <= { ~sign | ~r1[ reg_size-1 ], ~sign | ~r1[ reg_size-1 ], ~r1 };
				add_1_trg <= 1;
				state <= SHIFT;
			end

			SUB_DOUBLE:
			begin
				ra <= { ~sign | ~r1[ reg_size-1 ], ~r1, 1'b1 };
				add_1_trg <= 1;
				state <= SHIFT;
			end

			NOTHING:
			begin
				ra <= 'b0;
				add_1_trg <= 0;
				state <= SHIFT;
			end

			SHIFT:
			begin
				{ rc, r3, bt } <=
				 { sum[ reg_size+1 ], sum[ reg_size+1 ], sum, r2[ reg_size-1 : 1] };
				iterator <= iterator - 'b1;
				state <= RETURN_TO_REG;
			end

			RETURN_TO_REG:
			begin
				rb <= rc;
				r2 <= r3;

				if( iterator == 0 )
					state <= bt & ~sign ? COMPENSATION_1 : DONE;
				else
					state <= CHECK_TRIGGERS;
			end

			COMPENSATION_1:
			begin
				ra <= { 2'b00, r1 };
				add_1_trg <= 0;
				state <= COMPENSATION_2;
			end

			COMPENSATION_2:
			begin
				rc <= sum;
				state <= DONE;
			end
			
			DONE:
			begin

				mult_out_1 <= rc[ reg_size-1 : 0 ];
				mult_out_2 <= r2;

				if( got_out_mult )
				begin
					done_mult <= 0;
					data_req_mult <= 1;
					state <= ZERO_DATA;
				end

				else
				begin
					done_mult <= 1;
					state <= DONE;
				end
					
			end
			
		endcase

	
	
	assign sum = add_1_trg ? ra + rb + 1 : ra + rb;
	assign sign_out_mult = rc[ reg_size-1 ];
	assign zero_out_mult = { rc[ reg_size-1 : 0 ], r2 } == 'b0;
	

endmodule : booth