// Definitions for this specific RISC-V implementation.

package CpuPkg;

    typedef enum logic [2:0] {
        IMM_TYPE_I,
        IMM_TYPE_S,
        IMM_TYPE_B,
        IMM_TYPE_U,
        IMM_TYPE_J,
        IMM_TYPE_CSR
    } imm_type_e;

    typedef enum logic {
        ALU_ARG_1_SEL_REGFILE_R_DATA_1,
        ALU_ARG_1_SEL_PC
    } alu_arg_1_sel_e;

    typedef enum logic [1:0] {
        ALU_ARG_2_SEL_REGFILE_R_DATA_2,
        ALU_ARG_2_SEL_IMM,
        ALU_ARG_2_SEL_4
    } alu_arg_2_sel_e;

    typedef enum logic [3:0] {
        DATA_MEM_OP_LOAD_WORD,
        DATA_MEM_OP_LOAD_HALF,
        DATA_MEM_OP_LOAD_BYTE,
        DATA_MEM_OP_LOAD_HALF_UNSIGNED,
        DATA_MEM_OP_LOAD_BYTE_UNSIGNED,
        DATA_MEM_OP_STORE_WORD,
        DATA_MEM_OP_STORE_HALF,
        DATA_MEM_OP_STORE_BYTE,
        DATA_MEM_OP_NONE
    } data_mem_op_e;

    // REFACTOR Consider more verbose names? e.g. ALU_OP_SRL -> ALU_OP_SHIFT_RIGHT_LOGICAL.
    typedef enum logic [3:0] { 
        ALU_OP_ADD,
        ALU_OP_SLT,
        ALU_OP_SLTU,
        ALU_OP_AND,
        ALU_OP_OR,
        ALU_OP_XOR,
        ALU_OP_SLL,
        ALU_OP_SRL,
        ALU_OP_SUB,
        ALU_OP_SRA,
        ALU_OP_SEQ,
        ALU_OP_SNEQ,
        ALU_OP_SGE,
        ALU_OP_SGEU,
        ALU_OP_ARG_1_BYPASS,
        ALU_OP_ARG_2_BYPASS
    } alu_op_e;

    typedef enum logic [1:0] {
        REGFILE_W_DATA_SEL_ALU,
        REGFILE_W_DATA_SEL_DATA_MEM,
        REGFILE_W_DATA_SEL_CSR
    } regfile_w_data_sel_e;

    typedef enum logic [1:0] {
        BRANCH_TYPE_UNCONDITIONAL,
        BRANCH_TYPE_CONDITIONAL,
        BRANCH_TYPE_NONE
    } branch_type_e;

    typedef enum logic [2:0] {
        BRANCH_PC_SEL_PC_PLUS_IMM,
        BRANCH_PC_SEL_REGFILE_R_DATA_1_PLUS_IMM,
        BRANCH_PC_SEL_PC,
        BRANCH_PC_SEL_MEPC,
        BRANCH_PC_SEL_PC_PLUS_4
    } branch_pc_sel_e;

    typedef enum logic [1:0] {
        CSR_WRITE_TYPE_COPY,
        CSR_WRITE_TYPE_SET,
        CSR_WRITE_TYPE_CLEAR
    } csr_write_type_e;

    typedef logic [31:0] inst_t;
    typedef logic [31:0] word_t;
    typedef logic [4:0]  regfile_addr_t;
    typedef logic [11:0] csr_addr_t;

    typedef struct packed {
        // REFACTOR Rename to addr_1, addr_2?
        regfile_addr_t r_addr_1, r_addr_2;
    } regfile_r_req_st;

    typedef struct packed {
        logic          w_en;
        regfile_addr_t w_addr;
        word_t         w_data;
    } regfile_w_req_st;

    typedef struct packed {
        word_t r_data_1, r_data_2;
    } regfile_r_resp_st;

    typedef struct packed {
        logic            w_en;
        csr_addr_t       addr;
        csr_write_type_e w_type;
    } csr_req_st;

    typedef enum logic [1:0] {
        PC_REDIRECT_CAUSE_COND_BRANCH,
        PC_REDIRECT_CAUSE_UNCOND_BRANCH,
        PC_REDIRECT_CAUSE_TRAP
    } pc_redirect_cause_e;

    typedef struct packed {
        logic               valid;
        word_t              target_pc;
        pc_redirect_cause_e cause;
    } pc_redirect_st;

    // REFACTOR Data memory operations should have a separate enable, read/write select and access size instead of a
    // single enum.
    typedef struct packed {
        logic                regfile_w_en;
        regfile_addr_t       regfile_w_addr;
        //regfile_addr_t       regfile_r_addr_1, regfile_r_addr_2, regfile_w_addr;
        regfile_r_req_st     regfile_r_req;
        imm_type_e           imm_type;    
        alu_arg_1_sel_e      alu_arg_1_sel;
        alu_arg_2_sel_e      alu_arg_2_sel;    
        alu_op_e             alu_op;
        data_mem_op_e        data_mem_op;
        branch_type_e        branch_type;
        branch_pc_sel_e      branch_pc_sel;         
        regfile_w_data_sel_e regfile_w_data_sel;
        csr_req_st           csr_req;
        logic                restore_int_en;
        logic                wait_for_int;
    } uop_st;

    typedef struct packed {
        word_t            pc, imm, alu_result, data_mem_r_data, branch_target_pc, csr_r_data;
        inst_t            inst;
        uop_st            uop;
        regfile_r_resp_st regfile_r_resp; 
        pc_redirect_st    pc_redirect;
    } inst_packet_st;

    localparam PC_RESET = 32'h0;
endpackage