import DviPkg::*;
import CharDisplayPkg::*;


module RgbToDvi (
    input  logic            i_clk, i_clk_mul5, i_rst,
    input  video_timings_st i_video_timings,
    input  rgb_st           i_rgb,
    output dvi_st           o_dvi
);

    logic [9:0] w_tmds_char_red, w_tmds_char_green, w_tmds_char_blue;

    TmdsEncoder m_tmds_encode_red (
        .i_clk     ( i_clk ),
        .i_rst     ( i_rst ),
        .i_data_en ( i_video_timings.active ),
        .i_ctrl_0  ( '0 ),
        .i_ctrl_1  ( '0 ),
        .i_data    ( i_rgb.red ),
        .o_tmds    ( w_tmds_char_red )
    );
    
    TmdsSerializer m_tmds_serialize_red (
        .i_clk       ( i_clk_mul5 ),
        .i_clk_div5  ( i_clk ),
        .i_rst       ( i_rst ),
        .i_tmds_char ( w_tmds_char_red ),
        .o_serial    ( o_dvi.red )
    );
    
    TmdsEncoder m_tmds_encode_green (
        .i_clk     ( i_clk ),
        .i_rst     ( i_rst ),
        .i_data_en ( i_video_timings.active ),
        .i_ctrl_0  ( '0 ),
        .i_ctrl_1  ( '0 ),
        .i_data    ( i_rgb.green ),
        .o_tmds    ( w_tmds_char_green )
    );
    
    TmdsSerializer m_tmds_serialize_green (
        .i_clk       ( i_clk_mul5 ),
        .i_clk_div5  ( i_clk ),
        .i_rst       ( i_rst ),
        .i_tmds_char ( w_tmds_char_green ),
        .o_serial    ( o_dvi.green )
    );
    
    TmdsEncoder m_tmds_encode_blue (
        .i_clk     ( i_clk ),
        .i_rst     ( i_rst ),
        .i_data_en ( i_video_timings.active ),
        .i_ctrl_0  ( i_video_timings.hsync ),
        .i_ctrl_1  ( i_video_timings.vsync ),
        .i_data    ( i_rgb.blue ),
        .o_tmds    ( w_tmds_char_blue )
    );
    
    TmdsSerializer m_tmds_serialize_blue (
        .i_clk       ( i_clk_mul5 ),
        .i_clk_div5  ( i_clk ),
        .i_rst       ( i_rst ),
        .i_tmds_char ( w_tmds_char_blue ),
        .o_serial    ( o_dvi.blue )
    );
        
    always_comb begin
        o_dvi.clk = i_clk;
    end
endmodule