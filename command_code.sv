package command_code;

	typedef enum logic[3:0]
	{

		ADD = 'd0,
		OR = 'd1,
		ADC = 'd2,
		SBB = 'd3,
		AND = 'd4,
		SUB = 'd5,
		XOR = 'd6,
		CMP = 'd7,
		DIV = 'd8,
		IDIV = 'd9,
		MUL = 'd10,
		IMUL = 'd11,
		MOV = 'd12
		
	} commandCode_e;
	
endpackage : command_code