module general_purpose_registers
#( parameter reg_size = 8, gpr_number = 32 )
(

	input clk, rst,
	input gpr_write_1, gpr_write_2,
	input [ reg_size-1 : 0 ] gpr_datain_1, gpr_datain_2,
	input [ $clog2(gpr_number) - 1 : 0] gpr_addr_w_1, gpr_addr_w_2,
	input gpr_read_1, gpr_read_2,
	input [ $clog2(gpr_number) - 1 : 0] gpr_addr_r_1, gpr_addr_r_2,
	output reg [ reg_size-1 : 0 ] gpr_dataout_1, gpr_dataout_2

);

	logic [reg_size-1:0] mem_unit [gpr_number] ;

	integer i;

	always @(posedge clk or posedge rst)

		if(rst)
		begin
			for( i = 0; i < gpr_number; i = i + 1 ) mem_unit[i] <= 'b0;
			gpr_dataout_1 <= 'b0;
			gpr_dataout_2 <= 'b0;
		end

		else
		begin
			if(gpr_read_1)
				for( i = 0; i < gpr_number; i = i + 1 )
					if( gpr_addr_r_1 == i )
						gpr_dataout_1 <= mem_unit[ i ];

			if(gpr_read_2)
				for( i = 0; i < gpr_number; i = i + 1 )
					if( gpr_addr_r_2 == i )
						gpr_dataout_2 <= mem_unit[ i ];
			
			if(gpr_write_1)
				for (i = 0; i < gpr_number; i = i + 1)
					if ( gpr_addr_w_1 == i )
						mem_unit[ i ] <= gpr_datain_1;
			
			if(gpr_write_2)
				for (i = 0; i < gpr_number; i = i + 1)
					if ( gpr_addr_w_2 == i )
						mem_unit[ i ] <= gpr_datain_2;
		end
	
endmodule