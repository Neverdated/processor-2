package operand_store;

	typedef enum logic[1:0]
	{

		IMMEDIATE = 'd0,
		REGISTER = 'd1,
		MEMORY = 'd2,
		RELATIVE = 'd3
		
	} operandStore_e;
	
endpackage : operand_store