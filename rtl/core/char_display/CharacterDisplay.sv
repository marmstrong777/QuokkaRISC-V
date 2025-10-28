import DviPkg::*;
import CharDisplayPkg::*;


module CharacterDisplay (
    input  logic  i_clk_bus, i_clk_dvi, i_clk_dvi_mul5, i_rst_bus, i_rst_dvi,
    output dvi_st o_dvi,
    mem_if.slave  if_mem
);

    localparam FONT_WIDTH   = 8;
    localparam FONT_HEIGHT  = 16;
    localparam CHAR_ROWS    = 30;
    localparam CHAR_COLUMNS = 80;
    localparam TOTAL_CHARS  = CHAR_ROWS * CHAR_COLUMNS;

    typedef logic [7:0] char_t;

    char_t r_char_mem[TOTAL_CHARS - 1:0];

    rgb_st r_background_colour, r_font_colour;

    logic [$clog2( TOTAL_CHARS ) - 1:0] w_char_w_addr, w_char_w_addr_safe;

    always_comb begin
        if_mem.ready  = '1;
        if_mem.r_data = 'x;

        // REFACTOR Rename, swap to w_char_w_addr_unsafe and w_char_w_addr
        w_char_w_addr      = if_mem.addr[$clog2( TOTAL_CHARS ) - 1:0];
        w_char_w_addr_safe = w_char_w_addr < TOTAL_CHARS ? w_char_w_addr : '0;
    end

    always_ff @( posedge i_clk_bus ) begin
        if ( i_rst_bus ) begin
            r_font_colour <= '{
                red:   '1,
                green: '1,
                blue:  '1
            };
            r_background_colour <= '{
                red:   '0,
                green: '0,
                blue:  '0
            };
            
        end else begin
            // FIXME Not checking write enable here.
            if ( if_mem.valid ) begin
                case ( if_mem.addr[15] )
                1'b0: begin // Offset 0.
                    r_char_mem[w_char_w_addr_safe] <= if_mem.w_data[7:0];
                end
                1'b1: begin // Offset 0x8000
                    case ( if_mem.addr[2] )
                    1'b0: begin // Offset 0x8000 + 0.
                        r_background_colour.red   <= if_mem.w_data[7:0]; 
                        r_background_colour.green <= if_mem.w_data[15:8]; 
                        r_background_colour.blue  <= if_mem.w_data[23:16]; 
                    end
                    1'b1: begin // Offset 0x8000 + 4.
                        r_font_colour.red   <= if_mem.w_data[7:0]; 
                        r_font_colour.green <= if_mem.w_data[15:8]; 
                        r_font_colour.blue  <= if_mem.w_data[23:16];                 
                    end
                    endcase
                end
                endcase
            end
        end
    end

    // ========== Stage 0: Video timings.
    
    video_timings_st w_video_timings_s0;

    VideoTimingsGenerator m_video_timings (
        .i_clk           ( i_clk_dvi ),
        .i_rst           ( i_rst_dvi ),
        .o_video_timings ( w_video_timings_s0 )
    );

    // ========== Stage 1: Character lookup.
    
    // REFACTOR Inconsistency with naming, calling char coordinates x/y or column/row.
    logic [$clog2( CHAR_ROWS ) - 1:0]    w_char_row;
    logic [$clog2( CHAR_COLUMNS ) - 1:0] w_char_column;
    // REFACTOR Rename to w_char_r_addr, w_char_addr_r_safe to distinguish from write addr. Also swap (_unsafe postfix).
    logic [$clog2( TOTAL_CHARS ) - 1:0]  w_char_addr, w_char_addr_safe;
    char_t                               r_char, w_char_next;
    video_timings_st                     r_video_timings_s1;
    
    // TODO Placeholder, don't initilize in future.
    initial begin
        $readmemh("char_display_init.mem", r_char_mem);
    end
    
    // TODO Apparently reading from blockrams in a always_comb block like this is not synthesizable in some cases,
    // replace instances like this with direct assignment in an always_ff block.
    always_comb begin
        w_char_row    = w_video_timings_s0.pos_y / FONT_HEIGHT;
        w_char_column = w_video_timings_s0.pos_x / FONT_WIDTH;
        
        w_char_addr      = ( w_char_row * CHAR_COLUMNS ) + w_char_column;
        w_char_addr_safe = w_char_addr < TOTAL_CHARS ? w_char_addr : '0;
        w_char_next      = r_char_mem[w_char_addr_safe];
    end
    
    always_ff @( posedge i_clk_dvi ) begin
        r_char             <= w_char_next;
        r_video_timings_s1 <= w_video_timings_s0;
    end
    
    // ========== Stage 2: Font row bitmap lookup.
    
    // Font memory is structured as an array of individual font bitmap rows.
    logic [FONT_WIDTH - 1:0]                    r_font_mem[( FONT_HEIGHT * ( 2 ** $bits( char_t ) ) ) - 1:0];
    logic [$clog2( $size( r_font_mem ) ) - 1:0] w_font_addr;
    logic [FONT_WIDTH - 1:0]                    r_font_bitmap_row, w_font_bitmap_row_next;
    video_timings_st                            r_video_timings_s2;
    logic [$clog2( FONT_HEIGHT ) - 1:0]         w_font_y;
    logic [$clog2( FONT_WIDTH ) - 1:0]          r_font_x, w_font_x_next;
    
    initial begin
        $readmemh("char_display_font.mem", r_font_mem);
    end 
    
    always_comb begin
        w_font_y      = r_video_timings_s1.pos_y % FONT_HEIGHT;
        w_font_x_next = r_video_timings_s1.pos_x % FONT_WIDTH;
        
        w_font_addr            = ( r_char * FONT_HEIGHT ) + w_font_y;
        w_font_bitmap_row_next = r_font_mem[w_font_addr];
    end
    
    always_ff @( posedge i_clk_dvi ) begin
        r_font_bitmap_row  <= w_font_bitmap_row_next;
        r_font_x           <= w_font_x_next;
        r_video_timings_s2 <= r_video_timings_s1;
    end
    
    // ========== Stage 3: Output.
    
    rgb_st                   w_rgb;
    logic [FONT_WIDTH - 1:0] r_font_bitmap_row_rev;
    logic                    w_font_bitmap_bit;
    
    RgbToDvi m_rgb_dvi (
        .i_clk           ( i_clk_dvi ),
        .i_clk_mul5      ( i_clk_dvi_mul5 ),
        .i_rst           ( i_rst_dvi ),
        .i_video_timings ( r_video_timings_s2 ),
        .i_rgb           ( w_rgb ),
        .o_dvi           ( o_dvi )
    );
    
    integer i;
    
    always_comb begin
        for ( i = 0; i < $size( r_font_bitmap_row_rev ); i = i + 1 ) begin
            r_font_bitmap_row_rev[i] = r_font_bitmap_row[( $size( r_font_bitmap_row_rev ) - 1 ) - i];
        end
    
        w_font_bitmap_bit = r_font_bitmap_row_rev[r_font_x];
        w_rgb             = w_font_bitmap_bit ? r_font_colour : r_background_colour;
        

        // FIXME This fixes missing character on each row bug, why? Out of bounds access undefined behavior with
        // r_char_mem maybe? Try to identify what exactly about this block fixes the issue.
        if ( w_font_y == 0 ) begin
            w_rgb = r_background_colour;
        end
    end
endmodule
