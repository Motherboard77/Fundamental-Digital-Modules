`timescale 1ns / 1ps

module freq_div_by_three_CDC_free(

    input clk,
    input system_rst,
    output wire out_freq
);

    //reset synchronizer
    reg rst_sync_reg1;  //capture the asynchronous reset here first
    reg rst_sync_out;   //sync the above reg to this reg
    
    always@(posedge clk or posedge system_rst)
    begin
        if(system_rst)
        begin
            rst_sync_reg1 <= 1'b1;
            rst_sync_out <= 1'b1;
        end
        else
        begin
            //Synchronous De-assert the reset 
            rst_sync_reg1 <= 1'b0;
            rst_sync_out <= rst_sync_reg1;
        end
    end
    
    reg [1:0] pos_count;
    reg pos_pulse;
    
    always@(posedge clk or posedge rst_sync_out)
    begin
         if(rst_sync_out)
         begin
            pos_count <= 2'b00;
            pos_pulse <= 1'b0;
         end
         else 
            begin
                if(pos_count == 2'b10) 
                begin
                    pos_count <= 2'b00;
                    pos_pulse <= 1'b1;
                end
                else 
                begin
                    pos_count <= pos_count + 1'b1;
                    pos_pulse <= 1'b0;
                end
            end
    end
    
    reg neg_pulse;
    
    always@(negedge clk or posedge rst_sync_out)
    begin
        if(rst_sync_out)
        begin
            neg_pulse <= 1'b0;
        end
        else
        begin
            neg_pulse <= pos_pulse;     //delay the positive pulse by half-clock cycle
        end
    end

    assign out_freq = pos_pulse | neg_pulse ; 

endmodule
