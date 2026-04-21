import command_code::*;

module divide
#( parameter integer reg_size = 8 )
(

	input logic clk, rst,
	input logic[ reg_size-1 : 0 ] dividend_1, dividend_2, divider,
	input logic data_valid_div, got_out_div, sign,
	output logic[ reg_size-1 : 0 ] quotient, remainder,
	output logic done_div, data_req_div, sign_out_div, zero_out_div, overflow_out_div

);



	localparam iter_count = reg_size+1;

	logic [ reg_size-1 : 0 ] r1, r2, r3;
	logic [ reg_size : 0 ] ra, rb, rc, sum;
	logic [ $clog2( reg_size + 1 ) - 1 : 0 ] iterator;
	logic add_1_trg, sign_trg;
	
	enum
	{
	
		IDLE,
		GOT_DATA,
		EXTRA_SHIFT_1,
		EXTRA_SHIFT_2,
		CHECK_SUB_1,
		CHECK_SUB_2,
		SHIFT,
		RETURN_TO_REG,
		//CHECK_TRIGGERS,
		SUM,
		SUB,
		RESTORE_1,
		RESTORE_2,
		NEGATE_RESULT_1,
		NEGATE_RESULT_2,
		DONE,
		ERROR
		//GOT_MORE
	
	} state;



	always_ff @( posedge clk or posedge rst )
	if(rst)
	begin
		state <= IDLE;
		data_req_div <= 1;
		done_div <= 0;

		quotient <= 'b0;
		remainder <= 'b0;
		r1 <= 'b0;
		overflow_out_div <= 0;
	end
	else
	
		unique case(state)
		
			IDLE:
				state <= data_valid_div ? GOT_DATA : IDLE;
					
			GOT_DATA:
			begin

				data_req_div <= 0;

				rb <= { 1'b0, dividend_1 };
				r1 <= dividend_2;
				r2 <= divider;
				add_1_trg <= 1;
				iterator <= iter_count;
				sign_trg <= dividend_1[reg_size-1] ^ divider[reg_size-1];

				state <= sign ? EXTRA_SHIFT_1 : CHECK_SUB_1;
			end

			EXTRA_SHIFT_1:
			begin
				{ rc, r3 } <= { rb[ reg_size-1 : 0 ], r1, sign_trg };
				iterator <= iterator - 'b1;

				state <= EXTRA_SHIFT_2;
			end

			EXTRA_SHIFT_2:
			begin
				rb <= rc;
				r1 <= r3;

				state <= CHECK_SUB_1;
			end

			CHECK_SUB_1:
			begin
				ra <= sign & sign_trg ?                                                                                   
				 { sign & r2[ reg_size-1 ] , r2 } : { ~sign | ~r2[ reg_size-1 ] , ~r2 };
				add_1_trg <= ~sign | ~sign_trg;
				rb[ reg_size ] <= sign & rb[ reg_size-1 ];

				state <= CHECK_SUB_2;
			end

			CHECK_SUB_2:
				if(sign)
					case({rb[reg_size], r2[reg_size-1], sum[reg_size] })

						3'b000, 3'b010, 3'b101, 3'b111:
							state <= ERROR;
						default:
							state <= SHIFT;

					endcase
				else
					state <= sum[reg_size] ? SHIFT : ERROR;

			SHIFT:
			begin
				{ rc, r3 } <= { sum[ reg_size-1 : 0 ], r1, sum[reg_size] == r2[reg_size-1] };
				iterator <= iterator - 'b1;
				state <= RETURN_TO_REG;
			end

			RETURN_TO_REG:
			begin
				rb <= rc;
				r1 <= r3;

				if( iterator == 0 )
					//state <= ( r3[0] ^ ( r2[reg_size-1] ^ sign_trg ) ) & rc[reg_size:1] !== 'b0 ? ( sign ? NEGATE_RESULT_1 : DONE ) : RESTORE_1;
					state <= rc[reg_size] ? RESTORE_1 : ( sign ? NEGATE_RESULT_1 : DONE );
				else
					state <= r3[0] ? SUB : SUM;

			end

			SUM:
			begin
				ra <= { sign & r2[ reg_size-1 ] , r2 };
				add_1_trg <= 0;
				state <= SHIFT;
			end

			SUB:
			begin
				ra <= { ~sign | ~r2[ reg_size-1 ] , ~r2 };
				add_1_trg <= 1;
				state <= SHIFT;
			end

			RESTORE_1:
			begin
				//ra <= { r3[0] ? ~r2 : r2, r3[0] };
				//add_1_trg <= r3[0];
				ra <= { r2[reg_size-1] ? ~r2 : r2, r2[reg_size-1] };
				add_1_trg <= r2[reg_size-1];
				state <= RESTORE_2;
			end

			RESTORE_2:
			begin
				rc <= sum;
				state <= sign ? NEGATE_RESULT_1 : DONE ;
			end

			NEGATE_RESULT_1:
			begin
				//rc <= rc[ reg_size ] ? rc + 'b10 : rc;
				rb <= 'b0;
				ra <= { 1'b0, r1 };
				add_1_trg <= 1;

				// & rc[reg_size : 1] != 'b0
				state <= r1[reg_size-1] ? NEGATE_RESULT_2 : DONE;
			end

			NEGATE_RESULT_2:
			begin
				r1 <= sum;
				state <= DONE;
			end
			
			DONE:
			begin

				quotient <= r1;
				remainder <= rc[ reg_size : 1 ];
				overflow_out_div <= 0;

				if( got_out_div )
				begin
					done_div <= 0;
					data_req_div <= 1;
					state <= IDLE;
				end

				else
				begin
					done_div <= 1;
					state <= DONE;
				end
					
			end

			ERROR:
			begin

				quotient <= 'b0;
				remainder <= 'b0;
				overflow_out_div <= 1;

				if( got_out_div )
				begin
					done_div <= 0;
					data_req_div <= 1;
					state <= IDLE;
				end

				else
				begin
					done_div <= 1;
					state <= ERROR;
				end

			end
			
		endcase

	
	
	assign sum = add_1_trg ? ra + rb + 1 : ra + rb;
	assign zero_out_div = r1 == 'b0;
	assign sign_out_div = r1[ reg_size-1 ];
	

endmodule : divide