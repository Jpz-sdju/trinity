`include "defines.sv"
module iru_top (
    input wire clock,
    input wire reset_n,

    // Commit Ports from rob
    input wire       commit0_valid,
    input wire       commit0_need_to_wb,
    input wire [4:0] commit0_lrd,
    input wire [5:0] commit0_prd,
    input wire [5:0] commit0_old_prd,

    input wire       commit1_valid,
    input wire       commit1_need_to_wb,
    input wire [4:0] commit1_lrd,
    input wire [5:0] commit1_prd,
    input wire [5:0] commit1_old_prd,

    // Instruction 0 Inputs
    input  wire                      idu2iru_instr0_valid,
    output wire                      iru2idu_instr0_ready,
    input  wire [              31:0] idu2iru_instr0_instr,
    input  wire [       `LREG_RANGE] idu2iru_instr0_lrs1,
    input  wire [       `LREG_RANGE] idu2iru_instr0_lrs2,
    input  wire [       `LREG_RANGE] idu2iru_instr0_lrd,
    input  wire [         `PC_RANGE] idu2iru_instr0_pc,
    input  wire [              63:0] idu2iru_instr0_imm,
    input  wire                      idu2iru_instr0_src1_is_reg,
    input  wire                      idu2iru_instr0_src2_is_reg,
    input  wire                      idu2iru_instr0_need_to_wb,
    input  wire [    `CX_TYPE_RANGE] idu2iru_instr0_cx_type,
    input  wire                      idu2iru_instr0_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] idu2iru_instr0_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] idu2iru_instr0_muldiv_type,
    input  wire                      idu2iru_instr0_is_word,
    input  wire                      idu2iru_instr0_is_imm,
    input  wire                      idu2iru_instr0_is_load,
    input  wire                      idu2iru_instr0_is_store,
    input  wire [               3:0] idu2iru_instr0_ls_size,
    input  wire                      idu2iru_instr0_predicttaken,
    input  wire [              31:0] idu2iru_instr0_predicttarget,


    // Instruction 1 Inputs
    input  wire                      idu2iru_instr1_valid,
    output wire                      iru2idu_instr1_ready,
    input  wire [              31:0] idu2iru_instr1_instr,
    input  wire [       `LREG_RANGE] idu2iru_instr1_lrs1,
    input  wire [       `LREG_RANGE] idu2iru_instr1_lrs2,
    input  wire [       `LREG_RANGE] idu2iru_instr1_lrd,
    input  wire [         `PC_RANGE] idu2iru_instr1_pc,
    input  wire [              63:0] idu2iru_instr1_imm,
    input  wire                      idu2iru_instr1_src1_is_reg,
    input  wire                      idu2iru_instr1_src2_is_reg,
    input  wire                      idu2iru_instr1_need_to_wb,
    input  wire [    `CX_TYPE_RANGE] idu2iru_instr1_cx_type,
    input  wire                      idu2iru_instr1_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] idu2iru_instr1_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] idu2iru_instr1_muldiv_type,
    input  wire                      idu2iru_instr1_is_word,
    input  wire                      idu2iru_instr1_is_imm,
    input  wire                      idu2iru_instr1_is_load,
    input  wire                      idu2iru_instr1_is_store,
    input  wire [               3:0] idu2iru_instr1_ls_size,
    input  wire                      idu2iru_instr1_predicttaken,
    input  wire [              31:0] idu2iru_instr1_predicttarget,

    // Walk Signals
    input wire [1:0] rob_state,

    input wire       rob_walk0_valid,
    input wire       rob_walk1_valid,
    input wire [5:0] rob_walk0_prd,
    input wire [5:0] rob_walk1_prd,
    input wire [4:0] rob_walk0_lrd,
    input wire [4:0] rob_walk1_lrd,


    // Flush
    input wire flush_valid,

    // Pipeline Outputs for instruction 0
    output wire iru2isu_instr0_valid,
    input  wire iru2isu_instr0_ready,

    output wire [              31:0] iru2isu_instr0_instr,
    output wire [         `PC_RANGE] iru2isu_instr0_pc,
    output wire [       `LREG_RANGE] iru2isu_instr0_lrs1,
    output wire [       `LREG_RANGE] iru2isu_instr0_lrs2,
    output wire [       `LREG_RANGE] iru2isu_instr0_lrd,
    output wire [              63:0] iru2isu_instr0_imm,
    output wire                      iru2isu_instr0_src1_is_reg,
    output wire                      iru2isu_instr0_src2_is_reg,
    output wire                      iru2isu_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] iru2isu_instr0_cx_type,
    output wire                      iru2isu_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] iru2isu_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] iru2isu_instr0_muldiv_type,
    output wire                      iru2isu_instr0_is_word,
    output wire                      iru2isu_instr0_is_imm,
    output wire                      iru2isu_instr0_is_load,
    output wire                      iru2isu_instr0_is_store,
    output wire [               3:0] iru2isu_instr0_ls_size,
    output wire [       `PREG_RANGE] iru2isu_instr0_prs1,
    output wire [       `PREG_RANGE] iru2isu_instr0_prs2,
    output wire [       `PREG_RANGE] iru2isu_instr0_prd,
    output wire [       `PREG_RANGE] iru2isu_instr0_old_prd,
    //TODO delete _out suffix
    output wire                      iru2isu_instr0_predicttaken,
    output wire [              31:0] iru2isu_instr0_predicttarget,


    // // Pipeline Outputs for instruction 1
    // output wire iru2isu_instr1_valid,
    // input wire isu2iru_instr1_ready,
    // output wire [31:0] iru_instr1_instr,
    // output wire [`PC_RANGE] iru_instr1_pc,
    // output wire [`LREG_RANGE] iru_instr1_lrs1,
    // output wire [`LREG_RANGE] iru_instr1_lrs2,
    // output wire [`LREG_RANGE] iru_instr1_lrd,
    // output wire [63:0] iru_instr1_imm,
    // output wire iru_instr1_src1_is_reg,
    // output wire iru_instr1_src2_is_reg,
    // output wire iru_instr1_need_to_wb,
    // output wire [`CX_TYPE_RANGE] iru_instr1_cx_type,
    // output wire iru_instr1_is_unsigned,
    // output wire [`ALU_TYPE_RANGE] iru_instr1_alu_type,
    // output wire [`MULDIV_TYPE_RANGE] iru_instr1_muldiv_type,
    // output wire iru_instr1_is_word,
    // output wire iru_instr1_is_imm,
    // output wire iru_instr1_is_load,
    // output wire iru_instr1_is_store,
    // output wire [3:0] iru_instr1_ls_size,
    // output wire [`PREG_RANGE] iru_instr1_prs1,
    // output wire [`PREG_RANGE] iru_instr1_prs2,
    // output wire [`PREG_RANGE] iru_instr1_prd,
    // output wire [`PREG_RANGE] iru_instr1_old_prd,
    //output wire                iru2isu_instr1_predicttaken_out,
    //output wire [31:0]         iru2isu_instr1_predicttarge_out,


    /* --------------------- arch_rat : 32 arch regfile content -------------------- */
    output wire [`PREG_RANGE] debug_preg0,
    output wire [`PREG_RANGE] debug_preg1,
    output wire [`PREG_RANGE] debug_preg2,
    output wire [`PREG_RANGE] debug_preg3,
    output wire [`PREG_RANGE] debug_preg4,
    output wire [`PREG_RANGE] debug_preg5,
    output wire [`PREG_RANGE] debug_preg6,
    output wire [`PREG_RANGE] debug_preg7,
    output wire [`PREG_RANGE] debug_preg8,
    output wire [`PREG_RANGE] debug_preg9,
    output wire [`PREG_RANGE] debug_preg10,
    output wire [`PREG_RANGE] debug_preg11,
    output wire [`PREG_RANGE] debug_preg12,
    output wire [`PREG_RANGE] debug_preg13,
    output wire [`PREG_RANGE] debug_preg14,
    output wire [`PREG_RANGE] debug_preg15,
    output wire [`PREG_RANGE] debug_preg16,
    output wire [`PREG_RANGE] debug_preg17,
    output wire [`PREG_RANGE] debug_preg18,
    output wire [`PREG_RANGE] debug_preg19,
    output wire [`PREG_RANGE] debug_preg20,
    output wire [`PREG_RANGE] debug_preg21,
    output wire [`PREG_RANGE] debug_preg22,
    output wire [`PREG_RANGE] debug_preg23,
    output wire [`PREG_RANGE] debug_preg24,
    output wire [`PREG_RANGE] debug_preg25,
    output wire [`PREG_RANGE] debug_preg26,
    output wire [`PREG_RANGE] debug_preg27,
    output wire [`PREG_RANGE] debug_preg28,
    output wire [`PREG_RANGE] debug_preg29,
    output wire [`PREG_RANGE] debug_preg30,
    output wire [`PREG_RANGE] debug_preg31,
    input wire end_of_program
);

    // Internal signals between modules
    wire                      rn2fl_instr0_lrd_valid;
    wire                      rn2fl_instr1_lrd_valid;
    wire [               5:0] fl2rn_instr0prd;
    wire [               5:0] fl2rn_instr1prd;
    wire                      freelist_can_alloc;

    wire                      rn2specrat_instr0_lrd_wren;
    wire [               4:0] rn2specrat_instr0_lrd_wraddr;
    wire [               5:0] rn2specrat_instr0_lrd_wrdata;
    wire                      rn2specrat_instr1_lrd_wren;
    wire [               4:0] rn2specrat_instr1_lrd_wraddr;
    wire [               5:0] rn2specrat_instr1_lrd_wrdata;

    wire                      rn2specrat_instr0_lrs1_rden;
    wire [               4:0] rn2specrat_instr0_lrs1;
    wire                      rn2specrat_instr0_lrs2_rden;
    wire [               4:0] rn2specrat_instr0_lrs2;
    wire                      rn2specrat_instr0_lrd_rden;
    wire [               4:0] rn2specrat_instr0_lrd;
    wire                      rn2specrat_instr1_lrs1_rden;
    wire [               4:0] rn2specrat_instr1_lrs1;
    wire                      rn2specrat_instr1_lrs2_rden;
    wire [               4:0] rn2specrat_instr1_lrs2;
    wire                      rn2specrat_instr1_lrd_rden;
    wire [               4:0] rn2specrat_instr1_lrd;

    wire [               5:0] specrat2rn_instr0prs1;
    wire [               5:0] specrat2rn_instr0prs2;
    wire [               5:0] specrat2rn_instr0prd;
    wire [               5:0] specrat2rn_instr1prs1;
    wire [               5:0] specrat2rn_instr1prs2;
    wire [               5:0] specrat2rn_instr1prd;

    wire                      rn2pipe_instr0_valid;
    wire                      rn2pipe_instr0_ready;
    wire [       `LREG_RANGE] rn2pipe_instr0_lrs1;
    wire [       `LREG_RANGE] rn2pipe_instr0_lrs2;
    wire [       `LREG_RANGE] rn2pipe_instr0_lrd;
    wire [         `PC_RANGE] rn2pipe_instr0_pc;
    wire [              31:0] rn2pipe_instr0_instr;
    wire [              63:0] rn2pipe_instr0_imm;
    wire                      rn2pipe_instr0_src1_is_reg;
    wire                      rn2pipe_instr0_src2_is_reg;
    wire                      rn2pipe_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] rn2pipe_instr0_cx_type;
    wire                      rn2pipe_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] rn2pipe_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] rn2pipe_instr0_muldiv_type;
    wire                      rn2pipe_instr0_is_word;
    wire                      rn2pipe_instr0_is_imm;
    wire                      rn2pipe_instr0_is_load;
    wire                      rn2pipe_instr0_is_store;
    wire [               3:0] rn2pipe_instr0_ls_size;
    wire [       `PREG_RANGE] rn2pipe_instr0_prs1;
    wire [       `PREG_RANGE] rn2pipe_instr0_prs2;
    wire [       `PREG_RANGE] rn2pipe_instr0_prd;
    wire [       `PREG_RANGE] rn2pipe_instr0_old_prd;
    wire                      rn2pipe_instr0_predicttaken;
    wire [              31:0] rn2pipe_instr0_predicttarget;

    wire                      rn2pipe_instr1_valid;
    wire                      pipe2rn_instr1_ready;
    wire [       `LREG_RANGE] rn2pipe_instr1_lrs1;
    wire [       `LREG_RANGE] rn2pipe_instr1_lrs2;
    wire [       `LREG_RANGE] rn2pipe_instr1_lrd;
    wire [         `PC_RANGE] rn2pipe_instr1_pc;
    wire [              31:0] rn2pipe_instr1_instr;
    wire [              63:0] rn2pipe_instr1_imm;
    wire                      rn2pipe_instr1_src1_is_reg;
    wire                      rn2pipe_instr1_src2_is_reg;
    wire                      rn2pipe_instr1_need_to_wb;
    wire [    `CX_TYPE_RANGE] rn2pipe_instr1_cx_type;
    wire                      rn2pipe_instr1_is_unsigned;
    wire [   `ALU_TYPE_RANGE] rn2pipe_instr1_alu_type;
    wire [`MULDIV_TYPE_RANGE] rn2pipe_instr1_muldiv_type;
    wire                      rn2pipe_instr1_is_word;
    wire                      rn2pipe_instr1_is_imm;
    wire                      rn2pipe_instr1_is_load;
    wire                      rn2pipe_instr1_is_store;
    wire [               3:0] rn2pipe_instr1_ls_size;
    wire [       `PREG_RANGE] rn2pipe_instr1_prs1;
    wire [       `PREG_RANGE] rn2pipe_instr1_prs2;
    wire [       `PREG_RANGE] rn2pipe_instr1_prd;
    wire [       `PREG_RANGE] rn2pipe_instr1_old_prd;
    wire                      rn2pipe_instr1_predicttaken;
    wire [              31:0] rn2pipe_instr1_predicttarget;


    // ======================
    //        Rename
    // ======================
    rename u_rename (
        /* ----------------------------------- iru ---------------------------------- */
        //input instr from iru
        .instr0_valid        (idu2iru_instr0_valid),
        .instr0_ready        (iru2idu_instr0_ready),
        .instr0_instr        (idu2iru_instr0_instr),
        .instr0_lrs1         (idu2iru_instr0_lrs1),
        .instr0_lrs2         (idu2iru_instr0_lrs2),
        .instr0_lrd          (idu2iru_instr0_lrd),
        .instr0_pc           (idu2iru_instr0_pc),
        .instr0_imm          (idu2iru_instr0_imm),
        .instr0_src1_is_reg  (idu2iru_instr0_src1_is_reg),
        .instr0_src2_is_reg  (idu2iru_instr0_src2_is_reg),
        .instr0_need_to_wb   (idu2iru_instr0_need_to_wb),
        .instr0_cx_type      (idu2iru_instr0_cx_type),
        .instr0_is_unsigned  (idu2iru_instr0_is_unsigned),
        .instr0_alu_type     (idu2iru_instr0_alu_type),
        .instr0_muldiv_type  (idu2iru_instr0_muldiv_type),
        .instr0_is_word      (idu2iru_instr0_is_word),
        .instr0_is_imm       (idu2iru_instr0_is_imm),
        .instr0_is_load      (idu2iru_instr0_is_load),
        .instr0_is_store     (idu2iru_instr0_is_store),
        .instr0_ls_size      (idu2iru_instr0_ls_size),
        .instr0_predicttaken (idu2iru_instr0_predicttaken),
        .instr0_predicttarget(idu2iru_instr0_predicttarget),

        .instr1_valid               (),
        .instr1_ready               (),
        .instr1_instr               (),
        .instr1_lrs1                (),
        .instr1_lrs2                (),
        .instr1_lrd                 (),
        .instr1_pc                  (),
        .instr1_imm                 (),
        .instr1_src1_is_reg         (),
        .instr1_src2_is_reg         (),
        .instr1_need_to_wb          (),
        .instr1_cx_type             (),
        .instr1_is_unsigned         (),
        .instr1_alu_type            (),
        .instr1_muldiv_type         (),
        .instr1_is_word             (),
        .instr1_is_imm              (),
        .instr1_is_load             (),
        .instr1_is_store            (),
        .instr1_ls_size             (),
        .instr1_predicttaken        (),
        .instr1_predicttarget       (),
        /* -------------------------------- spec_rat -------------------------------- */
        //read from spec_rat
        .rn2specrat_instr0_lrs1_rden(rn2specrat_instr0_lrs1_rden),
        .rn2specrat_instr0_lrs1     (rn2specrat_instr0_lrs1),
        .rn2specrat_instr0_lrs2_rden(rn2specrat_instr0_lrs2_rden),
        .rn2specrat_instr0_lrs2     (rn2specrat_instr0_lrs2),
        .rn2specrat_instr0_lrd_rden (rn2specrat_instr0_lrd_rden),
        .rn2specrat_instr0_lrd      (rn2specrat_instr0_lrd),
        .specrat2rn_instr0prs1      (specrat2rn_instr0prs1),
        .specrat2rn_instr0prs2      (specrat2rn_instr0prs2),
        .specrat2rn_instr0prd       (specrat2rn_instr0prd),

        .rn2specrat_instr1_lrs1_rden(),
        .rn2specrat_instr1_lrs1     (),
        .rn2specrat_instr1_lrs2_rden(),
        .rn2specrat_instr1_lrs2     (),
        .rn2specrat_instr1_lrd_rden (),
        .rn2specrat_instr1_lrd      (),
        .specrat2rn_instr1prs1      (),
        .specrat2rn_instr1prs2      (),
        .specrat2rn_instr1prd       (),

        //read result from spec_rat
        .rn2specrat_instr0_lrd_wren  (rn2specrat_instr0_lrd_wren),
        .rn2specrat_instr0_lrd_wraddr(rn2specrat_instr0_lrd_wraddr),
        .rn2specrat_instr0_lrd_wrdata(rn2specrat_instr0_lrd_wrdata),
        .rn2specrat_instr1_lrd_wren  (),
        .rn2specrat_instr1_lrd_wraddr(),
        .rn2specrat_instr1_lrd_wrdata(),
        /* -------------------------------- freelist -------------------------------- */
        //read available free physical reg number from freelist
        .flush_valid                 (flush_valid),
        .rn2fl_instr0_lrd_valid      (rn2fl_instr0_lrd_valid),
        .rn2fl_instr1_lrd_valid      (),
        .fl2rn_instr0prd             (fl2rn_instr0prd),
        .fl2rn_instr1prd             (),
        /* ------------------------- output to pipe , then isu ------------------------ */
        .rn2pipe_instr0_prs1         (rn2pipe_instr0_prs1),
        .rn2pipe_instr0_prs2         (rn2pipe_instr0_prs2),
        .rn2pipe_instr0_prd          (rn2pipe_instr0_prd),
        .rn2pipe_instr0_valid        (rn2pipe_instr0_valid),
        .rn2pipe_instr0_ready        (rn2pipe_instr0_ready),
        .rn2pipe_instr0_lrs1         (rn2pipe_instr0_lrs1),
        .rn2pipe_instr0_lrs2         (rn2pipe_instr0_lrs2),
        .rn2pipe_instr0_lrd          (rn2pipe_instr0_lrd),
        .rn2pipe_instr0_pc           (rn2pipe_instr0_pc),
        .rn2pipe_instr0_instr        (rn2pipe_instr0_instr),
        .rn2pipe_instr0_imm          (rn2pipe_instr0_imm),
        .rn2pipe_instr0_src1_is_reg  (rn2pipe_instr0_src1_is_reg),
        .rn2pipe_instr0_src2_is_reg  (rn2pipe_instr0_src2_is_reg),
        .rn2pipe_instr0_need_to_wb   (rn2pipe_instr0_need_to_wb),
        .rn2pipe_instr0_cx_type      (rn2pipe_instr0_cx_type),
        .rn2pipe_instr0_is_unsigned  (rn2pipe_instr0_is_unsigned),
        .rn2pipe_instr0_alu_type     (rn2pipe_instr0_alu_type),
        .rn2pipe_instr0_muldiv_type  (rn2pipe_instr0_muldiv_type),
        .rn2pipe_instr0_is_word      (rn2pipe_instr0_is_word),
        .rn2pipe_instr0_is_imm       (rn2pipe_instr0_is_imm),
        .rn2pipe_instr0_is_load      (rn2pipe_instr0_is_load),
        .rn2pipe_instr0_is_store     (rn2pipe_instr0_is_store),
        .rn2pipe_instr0_ls_size      (rn2pipe_instr0_ls_size),
        .rn2pipe_instr0_old_prd      (rn2pipe_instr0_old_prd),
        .rn2pipe_instr0_predicttaken (rn2pipe_instr0_predicttaken),
        .rn2pipe_instr0_predicttarget(rn2pipe_instr0_predicttarget),
        .rn2pipe_instr1_prs1         (),
        .rn2pipe_instr1_prs2         (),
        .rn2pipe_instr1_prd          (),
        .rn2pipe_instr1_valid        (),
        .pipe2rn_instr1_ready        (),
        .rn2pipe_instr1_lrs1         (),
        .rn2pipe_instr1_lrs2         (),
        .rn2pipe_instr1_lrd          (),
        .rn2pipe_instr1_pc           (),
        .rn2pipe_instr1_instr        (),
        .rn2pipe_instr1_imm          (),
        .rn2pipe_instr1_src1_is_reg  (),
        .rn2pipe_instr1_src2_is_reg  (),
        .rn2pipe_instr1_need_to_wb   (),
        .rn2pipe_instr1_cx_type      (),
        .rn2pipe_instr1_is_unsigned  (),
        .rn2pipe_instr1_alu_type     (),
        .rn2pipe_instr1_muldiv_type  (),
        .rn2pipe_instr1_is_word      (),
        .rn2pipe_instr1_is_imm       (),
        .rn2pipe_instr1_is_load      (),
        .rn2pipe_instr1_is_store     (),
        .rn2pipe_instr1_ls_size      (),
        .rn2pipe_instr1_old_prd      (),
        .rn2pipe_instr1_predicttaken (),
        .rn2pipe_instr1_predicttarget(),
        .freelist_can_alloc          (freelist_can_alloc)

    );


    /* -------------------------------------------------------------------------- */
    /*                                Freelist inst                               */
    /* -------------------------------------------------------------------------- */
    freelist u_freelist (
        .clock             (clock),
        .reset_n           (reset_n),
        .req0_valid        (rn2fl_instr0_lrd_valid),
        .req0_data         (fl2rn_instr0prd),
        .req1_valid        (),
        .req1_data         (),
        .write0_valid      (commit0_valid & commit0_need_to_wb),
        .write0_data       (commit0_old_prd),
        .write1_valid      (commit1_valid & commit1_need_to_wb),
        .write1_data       (commit1_old_prd),
        .rob_state         (rob_state),
        .rob_walk0_valid   (rob_walk0_valid),
        .rob_walk1_valid   (rob_walk1_valid),
        .freelist_can_alloc(freelist_can_alloc)
    );



    // ======================
    //   Speculative RAT
    // ======================
    spec_rat #(
        .DATA_WIDTH(124)
    ) u_spec_rat (

        .clock                       (clock),
        .reset_n                     (reset_n),
        //3 read port for instr0
        .rn2specrat_instr0_lrd_wren  (rn2specrat_instr0_lrd_wren),
        .rn2specrat_instr0_lrd_wraddr(rn2specrat_instr0_lrd_wraddr),
        .rn2specrat_instr0_lrd_wrdata(rn2specrat_instr0_lrd_wrdata),
        .rn2specrat_instr0_lrs1_rden (rn2specrat_instr0_lrs1_rden),
        .rn2specrat_instr0_lrs1      (rn2specrat_instr0_lrs1),
        .rn2specrat_instr0_lrs2_rden (rn2specrat_instr0_lrs2_rden),
        .rn2specrat_instr0_lrs2      (rn2specrat_instr0_lrs2),
        .rn2specrat_instr0_lrd_rden  (rn2specrat_instr0_lrd_rden),
        .rn2specrat_instr0_lrd       (rn2specrat_instr0_lrd),
        //3 read port for instr1
        .rn2specrat_instr1_lrd_wren  (),
        .rn2specrat_instr1_lrd_wraddr(),
        .rn2specrat_instr1_lrd_wrdata(),
        .rn2specrat_instr1_lrs1_rden (),
        .rn2specrat_instr1_lrs1      (),
        .rn2specrat_instr1_lrs2_rden (),
        .rn2specrat_instr1_lrs2      (),
        .rn2specrat_instr1_lrd_rden  (),
        .rn2specrat_instr1_lrd       (),
        //read result
        .specrat2rn_instr0prs1       (specrat2rn_instr0prs1),
        .specrat2rn_instr0prs2       (specrat2rn_instr0prs2),
        .specrat2rn_instr0prd        (specrat2rn_instr0prd),
        .specrat2rn_instr1prs1       (),
        .specrat2rn_instr1prs2       (),
        .specrat2rn_instr1prd        (),
        //commit write prd to arch rat
        .commit0_valid               (commit0_valid),
        .commit0_need_to_wb          (commit0_need_to_wb),
        .commit0_lrd                 (commit0_lrd),
        .commit0_prd                 (commit0_prd),
        .commit1_valid               (),
        .commit1_need_to_wb          (),
        .commit1_lrd                 (),
        .commit1_prd                 (),
        //walking write prd again to spec rat
        .rob_state                   (rob_state),
        .rob_walk0_valid             (rob_walk0_valid),
        .rob_walk1_valid             (rob_walk1_valid),
        .rob_walk0_prd               (rob_walk0_prd),
        .rob_walk1_prd               (rob_walk1_prd),
        .rob_walk0_lrd               (rob_walk0_lrd),
        .rob_walk1_lrd               (rob_walk1_lrd),

        //physical reg number of 32 architecture reg, send to isu pregfile to do difftest
        //(debug_preg0: physical reg number of arch reg 0)
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

    // =================================================
    // Pipeline Register (Auto-stall) for instruction 0
    // =================================================
    pipereg_autostall iru_pipereg_instr0 (
        .clock                 (clock),
        .reset_n               (reset_n),
        // from rename
        .instr_valid_from_upper(rn2pipe_instr0_valid),
        .instr_ready_to_upper  (rn2pipe_instr0_ready),
        .instr                 (rn2pipe_instr0_instr),
        .pc                    (rn2pipe_instr0_pc),
        .lrs1                  (rn2pipe_instr0_lrs1),
        .lrs2                  (rn2pipe_instr0_lrs2),
        .lrd                   (rn2pipe_instr0_lrd),
        .imm                   (rn2pipe_instr0_imm),
        .src1_is_reg           (rn2pipe_instr0_src1_is_reg),
        .src2_is_reg           (rn2pipe_instr0_src2_is_reg),
        .need_to_wb            (rn2pipe_instr0_need_to_wb),
        .cx_type               (rn2pipe_instr0_cx_type),
        .is_unsigned           (rn2pipe_instr0_is_unsigned),
        .alu_type              (rn2pipe_instr0_alu_type),
        .muldiv_type           (rn2pipe_instr0_muldiv_type),
        .is_word               (rn2pipe_instr0_is_word),
        .is_imm                (rn2pipe_instr0_is_imm),
        .is_load               (rn2pipe_instr0_is_load),
        .is_store              (rn2pipe_instr0_is_store),
        .ls_size               (rn2pipe_instr0_ls_size),
        .prs1                  (rn2pipe_instr0_prs1),
        .prs2                  (rn2pipe_instr0_prs2),
        .prd                   (rn2pipe_instr0_prd),
        .old_prd               (rn2pipe_instr0_old_prd),
        .ls_address            (64'b0),
        .alu_result            (64'b0),
        .bju_result            (64'b0),
        .muldiv_result         (64'b0),
        .opload_read_data_wb   (64'b0),
        .predicttaken          (idu2iru_instr0_predicttaken),
        .predicttarget         (idu2iru_instr0_predicttarget),

        .instr_valid_to_lower     (iru2isu_instr0_valid),
        .instr_ready_from_lower   (iru2isu_instr0_ready),
        .lower_instr              (iru2isu_instr0_instr),
        .lower_pc                 (iru2isu_instr0_pc),
        .lower_lrs1               (iru2isu_instr0_lrs1),
        .lower_lrs2               (iru2isu_instr0_lrs2),
        .lower_lrd                (iru2isu_instr0_lrd),
        .lower_imm                (iru2isu_instr0_imm),
        .lower_src1_is_reg        (iru2isu_instr0_src1_is_reg),
        .lower_src2_is_reg        (iru2isu_instr0_src2_is_reg),
        .lower_need_to_wb         (iru2isu_instr0_need_to_wb),
        .lower_cx_type            (iru2isu_instr0_cx_type),
        .lower_is_unsigned        (iru2isu_instr0_is_unsigned),
        .lower_alu_type           (iru2isu_instr0_alu_type),
        .lower_muldiv_type        (iru2isu_instr0_muldiv_type),
        .lower_is_word            (iru2isu_instr0_is_word),
        .lower_is_imm             (iru2isu_instr0_is_imm),
        .lower_is_load            (iru2isu_instr0_is_load),
        .lower_is_store           (iru2isu_instr0_is_store),
        .lower_ls_size            (iru2isu_instr0_ls_size),
        .lower_prs1               (iru2isu_instr0_prs1),
        .lower_prs2               (iru2isu_instr0_prs2),
        .lower_prd                (iru2isu_instr0_prd),
        .lower_old_prd            (iru2isu_instr0_old_prd),
        .lower_ls_address         (),
        .lower_alu_result         (),
        .lower_bju_result         (),
        .lower_muldiv_result      (),
        .lower_opload_read_data_wb(),
        .lower_predicttaken       (iru2isu_instr0_predicttaken),
        .lower_predicttarget      (iru2isu_instr0_predicttarget),
        // flush input
        .flush_valid              (flush_valid)
    );

    // =================================================
    // Pipeline Register (Auto-stall) for instruction 1
    // =================================================
    // pipereg_autostall iru_pipereg1 (
    //     .clock(clock),
    //     .reset_n(reset_n),
    //     // from rename
    //     .instr_valid_from_upper(rn2pipe_instr1_valid),
    //     .instr_ready_to_upper  (pipe2rn_instr1_ready),
    //     // pipeline data in
    //     .instr      (rn2pipe_instr1_instr            ),
    //     .pc         (rn2pipe_instr1_pc         ),
    //     .lrs1       (rn2pipe_instr1_lrs1       ),
    //     .lrs2       (rn2pipe_instr1_lrs2       ),
    //     .lrd        (rn2pipe_instr1_lrd        ),
    //     .imm        (rn2pipe_instr1_imm        ),
    //     .src1_is_reg(rn2pipe_instr1_src1_is_reg),
    //     .src2_is_reg(rn2pipe_instr1_src2_is_reg),
    //     .need_to_wb (rn2pipe_instr1_need_to_wb ),
    //     .cx_type    (rn2pipe_instr1_cx_type    ),
    //     .is_unsigned(rn2pipe_instr1_is_unsigned),
    //     .alu_type   (rn2pipe_instr1_alu_type   ),
    //     .muldiv_type(rn2pipe_instr1_muldiv_type),
    //     .is_word    (rn2pipe_instr1_is_word    ),
    //     .is_imm     (rn2pipe_instr1_is_imm     ),
    //     .is_load    (rn2pipe_instr1_is_load    ),
    //     .is_store   (rn2pipe_instr1_is_store   ),
    //     .ls_size    (rn2pipe_instr1_ls_size    ),
    //     .prs1       (rn2pipe_instr1_prs1       ),
    //     .prs2       (rn2pipe_instr1_prs2       ),
    //     .prd        (rn2pipe_instr1_prd        ),
    //     .old_prd    (rn2pipe_instr1_old_prd    ),

    //     // pipeline pass-throughs not used here
    //     .ls_address         (64'b0),
    //     .alu_result         (64'b0),
    //     .bju_result         (64'b0),
    //     .muldiv_result      (64'b0),
    //     .opload_read_data_wb(64'b0),

    //     .instr_valid_to_lower  (iru2isu_instr1_valid      ),
    //     .instr_ready_from_lower(isu2iru_instr1_ready      ),
    //     .lower_instr           (iru_instr1_instr      ),
    //     .lower_pc              (iru_instr1_pc         ),
    //     .lower_lrs1            (iru_instr1_lrs1       ),
    //     .lower_lrs2            (iru_instr1_lrs2       ),
    //     .lower_lrd             (iru_instr1_lrd        ),
    //     .lower_imm             (iru_instr1_imm        ),
    //     .lower_src1_is_reg     (iru_instr1_src1_is_reg),
    //     .lower_src2_is_reg     (iru_instr1_src2_is_reg),
    //     .lower_need_to_wb      (iru_instr1_need_to_wb ),
    //     .lower_cx_type         (iru_instr1_cx_type    ),
    //     .lower_is_unsigned     (iru_instr1_is_unsigned),
    //     .lower_alu_type        (iru_instr1_alu_type   ),
    //     .lower_muldiv_type     (iru_instr1_muldiv_type),
    //     .lower_is_word         (iru_instr1_is_word    ),
    //     .lower_is_imm          (iru_instr1_is_imm     ),
    //     .lower_is_load         (iru_instr1_is_load    ),
    //     .lower_is_store        (iru_instr1_is_store   ),
    //     .lower_ls_size         (iru_instr1_ls_size    ),
    //     .lower_prs1            (iru_instr1_prs1       ),
    //     .lower_prs2            (iru_instr1_prs2       ),
    //     .lower_prd             (iru_instr1_prd        ),
    //     .lower_old_prd         (iru_instr1_old_prd    ),
    //     // flush
    //     .flush_valid(flush_valid)
    // );

endmodule
