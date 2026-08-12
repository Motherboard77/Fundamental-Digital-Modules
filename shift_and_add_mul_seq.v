
//4-bit multiplier using shift-and-add approach

module mul_shift_add(

  input clk,rst,
  input [3:0] multiplicand,
  input [3:0] multiplier,
  output reg done,
  output [15:0] mul_out
);

  reg [15:0] mul_acc;
  reg [3:0] multiplier_cap;
  reg [3:0] counter;		//no-of-processed-bits counter
  
  parameter IDLE = 2'b00, OP = 2'b01, DONE = 2'b10;
  reg [1:0] state, next_state;
  
  wire [7:0] compute;
  
  assign compute = multiplier_cap[0] ? (multiplicand << counter) : 8'b0;
  
  
  //FSM state calculation
  always@(posedge clk)
    begin
      if(rst)
        begin
          state <= IDLE;
        end
      else 
          state <= next_state;
    end
  
  always@(*)
    begin
      case(state)
        IDLE : next_state = OP;
        OP : begin
          	 next_state = (counter == 4'b0011) ? DONE : OP;
        	 end
        DONE : begin
          			next_state = DONE;
        	   end
      endcase
    end
  
  always@(posedge clk)
    begin
      if(rst)
        begin
          mul_acc <= 8'b0;
          multiplier_cap <= 4'b0;
          counter <= 4'b0;
        end
      else
         begin
           case(state)
             
             IDLE :  //capture the multiplier input
               		begin
                      multiplier_cap <= multiplier;
                    end
             OP :   begin
               			mul_acc <= mul_acc + compute;
               			multiplier_cap <= multiplier_cap >> 1; //shift right by 1 unit
               			counter <= counter + 1'b1;
             		end
             DONE : begin
               			//assert the done signal
               			done <= 1'b1;
             		end
           endcase
         end
    end
  
  assign mul_out = mul_acc; 
  
endmodule