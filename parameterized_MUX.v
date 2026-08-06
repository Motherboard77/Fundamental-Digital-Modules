
//Parameterized MUX Design
//INPUTS and sel_lines allocated at compile time
//SEL input bitwidth is computed at compile time, so we can give an arbitrary no, 
//...the tool will automaticaly perform the truncation


module n_inp_mux #(parameter BITWIDTH = 4, INPUTS = 8)(
  
  input [(BITWIDTH*INPUTS)-1:0] mux_inp_vector,
  input [no_of_sel_lines(INPUTS)-1:0] sel,         //process this value from a function in 0-sim time 
  output reg [BITWIDTH-1:0] mux_data_out
);
  
  
  //sel-lines comptute function
  function integer no_of_sel_lines(integer input_lines);		//no_of_sel_lines doubles down as both the return var & the function name 
    
    input_lines = input_lines - 1;    //count starting from 0
    no_of_sel_lines = 0;
    
    while(input_lines > 0)
     begin
       no_of_sel_lines = no_of_sel_lines + 1;
       input_lines = input_lines >> 1; 
     end
    
  endfunction
  
  //MUX selection based on sel val
  always@(*)
    begin
      mux_data_out = mux_inp_vector[(sel*BITWIDTH) +: BITWIDTH]; 
    end
  
endmodule