`include "defines.sv"
module memblock (
    input  wire                     clock,
    input  wire                     reset_n,
    input  wire                     instr_valid,
    output wire                     instr_ready,
    input  wire [      `PREG_RANGE] prd,
    input  wire                     is_load,
    input  wire                     is_store,
    input  wire                     is_unsigned,
    input  wire [       `SRC_RANGE] imm,
    input  wire [       `SRC_RANGE] src1,
    input  wire [       `SRC_RANGE] src2,
    input  wire [   `LS_SIZE_RANGE] ls_size,
    input  wire                     robidx_flag,
    input  wire [`ROB_SIZE_LOG-1:0] robidx,

    //trinity bus channel
    output reg                  lsu2arb_tbus_index_valid,
    input  wire                 lsu2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] lsu2arb_tbus_index,
    output reg  [   `SRC_RANGE] lsu2arb_tbus_write_data,
    output reg  [         63:0] lsu2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] lsu2arb_tbus_read_data,
    input  wire                      lsu2arb_tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] lsu2arb_tbus_operation_type,

    /* --------------------------- output to writeback -------------------------- */
    output wire               memblock_out_instr_valid,
    output wire               memblock_out_need_to_wb,
    output wire [`PREG_RANGE] memblock_out_prd,
    output wire               memblock_out_mmio,

    output wire                     memblock_out_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] memblock_out_robidx,

    output wire [       `SRC_RANGE] memblock_out_store_addr,
    output wire [       `SRC_RANGE] memblock_out_store_data,
    output wire [       `SRC_RANGE] memblock_out_store_mask,
    output wire [              3:0] memblock_out_store_ls_size,
    output wire [    `RESULT_RANGE] memblock_out_load_data,
    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                     flush_valid,
    input  wire                     flush_robidx_flag,
    input  wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    /* --------------------------- memblock to dcache --------------------------- */
    output wire memblock2dcache_flush
);
    wire [`RESULT_RANGE] ls_address;
    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );
    /* -------------------------------------------------------------------------- */
    /*                            store signal generate                            */
    /* -------------------------------------------------------------------------- */

    wire size_1b;
    wire size_1h;
    wire size_1w;
    wire size_2w;
    assign size_1b = ls_size[0];
    assign size_1h = ls_size[1];
    assign size_1w = ls_size[2];
    assign size_2w = ls_size[3];
    wire [          2:0] shift_size;
    wire [         63:0] opstore_write_mask_qual;
    wire [`RESULT_RANGE] opstore_write_data_qual;

    wire [         63:0] write_1b_mask = {56'b0, {8{1'b1}}};
    wire [         63:0] write_1h_mask = {48'b0, {16{1'b1}}};
    wire [         63:0] write_1w_mask = {32'b0, {32{1'b1}}};
    wire [         63:0] write_2w_mask = {64{1'b1}};

    assign shift_size              = ls_address[2:0];
    assign opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;
    assign opstore_write_data_qual = src2 << (shift_size * 8);


    /* -------------------------------------------------------------------------- */
    /*                                 output logic                               */
    /* -------------------------------------------------------------------------- */
    wire mmio_valid;
    wire mmio_valid_or_store;
    assign mmio_valid                 = instr_valid & instr_ready & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);
    assign mmio_valid_or_store        = mmio_valid | is_store & instr_ready & instr_valid;

    assign memblock_out_store_addr    = ls_address;
    assign memblock_out_store_data    = opstore_write_data_qual;
    assign memblock_out_store_mask    = opstore_write_mask_qual;
    assign memblock_out_store_ls_size = ls_size;

    assign memblock_out_instr_valid   = flush_this_beat ? 1'b0 : mmio_valid_or_store ? 1'b1 : ldu_out_instr_valid;
    assign memblock_out_need_to_wb    = mmio_valid_or_store ? is_load : ldu_out_need_to_wb;
    assign memblock_out_prd           = mmio_valid_or_store ? prd : ldu_out_prd;
    assign memblock_out_mmio          = mmio_valid;
    assign memblock_out_robidx_flag   = mmio_valid_or_store ? robidx_flag : ldu_out_robidx_flag;
    assign memblock_out_robidx        = mmio_valid_or_store ? robidx : ldu_out_robidx;
    assign memblock_out_load_data     = mmio_valid_or_store ? 'b0 : ldu_out_load_data;


    /* -------------------------------------------------------------------------- */
    /*                                  load unit                                 */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- output to writeback -------------------------- */
    wire                     ldu_out_instr_valid;
    wire                     ldu_out_need_to_wb;
    wire [      `PREG_RANGE] ldu_out_prd;
    wire                     ldu_out_robidx_flag;
    wire [`ROB_SIZE_LOG-1:0] ldu_out_robidx;
    wire [    `RESULT_RANGE] ldu_out_load_data;

    wire                     flush_this_beat;
    assign flush_this_beat = instr_valid & flush_valid & ((flush_robidx_flag ^ robidx_flag) ^ (flush_robidx < robidx));


    loadunit u_loadunit (
        .clock                      (clock),
        .reset_n                    (reset_n),
        .flush_this_beat            (flush_this_beat),
        .instr_valid                (instr_valid & is_load & ~mmio_valid),
        .instr_ready                (instr_ready),
        .prd                        (prd),
        .is_load                    (is_load),
        .is_unsigned                (is_unsigned),
        .imm                        (imm),
        .src1                       (src1),
        .src2                       (src2),
        .ls_size                    (ls_size),
        .robidx_flag                (robidx_flag),
        .robidx                     (robidx),
        .lsu2arb_tbus_index_valid   (lsu2arb_tbus_index_valid),
        .lsu2arb_tbus_index_ready   (lsu2arb_tbus_index_ready),
        .lsu2arb_tbus_index         (lsu2arb_tbus_index),
        .lsu2arb_tbus_write_data    (lsu2arb_tbus_write_data),
        .lsu2arb_tbus_write_mask    (lsu2arb_tbus_write_mask),
        .lsu2arb_tbus_read_data     (lsu2arb_tbus_read_data),
        .lsu2arb_tbus_operation_done(lsu2arb_tbus_operation_done),
        .lsu2arb_tbus_operation_type(lsu2arb_tbus_operation_type),
        .flush_valid                (flush_valid),
        .flush_robidx_flag          (flush_robidx_flag),
        .flush_robidx               (flush_robidx),
        .memblock2dcache_flush      (memblock2dcache_flush),
        .ldu_out_instr_valid        (ldu_out_instr_valid),
        .ldu_out_need_to_wb         (ldu_out_need_to_wb),
        .ldu_out_prd                (ldu_out_prd),
        .ldu_out_robidx_flag        (ldu_out_robidx_flag),
        .ldu_out_robidx             (ldu_out_robidx),
        .ldu_out_load_data          (ldu_out_load_data)
    );

endmodule
