`include "defines.sv"
module dcache_loadpipe #(
    parameter TAG_ARRAY_IDX_HIGH  = 11,
    parameter TAG_ARRAY_IDX_LOW   = 6,
    parameter TAGARRAY_ADDR_WIDTH = 6,
    parameter TAGARRAY_DATA_WIDTH = 29
) (
    input wire clock,    // Clock signal
    input wire reset_n,  // Active low reset
    input wire flush,

    input  wire                   fromldu_req_valid,
    output wire                   fromldu_req_ready,
    input  wire [   `VADDR_RANGE] fromldu_req_vaddr,
    input  wire [`ROB_SIZE_LOG:0] fromldu_req_robid,

    input wire                fromtlb_valid,
    input wire                fromtlb_hit,
    input wire [`PADDR_RANGE] fromtlb_paddr,


    output wire                           tagarray_rd_en,
    output wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_rd_idx,
    input  wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data[0:`DCACHE_WAY_NUM-1]


);
    reg                   ldu_l2_req_valid;
    reg [   `VADDR_RANGE] ldu_l2_req_vaddr;
    reg [`ROB_SIZE_LOG:0] ldu_l2_req_robid;

    dcache_loadpipe_l1 #(
        .TAG_ARRAY_IDX_HIGH (TAG_ARRAY_IDX_HIGH),
        .TAG_ARRAY_IDX_LOW  (TAG_ARRAY_IDX_LOW),
        .TAGARRAY_ADDR_WIDTH(TAGARRAY_ADDR_WIDTH)
    ) u_dcache_loadpipe_l1 (
        .clock            (clock),
        .reset_n          (reset_n),
        .flush            (flush),
        .fromldu_req_valid(fromldu_req_valid),
        .fromldu_req_ready(fromldu_req_ready),
        .fromldu_req_vaddr(fromldu_req_vaddr),
        .tagarray_rd_en   (tagarray_rd_en),
        .tagarray_rd_idx  (tagarray_rd_idx)
    );


    `MACRO_DFF_NONEN(ldu_l2_req_valid, fromldu_req_valid, 1)
    `MACRO_DFF_NONEN(ldu_l2_req_vaddr, fromldu_req_vaddr, `VADDR_LENGTH)
    `MACRO_DFF_NONEN(ldu_l2_req_robid, fromldu_req_robid, `ROB_SIZE_LOG + 1)

    dcache_loadpipe_l2 #(
        .TAG_ARRAY_IDX_HIGH (TAG_ARRAY_IDX_HIGH),
        .TAG_ARRAY_IDX_LOW  (TAG_ARRAY_IDX_LOW),
        .TAGARRAY_ADDR_WIDTH(TAGARRAY_ADDR_WIDTH),
        .TAGARRAY_DATA_WIDTH(TAGARRAY_DATA_WIDTH)
    ) u_dcache_loadpipe_l2 (
        .clock              (clock),
        .reset_n            (reset_n),
        .flush              (flush),
        .froml1_req_valid   (ldu_l2_req_valid),
        .froml1_req_ready   (),
        .froml1_req_vaddr   (ldu_l2_req_vaddr),
        .froml1_req_robid   (ldu_l2_req_robid),
        .fromtlb_valid      (ldu_l2_tlbresp_valid),
        .fromtlb_hit        (),
        .fromtlb_paddr      (ldu_l2_tlbresp_paddr),
        .tagarray_rd_data   (tagarray_rd_data),
        .mshr_allocate_valid(ldu_l2_allocate_mshr_valid),
        .mshr_allocate_ready(ldu_l2_allocate_mshr_ready),
        .mshr_allocate_paddr(ldu_l2_allocate_mshr_paddr),
        .mshr_allocate_robid(ldu_l2_allocate_mshr_robid)
    );


endmodule
