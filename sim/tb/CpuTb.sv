// REFACTOR Reuse timescale across testbenches.
`timescale 1ps / 1ps


module CpuTb();

    logic r_clk, r_rst;
    
    initial begin
        forever begin
            #1 r_clk = !r_clk;
        end
    end
    
    initial begin
        r_clk = 1;
        r_rst = 1;
        
        #4 r_rst = 0;
        
        #10000 $finish();
    end
    
    logic [3:0] w_leds;
    mem_if if_mem_inst(), if_mem_data(); 

    Cpu m_cpu (
        .i_clk       ( r_clk ),
        .i_rst       ( r_rst ),
        .o_leds      ( w_leds ),
        .if_mem_inst ( if_mem_inst ),
        .if_mem_data ( if_mem_data )
    );
endmodule
