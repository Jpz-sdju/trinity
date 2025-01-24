module xbar (
    input wire valid_in,
    input wire ready_out0,
    input wire ready_out1,
    output reg valid_out
);
    always @(*) begin
        valid_out = 'b0;
        if(ready_out0 & ready_out1)begin
            valid_out = valid_in;     
        end
    end
endmodule