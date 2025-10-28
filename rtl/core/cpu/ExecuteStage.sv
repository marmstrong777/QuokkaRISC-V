import CpuPkg::*;


module ExecuteStage (
    input  logic          i_clk, i_rst, i_flush, i_stall,
    input  word_t         i_mepc,
    inst_packet_if.in     if_decode_in,
    inst_packet_if.out    if_memory_out
);

    // ========== Arithmetic.

    word_t w_alu_arg_1, w_alu_arg_2, w_alu_result;

    always_comb begin
        case ( if_decode_in.inst_packet.uop.alu_arg_1_sel )
        ALU_ARG_1_SEL_REGFILE_R_DATA_1: w_alu_arg_1 = if_decode_in.inst_packet.regfile_r_resp.r_data_1;
        ALU_ARG_1_SEL_PC:               w_alu_arg_1 = if_decode_in.inst_packet.pc;
        default:                        w_alu_arg_1 = word_t'( 'x );
        endcase

        case ( if_decode_in.inst_packet.uop.alu_arg_2_sel )
        ALU_ARG_2_SEL_REGFILE_R_DATA_2: w_alu_arg_2 = if_decode_in.inst_packet.regfile_r_resp.r_data_2;
        ALU_ARG_2_SEL_IMM:              w_alu_arg_2 = if_decode_in.inst_packet.imm;
        ALU_ARG_2_SEL_4:                w_alu_arg_2 = 4;
        default:                        w_alu_arg_2 = word_t'( 'x );
        endcase
    end

    always_comb begin
        case( if_decode_in.inst_packet.uop.alu_op )
        ALU_OP_ADD: begin
            w_alu_result = w_alu_arg_1 + w_alu_arg_2;
        end

        ALU_OP_SLT: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } }, ( $signed( w_alu_arg_1 ) < $signed( w_alu_arg_2 ) ) };
        end

        ALU_OP_SLTU: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } },  ( w_alu_arg_1 < w_alu_arg_2 ) };
        end

        ALU_OP_AND: begin
            w_alu_result = w_alu_arg_1 & w_alu_arg_2;
        end
        
        ALU_OP_OR: begin
            w_alu_result = w_alu_arg_1 | w_alu_arg_2;
        end
        ALU_OP_XOR: begin
            w_alu_result = w_alu_arg_1 ^ w_alu_arg_2;
        end

        ALU_OP_SLL: begin
            w_alu_result = w_alu_arg_1 << w_alu_arg_2[4:0];
        end

        ALU_OP_SRL: begin
            w_alu_result = w_alu_arg_1 >> w_alu_arg_2[4:0];
        end

        ALU_OP_SUB: begin
            w_alu_result = w_alu_arg_1 - w_alu_arg_2;
        end

        ALU_OP_SRA: begin
            w_alu_result = $signed( w_alu_arg_1 ) >>> w_alu_arg_2[4:0];
        end

        ALU_OP_SEQ: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } },  ( w_alu_arg_1 == w_alu_arg_2 ) };
        end

        ALU_OP_SNEQ: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } },  ( w_alu_arg_1 != w_alu_arg_2 ) };
        end

        ALU_OP_SGE: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } },  ( $signed( w_alu_arg_1 ) >= $signed( w_alu_arg_2 ) ) };
        end

        ALU_OP_SGEU: begin
            w_alu_result = { { ( $size( w_alu_result ) - 1 ) { 1'b0 } },  ( w_alu_arg_1 >= w_alu_arg_2 ) };
        end

        ALU_OP_ARG_1_BYPASS: begin
            w_alu_result = w_alu_arg_1;
        end
        
        ALU_OP_ARG_2_BYPASS: begin
            w_alu_result = w_alu_arg_2;
        end
        
        default: begin
            w_alu_result = word_t'( 'x );
        end
        endcase
    end
    
    // ========== Branch.
    
    pc_redirect_st w_pc_redirect;
    
    always_comb begin
        if ( !if_decode_in.valid ) begin
            w_pc_redirect.valid     = '0;
            w_pc_redirect.target_pc = word_t'( 'x );
            w_pc_redirect.cause     = pc_redirect_cause_e'( 'x );
            
        end else begin
            case ( if_decode_in.inst_packet.uop.branch_pc_sel )
            BRANCH_PC_SEL_PC_PLUS_IMM: begin
                w_pc_redirect.target_pc = if_decode_in.inst_packet.pc + if_decode_in.inst_packet.imm;
                w_pc_redirect[0]        = 1'b0;
            end
            
            BRANCH_PC_SEL_REGFILE_R_DATA_1_PLUS_IMM: begin
                w_pc_redirect.target_pc = if_decode_in.inst_packet.regfile_r_resp.r_data_1 + if_decode_in.inst_packet.imm;
                w_pc_redirect[0]        = 1'b0;
            end

            BRANCH_PC_SEL_PC: begin
                w_pc_redirect.target_pc = if_decode_in.inst_packet.pc;
            end

            BRANCH_PC_SEL_MEPC: begin
                w_pc_redirect.target_pc = i_mepc;
            end

            BRANCH_PC_SEL_PC_PLUS_4: begin
                w_pc_redirect.target_pc = if_decode_in.inst_packet.pc + 4;
            end

            default: begin
                w_pc_redirect.target_pc = word_t'( 'x );
            end
            endcase
            
            if ( if_decode_in.valid ) begin
                case ( if_decode_in.inst_packet.uop.branch_type )
                BRANCH_TYPE_NONE: begin
                    w_pc_redirect.valid = 1'b0;
                    w_pc_redirect.cause = pc_redirect_cause_e'( 'x );
                end

                BRANCH_TYPE_UNCONDITIONAL: begin
                    w_pc_redirect.valid = 1'b1;
                    w_pc_redirect.cause = PC_REDIRECT_CAUSE_UNCOND_BRANCH;
                end

                BRANCH_TYPE_CONDITIONAL: begin
                    w_pc_redirect.valid = w_alu_result[0];
                    w_pc_redirect.cause = PC_REDIRECT_CAUSE_COND_BRANCH; 
                end

                default: begin
                    w_pc_redirect.valid = 1'b0;
                    w_pc_redirect.cause = pc_redirect_cause_e'( 'x );
                end
                endcase
            
            end else begin
                w_pc_redirect.valid = '0;
                w_pc_redirect.cause = pc_redirect_cause_e'( 'x );
            end
        end
    end
    
    // ==========
    
    logic          r_inst_packet_valid, w_handshake_in, w_handshake_out;
    inst_packet_st r_inst_packet, w_inst_packet_next;
    
    always_comb begin
        w_inst_packet_next             = if_decode_in.inst_packet;
        w_inst_packet_next.alu_result  = w_alu_result;
        w_inst_packet_next.pc_redirect = w_pc_redirect;
        
        if_memory_out.valid       = r_inst_packet_valid;
        w_handshake_out           = if_memory_out.ready && if_memory_out.valid;
        if_decode_in.ready        = ( !r_inst_packet_valid || w_handshake_out ) && !i_stall;
        w_handshake_in            = if_decode_in.ready && if_decode_in.valid;
        if_memory_out.inst_packet = r_inst_packet;
    end
        
    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin
            r_inst_packet_valid <= '0;
            r_inst_packet       <= inst_packet_st'( 'x );
            
        end else if ( i_flush ) begin
            r_inst_packet_valid <= '0;
            r_inst_packet       <= inst_packet_st'( 'x );

        end else begin        
            if ( w_handshake_in ) begin
                r_inst_packet_valid <= '1;
                r_inst_packet       <= w_inst_packet_next;
                
            end else if ( w_handshake_out ) begin
                r_inst_packet_valid <= '0;
                r_inst_packet       <= inst_packet_st'( 'x );
            end
        end
    end
endmodule
