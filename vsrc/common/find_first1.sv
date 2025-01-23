module find_first1 #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    wire data_in_is_zero;
    assign data_in_is_zero = (~(|data_in));
    assign data_out        = data_in_is_zero ? 'b1 : data_in & (~(data_in - 1));  // one-hot   

endmodule
