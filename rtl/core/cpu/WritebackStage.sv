import CpuPkg::*;


// REFACTOR Flush unused.
module WritebackStage (
    input  logic            i_clk, i_rst, i_flush, i_stall,
    output regfile_w_req_st o_regfile_w_req,
    inst_packet_if.in       if_memory_in
);

    // REFACTOR Rename.
    word_t w_data_mem_r_data_done;

    // TODO Memory exceptions e.g. misalignment, bus error.
    // Memory and peripherals just return the whole word, alignment and sign extension happens here.
    always_comb begin
        case ( if_memory_in.inst_packet.uop.data_mem_op )
        DATA_MEM_OP_LOAD_WORD: begin
            w_data_mem_r_data_done = if_memory_in.inst_packet.data_mem_r_data;
        end
        DATA_MEM_OP_LOAD_HALF: begin
            case ( if_memory_in.inst_packet.alu_result[1] )
            1'b0: begin
                w_data_mem_r_data_done = {{16{if_memory_in.inst_packet.data_mem_r_data[15]}}, if_memory_in.inst_packet.data_mem_r_data[15:0]};
            end
            1'b1: begin
                w_data_mem_r_data_done = {{16{if_memory_in.inst_packet.data_mem_r_data[31]}}, if_memory_in.inst_packet.data_mem_r_data[31:16]};
            end
            endcase
        end
        DATA_MEM_OP_LOAD_BYTE: begin
            case ( if_memory_in.inst_packet.alu_result[1:0] )
            2'b00: begin
                w_data_mem_r_data_done = {{24{if_memory_in.inst_packet.data_mem_r_data[7]}}, if_memory_in.inst_packet.data_mem_r_data[7:0]};
            end
            2'b01: begin
                w_data_mem_r_data_done = {{24{if_memory_in.inst_packet.data_mem_r_data[15]}}, if_memory_in.inst_packet.data_mem_r_data[15:8]};
            end
            2'b10: begin
                w_data_mem_r_data_done = {{24{if_memory_in.inst_packet.data_mem_r_data[23]}}, if_memory_in.inst_packet.data_mem_r_data[23:16]};
            end
            2'b11: begin
                w_data_mem_r_data_done = {{24{if_memory_in.inst_packet.data_mem_r_data[31]}}, if_memory_in.inst_packet.data_mem_r_data[31:24]};
            end
            endcase
        end
        DATA_MEM_OP_LOAD_HALF_UNSIGNED: begin
            case ( if_memory_in.inst_packet.alu_result[1] )
            1'b0: begin
                w_data_mem_r_data_done = {16'b0, if_memory_in.inst_packet.data_mem_r_data[15:0]};
            end
            1'b1: begin
                w_data_mem_r_data_done = {16'b0, if_memory_in.inst_packet.data_mem_r_data[31:16]};
            end
            endcase
        end
        DATA_MEM_OP_LOAD_BYTE_UNSIGNED: begin
            case ( if_memory_in.inst_packet.alu_result[1:0] )
            2'b00: begin
                w_data_mem_r_data_done = {24'b0, if_memory_in.inst_packet.data_mem_r_data[7:0]};
            end
            2'b01: begin
                w_data_mem_r_data_done = {24'b0, if_memory_in.inst_packet.data_mem_r_data[15:8]};
            end
            2'b10: begin
                w_data_mem_r_data_done = {24'b0, if_memory_in.inst_packet.data_mem_r_data[23:16]};
            end
            2'b11: begin
                w_data_mem_r_data_done = {24'b0, if_memory_in.inst_packet.data_mem_r_data[31:24]};
            end
            endcase
        end
        default: begin
            w_data_mem_r_data_done = word_t'( 'x );
        end
        endcase
    end

    word_t w_regfile_w_data;

    always_comb begin
        case ( if_memory_in.inst_packet.uop.regfile_w_data_sel )
        REGFILE_W_DATA_SEL_ALU      : w_regfile_w_data = if_memory_in.inst_packet.alu_result;
        REGFILE_W_DATA_SEL_DATA_MEM : w_regfile_w_data = w_data_mem_r_data_done;
        REGFILE_W_DATA_SEL_CSR      : w_regfile_w_data = if_memory_in.inst_packet.csr_r_data;
        default                     : w_regfile_w_data = word_t'( 'x );
        endcase
    
        o_regfile_w_req = '{
            w_en   : if_memory_in.valid && if_memory_in.inst_packet.uop.regfile_w_en, 
            w_addr : if_memory_in.inst_packet.uop.regfile_w_addr,
            w_data : w_regfile_w_data
        };
    end
    
    always_comb begin
        if_memory_in.ready = !i_stall;
    end
endmodule
