`include "defines.sv"
module isu_top (
    input wire clock,
    input wire reset_n,

    // Dispatch inputs from rename stage
    input  wire                      iru2isu_instr0_valid,
    output wire                      iru2isu_instr0_ready,
    input  wire [         `PC_RANGE] iru2isu_instr0_pc,
    input  wire [              31:0] iru2isu_instr0_instr,
    input  wire [       `LREG_RANGE] iru2isu_instr0_lrs1,
    input  wire [       `LREG_RANGE] iru2isu_instr0_lrs2,
    input  wire [       `LREG_RANGE] iru2isu_instr0_lrd,
    input  wire [       `PREG_RANGE] iru2isu_instr0_prd,
    input  wire [       `PREG_RANGE] iru2isu_instr0_old_prd,
    input  wire                      iru2isu_instr0_need_to_wb,
    input  wire [       `PREG_RANGE] iru2isu_instr0_prs1,
    input  wire [       `PREG_RANGE] iru2isu_instr0_prs2,
    input  wire                      iru2isu_instr0_src1_is_reg,
    input  wire                      iru2isu_instr0_src2_is_reg,
    input  wire [              63:0] iru2isu_instr0_imm,
    input  wire [    `CX_TYPE_RANGE] iru2isu_instr0_cx_type,
    input  wire                      iru2isu_instr0_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] iru2isu_instr0_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] iru2isu_instr0_muldiv_type,
    input  wire                      iru2isu_instr0_is_word,
    input  wire                      iru2isu_instr0_is_imm,
    input  wire                      iru2isu_instr0_is_load,
    input  wire                      iru2isu_instr0_is_store,
    input  wire [               3:0] iru2isu_instr0_ls_size,
    input  wire                      iru2isu_instr0_predicttaken,
    input  wire [              31:0] iru2isu_instr0_predicttarget,



    input  wire                      iru2isu_instr1_valid,
    output wire                      iru2isu_instr1_ready,
    input  wire [         `PC_RANGE] iru2isu_instr1_pc,
    input  wire [              31:0] iru2isu_instr1_instr,
    input  wire [       `LREG_RANGE] iru2isu_instr1_lrs1,
    input  wire [       `LREG_RANGE] iru2isu_instr1_lrs2,
    input  wire [       `LREG_RANGE] iru2isu_instr1_lrd,
    input  wire [       `PREG_RANGE] iru2isu_instr1_prd,
    input  wire [       `PREG_RANGE] iru2isu_instr1_old_prd,
    input  wire                      iru2isu_instr1_need_to_wb,
    input  wire [       `PREG_RANGE] iru2isu_instr1_prs1,
    input  wire [       `PREG_RANGE] iru2isu_instr1_prs2,
    input  wire                      iru2isu_instr1_src1_is_reg,
    input  wire                      iru2isu_instr1_src2_is_reg,
    input  wire [              63:0] iru2isu_instr1_imm,
    input  wire [    `CX_TYPE_RANGE] iru2isu_instr1_cx_type,
    input  wire                      iru2isu_instr1_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] iru2isu_instr1_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] iru2isu_instr1_muldiv_type,
    input  wire                      iru2isu_instr1_is_word,
    input  wire                      iru2isu_instr1_is_imm,
    input  wire                      iru2isu_instr1_is_load,
    input  wire                      iru2isu_instr1_is_store,
    input  wire [               3:0] iru2isu_instr1_ls_size,
    input  wire                      iru2isu_instr1_predicttaken,
    input  wire [              31:0] iru2isu_instr1_predicttarget,


    /* ---------------------------------- to sq --------------------------------- */
    output wire                   disp2sq_valid,
    input  wire                   sq_can_alloc,
    output wire [`ROB_SIZE_LOG:0] disp2sq_robid,
    output wire [      `PC_RANGE] disp2sq_pc,

    /* ------------------------------ write region ------------------------------ */
    input wire                   intwb0_instr_valid,
    input wire [`ROB_SIZE_LOG:0] intwb0_robid,
    input wire [    `PREG_RANGE] intwb0_prd,
    input wire                   intwb0_need_to_wb,
    input wire [  `RESULT_RANGE] intwb0_result,


    input wire                   ldu0_cmpl_valid,
    input wire [`ROB_SIZE_LOG:0] ldu0_cmpl_robid,
    input wire [    `PREG_RANGE] ldu0_cmpl_prd,
    input wire                   ldu0_cmpl_mmio_valid,
    input wire [  `RESULT_RANGE] ldu0_cmpl_result,

    /* --------------------------- mem_top to complete -------------------------- */
    input wire                   sq2rob_cmpl_valid,
    input wire [`ROB_SIZE_LOG:0] sq2rob_cmpl_robid,
    input wire                   sq2rob_cmpl_mmio,

    // Flush inputs from intwb0
    input wire                   flush_valid,
    input wire [`ROB_SIZE_LOG:0] flush_robid,

    // Commit outputs
    output wire                   commit0_valid,
    output wire [      `PC_RANGE] commit0_pc,
    output wire [           31:0] commit0_instr,
    output wire [    `LREG_RANGE] commit0_lrd,
    output wire [    `PREG_RANGE] commit0_prd,
    output wire [    `PREG_RANGE] commit0_old_prd,
    output wire                   commit0_need_to_wb,
    output wire [`ROB_SIZE_LOG:0] commit0_robid,
    output wire                   commit0_skip,

    output wire                   commit1_valid,
    output wire [      `PC_RANGE] commit1_pc,
    output wire [           31:0] commit1_instr,
    output wire [    `LREG_RANGE] commit1_lrd,
    output wire [    `PREG_RANGE] commit1_prd,
    output wire [    `PREG_RANGE] commit1_old_prd,
    output wire [`ROB_SIZE_LOG:0] commit1_robid,
    output wire                   commit1_need_to_wb,
    output wire                   commit1_skip,

    /* ----------------------------------to issue --------------------------------- */
    output wire                   issue0_valid,
    input  wire                   issue0_ready,
    output wire [`ROB_SIZE_LOG:0] issue0_robid,
    output wire [ `SQ_SIZE_LOG:0] issue0_sqid,
    output wire [           63:0] issue0_pc,
    output wire [           31:0] issue0_instr,
    output wire [    `LREG_RANGE] issue0_lrs1,
    output wire [    `LREG_RANGE] issue0_lrs2,
    output wire [    `LREG_RANGE] issue0_lrd,
    output wire [    `PREG_RANGE] issue0_prd,
    output wire [    `PREG_RANGE] issue0_old_prd,
    output wire                   issue0_need_to_wb,
    output wire [    `PREG_RANGE] issue0_prs1,
    output wire [    `PREG_RANGE] issue0_prs2,
    output wire                   issue0_src1_is_reg,
    output wire                   issue0_src2_is_reg,
    output wire [           63:0] issue0_imm,
    output wire [ `CX_TYPE_RANGE] issue0_cx_type,
    output wire                   issue0_is_unsigned,
    output wire [           10:0] issue0_alu_type,
    output wire [           12:0] issue0_muldiv_type,
    output wire                   issue0_is_word,
    output wire                   issue0_is_imm,
    output wire                   issue0_is_load,
    output wire                   issue0_is_store,
    output wire [            3:0] issue0_ls_size,
    output wire                   issue0_predicttaken,
    output wire [      `PC_RANGE] issue0_predicttarget,
    output wire [     `SRC_RANGE] issue0_src1,
    output wire [     `SRC_RANGE] issue0_src2,

    // ISU <->  MEM TOP
    output wire                   issue_st0_valid,
    output wire                   issue_st0_ready,
    output wire [      `PC_RANGE] issue_st0_pc,           //for debug
    output wire [           31:0] issue_st0_instr,
    output wire [`ROB_SIZE_LOG:0] issue_st0_robid,
    output wire [ `SQ_SIZE_LOG:0] issue_st0_sqid,
    output wire [     `SRC_RANGE] issue_st0_src1,
    output wire [     `SRC_RANGE] issue_st0_src2,
    output wire [    `PREG_RANGE] issue_st0_prd,
    output wire [     `SRC_RANGE] issue_st0_imm,
    output wire                   issue_st0_is_load,
    output wire                   issue_st0_is_store,
    output wire                   issue_st0_is_unsigned,
    output wire [ `LS_SIZE_RANGE] issue_st0_ls_size,

    output wire                   issue_load0_valid,
    output wire                   issue_load0_ready,
    output wire [      `PC_RANGE] issue_load0_pc,           //for debug
    output wire [           31:0] issue_load0_instr,
    output wire [`ROB_SIZE_LOG:0] issue_load0_robid,
    output wire [ `SQ_SIZE_LOG:0] issue_load0_sqid,
    output wire [     `SRC_RANGE] issue_load0_src1,
    output wire [     `SRC_RANGE] issue_load0_src2,
    output wire [    `PREG_RANGE] issue_load0_prd,
    output wire [     `SRC_RANGE] issue_load0_imm,
    output wire                   issue_load0_is_load,
    output wire                   issue_load0_is_store,
    output wire                   issue_load0_is_unsigned,
    output wire [ `LS_SIZE_RANGE] issue_load0_ls_size,

    /* ---------------------------------- walk ---------------------------------- */
    output wire [        1:0] rob_state,
    output wire               rob_walk0_valid,
    output wire               rob_walk0_complete,
    output wire [`LREG_RANGE] rob_walk0_lrd,
    output wire [`PREG_RANGE] rob_walk0_prd,
    output wire               rob_walk1_valid,
    output wire [`LREG_RANGE] rob_walk1_lrd,
    output wire [`PREG_RANGE] rob_walk1_prd,
    output wire               rob_walk1_complete,

    /* ---------------------------- from store queue ---------------------------- */
    input wire [`SQ_SIZE_LOG : 0] sq_enqptr,

    //preg content from arch_rat
    input  wire [`PREG_RANGE] debug_preg0,
    input  wire [`PREG_RANGE] debug_preg1,
    input  wire [`PREG_RANGE] debug_preg2,
    input  wire [`PREG_RANGE] debug_preg3,
    input  wire [`PREG_RANGE] debug_preg4,
    input  wire [`PREG_RANGE] debug_preg5,
    input  wire [`PREG_RANGE] debug_preg6,
    input  wire [`PREG_RANGE] debug_preg7,
    input  wire [`PREG_RANGE] debug_preg8,
    input  wire [`PREG_RANGE] debug_preg9,
    input  wire [`PREG_RANGE] debug_preg10,
    input  wire [`PREG_RANGE] debug_preg11,
    input  wire [`PREG_RANGE] debug_preg12,
    input  wire [`PREG_RANGE] debug_preg13,
    input  wire [`PREG_RANGE] debug_preg14,
    input  wire [`PREG_RANGE] debug_preg15,
    input  wire [`PREG_RANGE] debug_preg16,
    input  wire [`PREG_RANGE] debug_preg17,
    input  wire [`PREG_RANGE] debug_preg18,
    input  wire [`PREG_RANGE] debug_preg19,
    input  wire [`PREG_RANGE] debug_preg20,
    input  wire [`PREG_RANGE] debug_preg21,
    input  wire [`PREG_RANGE] debug_preg22,
    input  wire [`PREG_RANGE] debug_preg23,
    input  wire [`PREG_RANGE] debug_preg24,
    input  wire [`PREG_RANGE] debug_preg25,
    input  wire [`PREG_RANGE] debug_preg26,
    input  wire [`PREG_RANGE] debug_preg27,
    input  wire [`PREG_RANGE] debug_preg28,
    input  wire [`PREG_RANGE] debug_preg29,
    input  wire [`PREG_RANGE] debug_preg30,
    input  wire [`PREG_RANGE] debug_preg31,
    output wire               end_of_program

);
    //wb free busy_table
    wire               intwb02bt_free_instr0rd_en;
    wire [`PREG_RANGE] intwb02bt_free_instr0rd_addr;
    wire               ldu0_cmpl2bt_free_instr0rd_en;
    wire [`PREG_RANGE] ldu0_cmpl2bt_free_instr0rd_addr;

    assign intwb02bt_free_instr0rd_en   = intwb0_instr_valid && intwb0_need_to_wb;
    assign intwb02bt_free_instr0rd_addr = intwb0_prd;
    assign ldu0_cmpl2bt_free_instr0rd_en    = ldu0_cmpl_valid ;
    assign ldu0_cmpl2bt_free_instr0rd_addr  = ldu0_cmpl_prd;

    /* -------------------------------------------------------------------------- */
    /*                               dispatch to rob                              */
    /* -------------------------------------------------------------------------- */
    wire [   `ROB_SIZE_LOG:0] rob2disp_instr_robid;
    wire                      disp2rob_instr0_enq_valid;
    wire [         `PC_RANGE] disp2rob_instr0_pc;
    wire [              31:0] disp2rob_instr0_instr;
    wire [       `LREG_RANGE] disp2rob_instr0_lrd;
    wire [       `PREG_RANGE] disp2rob_instr0_prd;
    wire [       `PREG_RANGE] disp2rob_instr0_old_prd;
    wire                      disp2rob_instr0_need_to_wb;

    wire                      disp2rob_instr1_enq_valid;
    wire [         `PC_RANGE] disp2rob_instr1_pc;
    wire [              31:0] disp2rob_instr1_instr;
    wire [       `LREG_RANGE] disp2rob_instr1_lrd;
    wire [       `PREG_RANGE] disp2rob_instr1_prd;
    wire [       `PREG_RANGE] disp2rob_instr1_old_prd;
    wire                      disp2rob_instr1_need_to_wb;


    /* -------------------------------------------------------------------------- */
    /*                            dispatch to busytable                           */
    /* -------------------------------------------------------------------------- */
    wire [       `PREG_RANGE] disp2bt_instr0_rs1;
    wire                      disp2bt_instr0_src1_is_reg;
    wire                      bt2disp_instr0_src1_busy;
    wire [       `PREG_RANGE] disp2bt_instr0_rs2;
    wire                      disp2bt_instr0_src2_is_reg;
    wire                      bt2disp_instr0_src2_busy;

    wire [       `PREG_RANGE] disp2bt_instr1_rs1;
    wire                      disp2bt_instr1_src1_is_reg;
    wire                      bt2disp_instr1_src1_busy;
    wire [       `PREG_RANGE] disp2bt_instr1_rs2;
    wire                      disp2bt_instr1_src2_is_reg;
    wire                      bt2disp_instr1_src2_busy;

    wire                      disp2bt_alloc_instr0_rd_en;
    wire [       `PREG_RANGE] disp2bt_alloc_instr0_rd;
    wire                      disp2bt_alloc_instr1_rd_en;
    wire [       `PREG_RANGE] disp2bt_alloc_instr1_rd;

    wire                      disp2intisq_enq_valid;
    wire                      intisq2disp_enq_ready;


    /* -------------------------------------------------------------------------- */
    /*                                to issuequeue                               */
    /* -------------------------------------------------------------------------- */
    wire                      disp2intisq_instr0_enq_valid;
    wire [         `PC_RANGE] disp2intisq_instr0_pc;
    wire [              31:0] disp2intisq_instr0_instr;
    wire [       `PREG_RANGE] disp2intisq_instr0_prd;
    wire [       `PREG_RANGE] disp2intisq_instr0_old_prd;
    wire                      disp2intisq_instr0_need_to_wb;
    wire [       `PREG_RANGE] disp2intisq_instr0_prs1;
    wire [       `PREG_RANGE] disp2intisq_instr0_prs2;
    wire                      disp2intisq_instr0_src1_is_reg;
    wire                      disp2intisq_instr0_src2_is_reg;
    wire [              63:0] disp2intisq_instr0_imm;
    wire [    `CX_TYPE_RANGE] disp2intisq_instr0_cx_type;
    wire                      disp2intisq_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] disp2intisq_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] disp2intisq_instr0_muldiv_type;
    wire                      disp2intisq_instr0_is_word;
    wire                      disp2intisq_instr0_is_imm;
    wire                      disp2intisq_instr0_is_load;
    wire                      disp2intisq_instr0_is_store;
    wire [               3:0] disp2intisq_instr0_ls_size;
    wire [   `ROB_SIZE_LOG:0] disp2intisq_instr0_robid;
    wire [    `SQ_SIZE_LOG:0] disp2intisq_instr0_sqid;
    wire                      disp2intisq_instr0_predicttaken;
    wire [         `PC_RANGE] disp2intisq_instr0_predicttarget;
    wire                      disp2intisq_instr0_src1_state;
    wire                      disp2intisq_instr0_src2_state;

    wire                      disp2memisg_instr0_valid;
    wire [         `PC_RANGE] disp2memisg_instr0_pc;
    wire [              31:0] disp2memisg_instr0;
    wire [       `PREG_RANGE] disp2memisg_instr0_prd;
    wire [       `PREG_RANGE] disp2memisg_instr0_old_prd;
    wire [       `PREG_RANGE] disp2memisg_instr0_prs1;
    wire [       `PREG_RANGE] disp2memisg_instr0_prs2;
    wire [              63:0] disp2memisg_instr0_imm;
    wire                      disp2memisg_instr0_is_unsigned;
    wire                      disp2memisg_instr0_is_word;
    wire                      disp2memisg_instr0_is_imm;
    wire                      disp2memisg_instr0_is_load;
    wire                      disp2memisg_instr0_is_store;
    wire [               3:0] disp2memisg_instr0_ls_size;
    wire [   `ROB_SIZE_LOG:0] disp2memisg_instr0_robid;
    wire [    `SQ_SIZE_LOG:0] disp2memisg_instr0_sqid;
    wire                      disp2memisg_instr0_src1_state;
    wire                      disp2memisg_instr0_src2_state;



    wire                      rob_can_enq;
    wire                      iq_can_alloc0;
    wire                      iq_load0_can_alloc;
    wire                      iq_st0_can_alloc;


    wire [       `PREG_RANGE] issue_st0_prs1;
    wire [       `PREG_RANGE] issue_st0_prs2;
    wire [       `PREG_RANGE] issue_load0_prs1;


    wire [              31:0] intisq_pmu_block_enq_cycle_cnt;
    wire [              31:0] intisq_pmu_can_issue_more;

    dispatch u_dispatch (
        .clock                           (clock),
        .reset_n                         (reset_n),
        //decide if dispatch can read instr or not (ROB and ISQ available and (rob_state == `ROB_STATE_IDLE))
        .rob_can_enq                     (rob_can_enq),
        .iq_can_alloc0                   (iq_can_alloc0),
        .iq_load0_can_alloc              (iq_load0_can_alloc),
        .iq_st0_can_alloc                (iq_st0_can_alloc),
        .rob_state                       (rob_state),
        .rob2disp_instr_robid            (rob2disp_instr_robid),
        .sq_enqptr                       (sq_enqptr),
        /* ----------------------------------- iru ---------------------------------- */
        //iru input 
        .iru2isu_instr0_valid            (iru2isu_instr0_valid),
        .iru2isu_instr0_ready            (iru2isu_instr0_ready),
        .instr0_pc                       (iru2isu_instr0_pc),
        .instr0_instr                    (iru2isu_instr0_instr),
        .instr0_lrs1                     (iru2isu_instr0_lrs1),
        .instr0_lrs2                     (iru2isu_instr0_lrs2),
        .instr0_lrd                      (iru2isu_instr0_lrd),
        .instr0_prd                      (iru2isu_instr0_prd),
        .instr0_old_prd                  (iru2isu_instr0_old_prd),
        .instr0_need_to_wb               (iru2isu_instr0_need_to_wb),
        .instr0_prs1                     (iru2isu_instr0_prs1),
        .instr0_prs2                     (iru2isu_instr0_prs2),
        .instr0_src1_is_reg              (iru2isu_instr0_src1_is_reg),
        .instr0_src2_is_reg              (iru2isu_instr0_src2_is_reg),
        .instr0_imm                      (iru2isu_instr0_imm),
        .instr0_cx_type                  (iru2isu_instr0_cx_type),
        .instr0_is_unsigned              (iru2isu_instr0_is_unsigned),
        .instr0_alu_type                 (iru2isu_instr0_alu_type),
        .instr0_muldiv_type              (iru2isu_instr0_muldiv_type),
        .instr0_is_word                  (iru2isu_instr0_is_word),
        .instr0_is_imm                   (iru2isu_instr0_is_imm),
        .instr0_is_load                  (iru2isu_instr0_is_load),
        .instr0_is_store                 (iru2isu_instr0_is_store),
        .instr0_ls_size                  (iru2isu_instr0_ls_size),
        .iru2isu_instr0_predicttaken     (iru2isu_instr0_predicttaken),
        .iru2isu_instr0_predicttarget    (iru2isu_instr0_predicttarget),
        .iru2isu_instr1_valid            (),
        .iru2isu_instr1_ready            (),
        .instr1_pc                       (),
        .instr1_instr                    (),
        .instr1_lrs1                     (),
        .instr1_lrs2                     (),
        .instr1_lrd                      (),
        .instr1_prd                      (),
        .instr1_old_prd                  (),
        .instr1_need_to_wb               (),
        .instr1_prs1                     (),
        .instr1_prs2                     (),
        .instr1_src1_is_reg              (),
        .instr1_src2_is_reg              (),
        .instr1_imm                      (),
        .instr1_cx_type                  (),
        .instr1_is_unsigned              (),
        .instr1_alu_type                 (),
        .instr1_muldiv_type              (),
        .instr1_is_word                  (),
        .instr1_is_imm                   (),
        .instr1_is_load                  (),
        .instr1_is_store                 (),
        .instr1_ls_size                  (),
        .iru2isu_instr1_predicttaken     (),
        .iru2isu_instr1_predicttarget    (),
        /* ----------------------------------- rob ---------------------------------- */
        //disp send instr0 to rob
        .disp2rob_instr0_enq_valid       (disp2rob_instr0_enq_valid),
        .disp2rob_instr0_pc              (disp2rob_instr0_pc),
        .disp2rob_instr0_instr           (disp2rob_instr0_instr),
        .disp2rob_instr0_lrd             (disp2rob_instr0_lrd),
        .disp2rob_instr0_prd             (disp2rob_instr0_prd),
        .disp2rob_instr0_old_prd         (disp2rob_instr0_old_prd),
        .disp2rob_instr0_need_to_wb      (disp2rob_instr0_need_to_wb),
        .disp2rob_instr1_enq_valid       (),
        .disp2rob_instr1_pc              (),
        .disp2rob_instr1_instr           (),
        .disp2rob_instr1_lrd             (),
        .disp2rob_instr1_prd             (),
        .disp2rob_instr1_old_prd         (),
        .disp2rob_instr1_need_to_wb      (),
        /* ---------------------------- to int issuequeue --------------------------- */
        .disp2intisq_instr0_enq_valid    (disp2intisq_instr0_enq_valid),
        .disp2intisq_instr0_pc           (disp2intisq_instr0_pc),
        .disp2intisq_instr0_instr        (disp2intisq_instr0_instr),
        .disp2intisq_instr0_prd          (disp2intisq_instr0_prd),
        .disp2intisq_instr0_old_prd      (disp2intisq_instr0_old_prd),
        .disp2intisq_instr0_need_to_wb   (disp2intisq_instr0_need_to_wb),
        .disp2intisq_instr0_prs1         (disp2intisq_instr0_prs1),
        .disp2intisq_instr0_prs2         (disp2intisq_instr0_prs2),
        .disp2intisq_instr0_src1_is_reg  (disp2intisq_instr0_src1_is_reg),
        .disp2intisq_instr0_src2_is_reg  (disp2intisq_instr0_src2_is_reg),
        .disp2intisq_instr0_imm          (disp2intisq_instr0_imm),
        .disp2intisq_instr0_cx_type      (disp2intisq_instr0_cx_type),
        .disp2intisq_instr0_is_unsigned  (disp2intisq_instr0_is_unsigned),
        .disp2intisq_instr0_alu_type     (disp2intisq_instr0_alu_type),
        .disp2intisq_instr0_muldiv_type  (disp2intisq_instr0_muldiv_type),
        .disp2intisq_instr0_is_word      (disp2intisq_instr0_is_word),
        .disp2intisq_instr0_is_imm       (disp2intisq_instr0_is_imm),
        .disp2intisq_instr0_is_load      (disp2intisq_instr0_is_load),
        .disp2intisq_instr0_is_store     (disp2intisq_instr0_is_store),
        .disp2intisq_instr0_ls_size      (disp2intisq_instr0_ls_size),
        .disp2intisq_instr0_robid        (disp2intisq_instr0_robid),
        .disp2intisq_instr0_sqid         (disp2intisq_instr0_sqid),
        .disp2intisq_instr0_predicttaken (disp2intisq_instr0_predicttaken),
        .disp2intisq_instr0_predicttarget(disp2intisq_instr0_predicttarget),
        .disp2intisq_instr0_src1_state   (disp2intisq_instr0_src1_state),
        .disp2intisq_instr0_src2_state   (disp2intisq_instr0_src2_state),
        /* ---------------------------- to mem issuequeue --------------------------- */
        .disp2memisg_instr0_valid        (disp2memisg_instr0_valid),
        .disp2memisg_instr0_pc           (disp2memisg_instr0_pc),
        .disp2memisg_instr0              (disp2memisg_instr0),
        .disp2memisg_instr0_prd          (disp2memisg_instr0_prd),
        .disp2memisg_instr0_old_prd      (disp2memisg_instr0_old_prd),
        .disp2memisg_instr0_prs1         (disp2memisg_instr0_prs1),
        .disp2memisg_instr0_prs2         (disp2memisg_instr0_prs2),
        .disp2memisg_instr0_imm          (disp2memisg_instr0_imm),
        .disp2memisg_instr0_is_unsigned  (disp2memisg_instr0_is_unsigned),
        .disp2memisg_instr0_is_word      (disp2memisg_instr0_is_word),
        .disp2memisg_instr0_is_imm       (disp2memisg_instr0_is_imm),
        .disp2memisg_instr0_is_load      (disp2memisg_instr0_is_load),
        .disp2memisg_instr0_is_store     (disp2memisg_instr0_is_store),
        .disp2memisg_instr0_ls_size      (disp2memisg_instr0_ls_size),
        .disp2memisg_instr0_robid        (disp2memisg_instr0_robid),
        .disp2memisg_instr0_sqid         (disp2memisg_instr0_sqid),
        .disp2memisg_instr0_src1_state   (disp2memisg_instr0_src1_state),
        .disp2memisg_instr0_src2_state   (disp2memisg_instr0_src2_state),
        /* ----------------------------- to store queue ----------------------------- */
        .disp2sq_valid                   (disp2sq_valid),
        .sq_can_alloc                    (sq_can_alloc),
        .disp2sq_robid                   (disp2sq_robid),
        .disp2sq_pc                      (disp2sq_pc),
        /* ------------------------------- busy_table ------------------------------- */
        //disp read from busy_table
        .disp2bt_instr0_rs1              (disp2bt_instr0_rs1),
        .disp2bt_instr0_src1_is_reg      (disp2bt_instr0_src1_is_reg),
        .bt2disp_instr0_src1_busy        (bt2disp_instr0_src1_busy),
        .disp2bt_instr0_rs2              (disp2bt_instr0_rs2),
        .disp2bt_instr0_src2_is_reg      (disp2bt_instr0_src2_is_reg),
        .bt2disp_instr0_src2_busy        (bt2disp_instr0_src2_busy),
        .disp2bt_instr1_rs1              (),
        .disp2bt_instr1_src1_is_reg      (),
        .bt2disp_instr1_src1_busy        (),
        .disp2bt_instr1_rs2              (),
        .disp2bt_instr1_src2_is_reg      (),
        .bt2disp_instr1_src2_busy        (),
        //disp write rd as busy in busy_table
        .disp2bt_alloc_instr0_rd_en      (disp2bt_alloc_instr0_rd_en),
        .disp2bt_alloc_instr0_rd         (disp2bt_alloc_instr0_rd),
        .disp2bt_alloc_instr1_rd_en      (),
        .disp2bt_alloc_instr1_rd         (),
        //flush signal
        .flush_valid                     (flush_valid)
    );

    // Instantiate modules
    rob rob_inst (
        .clock            (clock),
        .reset_n          (reset_n),
        //disp input instr
        .instr0_enq_valid (disp2rob_instr0_enq_valid),
        .instr0_pc        (disp2rob_instr0_pc),
        .instr0_instr     (disp2rob_instr0_instr),
        .instr0_lrd       (disp2rob_instr0_lrd),
        .instr0_prd       (disp2rob_instr0_prd),
        .instr0_old_prd   (disp2rob_instr0_old_prd),
        .instr0_need_to_wb(disp2rob_instr0_need_to_wb),
        .instr1_enq_valid (),
        .instr1_pc        (),
        .instr1_instr     (),
        .instr1_lrd       (),
        .instr1_prd       (),
        .instr1_old_prd   (),
        .instr1_need_to_wb(),

        //write back signals
        .intwb0_instr_valid  (intwb0_instr_valid),
        .intwb0_robid        (intwb0_robid),
        .sq2rob_cmpl_valid   (sq2rob_cmpl_valid),
        .sq2rob_cmpl_robid   (sq2rob_cmpl_robid),
        .sq2rob_cmpl_mmio    (sq2rob_cmpl_mmio),
        .flush_valid         (flush_valid),
        .flush_robid         (flush_robid),
        //rob commit output
        .commit0_valid       (commit0_valid),
        .commit0_pc          (commit0_pc),
        .commit0_instr       (commit0_instr),
        .commit0_lrd         (commit0_lrd),
        .commit0_prd         (commit0_prd),
        .commit0_old_prd     (commit0_old_prd),
        .commit0_need_to_wb  (commit0_need_to_wb),
        .commit0_robid       (commit0_robid),
        .commit0_skip        (commit0_skip),
        .commit1_valid       (),
        .commit1_pc          (),
        .commit1_instr       (),
        .commit1_lrd         (),
        .commit1_prd         (),
        .commit1_old_prd     (),
        .commit1_robid       (),
        .commit1_need_to_wb  (),
        .commit1_skip        (),
        //walking logic
        .rob_state           (rob_state),
        .rob_walk0_valid     (rob_walk0_valid),
        .rob_walk0_complete  (rob_walk0_complete),
        .rob_walk0_lrd       (rob_walk0_lrd),
        .rob_walk0_prd       (rob_walk0_prd),
        .rob_walk1_valid     (rob_walk1_valid),
        .rob_walk1_lrd       (rob_walk1_lrd),
        .rob_walk1_prd       (rob_walk1_prd),
        .rob_walk1_complete  (rob_walk1_complete),
        .rob2disp_instr_robid(rob2disp_instr_robid),
        .rob_can_enq         (rob_can_enq),
        .end_of_program      (end_of_program)
    );

    /* -------------------------------------------------------------------------- */
    /*                              int   issuequeue                              */
    /* -------------------------------------------------------------------------- */

    int_isq #(
        .OUT_OF_ORDER(1)
    ) u_int_isq (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .iq_can_alloc0                 (iq_can_alloc0),
        .all_iq_ready                  (1'b1),
        .enq_instr0_valid              (disp2intisq_instr0_enq_valid),
        .enq_instr0_pc                 (disp2intisq_instr0_pc),
        .enq_instr0                    (disp2intisq_instr0_instr),
        .enq_instr0_imm                (disp2intisq_instr0_imm),
        .enq_instr0_src1_is_reg        (disp2intisq_instr0_src1_is_reg),
        .enq_instr0_src2_is_reg        (disp2intisq_instr0_src2_is_reg),
        .enq_instr0_need_to_wb         (disp2intisq_instr0_need_to_wb),
        .enq_instr0_cx_type            (disp2intisq_instr0_cx_type),
        .enq_instr0_is_unsigned        (disp2intisq_instr0_is_unsigned),
        .enq_instr0_alu_type           (disp2intisq_instr0_alu_type),
        .enq_instr0_muldiv_type        (disp2intisq_instr0_muldiv_type),
        .enq_instr0_is_word            (disp2intisq_instr0_is_word),
        .enq_instr0_is_imm             (disp2intisq_instr0_is_imm),
        .enq_instr0_is_load            (disp2intisq_instr0_is_load),
        .enq_instr0_is_store           (disp2intisq_instr0_is_store),
        .enq_instr0_ls_size            (disp2intisq_instr0_ls_size),
        .enq_instr0_prs1               (disp2intisq_instr0_prs1),
        .enq_instr0_prs2               (disp2intisq_instr0_prs2),
        .enq_instr0_prd                (disp2intisq_instr0_prd),
        .enq_instr0_old_prd            (disp2intisq_instr0_old_prd),
        .enq_instr0_predicttaken       (disp2intisq_instr0_predicttaken),
        .enq_instr0_predicttarget      (disp2intisq_instr0_predicttarget),
        .enq_instr0_robid              (disp2intisq_instr0_robid),
        .enq_instr0_sqid               (disp2intisq_instr0_sqid),
        .enq_instr0_src1_state         (disp2intisq_instr0_src1_state),
        .enq_instr0_src2_state         (disp2intisq_instr0_src2_state),
        .issue0_valid                  (issue0_valid),
        .issue0_ready                  (issue0_ready),
        .issue0_prs1                   (issue0_prs1),
        .issue0_prs2                   (issue0_prs2),
        .issue0_src1_is_reg            (issue0_src1_is_reg),
        .issue0_src2_is_reg            (issue0_src2_is_reg),
        .issue0_prd                    (issue0_prd),
        .issue0_old_prd                (issue0_old_prd),
        .issue0_pc                     (issue0_pc),
        .issue0_instr                  (issue0_instr),
        .issue0_imm                    (issue0_imm),
        .issue0_need_to_wb             (issue0_need_to_wb),
        .issue0_cx_type                (issue0_cx_type),
        .issue0_is_unsigned            (issue0_is_unsigned),
        .issue0_alu_type               (issue0_alu_type),
        .issue0_muldiv_type            (issue0_muldiv_type),
        .issue0_is_word                (issue0_is_word),
        .issue0_is_imm                 (issue0_is_imm),
        .issue0_is_load                (issue0_is_load),
        .issue0_is_store               (issue0_is_store),
        .issue0_ls_size                (issue0_ls_size),
        .issue0_predicttaken           (issue0_predicttaken),
        .issue0_predicttarget          (issue0_predicttarget),
        .issue0_robid                  (issue0_robid),
        .issue0_sqid                   (issue0_sqid),
        .writeback0_valid              (intwb0_instr_valid),
        .writeback0_need_to_wb         (intwb0_need_to_wb),
        .writeback0_prd                (intwb0_prd),
        .writeback1_valid              (ldu0_cmpl_valid),
        .writeback1_prd                (ldu0_cmpl_prd),
        .rob_state                     (rob_state),
        .flush_valid                   (flush_valid),
        .flush_robid                   (flush_robid),
        .intisq_pmu_block_enq_cycle_cnt(intisq_pmu_block_enq_cycle_cnt),
        .intisq_pmu_can_issue_more     (intisq_pmu_can_issue_more)
    );


    /* -------------------------------------------------------------------------- */
    /*                            mem issue group region                          */
    /* -------------------------------------------------------------------------- */
    lsisg u_lsisg (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .iq_load0_can_alloc            (iq_load0_can_alloc),
        .iq_st0_can_alloc              (iq_st0_can_alloc),
        .disp2memisg_instr0_valid      (disp2memisg_instr0_valid),
        .disp2memisg_instr0_pc         (disp2memisg_instr0_pc),
        .disp2memisg_instr0            (disp2memisg_instr0),
        .disp2memisg_instr0_imm        (disp2memisg_instr0_imm),
        .disp2memisg_instr0_is_unsigned(disp2memisg_instr0_is_unsigned),
        .disp2memisg_instr0_is_imm     (disp2memisg_instr0_is_imm),
        .disp2memisg_instr0_is_load    (disp2memisg_instr0_is_load),
        .disp2memisg_instr0_is_store   (disp2memisg_instr0_is_store),
        .disp2memisg_instr0_size       (disp2memisg_instr0_ls_size),
        .disp2memisg_instr0_prs1       (disp2memisg_instr0_prs1),
        .disp2memisg_instr0_prs2       (disp2memisg_instr0_prs2),
        .disp2memisg_instr0_prd        (disp2memisg_instr0_prd),
        .disp2memisg_instr0_robid      (disp2memisg_instr0_robid),
        .disp2memisg_instr0_sqid       (disp2memisg_instr0_sqid),
        .disp2memisg_instr0_src1_state (disp2memisg_instr0_src1_state),
        .disp2memisg_instr0_src2_state (disp2memisg_instr0_src2_state),
        .issue_st0_valid               (issue_st0_valid),
        .issue_st0_ready               (issue_st0_ready),
        .issue_st0_prs1                (issue_st0_prs1),
        .issue_st0_prs2                (issue_st0_prs2),
        .issue_st0_prd                 (issue_st0_prd),
        .issue_st0_pc                  (issue_st0_pc),
        .issue_st0_instr               (),
        .issue_st0_imm                 (issue_st0_imm),
        .issue_st0_is_unsigned         (issue_st0_is_unsigned),
        .issue_st0_is_load             (issue_st0_is_load),
        .issue_st0_is_store            (issue_st0_is_store),
        .issue_st0_ls_size             (issue_st0_ls_size),
        .issue_st0_robid               (issue_st0_robid),
        .issue_st0_sqid                (issue_st0_sqid),
        .issue_load0_valid             (issue_load0_valid),
        .issue_load0_ready             (issue_load0_ready),
        .issue_load0_prs1              (issue_load0_prs1),
        .issue_load0_prs2              (),
        .issue_load0_prd               (issue_load0_prd),
        .issue_load0_pc                (issue_load0_pc),
        .issue_load0_instr             (),
        .issue_load0_imm               (issue_load0_imm),
        .issue_load0_is_unsigned       (issue_load0_is_unsigned),
        .issue_load0_is_load           (issue_load0_is_load),
        .issue_load0_is_store          (issue_load0_is_store),
        .issue_load0_ls_size           (issue_load0_ls_size),
        .issue_load0_robid             (issue_load0_robid),
        .issue_load0_sqid              (issue_load0_sqid),

        .writeback0_valid              (intwb0_instr_valid),
        .writeback0_need_to_wb         (intwb0_need_to_wb),
        .writeback0_prd                (intwb0_prd),
        .writeback1_valid              (ldu0_cmpl_valid),
        .writeback1_prd                (ldu0_cmpl_prd),
        .rob_state                     (rob_state),
        .flush_valid                   (flush_valid),
        .flush_robid                   (flush_robid),
        .intisq_pmu_block_enq_cycle_cnt(),                    //only used in int_isq
        .intisq_pmu_can_issue_more     ()                     //only used in int_isq
    );





    /* -------------------------------------------------------------------------- */
    /*          isq read from pregfile , pregfile send result directly to exu     */
    /* -------------------------------------------------------------------------- */

    wire               intisq2prf_instr0_src1_is_reg;
    wire [`PREG_RANGE] intisq2prf_inst0_prs1;
    wire               intisq2prf_instr0_src2_is_reg;
    wire [`PREG_RANGE] intisq2prf_inst0_prs2;
    assign intisq2prf_instr0_src1_is_reg = issue0_valid && issue0_src1_is_reg;
    assign intisq2prf_inst0_prs1         = {`PREG_LENGTH{issue0_valid}} & issue0_prs1;
    assign intisq2prf_instr0_src2_is_reg = issue0_valid && issue0_src2_is_reg;
    assign intisq2prf_inst0_prs2         = {`PREG_LENGTH{issue0_valid}} & issue0_prs2;

    wire               prf_rden2;
    wire [`PREG_RANGE] prf_rdaddr2;
    wire               prf_rden3;
    wire [`PREG_RANGE] prf_rdaddr3;
    wire               prf_rden4;
    wire [`PREG_RANGE] prf_rdaddr4;
    /* ------------------------- store src1 and src2 both need read ------------------------ */
    assign prf_rden2   = issue_st0_valid;
    assign prf_rdaddr2 = {`PREG_LENGTH{issue_st0_valid}} & issue_st0_prs1;
    assign prf_rden3   = issue_st0_valid;
    assign prf_rdaddr3 = {`PREG_LENGTH{issue_st0_valid}} & issue_st0_prs2;
    assign prf_rden4   = issue_load0_valid;
    assign prf_rdaddr4 = {`PREG_LENGTH{issue_load0_valid}} & issue_load0_prs1;


    busy_table u_busy_table (
        .clock                     (clock),
        .reset_n                   (reset_n),
        //disp read rs1/rs2 port
        .disp2bt_instr0_rs1        (disp2bt_instr0_rs1),
        .disp2bt_instr0_src1_is_reg(disp2bt_instr0_src1_is_reg),
        .bt2disp_instr0_src1_busy  (bt2disp_instr0_src1_busy),
        .disp2bt_instr0_rs2        (disp2bt_instr0_rs2),
        .disp2bt_instr0_src2_is_reg(disp2bt_instr0_src2_is_reg),
        .bt2disp_instr0_src2_busy  (bt2disp_instr0_src2_busy),

        //disp write rd ad busy port
        .disp2bt_alloc_instr0_rd_en (disp2bt_alloc_instr0_rd_en),
        .disp2bt_alloc_instr0_rd    (disp2bt_alloc_instr0_rd),
        .disp2bt_instr1_rs1         (),
        .disp2bt_instr1_src1_is_reg (),
        .bt2disp_instr1_src1_busy   (),
        .disp2bt_instr1_rs2         (),
        .disp2bt_instr1_src2_is_reg (),
        .bt2disp_instr1_src2_busy   (),
        .disp2bt_alloc_instr1_rd_en (),
        .disp2bt_alloc_instr1_rd    (),
        //writeback free busy_table
        .intwb02bt_free_instr0_rd_en(intwb0_instr_valid & intwb0_need_to_wb),
        .intwb02bt_free_instr0_rd   (intwb0_prd),
        .ldu0_cmpl_free_en (ldu0_cmpl_valid ),
        .ldu0_cmpl_free_rd    (ldu0_cmpl_prd),
        //walking logic
        .flush_valid                (flush_valid),
        .flush_robid                (flush_robid),
        .rob_state                  (rob_state),
        .rob_walk0_valid            (rob_walk0_valid),
        .rob_walk1_valid            (rob_walk1_valid),
        .rob_walk0_prd              (rob_walk0_prd),
        .rob_walk1_prd              (rob_walk1_prd),
        .rob_walk0_complete         (rob_walk0_complete),
        .rob_walk1_complete         (rob_walk1_complete)
    );



    pregfile_64x64_8r4w u_pregfile_64x64_4r2w (
        .clock       (clock),
        .reset_n     (reset_n),
        //intblock writeback port 
        .wren0       (intwb0_instr_valid && intwb0_need_to_wb),
        .waddr0      (intwb0_prd),
        .wdata0      (intwb0_result),
        //mem_top writeback port
        .wren1       (ldu0_cmpl_valid ),
        .waddr1      (ldu0_cmpl_prd),
        .wdata1      (ldu0_cmpl_result),
        //intisq read then send result to exu
        .rden0       (intisq2prf_instr0_src1_is_reg),
        .raddr0      (intisq2prf_inst0_prs1),
        .rdata0      (issue0_src1),
        .rden1       (intisq2prf_instr0_src2_is_reg),
        .raddr1      (intisq2prf_inst0_prs2),
        .rdata1      (issue0_src2),
        .rden2       (prf_rden2),
        .raddr2      (prf_rdaddr2),
        .rdata2      (issue_st0_src1),
        .rden3       (prf_rden3),
        .raddr3      (prf_rdaddr3),
        .rdata3      (issue_st0_src2),
        /* ------------------------------ for load read ----------------------------- */
        .rden4       (prf_rden4),
        .raddr4      (prf_rdaddr4),
        .rdata4      (issue_load0_src1),
        .rden5       (),
        .raddr5      (),
        .rdata5      (),
        .rden6       (),
        .raddr6      (),
        .rdata6      (),
        .rden7       (),
        .raddr7      (),
        .rdata7      (),
        //phsical reg number from arch_rat
        .debug_preg0 (debug_preg0),
        .debug_preg1 (debug_preg1),
        .debug_preg2 (debug_preg2),
        .debug_preg3 (debug_preg3),
        .debug_preg4 (debug_preg4),
        .debug_preg5 (debug_preg5),
        .debug_preg6 (debug_preg6),
        .debug_preg7 (debug_preg7),
        .debug_preg8 (debug_preg8),
        .debug_preg9 (debug_preg9),
        .debug_preg10(debug_preg10),
        .debug_preg11(debug_preg11),
        .debug_preg12(debug_preg12),
        .debug_preg13(debug_preg13),
        .debug_preg14(debug_preg14),
        .debug_preg15(debug_preg15),
        .debug_preg16(debug_preg16),
        .debug_preg17(debug_preg17),
        .debug_preg18(debug_preg18),
        .debug_preg19(debug_preg19),
        .debug_preg20(debug_preg20),
        .debug_preg21(debug_preg21),
        .debug_preg22(debug_preg22),
        .debug_preg23(debug_preg23),
        .debug_preg24(debug_preg24),
        .debug_preg25(debug_preg25),
        .debug_preg26(debug_preg26),
        .debug_preg27(debug_preg27),
        .debug_preg28(debug_preg28),
        .debug_preg29(debug_preg29),
        .debug_preg30(debug_preg30),
        .debug_preg31(debug_preg31)
    );







    /* -------------------------------------------------------------------------- */
    /*                               difftest region                              */
    /* -------------------------------------------------------------------------- */
    reg                   flop_commit0_valid;
    reg                   flop_commit0_skip;
    reg                   flop_commit0_need_to_wb;
    reg [    `LREG_RANGE] flop_commit0_lrd;
    reg [    `PREG_RANGE] flop_commit0_prd;
    reg [      `PC_RANGE] flop_commit0_pc;
    reg [   `INSTR_RANGE] flop_commit0_instr;
    reg [`ROB_SIZE_LOG:0] flop_commit0_robid;

    `MACRO_DFF_NONEN(flop_commit0_valid, commit0_valid, 1)
    `MACRO_DFF_NONEN(flop_commit0_skip, commit0_skip, 1)
    `MACRO_DFF_NONEN(flop_commit0_need_to_wb, commit0_need_to_wb, 1)
    `MACRO_DFF_NONEN(flop_commit0_lrd, commit0_lrd, 5)
    `MACRO_DFF_NONEN(flop_commit0_prd, commit0_prd, `PREG_LENGTH)
    `MACRO_DFF_NONEN(flop_commit0_pc, commit0_pc, `PC_LENGTH)
    `MACRO_DFF_NONEN(flop_commit0_instr, commit0_instr, 32)
    `MACRO_DFF_NONEN(flop_commit0_robid, commit0_robid, `ROB_SIZE_LOG + 1)


    DifftestInstrCommit u_DifftestInstrCommit (
        .clock     (clock),
        .enable    (flop_commit0_valid),
        .io_valid  ('b0),                      //unuse!!!!
        .io_skip   (flop_commit0_skip),
        .io_isRVC  (1'b0),
        .io_rfwen  (flop_commit0_need_to_wb),
        .io_fpwen  (1'b0),
        .io_vecwen (1'b0),
        .io_wpdest (),
        .io_wdest  (flop_commit0_lrd),
        .io_pc     (flop_commit0_pc),
        .io_instr  (flop_commit0_instr),
        .io_robIdx (flop_commit0_robid),
        .io_lqIdx  (flop_commit0_prd),
        .io_sqIdx  ('b0),
        .io_isLoad (1'b1),                     //load queue idx
        .io_isStore('b0),                      //store queue idx
        .io_nFused ('b0),
        .io_special('b0),
        .io_coreid ('b0),
        .io_index  ('b0)
    );


    // DifftestIntWriteback u_DifftestIntWriteback(
    //     .clock      (clock      ),
    //     .enable     (flop_commit0_valid     ),
    //     .io_valid   (   ), //usese!
    //     .io_address (io_address ),
    //     .io_data    (io_data    ),
    //     .io_coreid  (io_coreid  )
    // );


    reg [63:0] commit_cnt;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            commit_cnt <= 0;
        end else if (commit0_valid) begin
            commit_cnt <= commit_cnt + 1;
        end
    end
    reg [63:0] cycle_cnt;
    always @(posedge clock) begin
        if (~reset_n) begin
            cycle_cnt <= 'b0;
        end else begin
            cycle_cnt <= cycle_cnt + 1'b1;
        end

    end
    DifftestTrapEvent u_DifftestTrapEvent (
        .clock      (clock),
        .enable     (1'b1),
        .io_hasTrap (1'b0),
        .io_cycleCnt(cycle_cnt),
        .io_instrCnt(commit_cnt),
        .io_hasWFI  ('b0),
        .io_code    ('b0),
        .io_pc      (flop_commit0_pc),
        .io_coreid  ('b0)
    );

    isu_pmu u_isu_pmu (
        .clock                         (clock),
        .end_of_program                (end_of_program),
        .intisq_pmu_block_enq_cycle_cnt(intisq_pmu_block_enq_cycle_cnt),
        .intisq_pmu_can_issue_more     (intisq_pmu_can_issue_more)
    );



endmodule






