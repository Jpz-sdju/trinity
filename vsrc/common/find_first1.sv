module find_first1 #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
 
assign data_out = data_in & (~(data_in - 1)); // one-hot   
 
endmodule