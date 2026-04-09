package command_code_st;

    import command_code::*;
    import operand_store::*;

    typedef struct packed {

        commandCode_e opcode;
        operandStore_e store_a, store_b;

    } commandCodeStore_e;
    
endpackage : command_code_st