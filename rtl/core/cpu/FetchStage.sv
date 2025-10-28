import CpuPkg::*;


// REFACTOR Put PC in parent module like CSRs?
module FetchStage (
    input  logic          i_clk, i_rst, i_flush,
    input  pc_redirect_st i_pc_redirect,
    // This represents the address of the next instruction to be dispatched.
    output word_t         o_pc,

    output logic          o_first_tick,
    mem_if.master         if_inst_mem,
    inst_packet_if.out    if_decode_out
);
    // r_first_tick is used because it takes an extra clock cycle to fetch the first instruction after reset, due
    // to the pc being invalid.
    logic  r_valid, r_first_tick, w_handshake_out;
    word_t r_pc, r_inst_pc, w_pc_plus_4; //, w_pc_next;
    inst_t r_inst, w_inst_next;

    // TODO Implement real memory access through mem_if.
    localparam MEM_SIZE_WORDS = 2048;

    logic[7:0] sim_mem[(MEM_SIZE_WORDS * 4) - 1:0];

    
    initial begin
        $readmemh("inst_mem.mem", sim_mem);
    end
    
    always_comb begin
        w_pc_plus_4 = r_pc + 4;
        
        w_inst_next = { 
            sim_mem[r_pc[$clog2($size(sim_mem)):0] + 3],
            sim_mem[r_pc[$clog2($size(sim_mem)):0] + 2],
            sim_mem[r_pc[$clog2($size(sim_mem)):0] + 1],
            sim_mem[r_pc[$clog2($size(sim_mem)):0] + 0]
        };

        o_pc = r_pc;
        o_first_tick = r_first_tick;
    end
    
    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin
            r_first_tick <= '1;
            r_pc         <= PC_RESET;
            r_inst_pc    <= word_t'( 'x );
            r_inst       <= inst_t'( 'x );
            r_valid      <= '0;
                        
        end else if ( i_flush ) begin
            r_first_tick <= '1;

            // Upon a trap pending, we wait for the pipeline to empty of all in flight instructions before writing
            // mtvec to the pc. The flush signal is asserted to prevent the fetch stage from dispatching new
            // instructions. The pc is still able to be written to while flush is asserted because
            // if branch instructions in flight can't set the pc, the value written to mepc may be invalid due to
            // being in a branch mispredict.
            if ( i_pc_redirect.valid ) begin
                r_pc <= i_pc_redirect.target_pc;
            end

            r_inst_pc <= word_t'( 'x );
            r_inst    <= inst_t'( 'x );
            r_valid   <= '0;
                                    
        end else begin
            r_first_tick <= 0;
            if ( w_handshake_out || r_first_tick ) begin
                r_pc         <= i_pc_redirect.valid ? i_pc_redirect.target_pc : w_pc_plus_4;
                r_inst_pc    <= r_pc;
                r_inst       <= w_inst_next;
                r_valid      <= '1;
            end
        end
    end

    always_comb begin
        if_decode_out.inst_packet      = inst_packet_st'( 'x );
        if_decode_out.inst_packet.pc   = r_inst_pc;
        if_decode_out.inst_packet.inst = r_inst;
        if_decode_out.valid            = r_valid;
        w_handshake_out                = if_decode_out.ready && if_decode_out.valid;
    end
endmodule
