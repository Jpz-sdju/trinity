 
module find_first1_base #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    input  [WIDTH-1:0] base,
    output [WIDTH-1:0] data_out
);
wire [2*WIDTH-1:0] double_in;
wire [2*WIDTH-1:0] double_out;


// wire data_in_is_zero ;
// assign data_in_is_zero= (~(|data_in));
assign double_in  = {data_in, data_in};
assign double_out = double_in & (~(double_in - base));
assign data_out   = (double_out[2*WIDTH-1:WIDTH] | double_out[WIDTH-1:0]); // one-hot   
endmodule