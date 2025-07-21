`include "defines.sv"
module dcache_loadpipe_l2 #(
    parameter TAG_ARRAY_IDX_HIGH  = 11,
    parameter TAG_ARRAY_IDX_LOW   = 6,
    parameter TAGARRAY_DATA_WIDTH = 44
) (
    input wire clock,    // Clock signal
    input wire reset_n,  // Active low reset
    input wire flush,

    input  wire                froml1_req_valid,
    output wire                froml1_req_ready,
    input  wire [`VADDR_RANGE] froml1_req_vaddr,

    input wire                fromtlb_valid,
    input wire [`PADDR_RANGE] fromtlb_paddr,

    input wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data[`DCACHE_WAY_NUM-1:0],



    output wire                                        tagarray_rd_en,
    output wire [TAG_ARRAY_IDX_HIGH:TAG_ARRAY_IDX_LOW] tagarray_rd_idx

);


    assign tagarray_rd_en  = froml1_req_valid;
    assign tagarray_rd_idx = froml1_req_vaddr[TAG_ARRAY_IDX_HIGH:TAG_ARRAY_IDX_LOW];

endmodule
