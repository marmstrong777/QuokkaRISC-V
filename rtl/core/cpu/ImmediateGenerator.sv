import CpuPkg::*;


module ImmediateGenerator (
    input  imm_type_e i_imm_type,
    input  inst_t     i_inst,
    output word_t     o_result
);

    always_comb begin
		case( i_imm_type )
			IMM_TYPE_I: begin
				o_result = {{21{i_inst[31]}}, i_inst[30:25], i_inst[24:21], i_inst[20]};
			end
            
			IMM_TYPE_S: begin
				o_result = {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:8], i_inst[7]};
			end

			IMM_TYPE_B: begin
				o_result = {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
			end

			IMM_TYPE_U: begin
				o_result = {i_inst[31], i_inst[30:20], i_inst[19:12], 12'b0};
			end

			IMM_TYPE_J: begin
				o_result = {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:25], i_inst[24:21], 1'b0};
			end
			IMM_TYPE_CSR: begin
				o_result = {27'b0, i_inst[19:15]};
			end
			default: begin
			    o_result = word_t'( 'x );
			end
		endcase
    end
endmodule