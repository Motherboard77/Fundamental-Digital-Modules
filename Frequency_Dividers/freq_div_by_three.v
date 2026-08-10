`timescale 1ns / 1ps

module freq_by_three (
    input  wire clk,
    input  wire system_rst,
    output wire  out_freq       // Changed to 'reg' to make it glitch-free
);


    reg rst_sync_reg1;
    reg rst_sync_out;

    always @(posedge clk or posedge system_rst) begin
        if (system_rst) begin
            rst_sync_reg1 <= 1'b1;
            rst_sync_out  <= 1'b1;
        end else begin
            rst_sync_reg1 <= 1'b0;
            rst_sync_out  <= rst_sync_reg1; // Safe synchronized reset output
        end
    end

    reg [1:0] counter;

    always @(posedge clk or posedge rst_sync_out) begin
        if (rst_sync_out) begin
            counter <= 2'b00;
        end else begin
            if (counter == 2'b10) begin
                counter <= 2'b00;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    reg delay_flop;

    always @(negedge clk or posedge rst_sync_out) begin
        if (rst_sync_out) begin
            delay_flop <= 1'b0;
        end else begin
            delay_flop <= counter[1];
        end
    end

    //wire comb_out = counter[1] | delay_flop;
    assign out_freq = counter[1] | delay_flop;

    //always @(posedge clk or posedge rst_sync_out) begin
   //     if (rst_sync_out) begin
    //        out_freq <= 1'b0;
    //    end else begin
    //        out_freq <= comb_out;
    //    end
   // end

endmodule
