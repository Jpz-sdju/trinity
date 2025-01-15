module agu (
    input  wire [   `SRC_RANGE] src1,
    // input wire [`SRC_RANGE] src2,
    input  wire [   `SRC_RANGE] imm,
    //input wire is_load,
    //input wire is_store,
    output wire [`RESULT_RANGE] ls_address
);
    wire [`RESULT_RANGE] sum = src1 + imm;
    assign ls_address[`RESULT_RANGE] = sum[`RESULT_WIDTH-1:0];
endmodule
