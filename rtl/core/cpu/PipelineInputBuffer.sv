module PipelineInputBuffer #(                                                                                                             
    parameter type D_TYPE = logic                                                                                                         
)(                                                                                                                                
    input  logic  i_clk, i_rst, i_ready, i_valid,                                                                           
    input  D_TYPE i_d_in,                                                                                                         
    output logic  o_ready, o_valid,                                                                                          
    output D_TYPE o_d_out                                                                                                         
);                                                                                                                                
                                                                                                                                  
    logic  r_d_buff_valid;                                                                                                        
    D_TYPE r_d_buff;                                                                                                              
    
    logic w_handshake;                                                                                                                              
    logic w_d_buff_w_en;                                                                                                          
    logic w_d_buff_consume;                                                                                                       
                                                                                                                                  
    always_comb begin
        w_handshake = o_ready && i_valid;
        
        // TODO Performance issue here I think, should o_valid depend on i_ready, does this add unnecessary latency.                                                                                                                
        o_valid = i_ready && ( r_d_buff_valid || w_handshake );                                                                   
                                                                                                                                  
        if ( o_valid ) begin                                                                                                      
            o_d_out = ( r_d_buff_valid ? r_d_buff : i_d_in );                                                                     
                                                                                                                                  
        end else begin                                                                                                            
            o_d_out = D_TYPE'('x);                                                                                                
        end                                                                                                                       
                                                                                                                                  
        w_d_buff_w_en    = w_handshake && ( i_ready ~^ r_d_buff_valid );                                                          
        w_d_buff_consume = o_valid && r_d_buff_valid && !w_handshake;                                                                                                                                                                                                                                                      
    end                                                                                                                           
                                                                                                                                  
    always_ff @( posedge i_clk ) begin                                                                                            
        if ( i_rst ) begin
                o_ready        <= 1;                                                                                                      
                r_d_buff_valid <= 0;                                                                                              
                r_d_buff       <= D_TYPE'('x);                                                                                   
                                                                                                                                  
        end else begin                                                                                                                                                                                                        
            if ( w_d_buff_w_en ) begin
                o_ready        <= 0;                                                                                        
                r_d_buff_valid <= 1;                                                                                          
                r_d_buff       <= i_d_in;
                                                                                 
            end else if ( w_d_buff_consume ) begin
                o_ready        <= 1;                                                                                         
                r_d_buff_valid <= 0;                                                                                              
                r_d_buff       <= D_TYPE'('x);                                                                                    
            
            end else if ( !r_d_buff_valid ) begin
                o_ready <= 1;
            end
            
            // This condition would result in loss of data.                                                                           
            assert( !( w_handshake && !i_ready && r_d_buff_valid ) ) else $error( "pipeline input buffer data loss condition" );                                                                                                                      
        end                                                                                                                       
    end                                                                                                                           
endmodule                                                                                                                         