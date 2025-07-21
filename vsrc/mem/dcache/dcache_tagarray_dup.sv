
`include "defines.sv"
// dcache_tagarray Module
module dcache_tagarray_dup #(
    parameter DATA_WIDTH = 38,  // Width of data
    parameter ADDR_WIDTH = 9    // Width of address bus (512 sets => 9 bits)
) (

    input  wire                       clock,            // Clock signal
    input  wire                       reset_n,          // Active low reset
    input  wire                       readport_rd_en,
    input  wire [`DCACHE_WAY_NUM-1:0] readport_rd_way,
    input  wire [     ADDR_WIDTH-1:0] readport_rd_idx,
    output wire [     DATA_WIDTH-1:0] readport_rd_data,


    input wire                       writeport_wr_en,
    input wire [`DCACHE_WAY_NUM-1:0] writeport_wr_way,
    input wire [     ADDR_WIDTH-1:0] writeport_wr_idx,
    input wire [     DATA_WIDTH-1:0] writeport_wr_data



);

    genvar i;

    generate
        for (i = 0; i < `DCACHE_WAY_NUM; i = i + 1) begin

            // Instantiate a single WAY for the dcache_tagarray
            sram #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) sram_inst_ways (
                .clock  (clock),
                .reset_n(reset_n),
                .ce     (ce),
                .we     (we),
                .waddr  (waddr),
                .raddr  (raddr),
                .din    (din),
                .wmask  (wmask),
                .dout   (dout)
            );

        end
    endgenerate



endmodule
