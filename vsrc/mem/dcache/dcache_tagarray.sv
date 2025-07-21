
`include "defines.sv"
// dcache_tagarray Module
module dcache_tagarray #(
    parameter DATA_WIDTH = 44,  // Width of data
    parameter ADDR_WIDTH = 6    // Width of address bus (512 sets => 9 bits)
) (


    input  wire                       clock,             // Clock signal
    input  wire                       reset_n,           // Active low reset
    input  wire                       readport0_rd_en,
    input  wire [`DCACHE_WAY_NUM-1:0] readport0_rd_way,
    input  wire [     ADDR_WIDTH-1:0] readport0_rd_idx,
    output wire [     DATA_WIDTH-1:0] readport0_rd_data,

    input  wire                       readport1_rd_en,
    input  wire [`DCACHE_WAY_NUM-1:0] readport1_rd_way,
    input  wire [     ADDR_WIDTH-1:0] readport1_rd_idx,
    output wire [     DATA_WIDTH-1:0] readport1_rd_data,

    input  wire                       readport2_rd_en,
    input  wire [`DCACHE_WAY_NUM-1:0] readport2_rd_way,
    input  wire [     ADDR_WIDTH-1:0] readport2_rd_idx,
    output wire [     DATA_WIDTH-1:0] readport2_rd_data,


    input wire                       writeport_wr_en,
    input wire [`DCACHE_WAY_NUM-1:0] writeport_wr_way,
    input wire [     ADDR_WIDTH-1:0] writeport_wr_idx,
    input wire [     DATA_WIDTH-1:0] writeport_wr_data

);

    dcache_tagarray_dup #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dcache_tagarray_dup0 (
        .clock            (clock),
        .reset_n          (reset_n),
        .readport_rd_en   (readport0_rd_en),
        .readport_rd_way  (readport0_rd_way),
        .readport_rd_idx  (readport0_rd_idx),
        .readport_rd_data (readport0_rd_data),
        .writeport_wr_en  (writeport_wr_en),
        .writeport_wr_way (writeport_wr_way),
        .writeport_wr_idx (writeport_wr_idx),
        .writeport_wr_data(writeport_wr_data)
    );

    dcache_tagarray_dup #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dcache_tagarray_dup1 (
        .clock            (clock),
        .reset_n          (reset_n),
        .readport_rd_en   (readport1_rd_en),
        .readport_rd_way  (readport1_rd_way),
        .readport_rd_idx  (readport1_rd_idx),
        .readport_rd_data (readport1_rd_data),
        .writeport_wr_en  (writeport_wr_en),
        .writeport_wr_way (writeport_wr_way),
        .writeport_wr_idx (writeport_wr_idx),
        .writeport_wr_data(writeport_wr_data)
    );
    
    dcache_tagarray_dup #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_dcache_tagarray_dup2 (
        .clock            (clock),
        .reset_n          (reset_n),
        .readport_rd_en   (readport2_rd_en),
        .readport_rd_way  (readport2_rd_way),
        .readport_rd_idx  (readport2_rd_idx),
        .readport_rd_data (readport2_rd_data),
        .writeport_wr_en  (writeport_wr_en),
        .writeport_wr_way (writeport_wr_way),
        .writeport_wr_idx (writeport_wr_idx),
        .writeport_wr_data(writeport_wr_data)
    );


endmodule
