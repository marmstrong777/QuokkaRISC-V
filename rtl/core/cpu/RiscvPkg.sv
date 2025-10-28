// Definitions from RISC-V specification.

package RiscvPkg;

    // ========== Instruction encodings.

    // REFACTOR Remove redundant _TYPE from enum names and values.
    typedef enum logic [6:0] { 
        OPCODE_TYPE_LUI       = 7'b0110111,
        OPCODE_TYPE_AUIPC     = 7'b0010111,
        OPCODE_TYPE_JAL       = 7'b1101111,
        OPCODE_TYPE_JALR      = 7'b1100111,
        OPCODE_TYPE_BRANCH    = 7'b1100011,
        OPCODE_TYPE_LOAD      = 7'b0000011,
        OPCODE_TYPE_STORE     = 7'b0100011,
        OPCODE_TYPE_ARITH_IMM = 7'b0010011,
        OPCODE_TYPE_ARITH     = 7'b0110011,
        OPCODE_TYPE_FENCE     = 7'b0001111,
        OPCODE_TYPE_SYSTEM    = 7'b1110011
    } opcode_type_e;

    typedef enum logic [2:0] {
        FUNCT3_TYPE_BRANCH_BEQ  = 3'b000,
        FUNCT3_TYPE_BRANCH_BNE  = 3'b001,
        FUNCT3_TYPE_BRANCH_BLT  = 3'b100,
        FUNCT3_TYPE_BRANCH_BGE  = 3'b101,
        FUNCT3_TYPE_BRANCH_BLTU = 3'b110,
        FUNCT3_TYPE_BRANCH_BGEU = 3'b111
    } funct3_type_branch_e;

    typedef enum logic [2:0] {
        FUNCT3_TYPE_LOAD_LB  = 3'b000,
        FUNCT3_TYPE_LOAD_LH  = 3'b001,
        FUNCT3_TYPE_LOAD_LW  = 3'b010,
        FUNCT3_TYPE_LOAD_LBU = 3'b100,
        FUNCT3_TYPE_LOAD_LHU = 3'b101
    } funct3_type_load_e;

    typedef enum logic [2:0] {
        FUNCT3_TYPE_STORE_SB = 3'b000,
        FUNCT3_TYPE_STORE_SH = 3'b001,
        FUNCT3_TYPE_STORE_SW = 3'b010
    } funct3_type_store_e;

    typedef enum logic [2:0] {
        FUNCT3_TYPE_ARITH_IMM_ADDI      = 3'b000,
        FUNCT3_TYPE_ARITH_IMM_SLTI      = 3'b010,
        FUNCT3_TYPE_ARITH_IMM_SLTIU     = 3'b011,
        FUNCT3_TYPE_ARITH_IMM_XORI      = 3'b100,
        FUNCT3_TYPE_ARITH_IMM_ORI       = 3'b110,
        FUNCT3_TYPE_ARITH_IMM_ANDI      = 3'b111,
        FUNCT3_TYPE_ARITH_IMM_SLLI      = 3'b001,
        FUNCT3_TYPE_ARITH_IMM_SRLI_SRAI = 3'b101
    } funct3_type_arith_imm_e;

    // REFACTOR These funct3 values for arithmetic r type instructions seem to be the same for arithmetic i type instructions, merge into one enum.
    typedef enum logic [2:0] {
        FUNCT3_TYPE_ARITH_IMM_ADD_SUB = 3'b000,
        FUNCT3_TYPE_ARITH_IMM_SLL     = 3'b001,
        FUNCT3_TYPE_ARITH_IMM_SLT     = 3'b010,
        FUNCT3_TYPE_ARITH_IMM_SLTU    = 3'b011,
        FUNCT3_TYPE_ARITH_IMM_XOR     = 3'b100,
        FUNCT3_TYPE_ARITH_IMM_SRL_SRA = 3'b101,
        FUNCT3_TYPE_ARITH_IMM_OR      = 3'b110,
        FUNCT3_TYPE_ARITH_IMM_AND     = 3'b111
    } funct3_type_arith_e;

    typedef enum logic [2:0] {
        FUNCT3_TYPE_SYSTEM_RET_WFI = 3'b000,
        FUNCT3_TYPE_SYSTEM_CSRRW   = 3'b001,
        FUNCT3_TYPE_SYSTEM_CSRRS   = 3'b010,
        FUNCT3_TYPE_SYSTEM_CSRRC   = 3'b011,
        FUNCT3_TYPE_SYSTEM_CSRRWI  = 3'b101,
        FUNCT3_TYPE_SYSTEM_CSRRSI  = 3'b110,
        FUNCT3_TYPE_SYSTEM_CSRRCI  = 3'b111
    } funct3_type_system_e;

    typedef enum logic [6:0] {
        FUNCT7_TYPE_ARITH_ADD_SRL = 7'b0000000,
        FUNCT7_TYPE_ARITH_SUB_SRA = 7'b0100000
    } funct7_type_arith_e;

    typedef enum logic [6:0] {
        FUNCT7_TYPE_ARITH_IMM_SRLI = 7'b0000000,
        FUNCT7_TYPE_ARITH_IMM_SRAI = 7'b0100000
    } funct7_type_arith_imm_e;

    typedef enum logic [6:0] {
        FUNCT7_TYPE_SYSTEM_MRET = 7'b0011000,
        FUNCT7_TYPE_SYSTEM_WFI  = 7'b0001000
    } funct7_type_system_e;

    typedef enum logic [4:0] {
        RS2_TYPE_SYSTEM_MRET = 5'b00010,
        RS2_TYPE_SYSTEM_WFI  = 5'b00101
    } rs2_type_system_e;

    typedef enum logic [11:0] {
        CSR_ADDR_MSTATUS  = 12'h300,
        CSR_ADDR_MIE      = 12'h304,
        CSR_ADDR_MTVEC    = 12'h305,
        CSR_ADDR_MSCRATCH = 12'h340,
        CSR_ADDR_MEPC     = 12'h341,
        CSR_ADDR_MCAUSE   = 12'h342,
        CSR_ADDR_MTVAL    = 12'h343,
        CSR_ADDR_MIP      = 12'h344
    } csr_addr_e;

    typedef enum logic {
        CSR_MTVEC_MODE_DIRECT   = '0,
        CSR_MTVEC_MODE_VECTORED = '1
    } csr_mtvec_mode_e;

    typedef enum logic [30:0] {
        EXCEPTION_CODE_MISALIGN_INST           = 31'd0,
        EXCEPTION_CODE_ACCESS_FAULT_INST       = 31'd1,
        EXCEPTION_CODE_ILLEGAL_INST            = 31'd2,
        EXCEPTION_CODE_BREAKPOINT              = 31'd3,
        EXCEPTION_CODE_MISALIGN_LOAD_ADDR      = 31'd4,
        EXCEPTION_CODE_ACCESS_FAULT_LOAD       = 31'd5,
        EXCEPTION_CODE_MISALIGN_STORE_AMO_ADDR = 31'd6,
        EXCEPTION_CODE_ACCESS_FAULT_STORE_AMO  = 31'd7,
        EXCEPTION_CODE_DOUBLE_TRAP             = 31'd16
    } exception_code_e;
    
    typedef enum logic [30:0] {
        INTERRUPT_CODE_SOFTWARE_M = 31'd3,
        INTERRUPT_CODE_TIMER_M    = 31'd7,
        INTERRUPT_CODE_EXTERNAL_M = 31'd11
    } interrupt_code_e;
endpackage