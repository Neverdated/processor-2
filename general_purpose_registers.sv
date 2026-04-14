module general_purpose_registers
#( parameter reg_size = 8, gpr_number = 32 )
(

	input clk, rst,
	input gpr_write,
	input [ reg_size-1 : 0 ] gpr_datain,
	input [ $clog2(gpr_number) - 1 : 0] gpr_addr_w,
	input gpr_read,
	input [ $clog2(gpr_number) - 1 : 0] gpr_addr_r,
	output reg [ reg_size-1 : 0 ] gpr_dataout

);

	logic [reg_size-1:0] mem_unit [gpr_number] ;

	integer i;

	always @(posedge clk or posedge rst)

		if(rst)
			for( i = 0; i < gpr_number; i = i + 1 ) mem_unit[i] <= 'b0;

		else
		begin
			if(gpr_read)
				for( i = 0; i < gpr_number; i = i + 1 )
					if( gpr_addr_r == i )
						gpr_dataout <= mem_unit[ i ];
			
			if(gpr_write)
				for (i = 0; i < gpr_number; i = i + 1)
					if ( gpr_addr_w == i )
						mem_unit[ i ] <= gpr_datain;
		end
	
endmodule