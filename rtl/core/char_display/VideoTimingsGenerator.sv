import CharDisplayPkg::*;


module VideoTimingsGenerator (
    input  logic            i_clk, i_rst,
    output video_timings_st o_video_timings
);

    localparam BACK_PORCH_HORIZONTAL  = 16;
    localparam ACTIVE_HORIZONTAL      = 640;
    localparam FRONT_PORCH_HORIZONTAL = 48;
    localparam SYNC_HORIZONTAL        = 96;
    
    localparam BACK_PORCH_VERTICAL  = 10;
    localparam ACTIVE_VERTICAL      = 480;
    localparam FRONT_PORCH_VERTICAL = 33;
    localparam SYNC_VERTICAL        = 2;

    logic w_is_bp_h, w_is_active_h, w_is_fp_h, w_is_bp_v, w_is_active_v, w_is_fp_v;
    
    always_comb begin
        w_is_fp_h                = '0;
        w_is_active_h            = '0;
        w_is_bp_h                = '0;
        o_video_timings.hsync    = '0;
        
        if ( o_video_timings.pos_x < ACTIVE_HORIZONTAL ) begin
            w_is_active_h = 1;
        
        end else if ( o_video_timings.pos_x < ( ACTIVE_HORIZONTAL + FRONT_PORCH_HORIZONTAL ) ) begin
            w_is_fp_h = 1;
        
        end else if ( o_video_timings.pos_x < ( ACTIVE_HORIZONTAL + FRONT_PORCH_HORIZONTAL + SYNC_HORIZONTAL ) ) begin
            o_video_timings.hsync = 1;
        
        end else begin
            w_is_bp_h = 1;
        end
    end
    
    always_comb begin
        w_is_fp_v             = '0;
        w_is_active_v         = '0;
        w_is_bp_v             = '0;
        o_video_timings.vsync = '0;
        
        if ( o_video_timings.pos_y < ACTIVE_VERTICAL ) begin
            w_is_active_v = 1;
        
        end else if ( o_video_timings.pos_y < ( ACTIVE_VERTICAL + FRONT_PORCH_VERTICAL ) ) begin
            w_is_fp_v = 1;
        
        end else if ( o_video_timings.pos_y < ( ACTIVE_VERTICAL + FRONT_PORCH_VERTICAL + SYNC_VERTICAL ) ) begin
            o_video_timings.vsync = 1;
        
        end else begin
            w_is_bp_v = 1;
        end
    end
    
    always_comb begin
        o_video_timings.frame = (
            ( o_video_timings.pos_x == ( ACTIVE_HORIZONTAL + FRONT_PORCH_HORIZONTAL + SYNC_HORIZONTAL + BACK_PORCH_HORIZONTAL - 1 ) ) 
            && ( o_video_timings.pos_y == ( ACTIVE_VERTICAL + FRONT_PORCH_VERTICAL + SYNC_VERTICAL + BACK_PORCH_VERTICAL - 1 ) )
        );
    
        o_video_timings.active = w_is_active_h && w_is_active_v;
    end

    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin
            o_video_timings.pos_x <= '0;
            o_video_timings.pos_y <= '0;
        
        end else begin
            if ( ( o_video_timings.pos_x + 1 ) < ( ACTIVE_HORIZONTAL + FRONT_PORCH_HORIZONTAL + SYNC_HORIZONTAL + BACK_PORCH_HORIZONTAL ) ) begin
                o_video_timings.pos_x <= o_video_timings.pos_x + 1;
           
            end else begin
                o_video_timings.pos_x <= '0;
            end
            
            if ( ( o_video_timings.pos_x + 1 ) == ( ACTIVE_HORIZONTAL + FRONT_PORCH_HORIZONTAL + SYNC_HORIZONTAL + BACK_PORCH_HORIZONTAL ) ) begin
                if( ( o_video_timings.pos_y + 1 ) < ( ACTIVE_VERTICAL + FRONT_PORCH_VERTICAL + SYNC_VERTICAL + BACK_PORCH_VERTICAL ) ) begin
                    o_video_timings.pos_y <= o_video_timings.pos_y + 1;
           
                end else begin
                    o_video_timings.pos_y <= '0;
                end
            end
        end
    end
endmodule