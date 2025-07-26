`include "defines.sv"
module dcache_loadpipe_l2 #(
    parameter TAG_ARRAY_IDX_HIGH  = 11,
    parameter TAG_ARRAY_IDX_LOW   = 6,
    parameter TAGARRAY_ADDR_WIDTH = 6,
    parameter TAGARRAY_DATA_WIDTH = 27
) (
    input wire clock,    // Clock signal
    input wire reset_n,  // Active low reset
    input wire flush,

    input  wire                   froml1_req_valid,
    output wire                   froml1_req_ready,
    input  wire [   `VADDR_RANGE] froml1_req_vaddr,
    input  wire [`ROB_SIZE_LOG:0] froml1_req_robid,
    // input  wire [`SQ_SIZE_LOG:0] froml1_req_sqid,


    input wire                fromtlb_valid,
    input wire                fromtlb_hit,
    input wire [`PADDR_RANGE] fromtlb_paddr,

    input wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data[0:`DCACHE_WAY_NUM-1],



    output wire                   mshr_allocate_valid,
    input  wire                   mshr_allocate_ready,
    output wire [   `PADDR_RANGE] mshr_allocate_paddr,
    output wire [`ROB_SIZE_LOG:0] mshr_allocate_robid

);

    /* ------------------------- lookup logic (s1)------------------------- */
    reg [`DCACHE_WAY_NUM-1:0] hitway;
    //means we lookup hit or miss is valid.
    wire froml1_is_valid;
    assign froml1_is_valid = froml1_req_valid & fromtlb_valid & fromtlb_hit;

    always @(*) begin
        integer i;
        hitway = 0;
        for (i = 0; i < `TAGRAM_WAYNUM; i = i + 1) begin
            if ((tagarray_rd_data[i][`DCACHE_TAGARRAY_TAG_RANGE] == fromtlb_paddr[38:12]) && tagarray_rd_data[i][`DCACHE_TAGARRAY_VALID_RANGE]) begin
                hitway[i] = 1'b1;
                break;
            end else begin
                hitway[i] = 1'b0;
            end
        end
    end

    wire lookup_hit = |hitway & froml1_is_valid;
    wire lookup_miss = !lookup_hit & froml1_is_valid;


    //Only when we have paddr,we should allocate MSHR.
    assign mshr_allocate_valid = lookup_miss ;


endmodule
