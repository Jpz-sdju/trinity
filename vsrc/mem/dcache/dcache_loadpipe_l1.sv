`include "defines.sv"
module dcache_loadpipe_l1 #(
    parameter TAG_ARRAY_IDX_HIGH = 11,
    parameter TAG_ARRAY_IDX_LOW  = 6
) (
    input wire clock,    // Clock signal
    input wire reset_n,  // Active low reset
    input wire flush,

    input  wire                fromldu_req_valid,
    output wire                fromldu_req_ready,
    input  wire [`VADDR_RANGE] fromldu_req_vaddr,

    output wire                                        tagarray_rd_en,
    output wire [TAG_ARRAY_IDX_HIGH:TAG_ARRAY_IDX_LOW] tagarray_rd_idx

);


    assign tagarray_rd_en  = fromldu_req_valid;
    assign tagarray_rd_idx = fromldu_req_vaddr[TAG_ARRAY_IDX_HIGH:TAG_ARRAY_IDX_LOW];

endmodule
