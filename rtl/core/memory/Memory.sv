import QuokkaRvPkg::*;

// REFACTOR Make word size parameterizable?
module Memory (
    input logic  i_clk, i_rst,
    mem_if.slave if_mem
);
    // TODO Make module parameter.
    localparam MEM_SIZE_WORDS = 16384;

    word_t r_mem [MEM_SIZE_WORDS - 1:0];
    word_t r_read;

    initial begin
        $readmemh("data_mem.mem", r_mem);
    end

    // Word aligned address.
    logic [31:0] w_addr_word_unsafe, w_addr_word;

    always_comb begin
        if_mem.ready  = '1;
        if_mem.r_data = r_read;

        w_addr_word_unsafe = { 2'b0, if_mem.addr[$size( if_mem.addr ) - 1:2] };
        w_addr_word = w_addr_word_unsafe < $size( r_mem ) ? w_addr_word_unsafe : '0; 
    end

    always_ff @( posedge i_clk ) begin
        if ( i_rst ) begin

        end else begin
            if ( if_mem.valid && if_mem.w_en) begin
                case ( if_mem.w_size )
                MEM_W_SIZE_WORD: begin
                    r_mem[w_addr_word] <= if_mem.w_data;
                end
                MEM_W_SIZE_HALF: begin
                    case ( if_mem.addr[1] )
                    1'b0: begin
                        r_mem[w_addr_word][15:0] <= if_mem.w_data[15:0];
                    end
                    1'b1: begin
                        r_mem[w_addr_word][31:16] <= if_mem.w_data[15:0];
                    end
                    endcase
                end
                MEM_W_SIZE_BYTE: begin
                    case ( if_mem.addr[1:0] )
                    2'b00: begin
                        r_mem[w_addr_word][7:0] <= if_mem.w_data[7:0];
                    end
                    2'b01: begin
                        r_mem[w_addr_word][15:8] <= if_mem.w_data[7:0];
                    end
                    2'b10: begin
                        r_mem[w_addr_word][23:16] <= if_mem.w_data[7:0];
                    end
                    2'b11: begin
                        r_mem[w_addr_word][31:24] <= if_mem.w_data[7:0];
                    end
                    endcase
                end
                default: begin
                end
                endcase
            end else begin

                r_read <= r_mem[w_addr_word];
            end
        end
    end
endmodule


