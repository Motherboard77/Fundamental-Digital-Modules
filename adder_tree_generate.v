


//Adder-Tree design using Generate

module param_adder_tree #(
  
  parameter INPUT_WIDTH = 8,
  parameter NO_OF_INPUTS = 16,
  parameter OUTPUT_WIDTH = INPUT_WIDTH + $clog2(NO_OF_INPUTS)
)(  
  input wire [INPUT_WIDTH-1:0] data_in [0:NO_OF_INPUTS-1],
  output wire [OUTPUT_WIDTH-1:0] data_out
);
  
  //compute the total no of stages required for the adder tree
  localparam STAGES = $clog2(NO_OF_INPUTS);		//lets say : for 4 inputs , 2 stages compute-tree
  
  //create a 2D array of wires to hold intermediate data
  
  genvar s,i;
  
  generate 
    
    //2D wire mesh, keep the width of each element in the stage equal to the output width
    //allocate each "element" in the stage (there will be NO_OF_INPUTS total elements), a fixed width of OUTPUT_WIDTH
    //the result should accumulate on the 0th index of ouput of the last stage
    
    wire [OUTPUT_WIDTH-1:0] adder_tree[0:STAGES][0:NO_OF_INPUTS-1];
    
    //initiaze STAGE-0
    for(i=0;i<NO_OF_INPUTS;i=i+1) begin : initialize_stage0
      assign adder_tree[0][i] = {{(OUTPUT_WIDTH-INPUT_WIDTH){1'b0}},data_in[i]};
    end
    
    //compute the stages in the tree, for each stage process element-pairs and add them
    for(s=0;s<STAGES;s= s+1) begin : stage_compute
        	
      //for the immediate-next stage, the no of elemets would half
      localparam ELEMENTS_IN_STAGE = NO_OF_INPUTS >> s; 
      
      for(i=0; i<ELEMENTS_IN_STAGE/2; i = i+1) begin : element_compute	
        assign adder_tree[s+1][i] = adder_tree[s][i*2] + adder_tree[s][(i*2)+1];        
      end
    end
    
  endgenerate
  
  assign data_out = adder_tree[STAGES][0];
  
endmodule