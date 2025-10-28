// REFACTOR Given this module is instantiated outside the core, it might not belong here. Rename to RiscvTimer to distinguish
// this timer mandated by the spec from other general purpose timer peripherals, place in own folder.
module CpuTimer (
    input  logic  i_clk, i_rst,
    output logic  o_int,
    output word_t o_time, o_timeh, 
    mem_if.slave  if_mem
);

    typedef enum logic [1:0] {
        CPU_TIMER_ADDR_MTIME     = 2'h0,
        CPU_TIMER_ADDR_MTIMEH    = 2'h1,
        CPU_TIMER_ADDR_MTIMECMP  = 2'h2,
        CPU_TIMER_ADDR_MTIMECMPH = 2'h3
    } cpu_timer_addr_e;
 
    logic            r_int, w_w_mtime;
    logic [63:0]     r_mtime, r_mtimecmp;
    word_t           r_read;
    cpu_timer_addr_e w_reg_sel;

    always_comb begin
        o_int         = r_int;
        o_time        = r_mtime[31:0];
        o_timeh       = r_mtime[63:32];
        if_mem.ready  = '1;
        if_mem.r_data = r_read;
    end

    always_comb begin
        w_reg_sel = cpu_timer_addr_e'( if_mem.addr[3:2] );
        w_w_mtime = if_mem.valid && if_mem.w_en && ( ( w_reg_sel == CPU_TIMER_ADDR_MTIME ) || ( w_reg_sel == CPU_TIMER_ADDR_MTIMEH ) );
    end

    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin
            r_read     <= '0;
            r_int      <= '0;
            r_mtime    <= '0;
            r_mtimecmp <= '0;

        end else begin
            r_int <= r_mtime >= r_mtimecmp;

            if ( if_mem.valid ) begin
                if ( if_mem.w_en ) begin
                    case ( w_reg_sel )
                    CPU_TIMER_ADDR_MTIME     : r_mtime[31:0]     <= if_mem.w_data;
                    CPU_TIMER_ADDR_MTIMEH    : r_mtime[63:32]    <= if_mem.w_data;
                    CPU_TIMER_ADDR_MTIMECMP  : r_mtimecmp[31:0]  <= if_mem.w_data;
                    CPU_TIMER_ADDR_MTIMECMPH : r_mtimecmp[63:32] <= if_mem.w_data;
                    endcase

                end else begin
                    case ( w_reg_sel )
                    CPU_TIMER_ADDR_MTIME     : r_read <= r_mtime[31:0];
                    CPU_TIMER_ADDR_MTIMEH    : r_read <= r_mtime[63:32];
                    CPU_TIMER_ADDR_MTIMECMP  : r_read <= r_mtimecmp[31:0];
                    CPU_TIMER_ADDR_MTIMECMPH : r_read <= r_mtimecmp[63:32];
                    endcase
                end
            end

            if ( !w_w_mtime ) begin
                r_mtime <= r_mtime + 1;
            end
        end
    end
endmodule