import command_code::*;

module divide
#( parameter integer reg_size = 8 )
( divide_if.slave main );



	localparam iter_count = reg_size+1;

	logic [ reg_size-1 : 0 ] r1, r2, r3;
	logic [ reg_size : 0 ] ra, rb, rc, sum;
	logic [ $clog2( reg_size + 1 ) - 1 : 0 ] iterator;
	logic add_1_trg, sign_wire, sign;
	
	enum
	{
	
		ZERO_DATA,
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
		NEGATE_RESULT,
		DONE,
		ERROR
		//GOT_MORE
	
	} state;



	always_ff @( posedge main.clk )
	if(main.rst)
	begin
		state <= ZERO_DATA;
		main.data_req <= 1;
		main.done <= 0;

		main.quotient <= 'b0;
		main.remainder <= 'b0;
	end
	else
	
		unique case(state)
		
			ZERO_DATA:
				state <= main.data_valid ? GOT_DATA : ZERO_DATA;
					
			GOT_DATA:
			begin

				main.data_req <= 0;

				rb <= { 1'b0, main.dividend_1 };
				r1 <= main.dividend_2;
				r2 <= main.divider;
				add_1_trg <= 1;
				iterator <= iter_count;
				sign <= main.sign;

				state <= sign ? EXTRA_SHIFT_1 : CHECK_SUB_1;

			end

			EXTRA_SHIFT_1:
			begin
				{ rc, r3 } <= { rb[ reg_size-1 : 0 ], r1, sign_wire };
				state <= EXTRA_SHIFT_2;
			end

			EXTRA_SHIFT_2:
			begin
				rb <= rc;
				r1 <= r3;
				iterator <= iterator - 'b1;
				state <= CHECK_SUB_1;
			end

			CHECK_SUB_1:
			begin
				ra <= sign & (rb[ reg_size-1 ] ^ r2[ reg_size-1 ]) ?
				 { sign & r2[ reg_size-1 ] , r2 } : { ~sign | ~r2[ reg_size-1 ] , ~r2 };
				add_1_trg <= ~sign | ~sign_wire;
				rb[ reg_size ] <= sign & rb[ reg_size-1 ];

				state <= CHECK_SUB_2;
			end

			CHECK_SUB_2:
				state <= rb[ reg_size ] ^ sum[ reg_size ] ? SHIFT : ERROR;

			SHIFT:
			begin
				{ rc, r3 } <= { sum[ reg_size-1 : 0 ], r1, ~sum[ reg_size ] };
				iterator <= iterator - 'b1;
				state <= RETURN_TO_REG;
			end

			RETURN_TO_REG:
			begin
				rb <= rc;
				r1 <= r3;

				if( iterator == 0 )
					state <= r3[0] ? ( sign ? NEGATE_RESULT : DONE ) : RESTORE_1;
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
				ra <= {r2, 1'b0 };
				add_1_trg <= 0;
				state <= RESTORE_2;
			end

			RESTORE_2:
			begin
				rc <= sum;
				state <= sign ? NEGATE_RESULT : DONE ;
			end

			NEGATE_RESULT:
			begin
				rc <= rc[ reg_size ] ? rc + 'b10 : rc;
				r1 <= r1[ reg_size-1 ] ? r1 + 'b1 : r1;

				state <= DONE;
			end
			
			DONE:
			begin

				main.quotient <= r1;
				main.remainder <= rc[ reg_size : 1 ];
				main.overflow_out <= 0;

				if( main.got_out )
				begin
					main.done <= 0;
					main.data_req <= 1;
					state <= ZERO_DATA;
				end

				else
				begin
					main.done <= 1;
					state <= DONE;
				end
					
			end

			ERROR:
			begin

				main.quotient <= 'b0;
				main.remainder <= 'b0;
				main.overflow_out <= 1;

				if( main.got_out )
				begin
					main.done <= 0;
					main.data_req <= 1;
					state <= ZERO_DATA;
				end

				else
				begin
					main.done <= 1;
					state <= ERROR;
				end

			end
			
		endcase

	
	
	assign sum = add_1_trg ? ra + rb + 1 : ra + rb;
	assign sign_wire = rb[ reg_size-1 ] ^ r2[ reg_size-1 ];
	assign main.zero_out = r1 == 'b0;
	assign sign_out = r1[ reg_size-1 ];
	

endmodule : divide