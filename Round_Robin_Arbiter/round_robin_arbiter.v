
//Round-Robin Arbiter

module rra #(parameter DATA_WIDTH = 8)(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] req_in,
  output [DATA_WIDTH-1:0] grant_out
);
  
  
  //register the grant
  reg [DATA_WIDTH-1:0] grant_compute;
  
  //create a wired array values of (DATA_WIDTH) rotations of the input REQ
  wire [DATA_WIDTH-1:0] rotator_value [DATA_WIDTH-1:0]; 
  
  //compute the rotation mesh
  genvar i;
  
  generate 
    for(i=0;i<DATA_WIDTH;i=i+1) 
      begin : rot_compute
        assign rotator_value[i] =  (req_in >> i) | (req_in << (DATA_WIDTH-i)) ; 
      end
  endgenerate
  
  //select a rotation based on the previous registered grant 
  reg [DATA_WIDTH-1:0] rot_sel;
  
  //one-hot encoded select using the grant-register
  integer j;
  
  always@(*)
    begin
      	rot_sel = {DATA_WIDTH{1'b0}}; 		// Initialize to zero
      	for(j=0;j<DATA_WIDTH;j=j+1)
    	begin
          if(j == DATA_WIDTH-1) 
            rot_sel = rot_sel | ({DATA_WIDTH{grant_compute[j]}} & rotator_value[0]);
          else
            rot_sel = rot_sel | ({DATA_WIDTH{grant_compute[j]}} & rotator_value[j+1]);
    	end
    end

  //compute the new grant based on the selected rotator in the seq block
  
  //implement additional logic : if previous grant is zero, compute directly on the input REQ vector instead of the rot_sel vector
  wire [DATA_WIDTH-1:0] new_grant_compute;
  
  assign new_grant_compute = |(grant_compute) ? ((~rot_sel + 1'b1) & rot_sel) : ((~req_in + 1'b1) & req_in) ;
  
  //create an array of vectors of the unrotated grants, that will be selected via one-hot encoding
  wire [DATA_WIDTH-1:0] grant_unrotate_vec[DATA_WIDTH-1:0];
  
  generate 
    for(i=0;i<DATA_WIDTH;i=i+1)
      begin : unrotate_vector
        assign grant_unrotate_vec[i] = (new_grant_compute << i) | (new_grant_compute >> (DATA_WIDTH-i)); 
      end
  endgenerate
  
  reg [DATA_WIDTH-1:0] final_grant_compute;
  
  //one-hot encoded select of the un-rotated grant based on the previous grant 
  always@(*)
  	begin
      final_grant_compute = {DATA_WIDTH{1'b0}};
      
      //new grant will be computed if the previous grant was not all 0s
      if(|(grant_compute))
        begin
          for(j=0;j<DATA_WIDTH;j=j+1)
            begin
              if(j == DATA_WIDTH-1) 
              	final_grant_compute = final_grant_compute | ({DATA_WIDTH{grant_compute[j]}} & grant_unrotate_vec[0]);  
              else
              	final_grant_compute = final_grant_compute | ({DATA_WIDTH{grant_compute[j]}} & grant_unrotate_vec[j+1]);
            end
        end
      else
        begin
          	final_grant_compute = new_grant_compute; 
        end
  	end
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  always@(posedge clk)
    begin
      if(rst)
        begin
          grant_compute <= {DATA_WIDTH{1'b0}};
        end
      else
        begin
          //compute the new grant as a function of REQ and prev grant
          grant_compute <= final_grant_compute ; 				//check priority set bit from LSB 
        end
    end
  
  assign grant_out = grant_compute; 
  
endmodule
