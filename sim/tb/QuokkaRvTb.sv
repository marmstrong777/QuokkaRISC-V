// REFACTOR Reuse timescale across testbenches.
`timescale 1ps / 1ps


import DviPkg::*;


module QuokkaRvTb();

    logic r_clk, r_rst;
    
    initial begin
        forever begin
            #1 r_clk = !r_clk;
        end
    end
    
    initial begin
        r_clk = 1;
        r_rst = 1;
        
        #16 r_rst = 0;
        
        #10000 $finish();
    end
    
    logic [3:0] w_leds;
    dvi_st      w_dvi;

    QuokkaRv m_quokka (
        .i_clk_core     ( r_clk ),
        .i_clk_dvi      ( 1'b0 ),
        .i_clk_dvi_mul5 ( 1'b0 ),
        .i_rst_core     ( r_rst ),
        .i_rst_dvi      ( 1'b0 ),
        .o_leds         ( w_leds ),
        .o_dvi          ( w_dvi )
    );
endmodule
