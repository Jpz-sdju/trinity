`include "defines.sv"
module mem_top (
    input wire clock,
    input wire reset_n,

    /* ------------------------------ dispatch sigs ----------------------------- */
    input  wire                   disp2sq_valid,
    input  wire [`ROB_SIZE_LOG:0] disp2sq_robid,
    input  wire [      `PC_RANGE] disp2sq_pc,     //for debug
    output wire                   sq_can_alloc,

    input  wire instr_valid,
    output wire instr_ready,

    input wire [      `PC_RANGE] pc,     //for debug
    input wire [`ROB_SIZE_LOG:0] robid,
    input wire [ `SQ_SIZE_LOG:0] sqid,

    input wire [    `SRC_RANGE] src1,
    input wire [    `SRC_RANGE] src2,
    input wire [   `PREG_RANGE] prd,
    input wire [    `SRC_RANGE] imm,
    input wire                  is_load,
    input wire                  is_store,
    input wire                  is_unsigned,
    input wire [`LS_SIZE_RANGE] ls_size,

    //trinity bus channel
    output reg                  load2arb_tbus_index_valid,
    input  wire                 load2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] load2arb_tbus_index,
    output reg  [   `SRC_RANGE] load2arb_tbus_write_data,
    output reg  [         63:0] load2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] load2arb_tbus_read_data,
    input  wire                      load2arb_tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] load2arb_tbus_operation_type,

    /* --------------------------- output to complete -------------------------- */
    output wire                   sq2rob_cmpl_valid,
    output wire [`ROB_SIZE_LOG:0] sq2rob_cmpl_robid,
    output wire                   sq2rob_cmpl_mmio,



    output wire                   ldu0_cmpl_valid,
    output wire [`ROB_SIZE_LOG:0] ldu0_cmpl_robid,
    output wire                   ldu0_cmpl_mmio,
    output wire [   `INSTR_RANGE] ldu0_cmpl_instr,  //for debug
    output wire [      `PC_RANGE] ldu0_cmpl_pc,     //for debug


    output wire                 ldu0_wb_valid,
    output wire [`RESULT_RANGE] ldu0_wb_load_data,
    output wire [  `PREG_RANGE] ldu0_wb_prd,



    /* -------------------------- redirect flush logic -------------------------- */
    input wire                   flush_valid,
    input wire [`ROB_SIZE_LOG:0] flush_robid,

    /* --------------------------- mem_top to dcache --------------------------- */
    output wire                        load2arb_flush_valid,          // use to flush dcache process
    /* --------------------------- SQ forwarding query -------------------------- */
    output wire                        ldu2sq_forward_req_valid,
    output wire [     `ROB_SIZE_LOG:0] ldu2sq_forward_req_sqid,
    output wire [`STOREQUEUE_SIZE-1:0] ldu2sq_forward_req_sqmask,
    output wire [          `SRC_RANGE] ldu2sq_forward_req_load_addr,
    output wire [      `LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    input  wire                        ldu2sq_forward_resp_valid,
    input  wire [          `SRC_RANGE] ldu2sq_forward_resp_data,
    input  wire [          `SRC_RANGE] ldu2sq_forward_resp_mask,


    /* --------------------------------- commit --------------------------------- */
    input wire                   commit0_valid,
    input wire [`ROB_SIZE_LOG:0] commit0_robid,

    input wire                   commit1_valid,
    input wire [`ROB_SIZE_LOG:0] commit1_robid
);

    wire                  st_agu0_cmpl_valid;
    wire [`SQ_SIZE_LOG:0] st_agu0_cmpl_sqid;
    wire                  st_agu0_cmpl_mmio;
    wire [    `SRC_RANGE] st_agu0_cmpl_addr;
    wire [    `SRC_RANGE] st_agu0_cmpl_mask;
    wire [           3:0] st_agu0_cmpl_size;

    wire                  st_dgu0_cmpl_valid;
    wire [`SQ_SIZE_LOG:0] st_dgu0_cmpl_sqid;
    wire [    `SRC_RANGE] st_dgu0_cmpl_data;

    /* -------------------------------------------------------------------------- */
    /*                                 output logic                               */
    /* -------------------------------------------------------------------------- */

    assign ldu0_cmpl_valid   = ldu_out_instr_valid;
    assign ldu0_cmpl_mmio    = ldu_out_mmio;
    assign ldu0_cmpl_robid   = ldu_out_robid;


    assign ldu0_wb_valid = ldu0_wb_valid ;
    assign ldu0_wb_load_data = ldu_out_load_data;
    assign ldu0_wb_prd       = ldu_out_prd;


    /* -------------------------------------------------------------------------- */
    /*                                  load unit                                 */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- output to writeback -------------------------- */
    wire                   ldu_out_instr_valid;
    wire                   ldu_out_need_to_wb;
    wire [    `PREG_RANGE] ldu_out_prd;
    wire [`ROB_SIZE_LOG:0] ldu_out_robid;
    wire [      `PC_RANGE] ldu_out_pc;
    wire [  `RESULT_RANGE] ldu_out_load_data;

    wire                   flush_this_beat;
    assign flush_this_beat = instr_valid & instr_ready & flush_valid & ((flush_robid[`ROB_SIZE_LOG] ^ robid[`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] < robid[`ROB_SIZE_LOG-1:0]));


    loadunit u_loadunit (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .flush_this_beat             (flush_this_beat),
        .instr_valid                 (instr_valid & is_load ),
        .pc                          (pc),
        .instr_ready                 (instr_ready),
        .prd                         (prd),
        .is_load                     (is_load),
        .is_unsigned                 (is_unsigned),
        .imm                         (imm),
        .src1                        (src1),
        .src2                        (src2),
        .ls_size                     (ls_size),
        .robid                       (robid),
        .sqid                        (sqid),
        .load2arb_tbus_index_valid   (load2arb_tbus_index_valid),
        .load2arb_tbus_index_ready   (load2arb_tbus_index_ready),
        .load2arb_tbus_index         (load2arb_tbus_index),
        .load2arb_tbus_write_data    (load2arb_tbus_write_data),
        .load2arb_tbus_write_mask    (load2arb_tbus_write_mask),
        .load2arb_tbus_read_data     (load2arb_tbus_read_data),
        .load2arb_tbus_operation_done(load2arb_tbus_operation_done),
        .load2arb_tbus_operation_type(load2arb_tbus_operation_type),
        .flush_valid                 (flush_valid),
        .flush_robid                 (flush_robid),
        .load2arb_flush_valid        (load2arb_flush_valid),
        .ldu_out_instr_valid         (ldu_out_instr_valid),
        .ldu_out_need_to_wb          (ldu_out_need_to_wb),
        .ldu_out_prd                 (ldu_out_prd),
        .ldu_out_robid               (ldu_out_robid),
        .ldu_out_pc                  (ldu_out_pc),
        .ldu_out_load_data           (ldu_out_load_data),
        /* --------------------------------- forward -------------------------------- */
        .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
        .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
        .ldu2sq_forward_req_sqmask   (ldu2sq_forward_req_sqmask),
        .ldu2sq_forward_req_load_addr(ldu2sq_forward_req_load_addr),
        .ldu2sq_forward_req_load_size(ldu2sq_forward_req_load_size),
        .ldu2sq_forward_resp_valid   (ldu2sq_forward_resp_valid),
        .ldu2sq_forward_resp_data    (ldu2sq_forward_resp_data),
        .ldu2sq_forward_resp_mask    (ldu2sq_forward_resp_mask)
    );





    /* -------------------------------------------------------------------------- */
    /*                             store queue region                             */
    /* -------------------------------------------------------------------------- */


    storequeue u_storequeue (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .disp2sq_valid               (disp2sq_valid),
        .sq_can_alloc                (sq_can_alloc),
        .disp2sq_robid               (disp2sq_robid),
        .disp2sq_pc                  (disp2sq_pc),
        .st_agu0_cmpl_valid          (st_agu0_cmpl_valid),
        .st_agu0_cmpl_mmio           (st_agu0_cmpl_mmio),
        .st_agu0_cmpl_addr           (st_agu0_cmpl_addr),
        .st_agu0_cmpl_mask           (st_agu0_cmpl_mask),
        .st_agu0_cmpl_size           (st_agu0_cmpl_size),
        .st_dgu0_cmpl_valid          (st_dgu0_cmpl_valid),
        .st_dgu0_cmpl_data           (st_dgu0_cmpl_data),
        .commit0_valid               (commit0_valid),
        .commit0_robid               (commit0_robid),
        .commit1_valid               (commit1_valid),
        .commit1_robid               (commit1_robid),
        .flush_valid                 (flush_valid),
        .flush_robid                 (flush_robid),
        .flush_sqid                  (flush_sqid),
        .sq2arb_tbus_index_valid     (sq2arb_tbus_index_valid),
        .sq2arb_tbus_index_ready     (sq2arb_tbus_index_ready),
        .sq2arb_tbus_index           (sq2arb_tbus_index),
        .sq2arb_tbus_write_data      (sq2arb_tbus_write_data),
        .sq2arb_tbus_write_mask      (sq2arb_tbus_write_mask),
        .sq2arb_tbus_read_data       (sq2arb_tbus_read_data),
        .sq2arb_tbus_operation_type  (sq2arb_tbus_operation_type),
        .sq2arb_tbus_operation_done  (sq2arb_tbus_operation_done),
        .sq2disp_sqid                (sq2disp_sqid),
        .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
        .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
        .ldu2sq_forward_req_sqmask   (ldu2sq_forward_req_sqmask),
        .ldu2sq_forward_req_load_addr(ldu2sq_forward_req_load_addr),
        .ldu2sq_forward_req_load_size(ldu2sq_forward_req_load_size),
        .ldu2sq_forward_resp_valid   (ldu2sq_forward_resp_valid),
        .ldu2sq_forward_resp_data    (ldu2sq_forward_resp_data),
        .ldu2sq_forward_resp_mask    (ldu2sq_forward_resp_mask)
    );

endmodule
