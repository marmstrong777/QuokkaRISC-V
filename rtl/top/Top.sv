import DviPkg::*;


module Top (
    // REFACTOR Signal names missing prefix, hdmi signal grouping, rename clk to sys_clk.
    input  logic       clk,
    output logic [3:0] leds,
    output logic       hdmi_tx_clk_n,
    output logic       hdmi_tx_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p
);
    logic w_clk_core, w_clk_dvi, w_clk_dvi_mul5;
  
    clk_gen m_clk_gen (
        .clk_in           ( clk ),
        .reset            ( 1'b0 ),
        .clk_out_core     ( w_clk_core ),
        .clk_out_dvi      ( w_clk_dvi ),
        .clk_out_dvi_mul5 ( w_clk_dvi_mul5 )
    );

    // REFACTOR Repetition of reset across each clock domain, use a module or maybe some other method of reset.
    logic [3:0] r_rst_core_count;
    logic       r_rst_core;
    
    always_ff @( posedge w_clk_core ) begin
        if ( r_rst_core_count < 4'd10 ) begin
            r_rst_core_count <= r_rst_core_count + 1;
            r_rst_core       <= 1'b1;
        
        end else begin
            r_rst_core <= 1'b0;
        end
    end
    
    logic [3:0] r_rst_dvi_count;
    logic       r_rst_dvi;
    
    always_ff @( posedge w_clk_dvi ) begin
        if ( r_rst_dvi_count < 4'd10 ) begin
            r_rst_dvi_count <= r_rst_dvi_count + 1;
            r_rst_dvi       <= 1'b1;
        
        end else begin
            r_rst_dvi <= 1'b0;
        end
    end
    
    dvi_st w_dvi;
    
    QuokkaRv m_quokka (
        .i_clk_core     ( w_clk_core ),
        .i_clk_dvi      ( w_clk_dvi ),
        .i_clk_dvi_mul5 ( w_clk_dvi_mul5 ),
        .i_rst_core     ( r_rst_core ),
        .i_rst_dvi      ( r_rst_dvi ),
        .o_leds         ( leds ),
        .o_dvi          ( w_dvi )
    );
    
    OBUFDS #(
        .IOSTANDARD("TMDS_33") // Specify the output I/O standard
    ) OBUFDS_inst0 (
        .O(hdmi_tx_p[0]),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
        .OB(hdmi_tx_n[0]),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
        .I(w_dvi.blue)      // Buffer input (this is the single ended standard)
    );
    OBUFDS #(
        .IOSTANDARD("TMDS_33") // Specify the output I/O standard
    ) OBUFDS_inst1 (
        .O(hdmi_tx_p[1]),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
        .OB(hdmi_tx_n[1]),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
        .I(w_dvi.green)      // Buffer input (this is the single ended standard)
    );
    OBUFDS #(
        .IOSTANDARD("TMDS_33") // Specify the output I/O standard
    ) OBUFDS_inst2 (
        .O(hdmi_tx_p[2]),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
        .OB(hdmi_tx_n[2]),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
        .I(w_dvi.red)      // Buffer input (this is the single ended standard)
    );
    OBUFDS #(
        .IOSTANDARD("TMDS_33") // Specify the output I/O standard
    ) OBUFDS_inst3 (
        .O(hdmi_tx_clk_p),     // Diff_p output (connect directly to top-level port) (p type differential o/p)
        .OB(hdmi_tx_clk_n),   // Diff_n output (connect directly to top-level port) (n type differential o/p)
        .I(w_dvi.clk)      // Buffer input (this is the single ended standard)
    );
endmodule
