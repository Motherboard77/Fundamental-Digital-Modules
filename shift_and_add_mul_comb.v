

module shift_and_add_mul_comb #(parameter K = 8)(

    input rst,
    input [K-1:0] multiplicand,
    input [K-1:0] multiplier,
    output reg [(2*K)-1:0] mul_out
);

    //pure comnbinational block 
    integer i;

    always@(*)
    begin
        if(rst)
        begin
            mul_out <= 0;
        end

        else
        begin
            for(int i=0; i<K; i = i+1)
            begin
                if(multiplier[i])
                    mul_out = mul_out + (multiplicand << i)
            end
        end
    end

endmodule 