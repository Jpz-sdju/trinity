`include "defines.sv"
module mem_top (
    input wire clock,
    input wire reset_n,

    /* ------------------------------ dispatch sigs ----------------------------- */
    input  wire                   disp2sq_valid,
    input  wire [`ROB_SIZE_LOG:0] disp2sq_robid,
    input  wire [      `PC_RANGE] disp2sq_pc,     //for debug
    output wire                   sq_can_alloc,
    output wire [ `SQ_SIZE_LOG:0] sq_enqptr,


    input  wire                   issue_st0_valid,
    output wire                   issue_st0_ready,
    input  wire [      `PC_RANGE] issue_st0_pc,           //for debug
    input  wire [`ROB_SIZE_LOG:0] issue_st0_robid,
    input  wire [ `SQ_SIZE_LOG:0] issue_st0_sqid,
    input  wire [     `SRC_RANGE] issue_st0_src1,
    input  wire [     `SRC_RANGE] issue_st0_src2,
    input  wire [    `PREG_RANGE] issue_st0_prd,
    input  wire [     `SRC_RANGE] issue_st0_imm,
    input  wire                   issue_st0_is_load,
    input  wire                   issue_st0_is_store,
    input  wire                   issue_st0_is_unsigned,
    input  wire [ `LS_SIZE_RANGE] issue_st0_ls_size,


    input  wire                   issue_load0_valid,
    output wire                   issue_load0_ready,
    input  wire [      `PC_RANGE] issue_load0_pc,           //for debug
    input  wire [`ROB_SIZE_LOG:0] issue_load0_robid,
    input  wire [ `SQ_SIZE_LOG:0] issue_load0_sqid,
    input  wire [     `SRC_RANGE] issue_load0_src1,
    input  wire [     `SRC_RANGE] issue_load0_src2,
    input  wire [    `PREG_RANGE] issue_load0_prd,
    input  wire [     `SRC_RANGE] issue_load0_imm,
    input  wire                   issue_load0_is_load,
    input  wire                   issue_load0_is_store,
    input  wire                   issue_load0_is_unsigned,
    input  wire [ `LS_SIZE_RANGE] issue_load0_ls_size,



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
    output wire load2arb_flush_valid,  // use to flush dcache process

    /* --------------------------------- commit --------------------------------- */
    input wire                   commit0_valid,
    input wire [`ROB_SIZE_LOG:0] commit0_robid,

    input wire                   commit1_valid,
    input wire [`ROB_SIZE_LOG:0] commit1_robid,

    /* ---------------------- dcache to arb to memory or l2 --------------------- */

    output wire                       dcache2arb_dbus_index_valid,
    output wire                       dcache2arb_dbus_index_ready,
    output wire [      `RESULT_RANGE] dcache2arb_dbus_index,
    output wire [`CACHELINE512_RANGE] dcache2arb_dbus_write_data,
    output wire [`CACHELINE512_RANGE] dcache2arb_dbus_read_data,
    output wire                       dcache2arb_dbus_operation_done,
    output wire [ `TBUS_OPTYPE_RANGE] dcache2arb_dbus_operation_type,
    output wire                       dcache2arb_dbus_burst_mode
);

    /* --------------------------- SQ forwarding query -------------------------- */
    wire                        ldu2sq_forward_req_valid;
    wire [     `ROB_SIZE_LOG:0] ldu2sq_forward_req_sqid;
    wire [`STOREQUEUE_SIZE-1:0] ldu2sq_forward_req_sqmask;
    wire [          `SRC_RANGE] ldu2sq_forward_req_load_addr;
    wire [      `LS_SIZE_RANGE] ldu2sq_forward_req_load_size;
    wire                        ldu2sq_forward_resp_valid;
    wire [          `SRC_RANGE] ldu2sq_forward_resp_data;
    wire [          `SRC_RANGE] ldu2sq_forward_resp_mask;




    wire                        st_agu0_cmpl_valid;
    wire [      `SQ_SIZE_LOG:0] st_agu0_cmpl_sqid;
    wire                        st_agu0_cmpl_mmio;
    wire [          `SRC_RANGE] st_agu0_cmpl_addr;
    wire [          `SRC_RANGE] st_agu0_cmpl_mask;
    wire [                 3:0] st_agu0_cmpl_size;
    wire                        st_dgu0_cmpl_valid;
    wire [      `SQ_SIZE_LOG:0] st_dgu0_cmpl_sqid;
    wire [          `SRC_RANGE] st_dgu0_cmpl_data;

    wire                        ldu_out_instr_valid;
    wire [         `PREG_RANGE] ldu_out_prd;
    wire [     `ROB_SIZE_LOG:0] ldu_out_robid;
    wire [           `PC_RANGE] ldu_out_pc;
    wire [       `RESULT_RANGE] ldu_out_load_data;



    //SQ bus channel : from SQ
    wire                        sq2arb_tbus_index_valid;
    wire                        sq2arb_tbus_index_ready;
    wire [       `RESULT_RANGE] sq2arb_tbus_index;
    wire [                63:0] sq2arb_tbus_write_data;
    wire [                63:0] sq2arb_tbus_write_mask;
    wire [                63:0] sq2arb_tbus_read_data;
    wire                        sq2arb_tbus_operation_done;
    wire [  `TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type;


    // LOADUNIT bus Channel Inputs and Outputs : from lsu
    wire                        load2arb_tbus_index_valid;  // Valid signal for load2arb_tbus_index
    wire [                63:0] load2arb_tbus_index;  // 64-bit input for load2arb_tbus_index (Channel 1)
    wire                        load2arb_tbus_index_ready;  // Ready signal for LSU channel
    wire [                63:0] load2arb_tbus_read_data;  // Output burst read data for LSU channel
    wire                        load2arb_tbus_operation_done;
    wire [  `TBUS_OPTYPE_RANGE] load2arb_tbus_operation_type;

    reg  [          `SRC_RANGE] load2arb_tbus_write_data;
    reg  [                63:0] load2arb_tbus_write_mask;

    //trinity bus channel:lsu to dcache
    wire                        tbus_index_valid;
    wire                        tbus_index_ready;
    wire [       `RESULT_RANGE] tbus_index;
    wire [          `SRC_RANGE] tbus_write_data;
    wire [                63:0] tbus_write_mask;
    wire [       `RESULT_RANGE] tbus_read_data;
    wire [  `TBUS_OPTYPE_RANGE] tbus_operation_type;
    wire                        tbus_operation_done;


    /* -------------------------------------------------------------------------- */
    /*                                  store unit                                */
    /* -------------------------------------------------------------------------- */

    storeunit u_storeunit (
        .clock            (clock),
        .reset_n          (reset_n),
        .issue_valid      (issue_st0_valid),
        .issue_ready      (issue_st0_ready),
        .robid            (issue_st0_robid),
        .sqid             (issue_st0_sqid),
        .src1             (issue_st0_src1),
        .src2             (issue_st0_src2),
        .imm              (issue_st0_imm),
        .ls_size          (issue_st0_ls_size),
        .st_agu_cmpl_valid(st_agu0_cmpl_valid),
        .st_agu_cmpl_sqid (st_agu0_cmpl_sqid),
        .st_agu_cmpl_mmio (st_agu0_cmpl_mmio),
        .st_agu_cmpl_addr (st_agu0_cmpl_addr),
        .st_agu_cmpl_size (st_agu0_cmpl_size),
        .st_agu_cmpl_mask (st_agu0_cmpl_mask),
        .st_dgu_cmpl_valid(st_dgu0_cmpl_valid),
        .st_dgu_cmpl_data (st_dgu0_cmpl_data),
        .flush_valid      (flush_valid),
        .flush_robid      (flush_robid)
    );



    /* -------------------------------------------------------------------------- */
    /*                                  load unit                                 */
    /* -------------------------------------------------------------------------- */

    /* ------------------------------ output logic ------------------------------ */

    assign ldu0_cmpl_valid   = ldu_out_instr_valid;
    assign ldu0_cmpl_mmio    = ldu_out_mmio;
    assign ldu0_cmpl_robid   = ldu_out_robid;


    assign ldu0_wb_valid     = ldu_out_instr_valid;
    assign ldu0_wb_load_data = ldu_out_load_data;
    assign ldu0_wb_prd       = ldu_out_prd;



    wire flush_this_beat;
    assign flush_this_beat = (issue_st0_valid | issue_load0_valid) & flush_valid & ((flush_robid[`ROB_SIZE_LOG] ^ issue_load0_robid[`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] < issue_load0_robid[`ROB_SIZE_LOG-1:0]));


    loadunit u_loadunit (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .instr_valid                 (issue_load0_valid & !flush_this_beat),
        .pc                          (issue_load0_pc),
        .instr_ready                 (issue_load0_ready),
        .prd                         (issue_load0_prd),
        .is_load                     (issue_load0_is_load),
        .is_unsigned                 (issue_load0_is_unsigned),
        .imm                         (issue_load0_imm),
        .src1                        (issue_load0_src1),
        .src2                        (issue_load0_src2),
        .ls_size                     (issue_load0_ls_size),
        .robid                       (issue_load0_robid),
        .sqid                        (issue_load0_sqid),
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
        .ldu_out_prd                 (ldu_out_prd),
        .ldu_out_robid               (ldu_out_robid),
        .ldu_out_pc                  (ldu_out_pc),
        .ldu_out_load_data           (ldu_out_load_data),
        /* --------------------------------- forward -------------------------------- */
        .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
        .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
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
        .st_agu0_cmpl_sqid           (st_agu0_cmpl_sqid),
        .st_agu0_cmpl_mmio           (st_agu0_cmpl_mmio),
        .st_agu0_cmpl_addr           (st_agu0_cmpl_addr),
        .st_agu0_cmpl_mask           (st_agu0_cmpl_mask),
        .st_agu0_cmpl_size           (st_agu0_cmpl_size),
        .st_dgu0_cmpl_valid          (st_dgu0_cmpl_valid),
        .st_dgu0_cmpl_sqid           (st_dgu0_cmpl_sqid),
        .st_dgu0_cmpl_data           (st_dgu0_cmpl_data),
        .commit0_valid               (commit0_valid),
        .commit0_robid               (commit0_robid),
        .commit1_valid               (commit1_valid),
        .commit1_robid               (commit1_robid),
        .flush_valid                 (flush_valid),
        .flush_robid                 (flush_robid),
        .sq2arb_tbus_index_valid     (sq2arb_tbus_index_valid),
        .sq2arb_tbus_index_ready     (sq2arb_tbus_index_ready),
        .sq2arb_tbus_index           (sq2arb_tbus_index),
        .sq2arb_tbus_write_data      (sq2arb_tbus_write_data),
        .sq2arb_tbus_write_mask      (sq2arb_tbus_write_mask),
        .sq2arb_tbus_read_data       (sq2arb_tbus_read_data),
        .sq2arb_tbus_operation_type  (sq2arb_tbus_operation_type),
        .sq2arb_tbus_operation_done  (sq2arb_tbus_operation_done),
        .sq_enqptr                   (sq_enqptr),
        .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
        .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
        .ldu2sq_forward_req_load_addr(ldu2sq_forward_req_load_addr),
        .ldu2sq_forward_req_load_size(ldu2sq_forward_req_load_size),
        .ldu2sq_forward_resp_valid   (ldu2sq_forward_resp_valid),
        .ldu2sq_forward_resp_data    (ldu2sq_forward_resp_data),
        .ldu2sq_forward_resp_mask    (ldu2sq_forward_resp_mask)
    );





    dcache_arb u_dcache_arb (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .load2arb_tbus_index_valid   (load2arb_tbus_index_valid),
        .load2arb_tbus_index         (load2arb_tbus_index),
        .load2arb_tbus_index_ready   (load2arb_tbus_index_ready),
        .load2arb_tbus_read_data     (load2arb_tbus_read_data),
        .load2arb_tbus_operation_done(load2arb_tbus_operation_done),
        .load2arb_flush_valid        (load2arb_flush_valid),
        .sq2arb_tbus_index_valid     (sq2arb_tbus_index_valid),
        .sq2arb_tbus_index_ready     (sq2arb_tbus_index_ready),
        .sq2arb_tbus_index           (sq2arb_tbus_index),
        .sq2arb_tbus_write_data      (sq2arb_tbus_write_data),
        .sq2arb_tbus_write_mask      (sq2arb_tbus_write_mask),
        .sq2arb_tbus_read_data       (sq2arb_tbus_read_data),
        .sq2arb_tbus_operation_done  (sq2arb_tbus_operation_done),
        .sq2arb_tbus_operation_type  (sq2arb_tbus_operation_type),
        .tbus_index_valid            (tbus_index_valid),
        .tbus_index_ready            (tbus_index_ready),
        .tbus_index                  (tbus_index),
        .tbus_write_mask             (tbus_write_mask),
        .tbus_write_data             (tbus_write_data),
        .tbus_read_data              (tbus_read_data),
        .tbus_operation_type         (tbus_operation_type),
        .tbus_operation_done         (tbus_operation_done),
        .arb2dcache_flush_valid      (arb2dcache_flush_valid)
    );



    wire arb2dcache_flush_valid;


    dcache u_dcache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (arb2dcache_flush_valid),          //flush_valid was send to mem_top to determine if dcache operation should be cancel or not
        //tbus channel from backend 
        .tbus_index_valid              (tbus_index_valid),
        .tbus_index_ready              (tbus_index_ready),
        .tbus_index                    (tbus_index),
        .tbus_write_data               (tbus_write_data),
        .tbus_write_mask               (tbus_write_mask),
        .tbus_read_data                (tbus_read_data),
        .tbus_operation_done           (tbus_operation_done),
        .tbus_operation_type           (tbus_operation_type),
        // dcache channel to memory or L2
        .dcache2arb_dbus_index_valid   (dcache2arb_dbus_index_valid),
        .dcache2arb_dbus_index_ready   (dcache2arb_dbus_index_ready),
        .dcache2arb_dbus_index         (dcache2arb_dbus_index),
        .dcache2arb_dbus_write_data    (dcache2arb_dbus_write_data),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type)
    );

endmodule
