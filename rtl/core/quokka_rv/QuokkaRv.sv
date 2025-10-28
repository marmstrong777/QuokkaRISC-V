import QuokkaRvPkg::*;
import DviPkg::*;


interface mem_if #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 32) ();
    logic                    valid; // Master requests memory access.
    logic                    w_en;
    logic                    ready; // Handshake with slave will occur on next clock cycle.
    logic [ADDR_WIDTH - 1:0] addr;
    logic [DATA_WIDTH - 1:0] r_data, w_data;
    mem_w_size_e             w_size;

    modport master (
        input  ready, r_data,
        output valid, w_en, addr, w_data, w_size
    );
    modport slave (
        input valid, w_en, addr, w_data, w_size,
        output ready, r_data
    );
endinterface


module QuokkaRv (
    input  logic       i_clk_core, i_clk_dvi, i_clk_dvi_mul5, i_rst_core, i_rst_dvi,
    output logic [3:0] o_leds,
    output dvi_st      o_dvi
); 
    // Cpu memory interface.
    mem_if if_mem_inst(), if_mem_data();

    // REFACTOR if_mem_memory is a confusing name.
    // Peripheral memory interfaces.
    mem_if if_mem_memory(), if_mem_char_display(), if_mem_cpu_timer(), if_mem_int_ctl();

    logic [31:0] r_prev_addr;

    always_comb begin
        if_mem_char_display.valid  = '0;
        if_mem_char_display.w_en   = if_mem_data.w_en;
        if_mem_char_display.addr   = {4'b0, if_mem_data.addr[27:0]};
        if_mem_char_display.w_data = if_mem_data.w_data;
        if_mem_char_display.w_size = if_mem_data.w_size;

        if_mem_memory.valid  = '0;
        if_mem_memory.w_en   = if_mem_data.w_en;
        if_mem_memory.addr   = {4'b0, if_mem_data.addr[27:0]};
        if_mem_memory.w_data = if_mem_data.w_data;
        if_mem_memory.w_size = if_mem_data.w_size;

        if_mem_cpu_timer.valid  = '0;
        if_mem_cpu_timer.w_en   = if_mem_data.w_en;
        if_mem_cpu_timer.addr   = {4'b0, if_mem_data.addr[27:0]};
        if_mem_cpu_timer.w_data = if_mem_data.w_data;
        if_mem_cpu_timer.w_size = if_mem_data.w_size;

        if_mem_int_ctl.valid  = '0;
        if_mem_int_ctl.w_en   = if_mem_data.w_en;
        if_mem_int_ctl.addr   = {4'b0, if_mem_data.addr[27:0]};
        if_mem_int_ctl.w_data = if_mem_data.w_data;
        if_mem_int_ctl.w_size = if_mem_data.w_size;

        // TODO Consider flaws in keeping ready as default 1 here.
        if_mem_data.ready = '1;
        if_mem_data.r_data = 'x;

        // REFACTOR Duplication of this address decoding is bad, also use an enum.
        case ( if_mem_data.addr[31:28] )
        // Data memory: 0x10000000 -> 0x1FFFFFFF
        4'b0001: begin
            if_mem_memory.valid = if_mem_data.valid;

            if_mem_data.ready  = if_mem_memory.ready;
        end
        // Character display: 0x80000000 -> 0x8FFFFFFF
        4'b1000: begin
            if_mem_char_display.valid  = if_mem_data.valid;

            if_mem_data.ready  = if_mem_char_display.ready;
        end
        // Cpu timer: 0x90000000 -> 0x9FFFFFFF
        4'b1001: begin
            if_mem_cpu_timer.valid = if_mem_data.valid;

            if_mem_data.ready = if_mem_cpu_timer.ready;
        end
        // Interrupt controller: 0xA0000000 -> 0xAFFFFFFF
        4'b1010: begin
            if_mem_int_ctl.valid = if_mem_data.valid;

            if_mem_data.ready = if_mem_int_ctl.ready;
        end
        default: begin
        end
        endcase

        // Read data is returned on the next clock cycle
        case ( r_prev_addr[31:28] )
        // Data memory: 0x10000000 -> 0x1FFFFFFF
        4'b0001: begin
            if_mem_data.r_data = if_mem_memory.r_data; 
        end
        // Character display: 0x80000000 -> 0x8FFFFFFF
        4'b1000: begin
            if_mem_data.r_data = if_mem_char_display.r_data; 
        end
        // Cpu timer: 0x90000000 -> 0x9FFFFFFF
        4'b1001: begin
            if_mem_data.r_data = if_mem_cpu_timer.r_data;
        end
        // Interrupt controller: 0xA0000000 -> 0xAFFFFFFF
        4'b1010: begin
            if_mem_data.r_data = if_mem_int_ctl.r_data;
        end
        default: begin
        end
        endcase
    end

    always_ff @( posedge i_clk_core ) begin
        r_prev_addr <= if_mem_data.addr;
    end

    logic w_int_cpu_timer, w_int_int_ctl;

    Cpu m_cpu (
        .i_clk       ( i_clk_core ),
        .i_rst       ( i_rst_core ),
        .i_int_timer ( w_int_cpu_timer ),
        .i_int_ext   ( w_int_int_ctl ),
        .o_leds      ( o_leds ),
        .if_mem_inst ( if_mem_inst ),
        .if_mem_data ( if_mem_data )
    );
    
    Memory m_memory (
        .i_clk  ( i_clk_core ),
        .i_rst  ( i_rst_core ),
        .if_mem ( if_mem_memory )
    );

    CharacterDisplay m_char_display (
        .i_clk_bus      ( i_clk_core ),
        .i_clk_dvi      ( i_clk_dvi ),
        .i_clk_dvi_mul5 ( i_clk_dvi_mul5 ),
        .i_rst_bus      ( i_rst_core ),
        .i_rst_dvi      ( i_rst_dvi ),
        .o_dvi          ( o_dvi ),
        .if_mem         ( if_mem_char_display )
    );

    // FIXME Need to implement as CSR mtime, mtimeh;
    word_t w_cpu_timer_time, w_cpu_timer_timeh;

    CpuTimer m_cpu_timer (
        .i_clk   ( i_clk_core ),
        .i_rst   ( i_rst_core ),
        .o_int   ( w_int_cpu_timer ),
        .o_time  ( w_cpu_timer_time ),
        .o_timeh ( w_cpu_timer_timeh),
        .if_mem  ( if_mem_cpu_timer )
    );

    // FIXME Placeholder external interrupt source.
    logic [23:0] r_int_ctl_test = '0;
    always_ff @( posedge i_clk_core ) begin
        r_int_ctl_test <= r_int_ctl_test + 1;
    end
    logic w_int_ctl_test_int;
    always_comb begin
        //w_int_ctl_test_int = r_int_ctl_test > 200;
        w_int_ctl_test_int = '0;
    end

    InterruptController #(
        .NUM_INT_SRCS( 1 )
    ) m_int_ctl (
        .i_clk  ( i_clk_core ),
        .i_int  ( w_int_ctl_test_int ),
        .o_int  ( w_int_int_ctl ),
        .if_mem ( if_mem_int_ctl )
    );
endmodule
