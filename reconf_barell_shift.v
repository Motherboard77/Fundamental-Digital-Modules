
//Reconfigurable (LEFT/RIGHT) Barrel Shifter

module Barrel_Shifter_Reconfigurable #(parameter K = 8)(

  input [K-1:0] inp_to_convt,
  input [$clog2(K)-1:0] sel,
  input mode,
  output [K-1:0] shifted_out
);
  
  wire [K-1:0] inp_inverted;
  genvar i;
  generate 
    for(i = 0; i<K; i=i+1) begin : bits_inverted
        assign inp_inverted[i] = inp_to_convt[K-1-i];   
      end
  endgenerate
  
  
  //create a 2D stage grid
  wire [K-1:0] STAGES[0:$clog2(K)] ;
  
  //assign to STAGE-0 either the original or the inverted bitstream based on mode signal
  //mode == 1 -> LEFT shift
  //mode == 0 -> RIGHT shift
  assign STAGES[0] = mode ? inp_inverted : inp_to_convt;
  
  generate 
    for(i=0;i<$clog2(K);i=i+1) begin : shifter_HW
        
      assign STAGES[i+1] = sel[i] ? STAGES[i] >> (1 << i) : STAGES[i] ; 
      
      end
  endgenerate 
  
  //output the processed bits
  generate 
    for(i=0;i<K;i=i+1) begin : output_processed
      assign shifted_out[i] = mode ? STAGES[$clog2(K)][K-1-i] : STAGES[$clog2(K)][i];
    end
  endgenerate
  
endmodule