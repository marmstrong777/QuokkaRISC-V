import CpuPkg::*;
import RiscvPkg::*;

interface inst_packet_if ();
    logic          ready, valid;
    inst_packet_st inst_packet;
    
    modport in (
        input  valid, inst_packet,
        output ready
    );
    
    modport out (
        input  ready,
        output valid, inst_packet
    );
endinterface

// ========== CSR defintions.

typedef struct packed {
    logic [23:0] unused_2;
    logic        mpie;
    logic [2:0]  unused_1;
    logic        mie;
    logic [2:0]  unused_0;
} mstatus_st;

typedef struct packed {
    logic        interrupt;
    logic [30:0] code;
} mcause_st;

typedef struct packed {
    logic [29:0] base;
    logic [1:0]  mode;
} mtvec_st;

typedef struct packed {
    logic [19:0] unused_3;
    logic        meie;
    logic [2:0]  unused_2;
    logic        mtie;
    logic [2:0]  unused_1;
    logic        msie;
    logic [2:0]  unused_0;
} mie_st;

typedef struct packed {
    logic [19:0] unused_3;
    logic        meip;
    logic [2:0]  unused_2;
    logic        mtip;
    logic [2:0]  unused_1;
    logic        msip;
    logic [2:0]  unused_0;
} mip_st;

// ==========

// TODO Implement Zicntr. Note that instructions that result in exceptions (even ebreak, ecall) do not retire/increment instret.
// REFACTOR Interfaces in module instantiation ports should have the modport suffix.
// TODO Remove leds.
module Cpu (
    input  logic        i_clk, i_rst, i_int_timer, i_int_ext,
    output logic  [3:0] o_leds,
    mem_if.master       if_mem_inst,
    mem_if.master       if_mem_data
);
    inst_packet_if if_fetch_decode(), if_decode_execute(), if_execute_memory(), if_memory_writeback();

    mstatus_st r_mstatus;
    mie_st     r_mie;
    mtvec_st   r_mtvec;
    mcause_st  r_mcause;
    mip_st     r_mip;
    word_t     r_mscratch, r_mepc, r_mtval;

    logic w_external_int, w_software_int, w_timer_int;

    word_t w_csr_w_data, w_csr_r_data, r_csr_r_data;

    // TODO A read enable signal may be required, some CSR reads may have side effects?
    always_comb begin
        unique case( if_execute_memory.inst_packet.uop.csr_req.addr )
        CSR_ADDR_MSTATUS  : w_csr_r_data = word_t'( r_mstatus );
        CSR_ADDR_MIE      : w_csr_r_data = word_t'( r_mie );
        CSR_ADDR_MTVEC    : w_csr_r_data = word_t'( r_mtvec );
        CSR_ADDR_MSCRATCH : w_csr_r_data = word_t'( r_mscratch );
        CSR_ADDR_MEPC     : w_csr_r_data = word_t'( r_mepc );
        CSR_ADDR_MCAUSE   : w_csr_r_data = word_t'( r_mcause );
        CSR_ADDR_MTVAL    : w_csr_r_data = word_t'( r_mtval );
        CSR_ADDR_MIP      : w_csr_r_data = word_t'( r_mip );
        // FIXME Invalid address, raise exception.
        default           : w_csr_r_data = word_t'( 'x );
        endcase

        unique case( if_execute_memory.inst_packet.uop.csr_req.w_type )
        CSR_WRITE_TYPE_COPY  : w_csr_w_data = if_execute_memory.inst_packet.alu_result;
        CSR_WRITE_TYPE_SET   : w_csr_w_data = w_csr_r_data | if_execute_memory.inst_packet.alu_result;
        CSR_WRITE_TYPE_CLEAR : w_csr_w_data = w_csr_r_data & ( ~if_execute_memory.inst_packet.alu_result );
        default              : w_csr_w_data = word_t'( 'x );
        endcase
    end

    always_ff @( posedge i_clk ) begin
        r_csr_r_data <= w_csr_r_data;
    end

    // TODO Consider the following edge cases for interrupts:
    // - mie asserted, m*ip asserted, while waiting for pipeline to empty one of aforementioned instructions clears
    //   the mie bit

    logic w_is_pipeline_empty, w_any_int, w_any_trap;

    always_comb begin
        w_is_pipeline_empty = !if_fetch_decode.valid && !if_decode_execute.valid && !if_execute_memory.valid && !if_memory_writeback.valid;
    end

    word_t         w_pc, w_trap_pc;
    pc_redirect_st w_pc_redirect_final;
    mcause_st      w_trap_cause;
    pc_redirect_st r_trap_redirect;

    // For a brief window of time after a pending interrupt bit in the mip CSR is asserted, it is possible that an in
    // flight instruction preceding the trap handler and reading the mip CSR will observe that the pending interrupt
    // bit is asserted. It is inferred from the spec that software is permitted to observe the pending interrupt bit
    // asserted before the corresponding trap begins execution. Trap handler dispatch is not immediate.
    always_comb begin
        w_external_int = r_mstatus.mie && r_mie.meie && r_mip.meip;
        w_software_int = r_mstatus.mie && r_mie.msie && r_mip.msip;
        w_timer_int    = r_mstatus.mie && r_mie.mtie && r_mip.mtip;
        w_any_int      = w_external_int || w_software_int || w_timer_int;
        w_any_trap     = w_any_int;

        // TODO Exceptions would go before external int here in the branch chain.
        if ( w_external_int ) begin
            w_trap_cause = '{
                interrupt: '1,
                code:       INTERRUPT_CODE_EXTERNAL_M
            };

        end else if ( w_software_int ) begin
            w_trap_cause = '{
                interrupt: '1,
                code:       INTERRUPT_CODE_SOFTWARE_M
            };

        end else if ( w_timer_int ) begin
            w_trap_cause = '{
                interrupt: '1,
                code:       INTERRUPT_CODE_TIMER_M
            };

        end else begin
            w_trap_cause = mcause_st'( 'x );
        end

        unique case ( r_mtvec.mode )
        CSR_MTVEC_MODE_DIRECT: begin
            w_trap_pc = {r_mtvec.base, 2'b0};
        end
        CSR_MTVEC_MODE_VECTORED: begin
            w_trap_pc = {r_mtvec.base, 2'b0} + (w_trap_cause.interrupt ? (w_trap_cause.code * 4) : '0);
        end
        default: begin
            w_trap_pc = word_t'( 'x );
        end
        endcase

        // No in flight instruction will be present in the pipeline to set a branch pc redirect at the same time as
        // the trap pc redirect.
        // TODO Assertion is broken and triggers on t=0.
        //assert( !( w_branch_pc_redirect.valid && r_trap_redirect.valid ) ) else $error( "Simultaneous branch and trap pc redirect valid" );
        
        if( if_execute_memory.valid && if_execute_memory.inst_packet.pc_redirect.valid ) begin
            w_pc_redirect_final = '{
                valid     : '1,
                target_pc : if_execute_memory.inst_packet.pc_redirect.target_pc,
                cause     : if_execute_memory.inst_packet.pc_redirect.cause
            };

        end else if ( r_trap_redirect.valid ) begin
            w_pc_redirect_final = '{
                valid     : '1,
                target_pc : r_trap_redirect.target_pc,
                cause     : r_trap_redirect.cause
            };
        
        end else begin
            w_pc_redirect_final = '{
                valid     : '0,
                target_pc : word_t'( 'x ),
                cause     : pc_redirect_cause_e'( 'x )
            };
        end
    end


    // REFACTOR Potential complexities and infrequency of writing to a CSR may mean the best solution is just flushing
    // the pipeline.
    always_ff @( posedge i_clk ) begin
        if( i_rst ) begin
            r_mstatus  <= '0;
            r_mie      <= '0;
            r_mtvec    <= { 30'b0, CSR_MTVEC_MODE_DIRECT };
            r_mscratch <= '0;
            r_mepc     <= '0;
            r_mcause   <= '0;
            r_mtval    <= '0;
            r_mip      <= '0;

            r_trap_redirect <= '{
                valid     : '0,
                target_pc : word_t'( 'x ),
                cause     : pc_redirect_cause_e'( 'x )
            };

        end else begin
            r_mip.mtip <= i_int_timer;
            r_mip.meip <= i_int_ext;

            // Before the trap handler is dispatched, we wait for the pipeline to clear because an in flight
            // instruction may raise an exception. In addition, we want to wait for any flight branches to resolve as
            // we don't want to store a mispredicted pc in mepc. By clearing mstatus.mie w_any_trap is deasserted thus
            // allowing the fetch stage to dispatch instructions from the new pc.
            // REFACTOR Merge this condition into a signal (w_trap_dispatch).
            if ( w_any_trap && w_is_pipeline_empty ) begin
                r_trap_redirect <= '{
                    valid     : '1,
                    target_pc : w_trap_pc,
                    cause     : PC_REDIRECT_CAUSE_TRAP
                };
                // TODO Any hazard problems with writing to mstatus.mie using a CSR write instruction right before a trap dispatch?
                r_mstatus.mpie <= r_mstatus.mie;
                r_mstatus.mie  <= '0;

                // TODO This is the fetch stage pc, in the case of exceptions it needs to be that of the faulting instruction.
                r_mepc         <= w_pc;

                r_mcause       <= w_trap_cause;
                r_mtval        <= '0;
            
            end else begin
                r_trap_redirect <= '{
                    valid     : '0,
                    target_pc : word_t'( 'x ),
                    cause     : pc_redirect_cause_e'( 'x )
                };

                assert( !( if_execute_memory.valid && if_execute_memory.inst_packet.uop.csr_req.w_en && if_execute_memory.inst_packet.uop.restore_int_en ) ) else $error( "Simultaneous write to CSR and interrupt enable restore" );

                if( if_execute_memory.valid && if_execute_memory.inst_packet.uop.csr_req.w_en ) begin
                    `ifndef SYNTHESIS
                        assert( !$isunknown( w_csr_w_data ) ) else $error( "Undefined CSR write data" );
                    `endif
                    // REFACTOR Convert all applicable case statements to unique case?
                    // FIXME Not performing checks for CSR read/write legality.
                    unique case ( if_execute_memory.inst_packet.uop.csr_req.addr )
                    CSR_ADDR_MSTATUS  : r_mstatus  <= w_csr_w_data;
                    CSR_ADDR_MIE      : r_mie      <= w_csr_w_data;
                    CSR_ADDR_MTVEC    : r_mtvec    <= w_csr_w_data;
                    CSR_ADDR_MSCRATCH : r_mscratch <= w_csr_w_data;
                    CSR_ADDR_MEPC     : r_mepc     <= w_csr_w_data;
                    CSR_ADDR_MCAUSE   : r_mcause   <= w_csr_w_data;
                    CSR_ADDR_MTVAL    : r_mtval    <= w_csr_w_data;
                    //CSR_ADDR_MIP      : r_mip      <= w_csr_w_data;
                    default: begin
                        // FIXME Invalid address, raise exception.
                    end
                    endcase
                
                end else if ( if_execute_memory.valid && if_execute_memory.inst_packet.uop.restore_int_en ) begin
                    r_mstatus.mie  <= r_mstatus.mpie;
                    r_mstatus.mpie <= '1;
                end
            end
        end
    end
    
    regfile_r_req_st  w_regfile_r_req;
    regfile_r_resp_st w_regfile_r_resp;
    regfile_w_req_st  w_regfile_w_req;
    
    logic w_fetch_flush, w_decode_flush, w_execute_flush, w_memory_flush, w_writeback_flush;
    
    always_comb begin
        // FIXME We have undefined flush signals is this a problem?
        // If any trap is pending dispatch, the fetch stage alone is flushed continuously to allow for the pipeline
        // to empty. 
        w_fetch_flush   = w_pc_redirect_final.valid || w_any_trap;
        w_decode_flush  = if_execute_memory.valid && if_execute_memory.inst_packet.pc_redirect.valid;

        w_execute_flush = '0;

        // REFACTOR It might be safe to have the writeback stage valid when dispatching a trap.
    end

    RegisterFile m_regfile (
        .i_clk    ( i_clk ),
        .i_rst    ( i_rst ),
        .i_flush  ( '0 ),
        .i_r_req  ( w_regfile_r_req ),
        .i_w_req  ( w_regfile_w_req ),
        .o_r_resp ( w_regfile_r_resp )
    );
   
    logic w_first_tick;

    // REFACTOR remove pc register from stage, put it in core with regfile?
    FetchStage m_fetch (
        .i_clk          ( i_clk ),
        .i_rst          ( i_rst ),
        .i_flush        ( w_fetch_flush ),
        .i_pc_redirect  ( w_pc_redirect_final ),
        .o_pc           ( w_pc ),
        .o_first_tick   ( w_first_tick ),
        .if_inst_mem    ( if_mem_inst ),
        .if_decode_out  ( if_fetch_decode )
    );
    
    logic w_decode_stall, w_execute_stall, w_memory_stall, w_writeback_stall, w_hazard_regfile_raw_1, w_hazard_regfile_raw_2, w_hazard_mepc_raw, w_hazard_mstatus_raw, w_wait_for_int;
    
    // FIXME Check if hazard logic required for CSRs.
    always_comb begin
        // TODO Data forwarding.
        // TODO There are many cases where instructions aren't actually using the value read from the regfile, yet the hazard signal
        // will still be set active (maybe create comb logic flag based on uop values to determine if regfile read 1/2 is used).
        w_hazard_regfile_raw_1 = (
            if_fetch_decode.valid && ( w_regfile_r_req.r_addr_1 != '0 ) && (
                ( if_decode_execute.valid   && if_decode_execute.inst_packet.uop.regfile_w_en   && ( w_regfile_r_req.r_addr_1 == if_decode_execute.inst_packet.uop.regfile_w_addr   ) ) ||
                ( if_execute_memory.valid   && if_execute_memory.inst_packet.uop.regfile_w_en   && ( w_regfile_r_req.r_addr_1 == if_execute_memory.inst_packet.uop.regfile_w_addr   ) ) ||
                ( if_memory_writeback.valid && if_memory_writeback.inst_packet.uop.regfile_w_en && ( w_regfile_r_req.r_addr_1 == if_memory_writeback.inst_packet.uop.regfile_w_addr ) )
            )
        );
        w_hazard_regfile_raw_2 = (
            if_fetch_decode.valid && ( w_regfile_r_req.r_addr_2 != '0 ) && (
                ( if_decode_execute.valid   && if_decode_execute.inst_packet.uop.regfile_w_en   && ( w_regfile_r_req.r_addr_2 == if_decode_execute.inst_packet.uop.regfile_w_addr   ) ) ||
                ( if_execute_memory.valid   && if_execute_memory.inst_packet.uop.regfile_w_en   && ( w_regfile_r_req.r_addr_2 == if_execute_memory.inst_packet.uop.regfile_w_addr   ) ) ||
                ( if_memory_writeback.valid && if_memory_writeback.inst_packet.uop.regfile_w_en && ( w_regfile_r_req.r_addr_2 == if_memory_writeback.inst_packet.uop.regfile_w_addr ) )
            )
        );

        w_decode_stall = w_hazard_regfile_raw_1 || w_hazard_regfile_raw_2;

        // FIXME Should this be the branch pc redirect valid or the final pc redirect valid?
        // FIXME Problem with the pc redirect not being defined upon reset.
        w_execute_stall = if_execute_memory.valid && if_execute_memory.inst_packet.pc_redirect.valid;

        // if execute->memory reg contains csr write AND decode->execute reg contains mepc read
        // FIXME Need to think about other cases where mepc might be written to.
        // In the case where we have an instruction writing to mepc and immediately following that an mret,
        // we meed to stall the execute stage so that mret sees the updated mepc. This is because 
        w_hazard_mepc_raw = (
            if_decode_execute.valid && if_execute_memory.valid && if_execute_memory.inst_packet.uop.csr_req.w_en &&
            ( if_execute_memory.inst_packet.uop.csr_req.addr == CSR_ADDR_MEPC ) &&
            ( if_decode_execute.inst_packet.uop.branch_pc_sel == BRANCH_PC_SEL_PC )
        );

        w_hazard_mstatus_raw = (
            if_decode_execute.valid && if_execute_memory.valid && if_execute_memory.inst_packet.uop.csr_req.w_en &&
            ( if_execute_memory.inst_packet.uop.csr_req.addr == CSR_ADDR_MSTATUS ) &&
            if_decode_execute.inst_packet.uop.wait_for_int
        );

        w_wait_for_int = if_execute_memory.valid && if_execute_memory.inst_packet.uop.wait_for_int && r_mstatus.mie && !w_any_trap;

        w_memory_stall    = w_hazard_mepc_raw || w_hazard_mstatus_raw || w_wait_for_int;
        w_writeback_stall = '0;
    end
    
    // TODO Temporary remove.
    logic [3:0] r_leds;
    
    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin
            r_leds <= 4'b0;
 
        end else begin
            if ( if_execute_memory.valid && ( if_execute_memory.inst_packet.uop.data_mem_op == DATA_MEM_OP_STORE_WORD ) ) begin
                r_leds <= if_execute_memory.inst_packet.regfile_r_resp.r_data_2[3:0];
            end
        end
    end
    
    always_comb begin
        o_leds = r_leds;
    end
    
    DecodeStage m_decode (
        .i_clk            ( i_clk ),
        .i_rst            ( i_rst ),
        .i_flush          ( w_decode_flush ),
        .i_stall          ( w_decode_stall ),
        .i_regfile_r_resp ( w_regfile_r_resp ),
        .o_regfile_r_req  ( w_regfile_r_req ),
        .if_fetch_in      ( if_fetch_decode ),
        .if_execute_out   ( if_decode_execute )
    );
    
    ExecuteStage m_execute (
        .i_clk         ( i_clk ),
        .i_rst         ( i_rst ),
        .i_flush       ( w_execute_flush ),
        .i_stall       ( w_execute_stall ),
        .i_mepc        ( r_mepc ),
        .if_decode_in  ( if_decode_execute ),
        .if_memory_out ( if_execute_memory )
    );
   
    MemoryStage m_memory (
        .i_clk            ( i_clk ),
        .i_rst            ( i_rst ),
        .i_flush          ( '0 ),
        .i_stall          ( w_memory_stall ),
        .i_csr_r_data     ( r_csr_r_data ),
        .if_data_mem      ( if_mem_data ),
        .if_execute_in    ( if_execute_memory ),
        .if_writeback_out ( if_memory_writeback )
    );
    
    WritebackStage m_writeback (
        .i_clk           ( i_clk ),
        .i_rst           ( i_rst ),
        .i_flush         ( '0 ),
        .i_stall         ( w_writeback_stall ),
        .o_regfile_w_req ( w_regfile_w_req ),
        .if_memory_in    ( if_memory_writeback )
    );
endmodule
