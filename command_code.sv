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
		JA = 'd22,
		JZ = 'd23,
		JBE = 'd24,
		JC = 'd25,
		JS = 'd26,
		JG = 'd27,
		JGE = 'd28,
		JL = 'd29,
		JLE = 'd30,
		JMP = 'd31,
		JNC = 'd32,
		JNG = 'd33,
		JNLE = 'd34,
		JNO = 'd35,
		JNS = 'd36,
		JNZ = 'd37,
		JO = 'd38
		
	} commandCode_e;
	
endpackage : command_code