`include "defines.sv"
module dispatch (
    input wire clock,
    input wire reset_n,

    input wire iq_can_alloc0,
    input wire iq_load0_can_alloc,
    input wire iq_st0_can_alloc,
    input wire sq_can_alloc,

    /* ---------------------------instr0 from rename  --------------------------- */
    input  wire                      iru2isu_instr0_valid,
    output wire                      iru2isu_instr0_ready,
    //data to rob
    input  wire [         `PC_RANGE] instr0_pc,
    input  wire [              31:0] instr0_instr,
    input  wire [       `LREG_RANGE] instr0_lrs1,
    input  wire [       `LREG_RANGE] instr0_lrs2,
    input  wire [       `LREG_RANGE] instr0_lrd,
    input  wire [       `PREG_RANGE] instr0_prd,
    input  wire [       `PREG_RANGE] instr0_old_prd,
    input  wire                      instr0_need_to_wb,
    //remain info go to issue queue alone with above signals
    input  wire [       `PREG_RANGE] instr0_prs1,
    input  wire [       `PREG_RANGE] instr0_prs2,
    input  wire                      instr0_src1_is_reg,
    input  wire                      instr0_src2_is_reg,
    input  wire [              63:0] instr0_imm,
    input  wire [    `CX_TYPE_RANGE] instr0_cx_type,
    input  wire                      instr0_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] instr0_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input  wire                      instr0_is_word,
    input  wire                      instr0_is_imm,
    input  wire                      instr0_is_load,
    input  wire                      instr0_is_store,
    input  wire [               3:0] instr0_ls_size,
    input  wire                      iru2isu_instr0_predicttaken,
    input  wire [              31:0] iru2isu_instr0_predicttarget,


    /* ---------------------------instr1 from rename  --------------------------- */
    input  wire               iru2isu_instr1_valid,
    output wire               iru2isu_instr1_ready,
    //data to rob
    input  wire [  `PC_RANGE] instr1_pc,
    input  wire [       31:0] instr1_instr,
    input  wire [`LREG_RANGE] instr1_lrs1,
    input  wire [`LREG_RANGE] instr1_lrs2,
    input  wire [`LREG_RANGE] instr1_lrd,
    input  wire [`PREG_RANGE] instr1_prd,
    input  wire [`PREG_RANGE] instr1_old_prd,
    input  wire               instr1_need_to_wb,

    input wire [       `PREG_RANGE] instr1_prs1,
    input wire [       `PREG_RANGE] instr1_prs2,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire [              63:0] instr1_imm,
    input wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,
    input wire                      instr1_is_word,
    input wire                      instr1_is_imm,
    input wire                      instr1_is_load,
    input wire                      instr1_is_store,
    input wire [               3:0] instr1_ls_size,
    input wire                      iru2isu_instr1_predicttaken,
    input wire [              31:0] iru2isu_instr1_predicttarget,


    /* ------------------------------ port with rob ----------------------------- */
    //signal from rob
    input  wire                   rob_can_enq,
    input  wire [`ROB_SIZE_LOG:0] rob2disp_instr_robid,       //7 bit, robid send to isq
    input  wire [            1:0] rob_state,
    //write port
    output wire                   disp2rob_instr0_enq_valid,
    output wire [      `PC_RANGE] disp2rob_instr0_pc,
    output wire [           31:0] disp2rob_instr0_instr,
    output wire [    `LREG_RANGE] disp2rob_instr0_lrd,
    output wire [    `PREG_RANGE] disp2rob_instr0_prd,
    output wire [    `PREG_RANGE] disp2rob_instr0_old_prd,
    output wire                   disp2rob_instr0_need_to_wb,

    output wire               disp2rob_instr1_enq_valid,
    output wire [  `PC_RANGE] disp2rob_instr1_pc,
    output wire [       31:0] disp2rob_instr1_instr,
    output wire [`LREG_RANGE] disp2rob_instr1_lrd,
    output wire [`PREG_RANGE] disp2rob_instr1_prd,
    output wire [`PREG_RANGE] disp2rob_instr1_old_prd,
    output wire               disp2rob_instr1_need_to_wb,

    /* ------------------------------ to int isq ----------------------------- */
    output wire                      disp2intisq_instr0_enq_valid,
    output wire [         `PC_RANGE] disp2intisq_instr0_pc,
    output wire [              31:0] disp2intisq_instr0_instr,
    output wire [       `PREG_RANGE] disp2intisq_instr0_prd,
    output wire [       `PREG_RANGE] disp2intisq_instr0_old_prd,
    output wire                      disp2intisq_instr0_need_to_wb,
    output wire [       `PREG_RANGE] disp2intisq_instr0_prs1,
    output wire [       `PREG_RANGE] disp2intisq_instr0_prs2,
    output wire                      disp2intisq_instr0_src1_is_reg,
    output wire                      disp2intisq_instr0_src2_is_reg,
    output wire [              63:0] disp2intisq_instr0_imm,
    output wire [    `CX_TYPE_RANGE] disp2intisq_instr0_cx_type,
    output wire                      disp2intisq_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] disp2intisq_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] disp2intisq_instr0_muldiv_type,
    output wire                      disp2intisq_instr0_is_word,
    output wire                      disp2intisq_instr0_is_imm,
    output wire                      disp2intisq_instr0_is_load,
    output wire                      disp2intisq_instr0_is_store,
    output wire [               3:0] disp2intisq_instr0_ls_size,
    output wire [   `ROB_SIZE_LOG:0] disp2intisq_instr0_robid,          //7 bit, robid send to isq
    output wire [    `SQ_SIZE_LOG:0] disp2intisq_instr0_sqid,           //7 bit, robid send to isq
    output wire                      disp2intisq_instr0_predicttaken,
    output wire [              31:0] disp2intisq_instr0_predicttarget,
    output wire                      disp2intisq_instr0_src1_state,
    output wire                      disp2intisq_instr0_src2_state,


    /* ------------------------------ to mem isq ----------------------------- */
    output wire                   disp2memisg_instr0_valid,
    output wire [      `PC_RANGE] disp2memisg_instr0_pc,
    output wire [           31:0] disp2memisg_instr0,
    output wire [    `PREG_RANGE] disp2memisg_instr0_prd,
    output wire [    `PREG_RANGE] disp2memisg_instr0_old_prd,
    output wire [    `PREG_RANGE] disp2memisg_instr0_prs1,
    output wire [    `PREG_RANGE] disp2memisg_instr0_prs2,
    output wire [           63:0] disp2memisg_instr0_imm,
    output wire                   disp2memisg_instr0_is_unsigned,
    output wire                   disp2memisg_instr0_is_word,
    output wire                   disp2memisg_instr0_is_imm,
    output wire                   disp2memisg_instr0_is_load,
    output wire                   disp2memisg_instr0_is_store,
    output wire [            3:0] disp2memisg_instr0_ls_size,
    output wire [`ROB_SIZE_LOG:0] disp2memisg_instr0_robid,        //7 bit, robid send to isq
    output wire [ `SQ_SIZE_LOG:0] disp2memisg_instr0_sqid,
    output wire                   disp2memisg_instr0_src1_state,
    output wire                   disp2memisg_instr0_src2_state,


    /* -------------------------- port with store queue ------------------------- */
    input  wire [`SQ_SIZE_LOG : 0] sq_enqptr,
    output wire                    disp2sq_valid,
    output wire [ `ROB_SIZE_LOG:0] disp2sq_robid,
    output wire [       `PC_RANGE] disp2sq_pc,

    /* -------------------------- port with busy_table -------------------------- */
    // Read Port 0
    output wire [`PREG_RANGE] disp2bt_instr0_rs1,          // Address for disp2bt_instr0rs1_busy
    output wire               disp2bt_instr0_src1_is_reg,
    input  wire               bt2disp_instr0_src1_busy,
    // Read Port 1
    output wire [`PREG_RANGE] disp2bt_instr0_rs2,          // Address for disp2bt_instr0rs2_busy
    output wire               disp2bt_instr0_src2_is_reg,
    input  wire               bt2disp_instr0_src2_busy,
    // Read Port 2
    output wire [`PREG_RANGE] disp2bt_instr1_rs1,          // Address for disp2bt_instr1rs1_busy
    output wire               disp2bt_instr1_src1_is_reg,
    input  wire               bt2disp_instr1_src1_busy,
    // Read Port 3
    output wire [`PREG_RANGE] disp2bt_instr1_rs2,          // Address for disp2bt_instr1rs2_busy
    output wire               disp2bt_instr1_src2_is_reg,
    input  wire               bt2disp_instr1_src2_busy,

    // write busy bit to 1 in busy_table
    output wire               disp2bt_alloc_instr0_rd_en,  // Enable for alloc_instr0rd0
    output wire [`PREG_RANGE] disp2bt_alloc_instr0_rd,     // Address for alloc_instr0rd0
    output wire               disp2bt_alloc_instr1_rd_en,  // Enable for alloc_instr1rd1
    output wire [`PREG_RANGE] disp2bt_alloc_instr1_rd,     // Address for alloc_instr1rd1

    /* ---------------------------- flush logic ---------------------------- */
    //flush signals
    input wire flush_valid

);

    wire instr0_exceptrob_rdy;
    wire instr1_exceptrob_rdy;
    wire instr2_exceptrob_rdy;
    wire instr3_exceptrob_rdy;
    wire instr0_is_ls;
    wire instr1_is_ls;
    wire instr2_is_ls;
    wire instr3_is_ls;

    assign instr0_is_ls               = instr0_is_store || instr0_is_load;
    assign instr1_is_ls               = instr1_is_store || instr1_is_load;
    //For a specific resource , applcation valid sigs should be HIGH when other resources is ready except this specific resource.
    assign instr0_exceptrob_rdy      = instr0_is_store && sq_can_alloc && iq_st0_can_alloc || instr0_is_load && iq_load0_can_alloc || !instr0_is_ls && iq_can_alloc0;
    assign instr1_exceptrob_rdy      = instr1_is_store && sq_can_alloc && iq_st0_can_alloc || instr1_is_load && iq_load0_can_alloc || !instr1_is_ls && iq_can_alloc0;

    //disp2pipe ready
    assign iru2isu_instr0_ready       = rob_can_enq && instr0_exceptrob_rdy && ~flush_valid && (rob_state == `ROB_STATE_IDLE);
    assign iru2isu_instr1_ready       = 1'b0;

    /* --------------------- write instr0 and instr1 to rob --------------------- */
    assign disp2rob_instr0_enq_valid  = iru2isu_instr0_valid && ~flush_valid && instr0_exceptrob_rdy;
    assign disp2rob_instr0_pc         = instr0_pc;
    assign disp2rob_instr0_instr      = instr0_instr;
    assign disp2rob_instr0_lrd        = instr0_lrd;
    assign disp2rob_instr0_prd        = instr0_prd;
    assign disp2rob_instr0_old_prd    = instr0_old_prd;
    assign disp2rob_instr0_need_to_wb = instr0_need_to_wb;


    assign disp2rob_instr1_enq_valid  = iru2isu_instr1_valid;
    assign disp2rob_instr1_pc         = instr1_pc;
    assign disp2rob_instr1_instr      = instr1_instr;
    assign disp2rob_instr1_lrd        = instr1_lrd;
    assign disp2rob_instr1_prd        = instr1_prd;
    assign disp2rob_instr1_old_prd    = instr1_old_prd;
    assign disp2rob_instr1_need_to_wb = instr1_need_to_wb;

    /* ------------ write prd0 and prd1 busy bit to 1 in busy_vector ------------ */
    assign disp2bt_alloc_instr0_rd_en = instr0_need_to_wb && iru2isu_instr0_valid && ~flush_valid && instr0_exceptrob_rdy & rob_can_enq;
    assign disp2bt_alloc_instr0_rd    = instr0_prd;
    assign disp2bt_alloc_instr1_rd_en = instr1_need_to_wb && iru2isu_instr0_valid && ~flush_valid && instr1_exceptrob_rdy & rob_can_enq;
    assign disp2bt_alloc_instr1_rd    = instr1_prd;

    /* ------- read instr0 and instr1 rs1 rs2 busy status from busy_vector ------ */
    assign disp2bt_instr0_rs1         = instr0_prs1;  //use to set sleep bit in issue queue
    assign disp2bt_instr0_rs2         = instr0_prs2;  //use to set sleep bit in issue queue
    assign disp2bt_instr1_rs1         = instr1_prs1;  //use to set sleep bit in issue queue
    assign disp2bt_instr1_rs2         = instr1_prs2;  //use to set sleep bit in issue queue

    assign disp2bt_instr0_src1_is_reg = instr0_src1_is_reg;
    assign disp2bt_instr0_src2_is_reg = instr0_src2_is_reg;
    assign disp2bt_instr1_src1_is_reg = instr1_src1_is_reg;
    assign disp2bt_instr1_src2_is_reg = instr1_src2_is_reg;

    wire is_int;
    wire is_ls;
    assign is_int                           = iru2isu_instr0_valid & ~(instr0_is_load | instr0_is_store);
    assign is_ls                            = iru2isu_instr0_valid & (instr0_is_load | instr0_is_store);
    /* -------------------------------------------------------------------------- */
    /*                              to int issuequeue                             */
    /* -------------------------------------------------------------------------- */
    assign disp2intisq_instr0_enq_valid     = is_int && ~flush_valid && rob_can_enq && instr0_exceptrob_rdy;
    assign disp2intisq_instr0_pc            = instr0_pc;
    assign disp2intisq_instr0_instr         = instr0_instr;
    assign disp2intisq_instr0_prd           = instr0_prd;
    assign disp2intisq_instr0_old_prd       = instr0_old_prd;
    assign disp2intisq_instr0_need_to_wb    = instr0_need_to_wb;
    assign disp2intisq_instr0_prs1          = instr0_prs1;
    assign disp2intisq_instr0_prs2          = instr0_prs2;
    assign disp2intisq_instr0_src1_is_reg   = instr0_src1_is_reg;
    assign disp2intisq_instr0_src2_is_reg   = instr0_src2_is_reg;
    assign disp2intisq_instr0_imm           = instr0_imm;
    assign disp2intisq_instr0_cx_type       = instr0_cx_type;
    assign disp2intisq_instr0_is_unsigned   = instr0_is_unsigned;
    assign disp2intisq_instr0_alu_type      = instr0_alu_type;
    assign disp2intisq_instr0_muldiv_type   = instr0_muldiv_type;
    assign disp2intisq_instr0_is_word       = instr0_is_word;
    assign disp2intisq_instr0_is_imm        = instr0_is_imm;
    assign disp2intisq_instr0_is_load       = instr0_is_load;
    assign disp2intisq_instr0_is_store      = instr0_is_store;
    assign disp2intisq_instr0_ls_size       = instr0_ls_size;
    assign disp2intisq_instr0_robid         = rob2disp_instr_robid;
    assign disp2intisq_instr0_sqid          = sq_enqptr;
    assign disp2intisq_instr0_predicttaken  = iru2isu_instr0_predicttaken;
    assign disp2intisq_instr0_predicttarget = iru2isu_instr0_predicttarget;
    assign disp2intisq_instr0_src1_state    = bt2disp_instr0_src1_busy;
    assign disp2intisq_instr0_src2_state    = bt2disp_instr0_src2_busy;


    /* -------------------------------------------------------------------------- */
    /*                              to mem issuequeue                             */
    /* -------------------------------------------------------------------------- */
    assign disp2memisg_instr0_valid         = is_ls && ~flush_valid && rob_can_enq && sq_can_alloc;
    assign disp2memisg_instr0_pc            = instr0_pc;
    assign disp2memisg_instr0               = instr0_instr;
    assign disp2memisg_instr0_prd           = instr0_prd;
    assign disp2memisg_instr0_old_prd       = instr0_old_prd;
    assign disp2memisg_instr0_prs1          = instr0_prs1;
    assign disp2memisg_instr0_prs2          = instr0_prs2;
    assign disp2memisg_instr0_imm           = instr0_imm;
    assign disp2memisg_instr0_is_unsigned   = instr0_is_unsigned;
    assign disp2memisg_instr0_is_word       = instr0_is_word;
    assign disp2memisg_instr0_is_imm        = instr0_is_imm;
    assign disp2memisg_instr0_is_load       = instr0_is_load;
    assign disp2memisg_instr0_is_store      = instr0_is_store;
    assign disp2memisg_instr0_ls_size       = instr0_ls_size;
    assign disp2memisg_instr0_robid         = rob2disp_instr_robid;
    assign disp2memisg_instr0_sqid          = sq_enqptr;
    assign disp2memisg_instr0_src1_state    = bt2disp_instr0_src1_busy;
    assign disp2memisg_instr0_src2_state    = bt2disp_instr0_src2_busy;



    /* -------------------------------------------------------------------------- */
    /*                               to store queue                               */
    /* -------------------------------------------------------------------------- */
    assign disp2sq_valid                    = iru2isu_instr0_valid & instr0_is_store & ~flush_valid && rob_can_enq && iq_st0_can_alloc;
    assign disp2sq_robid                    = rob2disp_instr_robid;
    assign disp2sq_pc                       = instr0_pc;


endmodule


