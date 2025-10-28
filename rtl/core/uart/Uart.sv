
// TODO Implement transmit.
// TODO Detect framing error (check stop bit).
// TODO Ability to set baud rate.
// TODO Read flag to indicate uart packets have been lost due to overflow.
// FIXME Add flag to enable data receive in fifo.
module Uart (
    input  logic i_clk_bus, i_clk_uart, i_rst_bus, i_rst_uart, i_rx_async,
    output logic o_int, o_tx,
    mem_if       if_mem
);
    // REFACTOR Put rx / tx into own modules.

    // REFACTOR All POW2 paramters should be renamed to LOG2, POW2 doesn't make sense.
    // FIXME Static assert OVERSAMPLE is a power of 2 (for the overflow behavior to work). Make it OVERSAMPLE_LOG2?
    localparam OVERSAMPLE = 16;

    localparam NUM_DATA_BITS = 8;
    localparam FIFO_DEPTH = 1024;

    logic [7:0] r_rx_fifo [FIFO_DEPTH - 1:0];

    typedef enum logic [1:0] {
        RX_STATE_IDLE,
        RX_STATE_START,
        RX_STATE_DATA,
        RX_STATE_STOP
    } rx_state_e;

    rx_state_e r_rx_state;

    logic [2:0] r_rx_sync;
    logic       w_rx, w_rx_negedge;

    // REFACTOR Rename to r_data_idx.
    logic [$clog2( NUM_DATA_BITS ) - 1:0] r_data_cnt;

    always_comb begin
        // REFACTOR Confusing naming. r_rx_sync[0] r_rx_sync, r_rx_sync[1] -> r_rx, r_rx_sync[2] -> r_rx_prev.
        w_rx         = r_rx_sync[1];
        w_rx_negedge = !r_rx_sync[1] && r_rx_sync[2];
    end 

    // REFACTOR Rename to r_sample_idx.
    // This register is used for the timing of sampling the uart input line, designed to overflow, therefore each
    // the sample period (in clock cycles) is a power of 2.
    logic [$clog2( OVERSAMPLE ) - 1:0] r_sample_cnt;

    // This signal is designed to assert for one clock cycle in the middle of each received uart bit.
    logic w_middle_bit;

    // We need a copy of r_uart_ctl.rx_en in the uart clock domain.
    logic r_rx_en_uart_sync, r_rx_en_uart;

    always_ff @( posedge i_clk ) begin
        if ( i_rst_uart ) begin
            r_rx_en_uart_sync <= '0;
            r_rx_en_uart      <= '0;

        end else begin
            r_rx_en_uart_sync <= r_uart_ctl.rx_en;
            r_rx_en_uart      <= r_rx_en_uart_sync;
        end
    end 

    always_comb begin
        // REFACTOR Rename to w_sample_now?
        w_middle_bit = r_sample_cnt == ( ( OVERSAMPLE / 2 ) - 1 );

        w_rx_fifo_w_en = ( r_rx_state == RX_STATE_STOP ) && w_middle_bit && r_rx_en_uart;
    end

    logic [NUM_DATA_BITS - 1:0] r_rx_shift;

    always_ff @( posedge i_clk_uart ) begin
        if ( i_rst_uart ) begin
            r_rx_state <= RX_STATE_IDLE;
            r_rx_sync  <= '1;

        end else begin
            r_rx_sync <= { r_rx_sync[1], r_rx_sync[0], i_rx_async };

            case( r_rx_state )
            RX_STATE_IDLE: begin
                if ( w_rx_negedge ) begin
                    // Negative edge of start bit, start of frame.
                    r_sample_cnt <= '0;
                    r_rx_state   <= RX_STATE_START;
                
                end else begin
                    r_sample_cnt <= r_sample_cnt + 1;
                end
            end
            RX_STATE_START: begin
                r_sample_cnt <= r_sample_cnt + 1;

                if ( w_middle_bit ) begin
                    // Middle of start bit.
                    r_data_cnt <= '0;
                    r_rx_state <= RX_STATE_DATA;
                end
            end
            RX_STATE_DATA: begin
                r_sample_cnt <= r_sample_cnt + 1;

                if ( w_middle_bit ) begin
                    // Middle of data bit of index r_data_cnt.
                    r_rx_shift <= { w_rx, r_rx_shift[NUM_DATA_BITS - 1:1] };

                    if ( r_data_cnt == ( NUM_DATA_BITS - 1 ) ) begin
                        r_rx_state <= RX_STATE_STOP;

                    end else begin
                        r_data_cnt <= r_data_cnt + 1;
                    end
                end
            end
            RX_STATE_STOP: begin
                r_sample_cnt <= r_sample_cnt + 1;

                if ( w_middle_bit ) begin
                    // Middle of stop bit.
                    r_rx_state <= RX_STATE_IDLE;
                end
            end
            endcase
        end
    end

    // TODO Way to get fifo width and depth (size of din/dout port for width maybe?).
    logic [NUM_DATA_BITS - 1:0] w_fifo_rx_r_data;

    lgoic w_fifo_rx_w_en, w_fifo_rx_r_en, w_fifo_full, w_fifo_empty;
    logic [7:0] w_fifo_rx_cnt;

    // REFACTOR Inconsistent naming of variables.
    uart_fifo_async m_fifo_rx (
        .rst           ( i_rst_bus ),
        .wr_clk        ( i_clk_uart ),
        .rd_clk        ( i_clk_bus ),
        .din           ( r_rx_shift ),
        .wr_en         ( w_rx_fifo_w_en ),
        .rd_en         ( w_rx_fifo_r_en ),
        .dout          ( w_fifo_rx_r_data ),
        .full          ( w_fifo_full ),
        .empty         ( w_rx_fifo_empty ),
        .rd_data_count ( w_fifo_rx_cnt ),
        .wr_rst_busy   (  ),
        .rd_rst_busy   (  )
    );

    // FIXME This is hard coded but should be referenced from the ip somehow.
    // The 255 instead of 256 is not a mistake, referencing the xilinx fifo ip generator.
    localparam RX_FIFO_DEPTH = 255;

    // ========== Memory interface and interrupt logic.

    typedef enum logic [2:0] {
        UART_ADDR_CTL            = 3'h0,
        UART_ADDR_FIFO_WATERMARK = 3'h1,
        UART_ADDR_TIMER_CMP      = 3'h2,
        UART_ADDR_RX             = 3'h3,
        UART_ADDR_RX_COUNT       = 3'h4
    } uart_addr_e;

    typedef struct packed {
        logic rx_en,
        logic rx_watermark_int_en,
        logic rx_timer_int_en,
    } uart_ctl_st;

    uart_ctl_st r_uart_ctl;
    word_t r_fifo_rx_watermark, r_timer, r_timer_cmp;

    word_t r_read;

    uart_addr_e w_uart_addr;
    logic w_fifo_rx_watermark_int, w_timer_int

    always_comb begin
        w_uart_addr = uart_addr_e'( if_mem.addr[4:2] );

        w_fifo_rx_watermark_int = ( w_fifo_rx_cnt >= r_fifo_rx_watermark ) && r_uart_ctl.rx_watermark_int_en;
        w_timer_int             = ( r_timer >= r_timer_cmp ) && !w_rx_fifo_empty && r_uart_ctl.rx_timer_int_en;

        w_rx_fifo_r_en = if_mem.valid && !if_mem.w_en && ( w_uart_addr == UART_ADDR_RX );
    end

    always_ff @( posdege i_clk_bus ) begin
        if ( i_rst_bus ) begin
            r_fifo_rx_watermark <= '0;
            r_timer             <= '0;
            r_timer_cmp         <= '0;
            r_uart_ctl          <= '{
                .rx_en:               '0,
                .rx_watermark_int_en: '0,
                .rx_timer_int_en:     '0
            };

        end else begin
            if ( w_fifo_empty ) begin
                r_timer <= '0;

            // We don't want the timer to overflow, thus the comparison.
            end else if ( r_timer < r_timer_cmp ) begin
                r_timer <= r_timer + 1;
            end

            if ( if_mem.valid ) begin
                if ( if_mem.w_en ) begin

                end else begin
                    case ( w_uart_addr )
                    UART_ADDR_CTL
                    UART_ADDR_FIFO_WATERMARK
                    UART_ADDR_TIMER_CMP
                    UART_ADDR_RX: begin
                        // FIXME Fifo read enable MUST be asserted.
                        r_read <= w_fifo_rx_r_data;
                    end
                    UART_ADDR_TX
                    endcase
                end
            end
        end
    end

    // ==========

endmodule