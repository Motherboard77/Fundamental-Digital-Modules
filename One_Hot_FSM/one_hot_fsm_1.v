

//ONE-HOT FSM solved problem

module one_hot_fsm #(parameter STATES = 5)(
  
  input inp,
  input [STATES-1:0] state_in,
  output [STATES-1:0] state_out,
  
  output z
);
  
  
  //create the one-hot FSM state equations
  assign state_out[0] = (state_in[0] & ~inp) | (state_in[4] & ~inp);
  assign state_out[1] = (state_in[0] & inp) | (state_in[3] & inp);
  assign state_out[2] = (state_in[1] & ~inp) | (state_in[2] & ~inp)  | (state_in[4] & inp);
  assign state_out[3] = (state_in[2] & inp);
  assign state_out[4] = (state_in[1] & inp) | (state_in[3] & ~inp);
  
  
  assign z = (state_in[0] & inp) | (state_in[3] & inp) | (state_in[2] & inp) | (state_in[4] & inp);
  
endmodule