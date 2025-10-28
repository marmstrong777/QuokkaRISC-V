import CpuPkg::*;
import RiscvPkg::*;


// FIXME Illegal instruction should result in all side effect causing uop fields disabled e.g. write enable.
// REFACTOR Should probably put the instruction name in it's case statement for clarity.
module InstructionDecoder (
    input  inst_t i_inst,
    output logic  o_illegal,
    output uop_st o_uop
);

    logic [6:0] w_opcode;
    logic [2:0] w_funct3;
    logic [6:0] w_funct7;

    always_comb begin
        // To be overwritten to 1 in the default cases.
        o_illegal = '0;
    
        w_opcode = i_inst[6:0];
        w_funct3 = i_inst[14:12];
        w_funct7 = i_inst[31:25];
        
        // REFACTOR Set to 'x if read value is not used?
        o_uop.regfile_r_req.r_addr_1 = i_inst[19:15]; 
        o_uop.regfile_r_req.r_addr_2 = i_inst[24:20];
        o_uop.regfile_w_addr         = i_inst[11:7];
        o_uop.csr_req.addr           = i_inst[31:20];

        case ( w_opcode )
        OPCODE_TYPE_LUI : begin
            // REFACTOR alu_arg2_bypass could be replaced with a regfile write sel case for imm? Might be wasteful however.
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_U;
            o_uop.alu_arg_1_sel      = alu_arg_1_sel_e'( 'x );
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_IMM;
            o_uop.alu_op             = ALU_OP_ARG_2_BYPASS;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;
        end

        OPCODE_TYPE_AUIPC : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_U;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_PC;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_IMM;
            o_uop.alu_op             = ALU_OP_ADD;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;
        end

        OPCODE_TYPE_JAL : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_J;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_PC;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_4;
            o_uop.alu_op             = ALU_OP_ADD;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_UNCONDITIONAL;
            o_uop.branch_pc_sel      = BRANCH_PC_SEL_PC_PLUS_IMM;
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;
        end

        OPCODE_TYPE_JALR : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_I;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_PC;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_4;
            o_uop.alu_op             = ALU_OP_ADD;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_UNCONDITIONAL;
            o_uop.branch_pc_sel      = BRANCH_PC_SEL_REGFILE_R_DATA_1_PLUS_IMM;
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;
        end

        // REFACTOR Rename this opcode group to COND_BRANCH?
        OPCODE_TYPE_BRANCH : begin
            o_uop.regfile_w_en       = '0;
            o_uop.imm_type           = IMM_TYPE_B;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_REGFILE_R_DATA_2;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_CONDITIONAL;
            o_uop.branch_pc_sel      = BRANCH_PC_SEL_PC_PLUS_IMM;
            o_uop.regfile_w_data_sel = regfile_w_data_sel_e'( 'x );
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;

            case ( funct3_type_branch_e'( w_funct3 ) )
            FUNCT3_TYPE_BRANCH_BEQ  : o_uop.alu_op = ALU_OP_SEQ;
            FUNCT3_TYPE_BRANCH_BNE  : o_uop.alu_op = ALU_OP_SNEQ;
            FUNCT3_TYPE_BRANCH_BLT  : o_uop.alu_op = ALU_OP_SLT;
            FUNCT3_TYPE_BRANCH_BGE  : o_uop.alu_op = ALU_OP_SGE;
            FUNCT3_TYPE_BRANCH_BLTU : o_uop.alu_op = ALU_OP_SLTU;
            FUNCT3_TYPE_BRANCH_BGEU : o_uop.alu_op = ALU_OP_SGEU;
            
            default: begin
                o_uop.alu_op = alu_op_e'( 'x );
                
                o_illegal = '1;
            end
            endcase
        end

        OPCODE_TYPE_LOAD : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_I;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_IMM;
            o_uop.alu_op             = ALU_OP_ADD;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_DATA_MEM;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;

            case ( funct3_type_load_e'( w_funct3 ) )
            FUNCT3_TYPE_LOAD_LB  : o_uop.data_mem_op = DATA_MEM_OP_LOAD_BYTE;
            FUNCT3_TYPE_LOAD_LH  : o_uop.data_mem_op = DATA_MEM_OP_LOAD_HALF;
            FUNCT3_TYPE_LOAD_LW  : o_uop.data_mem_op = DATA_MEM_OP_LOAD_WORD;
            FUNCT3_TYPE_LOAD_LBU : o_uop.data_mem_op = DATA_MEM_OP_LOAD_BYTE_UNSIGNED;
            FUNCT3_TYPE_LOAD_LHU : o_uop.data_mem_op = DATA_MEM_OP_LOAD_HALF_UNSIGNED;
            
            default: begin
                o_uop.data_mem_op = data_mem_op_e'( 'x );
                
                o_illegal = '1;
            end
            endcase
        end

        OPCODE_TYPE_STORE : begin
            o_uop.regfile_w_en       = '0;
            o_uop.imm_type           = IMM_TYPE_S;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_IMM;
            o_uop.alu_op             = ALU_OP_ADD;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = regfile_w_data_sel_e'( 'x );
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;

            case ( funct3_type_store_e'( w_funct3 ) )
            FUNCT3_TYPE_STORE_SB : o_uop.data_mem_op = DATA_MEM_OP_STORE_BYTE;
            FUNCT3_TYPE_STORE_SH : o_uop.data_mem_op = DATA_MEM_OP_STORE_HALF;
            FUNCT3_TYPE_STORE_SW : o_uop.data_mem_op = DATA_MEM_OP_STORE_WORD;
            
            default: begin
                o_uop.data_mem_op = data_mem_op_e'( 'x );
                
                o_illegal = '1;
            end
            endcase
        end

        OPCODE_TYPE_ARITH_IMM : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = IMM_TYPE_I;
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_IMM;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;

            case ( funct3_type_arith_imm_e'( w_funct3 ) )
                FUNCT3_TYPE_ARITH_IMM_ADDI  : o_uop.alu_op = ALU_OP_ADD;
                FUNCT3_TYPE_ARITH_IMM_SLTI  : o_uop.alu_op = ALU_OP_SLT;
                FUNCT3_TYPE_ARITH_IMM_SLTIU : o_uop.alu_op = ALU_OP_SLTU;
                FUNCT3_TYPE_ARITH_IMM_XORI  : o_uop.alu_op = ALU_OP_XOR;
                FUNCT3_TYPE_ARITH_IMM_ORI   : o_uop.alu_op = ALU_OP_OR;
                FUNCT3_TYPE_ARITH_IMM_ANDI  : o_uop.alu_op = ALU_OP_AND;
                FUNCT3_TYPE_ARITH_IMM_SLLI  : o_uop.alu_op = ALU_OP_SLL;

                FUNCT3_TYPE_ARITH_IMM_SRLI_SRAI : begin
                    case ( funct7_type_arith_imm_e'( w_funct7 ) )
                    FUNCT7_TYPE_ARITH_IMM_SRLI : o_uop.alu_op = ALU_OP_SRL;
                    FUNCT7_TYPE_ARITH_IMM_SRAI : o_uop.alu_op = ALU_OP_SRA;
                    
                    default: begin
                        o_uop.alu_op = alu_op_e'( 'x );
                        
                        o_illegal = '1;
                    end
                    endcase
                end
            endcase
        end

        OPCODE_TYPE_ARITH : begin
            o_uop.regfile_w_en       = '1;
            o_uop.imm_type           = imm_type_e'( 'x );
            o_uop.alu_arg_1_sel      = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
            o_uop.alu_arg_2_sel      = ALU_ARG_2_SEL_REGFILE_R_DATA_2;
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_ALU;
            o_uop.csr_req.w_en       = '0;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = '0;
            o_uop.wait_for_int       = '0;

            case ( funct3_type_arith_e'( w_funct3 ) )
                FUNCT3_TYPE_ARITH_IMM_ADD_SUB : begin
                    case ( funct7_type_arith_e'( w_funct7 ) )
                    FUNCT7_TYPE_ARITH_ADD_SRL : o_uop.alu_op = ALU_OP_ADD;
                    FUNCT7_TYPE_ARITH_SUB_SRA : o_uop.alu_op = ALU_OP_SUB;
                    
                    default: begin
                        o_uop.alu_op = alu_op_e'( 'x );
                        
                        o_illegal = '1;
                    end
                    endcase
                end

                FUNCT3_TYPE_ARITH_IMM_SLL  : o_uop.alu_op = ALU_OP_SLL;
                FUNCT3_TYPE_ARITH_IMM_SLT  : o_uop.alu_op = ALU_OP_SLT;
                FUNCT3_TYPE_ARITH_IMM_SLTU : o_uop.alu_op = ALU_OP_SLTU;
                FUNCT3_TYPE_ARITH_IMM_XOR  : o_uop.alu_op = ALU_OP_XOR;

                FUNCT3_TYPE_ARITH_IMM_SRL_SRA : begin
                    case ( funct7_type_arith_e'( w_funct7 ) )
                    FUNCT7_TYPE_ARITH_ADD_SRL : o_uop.alu_op = ALU_OP_SRL;
                    FUNCT7_TYPE_ARITH_SUB_SRA : o_uop.alu_op = ALU_OP_SRA;
                    
                    default: begin
                        o_uop.alu_op = alu_op_e'( 'x );
                        
                        o_illegal = '1;
                    end
                    endcase
                end

                FUNCT3_TYPE_ARITH_IMM_OR  : o_uop.alu_op = ALU_OP_OR;
                FUNCT3_TYPE_ARITH_IMM_AND : o_uop.alu_op = ALU_OP_AND;
            endcase
        end

        OPCODE_TYPE_FENCE : begin
            // TODO Implement.
            o_uop.regfile_w_en       = 'x;
            o_uop.imm_type           = imm_type_e'( 'x );
            o_uop.alu_arg_1_sel      = alu_arg_1_sel_e'( 'x );
            o_uop.alu_arg_2_sel      = alu_arg_2_sel_e'( 'x );
            o_uop.alu_op             = alu_op_e'( 'x );
            o_uop.data_mem_op        = data_mem_op_e'( 'x );
            o_uop.branch_type        = branch_type_e'( 'x );
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = regfile_w_data_sel_e'( 'x );
            o_uop.csr_req.w_en       = 'x;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = 'x;
            o_uop.wait_for_int       = 'x;
        end

        // regfile_w_en
        // imm_type
        // alu_arg_1_sel
        // alu_arg_2_sel
        // alu_op
        // data_mem_op
        // branch_type
        // branch_pc_sel
        // regfile_w_data_sel
        // csr_req

        OPCODE_TYPE_SYSTEM : begin
            
            o_uop.data_mem_op        = DATA_MEM_OP_NONE;
            o_uop.branch_type        = BRANCH_TYPE_NONE;
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = REGFILE_W_DATA_SEL_CSR;

            // FIXME Need to also check rs1 and rd fields for some of these system instructions.
            case ( funct3_type_system_e'( w_funct3 ) )
            FUNCT3_TYPE_SYSTEM_RET_WFI: begin
                case ( { funct7_type_system_e'( w_funct7 ), rs2_type_system_e'( o_uop.regfile_r_req.r_addr_2 ) } )
                { FUNCT7_TYPE_SYSTEM_MRET, RS2_TYPE_SYSTEM_MRET }: begin
                    o_uop.regfile_w_en   = '0;
                    o_uop.imm_type       = imm_type_e'( 'x );
                    o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                    o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                    o_uop.alu_op         = alu_op_e'( 'x );
                    o_uop.branch_type    = BRANCH_TYPE_UNCONDITIONAL;
                    o_uop.branch_pc_sel  = BRANCH_PC_SEL_MEPC;
                    o_uop.csr_req.w_en   = '0;  
                    o_uop.csr_req.w_type = csr_write_type_e'( 'x );
                    o_uop.restore_int_en = '1;
                    o_uop.wait_for_int   = '0;
                end
                { FUNCT7_TYPE_SYSTEM_WFI, RS2_TYPE_SYSTEM_WFI }: begin
                    o_uop.regfile_w_en   = '0;
                    o_uop.imm_type       = imm_type_e'( 'x );
                    o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                    o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                    o_uop.alu_op         = alu_op_e'( 'x );
                    o_uop.branch_type    = BRANCH_TYPE_UNCONDITIONAL;
                    o_uop.branch_pc_sel  = BRANCH_PC_SEL_PC_PLUS_4;
                    o_uop.csr_req.w_en   = '0;  
                    o_uop.csr_req.w_type = csr_write_type_e'( 'x );
                    o_uop.restore_int_en = '0;
                    o_uop.wait_for_int   = '1;
                end
                default: begin
                    o_uop.regfile_w_en   = 'x;
                    o_uop.imm_type       = imm_type_e'( 'x );
                    o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                    o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                    o_uop.alu_op         = alu_op_e'( 'x );
                    o_uop.csr_req.w_en   = 'x;
                    o_uop.csr_req.w_type = csr_write_type_e'( 'x );
                    o_uop.restore_int_en = 'x;
                    o_uop.wait_for_int   = 'x;
                    
                    o_illegal = '1;
                end
                endcase
            end
            FUNCT3_TYPE_SYSTEM_CSRRW: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = imm_type_e'( 'x );
                o_uop.alu_arg_1_sel  = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
                o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                o_uop.alu_op         = ALU_OP_ARG_1_BYPASS;
                o_uop.csr_req.w_en   = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_COPY;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            FUNCT3_TYPE_SYSTEM_CSRRS: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = imm_type_e'( 'x );
                o_uop.alu_arg_1_sel  = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
                o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                o_uop.alu_op         = ALU_OP_ARG_1_BYPASS;
                o_uop.csr_req.w_en   = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_SET;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            FUNCT3_TYPE_SYSTEM_CSRRC: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = imm_type_e'( 'x );
                o_uop.alu_arg_1_sel  = ALU_ARG_1_SEL_REGFILE_R_DATA_1;
                o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                o_uop.alu_op         = ALU_OP_ARG_1_BYPASS;
                o_uop.csr_req.w_en   = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_CLEAR;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            FUNCT3_TYPE_SYSTEM_CSRRWI: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = IMM_TYPE_CSR;
                o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                o_uop.alu_arg_2_sel  = ALU_ARG_2_SEL_IMM;
                o_uop.alu_op         = ALU_OP_ARG_2_BYPASS;
                o_uop.csr_req.w_en   = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_COPY;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            FUNCT3_TYPE_SYSTEM_CSRRSI: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = IMM_TYPE_CSR;
                o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                o_uop.alu_arg_2_sel  = ALU_ARG_2_SEL_IMM;
                o_uop.alu_op         = ALU_OP_ARG_2_BYPASS;
                o_uop.csr_req.w_en = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_SET;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            FUNCT3_TYPE_SYSTEM_CSRRCI: begin
                o_uop.regfile_w_en   = '1;
                o_uop.imm_type       = IMM_TYPE_CSR;
                o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                o_uop.alu_arg_2_sel  = ALU_ARG_2_SEL_IMM;
                o_uop.alu_op         = ALU_OP_ARG_2_BYPASS;
                o_uop.csr_req.w_en = '1;
                o_uop.csr_req.w_type = CSR_WRITE_TYPE_CLEAR;
                o_uop.restore_int_en = '0;
                o_uop.wait_for_int   = '0;
            end
            default: begin
                o_uop.regfile_w_en   = 'x;
                o_uop.imm_type       = imm_type_e'( 'x );
                o_uop.alu_arg_1_sel  = alu_arg_1_sel_e'( 'x );
                o_uop.alu_arg_2_sel  = alu_arg_2_sel_e'( 'x );
                o_uop.alu_op         = alu_op_e'( 'x );
                o_uop.csr_req.w_en   = 'x;
                o_uop.csr_req.w_type = csr_write_type_e'( 'x );
                o_uop.restore_int_en = 'x;
                o_uop.wait_for_int   = 'x;
                
                o_illegal = '1;
            end
            endcase
        end
        
        default: begin
            o_uop.regfile_w_en       = 'x;
            o_uop.imm_type           = imm_type_e'( 'x );
            o_uop.alu_arg_1_sel      = alu_arg_1_sel_e'( 'x );
            o_uop.alu_arg_2_sel      = alu_arg_2_sel_e'( 'x );
            o_uop.alu_op             = alu_op_e'( 'x );
            o_uop.data_mem_op        = data_mem_op_e'( 'x );
            o_uop.branch_type        = branch_type_e'( 'x );
            o_uop.branch_pc_sel      = branch_pc_sel_e'( 'x );
            o_uop.regfile_w_data_sel = regfile_w_data_sel_e'( 'x );
            o_uop.csr_req.w_en       = 'x;
            o_uop.csr_req.w_type     = csr_write_type_e'( 'x );
            o_uop.restore_int_en     = 'x;
            o_uop.wait_for_int       = 'x;

            o_illegal = 1;
        end
        endcase
    end
endmodule