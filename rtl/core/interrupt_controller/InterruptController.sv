// REFACTOR This documentation needs to go in .rdl file.
// Reading offset 0 returns the interrupt enables, writing sets the enables.
// Reading offset 4 returns the pending bits, writing will clear the pending bits that are set in the write data.
module InterruptController #(
    parameter NUM_INT_SRCS
) (
    input logic                      i_clk,
    input logic [NUM_INT_SRCS - 1:0] i_int,
    output logic                     o_int,
    mem_if                           if_mem
);
    generate;
        if ( NUM_INT_SRCS > 32 ) begin
            $error( "Maximum of 32 interrupt sources supported." );
        end
    endgenerate

    logic [NUM_INT_SRCS - 1:0] r_en      = '0;
    logic [NUM_INT_SRCS - 1:0] r_pending = '0; // FIXME Undefined at reset still.

    logic [NUM_INT_SRCS - 1:0] w_pending_next;

    typedef enum logic {
        INT_CTL_ADDR_ENABLE  = 1'h0,
        INT_CTL_ADDR_PENDING = 1'h1
    } int_ctl_addr_e;

    int_ctl_addr_e w_int_ctl_addr;

    word_t r_data;

    always_comb begin
        o_int = |( r_en & r_pending );

        if_mem.ready  = '1;
        if_mem.r_data = r_data;

        w_int_ctl_addr = int_ctl_addr_e'( if_mem.addr[2] );

        if ( if_mem.valid && if_mem.w_en && ( w_int_ctl_addr == INT_CTL_ADDR_PENDING ) ) begin
            w_pending_next = ( r_pending & ~if_mem.w_data ) | i_int;
            
        end else begin
            w_pending_next = r_pending | i_int;
        end
    end

    always_ff @( posedge i_clk ) begin
        r_pending <= w_pending_next;

        if ( if_mem.valid ) begin
            if ( if_mem.w_en ) begin
                // Missing INT_CTL_ADDR_PENDING case is intentional.
                case ( w_int_ctl_addr )
                INT_CTL_ADDR_ENABLE: begin
                    r_en <= if_mem.w_data[NUM_INT_SRCS - 1:0];
                end
                endcase

            end else begin
                case ( w_int_ctl_addr )
                INT_CTL_ADDR_ENABLE: begin
                    r_data <= r_en;
                end
                INT_CTL_ADDR_PENDING: begin
                    r_data <= r_pending;
                end
                endcase
            end
        end
    end
endmodule
