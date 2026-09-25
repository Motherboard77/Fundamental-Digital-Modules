
///4-BIT UP-DOWN SYNCHRONOUS COUNTER


module sync_up_down_count #(parameter MOD_VAL = 12, parameter OUTPUT_WIDTH = 4)(
  
  input clk, 
  input en,
  output [OUTPUT_WIDTH-1:0] count_out,
  input dir                                  //control-signal to control UP<->DOWN count
);
  
  //define a register to keep track of count
  reg [OUTPUT_WIDTH-1:0] up_down_count;
  
  always@(posedge clk)
    begin
      
          if(en)					//check the enable status
          	begin
          		//check the "dir" status
          		case(dir)
            	1'b1  : begin
                  		if(up_down_count == MOD_VAL-1)
                    	up_down_count <= 4'b0000;
                  		else
                  		up_down_count <= up_down_count + 1'b1;		//UP COUNT
                		end
            	1'b0    : begin
                  		  if (up_down_count == 4'b0000)
                            up_down_count <= MOD_VAL-1;
                  		  else
                  		  	up_down_count <= up_down_count - 1'b1;		//DOWN COUNT
                		  end
            	default : up_down_count <= up_down_count ;    			//hold 
          		endcase
          	end
          else
            begin
              //hold the value 
              up_down_count <= up_down_count ;
            end
    end
  
  assign count_out = up_down_count ; 
  
endmodule
