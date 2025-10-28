// REFACTOR Reuse timescale across testbenches.
`timescale 1ps / 1ps


module UartTb();

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

    logic r_rx;

    initial begin
        r_rx = '1;

        // Start.
        #64 r_rx = '0;

        // 32 is 2 * OVERSAMPLE.
        // 0x61
        #32 r_rx = '1;
        #32 r_rx = '0;
        #32 r_rx = '0;
        #32 r_rx = '0;
        #32 r_rx = '0;
        #32 r_rx = '1;
        #32 r_rx = '1;
        #32 r_rx = '0;
        
        // Stop.
        #32 r_rx = '1;
    end

    logic w_tx;

    mem_if if_mem_uart(); 
    
    Uart m_uart (
        .i_clk  ( r_clk ),
        .i_rst  ( r_rst ),
        .i_rx   ( r_rx ),
        .o_tx   ( w_tx ),
        .if_mem ( if_mem_uart )
    );
endmodule
