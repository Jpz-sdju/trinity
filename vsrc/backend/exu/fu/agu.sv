module agu (
    input wire [`SRC_RANGE] src1,
    // input wire [`SRC_RANGE] src2,
    input wire [`SRC_RANGE] imm,
    //input wire is_load,
    //input wire is_store,
    output wire [`VADDR_RANGE] ls_address
);
    wire [`VADDR_RANGE] sum = src1 + imm;
    assign ls_address[`VADDR_RANGE] =  sum[`VADDR_RANGE];
endmodule