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

    input  wire                froml1_req_valid,
    output wire                froml1_req_ready,
    input  wire [`VADDR_RANGE] froml1_req_vaddr,

    input wire                fromtlb_valid,
    input wire [`PADDR_RANGE] fromtlb_paddr,

    input wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data[0:`DCACHE_WAY_NUM-1],



    output wire                           tagarray_rd_en,
    output wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_rd_idx

);

    /* ------------------------- lookup logic (s1)------------------------- */
    reg [`DCACHE_WAY_NUM-1:0] hitway;

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

    wire lookup_hit = |hitway;
    wire lookup_miss = !lookup_hit;

    


endmodule
