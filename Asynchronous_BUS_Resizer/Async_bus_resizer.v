
module bus_resizer #(parameter inp_dat_width = 8, parameter WORD_SIZE = 4, parameter out_dat_width = (WORD_SIZE*inp_dat_width))(
					
  input [inp_dat_width-1:0] data_in,
  input clk_dom1,clk_dom2,
  input rst1,rst2,
  output [out_dat_width-1:0] data_out
);  
  
  //data-input register 
  //reg [inp_dat_width-1:0] data_in_reg;
  
  //word-growth counter 
  reg [1:0] cnt_check;
  
  //data-growth register array
  reg [WORD_SIZE*inp_dat_width-1:0] inp_loader ; //driven by clock-domain-1
  
  //intermediate data-loaded storage
  wire [WORD_SIZE*inp_dat_width-1:0] inp_loader_cap ;
    
  //2-stage data-receiver at CLOCK-DOMAIN-2
  reg [WORD_SIZE*inp_dat_width-1:0] out_loader_stage1, out_loader_stage2 ;  //driven by clock-domain-2
  
  //domain-bypass enables : enables-disables the FF drivers on either domains depending on whether the data is latched or pending
  //for instance, in domain-1, once the 4W is loaded, this info must be communicated to domain-2, and simulteneously domain-1 is kept at HOLD
  //once domain-2 acknoledges the LOAD-done signal from DOMAIN-1, it asserts the enable to its clock domain, to latch-in the data, and simultaneously 
  //communicate to domain-1, the data is "taken" into domain-2
  
  //enable registers
  reg domain_one_req;   //depend on the ACK from domain-2, initially set to 1 upon reset
  reg domain_two_ack;   //depend on the counter val (LOAD =11) from domain-1, initially set to 1 upon reset
  
  //cross-domain enable-signal synchronizer
  reg req_dom1_to_dom2_ff1,req_dom1_to_dom2_ff2;
  reg ack_dom2_to_dom1_ff1,ack_dom2_to_dom1_ff2;
  
  
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  //Synchronize the ACK singal into the DOMAIN-1, driven by the clk_dom1 signal
  always@(posedge clk_dom1 or posedge rst1)
    begin
      if(rst1)
        begin
          ack_dom2_to_dom1_ff1 <= 1'b0;
          ack_dom2_to_dom1_ff2 <= 1'b0;
        end
      else
        begin
          ack_dom2_to_dom1_ff1 <= domain_two_ack;
          ack_dom2_to_dom1_ff2 <= ack_dom2_to_dom1_ff1;
        end
    end
 
  //DE-MUX comb logic
  assign inp_loader_cap = data_in << (cnt_check*inp_dat_width); 
  
  ////////////////////////////////////////////DOMAIN-1///////////////////////////////////////
  
  always@(posedge clk_dom1 or posedge rst1)
    begin
      if(rst1)
        begin
          //reset the elements in clock-domain-1
          cnt_check <= 2'b00;
          //data_in_reg <= 0; 
          inp_loader <= 0;  
          domain_one_req <= 1'b0;
        end
      else
        if(!domain_one_req && !ack_dom2_to_dom1_ff2)    //load the data when there is no pending ACK and the req flag is not asserted
      	begin         
          
          	inp_loader <= inp_loader | inp_loader_cap;		//counter based loading, accumulate(bitwise-OR) the values          
          
          if(cnt_check == (WORD_SIZE-1))			
            begin
              	cnt_check <= 2'b00;
                domain_one_req <= 1'b1;					//data-loading complete, assert the req signal to signal to domain-2
            end
          else
            begin
              	cnt_check <= cnt_check + 1'b1;
            end                  
        end
      
      //extra-hanshake protection layer, assert the req to 0, when ack is received, this de-asserted req will go and de-assert the ack, whose value is used to clear the inp_loader
      
      else if(domain_one_req && ack_dom2_to_dom1_ff2)
      begin
        inp_loader <= 0;
        domain_one_req <= 1'b0;
      end
           
      
      //else if (!domain_one_req && !ack_dom2_to_dom1_ff2 && (inp_loader != 0))
     //   begin      		
     //     	inp_loader <= 0;			//clear the word buffer for the next batch
     //   end
    end
  
  
 ////////////////////////////////////////////DOMAIN-2/////////////////////////////////////////////////// 
  
 //synchronize the REQ singal into domain-2
  always@(posedge clk_dom2 or posedge rst2)
    begin
      if(rst2)
        begin
          req_dom1_to_dom2_ff1 <= 1'b0;
          req_dom1_to_dom2_ff2 <= 1'b0;
        end
      else
        begin
          req_dom1_to_dom2_ff1 <= domain_one_req;
          req_dom1_to_dom2_ff2 <= req_dom1_to_dom2_ff1;
        end
    end
  
  
  always@(posedge clk_dom2 or posedge rst2)
    begin
      if(rst2)
        begin
          out_loader_stage1 <= 0;
          out_loader_stage2 <= 0; 
          domain_two_ack <= 1'b0;
        end      
      else
        begin
        	if(!domain_two_ack && req_dom1_to_dom2_ff2)  		//ACK is not set, and REQ is asserted, latch-in the data
          	begin
            	out_loader_stage1 <= inp_loader;				//data is latched-in
            	domain_two_ack <= 1'b1;							//signal domain-1 the data has been latched-in
          	end
      
      		//Handshake-release phase : wait for the request de-assertion from Domain-1
      		else if(!req_dom1_to_dom2_ff2 && domain_two_ack)
        	begin
      			domain_two_ack <= 1'b0;
        	end
          
          	//register the data into stage-2
          	out_loader_stage2 <= out_loader_stage1;
        end     
    end
  
  
	assign data_out = out_loader_stage2; 
 
  
endmodule 