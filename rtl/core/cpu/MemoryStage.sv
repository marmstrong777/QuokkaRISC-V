import QuokkaRvPkg::*;
import CpuPkg::*;


module MemoryStage (
    input logic        i_clk, i_rst, i_flush, i_stall,
    input word_t       i_csr_r_data,
    mem_if.master      if_data_mem,
    inst_packet_if.in  if_execute_in,
    inst_packet_if.out if_writeback_out
);
    
    // FIXME Need to stall this stage based on if_data_mem not ready signal from slave.
    always_comb begin
        if_data_mem.valid = if_execute_in.valid && ( if_execute_in.inst_packet.uop.data_mem_op != DATA_MEM_OP_NONE );
        if_data_mem.w_en  = (
            ( if_execute_in.inst_packet.uop.data_mem_op == DATA_MEM_OP_STORE_BYTE ) ||
            ( if_execute_in.inst_packet.uop.data_mem_op == DATA_MEM_OP_STORE_HALF ) ||
            ( if_execute_in.inst_packet.uop.data_mem_op == DATA_MEM_OP_STORE_WORD )
        );

        if_data_mem.addr   = if_execute_in.inst_packet.alu_result;
        if_data_mem.w_data = if_execute_in.inst_packet.regfile_r_resp.r_data_2;
        
        case ( if_execute_in.inst_packet.uop.data_mem_op )
        DATA_MEM_OP_STORE_WORD: begin
            if_data_mem.w_size = MEM_W_SIZE_WORD;
        end
        DATA_MEM_OP_STORE_HALF: begin
            if_data_mem.w_size = MEM_W_SIZE_HALF;
        end
        DATA_MEM_OP_STORE_BYTE: begin
            if_data_mem.w_size = MEM_W_SIZE_BYTE;
        end
        default:
            if_data_mem.w_size = mem_w_size_e'( 'x );
        endcase
    end
    
    logic          r_inst_packet_valid, w_handshake_in, w_handshake_out;
    inst_packet_st r_inst_packet, w_inst_packet_next, w_inst_packet_merge;
    
    always_comb begin
        w_inst_packet_next = if_execute_in.inst_packet;
        
        if_writeback_out.valid              = r_inst_packet_valid;
        w_handshake_out                     = if_writeback_out.ready && if_writeback_out.valid;
        if_execute_in.ready                 = ( !r_inst_packet_valid || w_handshake_out ) && !i_stall;
        w_handshake_in                      = if_execute_in.ready && if_execute_in.valid;
        w_inst_packet_merge                 = r_inst_packet;
        w_inst_packet_merge.data_mem_r_data = if_data_mem.r_data;
        // REFACTOR Just directly write the csr read value into inst_packet in w_inst_packet_next?
        w_inst_packet_merge.csr_r_data      = i_csr_r_data;
        if_writeback_out.inst_packet        = w_inst_packet_merge;
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
