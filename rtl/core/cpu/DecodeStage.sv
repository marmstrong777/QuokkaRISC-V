import CpuPkg::*;


module DecodeStage (
    input  logic             i_clk, i_rst, i_flush, i_stall,
    input  regfile_r_resp_st i_regfile_r_resp,
    output regfile_r_req_st  o_regfile_r_req,
    inst_packet_if.in        if_fetch_in,
    inst_packet_if.out       if_execute_out
);

    // ========== Instruction decoder.

    logic  w_illegal;
    uop_st w_uop;

    InstructionDecoder m_inst_decoder (
        .i_inst    ( if_fetch_in.inst_packet.inst ),
        .o_illegal ( w_illegal ),
        .o_uop     ( w_uop )
    );

    // ========== Immediate generator.

    word_t w_imm;

    ImmediateGenerator m_imm_gen (
        .i_imm_type ( w_uop.imm_type ),
        .i_inst     ( if_fetch_in.inst_packet.inst ),
        .o_result   ( w_imm )
    );

    // ==========
    
    always_comb begin
        o_regfile_r_req = w_uop.regfile_r_req;
    end
    
    logic r_inst_packet_valid, w_handshake_in, w_handshake_out;
    inst_packet_st r_inst_packet, w_inst_packet_next, w_inst_packet_merge;
    
    always_comb begin
        w_inst_packet_next     = if_fetch_in.inst_packet;
        w_inst_packet_next.uop = w_uop;
        w_inst_packet_next.imm = w_imm;
  
        if_execute_out.valid               = r_inst_packet_valid;
        w_handshake_out                    = if_execute_out.ready && if_execute_out.valid;
        if_fetch_in.ready                  = ( !r_inst_packet_valid || w_handshake_out ) && !i_stall;
        w_handshake_in                     = if_fetch_in.ready && if_fetch_in.valid;
        w_inst_packet_merge                = r_inst_packet;
        w_inst_packet_merge.regfile_r_resp = i_regfile_r_resp;
        if_execute_out.inst_packet         = w_inst_packet_merge;
    end

    always_ff @( posedge i_clk ) begin
        if ( i_rst || i_flush ) begin
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
