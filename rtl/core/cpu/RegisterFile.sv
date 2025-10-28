import CpuPkg::*;


// TODO Is the flush signal even needed?
module RegisterFile (
    input  logic             i_clk, i_rst, i_flush,
    input  regfile_r_req_st  i_r_req,
    input  regfile_w_req_st  i_w_req,
    output regfile_r_resp_st o_r_resp
);
    
    // All general purpose registers are left undefined at startup.
    // FPGA's typically have dual port blockram, so if we want blockram to be inferred we can't have 1 write port +
    // 2 read ports on the same blockram, thus we duplicate the writes across 2 blockrams.
    // TODO Synthesizer complaing about output register not being inferred, is there a problem with this implementation?
    // REFACTOR Magic vector length.
    (* ram_style="block" *) logic [31:0] mem0 [0:31];
    (* ram_style="block" *) logic [31:0] mem1 [0:31];
    
    always_ff @(posedge i_clk) begin
        if (i_w_req.w_en) begin
            mem0[i_w_req.w_addr] <= i_w_req.w_data;
            mem1[i_w_req.w_addr] <= i_w_req.w_data;
        end
        o_r_resp.r_data_1 <= (i_r_req.r_addr_1 == 0) ? '0 : mem0[i_r_req.r_addr_1];
        o_r_resp.r_data_2 <= (i_r_req.r_addr_2 == 0) ? '0 : mem1[i_r_req.r_addr_2];
    end
endmodule
