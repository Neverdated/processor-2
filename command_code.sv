package command_code;

	typedef enum logic[5:0]
	{

		ADD = 'd0,
		OR = 'd1,
		ADC = 'd2,
		SBB = 'd3,
		AND = 'd4,
		SUB = 'd5,
		XOR = 'd6,
		NOT = 'd13,
		CMP = 'd7,
		TEST = 'd14,
		DIV = 'd8,
		IDIV = 'd9,
		MUL = 'd10,
		IMUL = 'd11,
		MOV = 'd12,
		CLC = 'd15,
		STC = 'd16,
		CLD = 'd17,
		STD = 'd18,
		CLI = 'd19,
		STI = 'd20,
		CMC = 'd21,
		BEQ = 'd22,
		BNE = 'd23,
		BLT = 'd24,
		BGE = 'd25,
		BLTU = 'd26,
		BGEU = 'd27,
		JAL = 'd28,
		JALR = 'd29
		
	} commandCode_e;
	
endpackage : command_code