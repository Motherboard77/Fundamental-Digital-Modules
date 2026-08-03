
// N-bit BARRREL SHIFTER

module barrell_shift_n_bit #(parameter K = 8)(

  input [K-1:0] inp_to_shift,
  input [$clog2(K)-1:0] sel,
  output [K-1:0] shifted_out
);

  wire [K-1:0] inp_to_latch [$clog2(K) : 0];
  wire [K-1:0] mux_out_cap [$clog2(K) : 0];
    
  assign inp_to_latch[0] = inp_to_shift;
  
  genvar i;
  
  generate 
    
    for(i = 0; i < $clog2(K) ; i = i + 1)   begin : barett_stage_generate
      
      assign mux_out_cap[i] = 	sel[i] ? inp_to_latch[i] >> (1 << i) : inp_to_latch[i] ;    //shift data-right by 1 unit or keep as it is
      assign inp_to_latch[i+1] = mux_out_cap[i] ; 
      
    end
    
  endgenerate
  
  
  assign shifted_out = inp_to_latch[3];
  
endmodule