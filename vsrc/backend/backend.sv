//compile and debug
//remove redundant parameter and define
module backend #(
) (
    input clock,
    input reset_n,

    input         ibuffer_instr_valid,
    output        ibuffer_instr_ready,        //backend control ibuffer read stall(backend_stall) and fifo_read_en
    input         ibuffer_predicttaken_out,
    input  [31:0] ibuffer_predicttarget_out,
    input  [31:0] ibuffer_inst_out,
    input  [31:0] ibuffer_pc_out,

    output        flush_valid,
    output [63:0] flush_target,

    // TBUS 
    output        tbus_index_valid,
    input         tbus_index_ready,
    output [31:0] tbus_index,
    output [31:0] tbus_write_data,
    output [ 3:0] tbus_write_mask,
    input  [31:0] tbus_read_data,
    input         tbus_operation_done,
    output        tbus_operation_type,
    output        mem2dcache_flush,

    //bht btb port
    output        intwb0_bht_write_enable,
    output [ 9:0] intwb0_bht_write_index,
    output        intwb0_bht_write_counter_select,
    output        intwb0_bht_write_inc,
    output        intwb0_bht_write_dec,
    output        intwb0_bht_valid_in,
    output        intwb0_btb_ce,
    output        intwb0_btb_we,
    output [ 3:0] intwb0_btb_wmask,
    output [ 9:0] intwb0_btb_write_index,
    output [47:0] intwb0_btb_din
);
    //---------------- internal signals ----------------//
    wire [`INSTR_ID_WIDTH-1:0] flush_robid;
    // commit signals
    wire                       commit0_valid;
    wire [               31:0] commit0_pc;
    wire [               31:0] commit0_instr;
    wire [                4:0] commit0_lrd;
    wire [                5:0] commit0_prd;
    wire [                5:0] commit0_old_prd;
    wire                       commit0_need_to_wb;
    wire [                5:0] commit0_robid;
    wire                       commit0_skip;

    wire                       commit1_valid;
    wire [               31:0] commit1_pc;
    wire [               31:0] commit1_instr;
    wire [                4:0] commit1_lrd;
    wire [                5:0] commit1_prd;
    wire [                5:0] commit1_old_prd;
    wire                       commit1_need_to_wb;
    wire [                5:0] commit1_robid;
    wire                       commit1_skip;

    /* --------------------- arch_rat : 32 arch regfile content -------------------- */
    wire [        `PREG_RANGE] debug_preg0;
    wire [        `PREG_RANGE] debug_preg1;
    wire [        `PREG_RANGE] debug_preg2;
    wire [        `PREG_RANGE] debug_preg3;
    wire [        `PREG_RANGE] debug_preg4;
    wire [        `PREG_RANGE] debug_preg5;
    wire [        `PREG_RANGE] debug_preg6;
    wire [        `PREG_RANGE] debug_preg7;
    wire [        `PREG_RANGE] debug_preg8;
    wire [        `PREG_RANGE] debug_preg9;
    wire [        `PREG_RANGE] debug_preg10;
    wire [        `PREG_RANGE] debug_preg11;
    wire [        `PREG_RANGE] debug_preg12;
    wire [        `PREG_RANGE] debug_preg13;
    wire [        `PREG_RANGE] debug_preg14;
    wire [        `PREG_RANGE] debug_preg15;
    wire [        `PREG_RANGE] debug_preg16;
    wire [        `PREG_RANGE] debug_preg17;
    wire [        `PREG_RANGE] debug_preg18;
    wire [        `PREG_RANGE] debug_preg19;
    wire [        `PREG_RANGE] debug_preg20;
    wire [        `PREG_RANGE] debug_preg21;
    wire [        `PREG_RANGE] debug_preg22;
    wire [        `PREG_RANGE] debug_preg23;
    wire [        `PREG_RANGE] debug_preg24;
    wire [        `PREG_RANGE] debug_preg25;
    wire [        `PREG_RANGE] debug_preg26;
    wire [        `PREG_RANGE] debug_preg27;
    wire [        `PREG_RANGE] debug_preg28;
    wire [        `PREG_RANGE] debug_preg29;
    wire [        `PREG_RANGE] debug_preg30;
    wire [        `PREG_RANGE] debug_preg31;

    // IDU <-> IRU
    wire                       iru2idu_instr0_ready;
    wire                       idu2iru_instr0_valid;
    wire [               31:0] idu2iru_instr0_instr;
    wire [               31:0] idu2iru_instr0_pc;
    wire [                4:0] idu2iru_instr0_lrs1;
    wire [                4:0] idu2iru_instr0_lrs2;
    wire [                4:0] idu2iru_instr0_lrd;
    wire [               31:0] idu2iru_instr0_imm;
    wire                       idu2iru_instr0_src1_is_reg;
    wire                       idu2iru_instr0_src2_is_reg;
    wire                       idu2iru_instr0_need_to_wb;
    wire [                2:0] idu2iru_instr0_cx_type;
    wire                       idu2iru_instr0_is_unsigned;
    wire [                3:0] idu2iru_instr0_alu_type;
    wire                       idu2iru_instr0_is_word;
    wire                       idu2iru_instr0_is_load;
    wire                       idu2iru_instr0_is_imm;
    wire                       idu2iru_instr0_is_store;
    wire [                1:0] idu2iru_instr0_ls_size;
    wire [                2:0] idu2iru_instr0_muldiv_type;
    wire [                5:0] idu2iru_instr0_prs1;
    wire [                5:0] idu2iru_instr0_prs2;
    wire [                5:0] idu2iru_instr0_prd;
    wire [                5:0] idu2iru_instr0_old_prd;
    wire                       idu2iru_instr0_predicttaken;
    wire [               31:0] idu2iru_instr0_predicttarget;


    // IRU <-> ISU
    wire                       iru2isu_instr0_valid;
    wire                       isu2iru_instr0_ready;
    wire [               31:0] iru2isu_instr0_instr;
    wire [               31:0] iru2isu_instr0_pc;
    wire [                4:0] iru2isu_instr0_lrs1;
    wire [                4:0] iru2isu_instr0_lrs2;
    wire [                4:0] iru2isu_instr0_lrd;
    wire [               31:0] iru2isu_instr0_imm;
    wire                       iru2isu_instr0_src1_is_reg;
    wire                       iru2isu_instr0_src2_is_reg;
    wire                       iru2isu_instr0_need_to_wb;
    wire [                2:0] iru2isu_instr0_cx_type;
    wire                       iru2isu_instr0_is_unsigned;
    wire [                3:0] iru2isu_instr0_alu_type;
    wire [                2:0] iru2isu_instr0_muldiv_type;
    wire                       iru2isu_instr0_is_word;
    wire                       iru2isu_instr0_is_imm;
    wire                       iru2isu_instr0_is_load;
    wire                       iru2isu_instr0_is_store;
    wire [                1:0] iru2isu_instr0_ls_size;
    wire [                5:0] iru2isu_instr0_prs1;
    wire [                5:0] iru2isu_instr0_prs2;
    wire [                5:0] iru2isu_instr0_prd;
    wire [                5:0] iru2isu_instr0_old_prd;
    wire                       iru2isu_instr0_predicttaken;
    wire [               31:0] iru2isu_instr0_predicttarget;

    // ISU <-> EXU
    wire [                5:0] isu2exu_instr0_robid;
    wire [               31:0] isu2exu_instr0_pc;
    wire [               31:0] isu2exu_instr0_instr;
    wire [                4:0] isu2exu_instr0_lrs1;
    wire [                4:0] isu2exu_instr0_lrs2;
    wire [                4:0] isu2exu_instr0_lrd;
    wire [                5:0] isu2exu_instr0_prd;
    wire [                5:0] isu2exu_instr0_old_prd;
    wire                       isu2exu_instr0_need_to_wb;
    wire [                5:0] isu2exu_instr0_prs1;
    wire [                5:0] isu2exu_instr0_prs2;
    wire                       isu2exu_instr0_src1_is_reg;
    wire                       isu2exu_instr0_src2_is_reg;
    wire [               31:0] isu2exu_instr0_imm;
    wire [                2:0] isu2exu_instr0_cx_type;
    wire                       isu2exu_instr0_is_unsigned;
    wire [                3:0] isu2exu_instr0_alu_type;
    wire [                2:0] isu2exu_instr0_muldiv_type;
    wire                       isu2exu_instr0_is_word;
    wire                       isu2exu_instr0_is_imm;
    wire                       isu2exu_instr0_is_load;
    wire                       isu2exu_instr0_is_store;
    wire [                1:0] isu2exu_instr0_ls_size;
    wire                       isu2exu_instr0_predicttaken;
    wire [               31:0] isu2exu_instr0_predicttarget;
    wire [      `RESULT_RANGE] isu2exu_instr0_src1;
    wire [      `RESULT_RANGE] isu2exu_instr0_src2;

    //writeback signal
    wire                       intwb0_instr_valid;
    wire [                5:0] intwb0_robid;
    wire [                5:0] intwb0_prd;
    wire                       intwb0_need_to_wb;
    wire [      `RESULT_RANGE] intwb0_result;

    wire                       memwb_instr_valid;
    wire [                5:0] memwb_robid;
    wire [                5:0] memwb_prd;
    wire                       memwb_need_to_wb;
    wire                       memwb_mmio_valid;
    wire [      `RESULT_RANGE] memwb_result;

    wire                       isu2exu_instr0_valid;
    wire                       deq_ready;

    // rob walk signal
    wire [                2:0] rob_state;
    wire                       rob_walk0_valid;
    wire                       rob_walk0_complete;
    wire [                4:0] rob_walk0_lrd;
    wire [                5:0] rob_walk0_prd;
    wire                       rob_walk1_valid;
    wire [                4:0] rob_walk1_lrd;
    wire [                5:0] rob_walk1_prd;
    wire                       rob_walk1_complete;

    wire                       int_instr_ready;
    wire                       mem_instr_ready;


    //TODO add _instr0_ to output port
    idu_top u_idu_top (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .ibuffer_instr_valid         (ibuffer_instr_valid),
        .ibuffer_predicttaken_out    (ibuffer_predicttaken_out),
        .ibuffer_predicttarget_out   (ibuffer_predicttarget_out),
        .ibuffer_inst_out            (ibuffer_inst_out),
        .ibuffer_pc_out              (ibuffer_pc_out),
        .ibuffer_instr_ready         (ibuffer_instr_ready),
        .flush_valid                 (flush_valid),
        .iru2idu_instr_ready         (iru2idu_instr0_ready),
        .idu2iru_instr_valid         (idu2iru_instr0_valid),
        .idu2iru_instr               (idu2iru_instr0_instr),
        .idu2iru_pc                  (idu2iru_instr0_pc),
        .idu2iru_lrs1                (idu2iru_instr0_lrs1),
        .idu2iru_lrs2                (idu2iru_instr0_lrs2),
        .idu2iru_lrd                 (idu2iru_instr0_lrd),
        .idu2iru_imm                 (idu2iru_instr0_imm),
        .idu2iru_src1_is_reg         (idu2iru_instr0_src1_is_reg),
        .idu2iru_src2_is_reg         (idu2iru_instr0_src2_is_reg),
        .idu2iru_need_to_wb          (idu2iru_instr0_need_to_wb),
        .idu2iru_cx_type             (idu2iru_instr0_cx_type),
        .idu2iru_is_unsigned         (idu2iru_instr0_is_unsigned),
        .idu2iru_alu_type            (idu2iru_instr0_alu_type),
        .idu2iru_is_word             (idu2iru_instr0_is_word),
        .idu2iru_is_load             (idu2iru_instr0_is_load),
        .idu2iru_is_imm              (idu2iru_instr0_is_imm),
        .idu2iru_is_store            (idu2iru_instr0_is_store),
        .idu2iru_ls_size             (idu2iru_instr0_ls_size),
        .idu2iru_muldiv_type         (idu2iru_instr0_muldiv_type),
        .idu2iru_prs1                (idu2iru_instr0_prs1),
        .idu2iru_prs2                (idu2iru_instr0_prs2),
        .idu2iru_prd                 (idu2iru_instr0_prd),
        .idu2iru_old_prd             (idu2iru_instr0_old_prd),
        .idu2iru_instr0_predicttaken (idu2iru_instr0_predicttaken),
        .idu2iru_instr0_predicttarget(idu2iru_instr0_predicttarget)
    );

    //TODO add idu2iru/ iru2isu prefix
    iru_top u_iru_top (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .commit0_valid               (commit0_valid),
        .commit0_need_to_wb          (commit0_need_to_wb),
        .commit0_lrd                 (commit0_lrd),
        .commit0_prd                 (commit0_prd),
        .commit0_old_prd             (commit0_old_prd),
        .commit1_valid               (commit1_valid),
        .commit1_need_to_wb          (commit1_need_to_wb),
        .commit1_lrd                 (commit1_lrd),
        .commit1_prd                 (commit1_prd),
        .commit1_old_prd             (commit1_old_prd),
        .idu2iru_instr0_valid        (idu2iru_instr0_valid),
        .iru2idu_instr0_ready        (iru2idu_instr0_ready),
        .idu2iru_instr0_instr        (idu2iru_instr0_instr),          //input
        .idu2iru_instr0_lrs1         (idu2iru_instr0_lrs1),
        .idu2iru_instr0_lrs2         (idu2iru_instr0_lrs2),
        .idu2iru_instr0_lrd          (idu2iru_instr0_lrd),
        .idu2iru_instr0_pc           (idu2iru_instr0_pc),
        .idu2iru_instr0_imm          (idu2iru_instr0_imm),
        .idu2iru_instr0_src1_is_reg  (idu2iru_instr0_src1_is_reg),
        .idu2iru_instr0_src2_is_reg  (idu2iru_instr0_src2_is_reg),
        .idu2iru_instr0_need_to_wb   (idu2iru_instr0_need_to_wb),
        .idu2iru_instr0_cx_type      (idu2iru_instr0_cx_type),
        .idu2iru_instr0_is_unsigned  (idu2iru_instr0_is_unsigned),
        .idu2iru_instr0_alu_type     (idu2iru_instr0_alu_type),
        .idu2iru_instr0_muldiv_type  (idu2iru_instr0_muldiv_type),
        .idu2iru_instr0_is_word      (idu2iru_instr0_is_word),
        .idu2iru_instr0_is_imm       (idu2iru_instr0_is_imm),
        .idu2iru_instr0_is_load      (idu2iru_instr0_is_load),
        .idu2iru_instr0_is_store     (idu2iru_instr0_is_store),
        .idu2iru_instr0_ls_size      (idu2iru_instr0_ls_size),
        .idu2iru_instr0_predicttaken (idu2iru_instr0_predicttaken),
        .idu2iru_instr0_predicttarget(idu2iru_instr0_predicttarget),
        .idu2iru_instr1_valid        (),
        .iru2idu_instr1_ready        (),
        .idu2iru_instr1_instr        (),
        .idu2iru_instr1_lrs1         (),
        .idu2iru_instr1_lrs2         (),
        .idu2iru_instr1_lrd          (),
        .idu2iru_instr1_pc           (),
        .idu2iru_instr1_imm          (),
        .idu2iru_instr1_src1_is_reg  (),
        .idu2iru_instr1_src2_is_reg  (),
        .idu2iru_instr1_need_to_wb   (),
        .idu2iru_instr1_cx_type      (),
        .idu2iru_instr1_is_unsigned  (),
        .idu2iru_instr1_alu_type     (),
        .idu2iru_instr1_muldiv_type  (),
        .idu2iru_instr1_is_word      (),
        .idu2iru_instr1_is_imm       (),
        .idu2iru_instr1_is_load      (),
        .idu2iru_instr1_is_store     (),
        .idu2iru_instr1_ls_size      (),
        .idu2iru_instr1_predicttaken (),
        .idu2iru_instr1_predicttarget(),
        .rob_state                   (rob_state),
        .walking_valid0              (rob_walk0_valid),
        .walking_valid1              (rob_walk1_valid),
        .walking_prd0                (rob_walk0_prd),
        .walking_prd1                (rob_walk1_prd),
        .walking_lrd0                (rob_walk0_lrd),
        .walking_lrd1                (rob_walk1_lrd),
        .flush_valid                 (flush_valid),
        .iru2isu_instr0_valid        (iru2isu_instr0_valid),
        .isu2iru_instr0_ready        (isu2iru_instr0_ready),
        .iru2isu_instr0_instr        (iru2isu_instr0_instr),          //output
        .iru2isu_instr0_pc           (iru2isu_instr0_pc),
        .iru2isu_instr0_lrs1         (iru2isu_instr0_lrs1),
        .iru2isu_instr0_lrs2         (iru2isu_instr0_lrs2),
        .iru2isu_instr0_lrd          (iru2isu_instr0_lrd),
        .iru2isu_instr0_imm          (iru2isu_instr0_imm),
        .iru2isu_instr0_src1_is_reg  (iru2isu_instr0_src1_is_reg),
        .iru2isu_instr0_src2_is_reg  (iru2isu_instr0_src2_is_reg),
        .iru2isu_instr0_need_to_wb   (iru2isu_instr0_need_to_wb),
        .iru2isu_instr0_cx_type      (iru2isu_instr0_cx_type),
        .iru2isu_instr0_is_unsigned  (iru2isu_instr0_is_unsigned),
        .iru2isu_instr0_alu_type     (iru2isu_instr0_alu_type),
        .iru2isu_instr0_muldiv_type  (iru2isu_instr0_muldiv_type),
        .iru2isu_instr0_is_word      (iru2isu_instr0_is_word),
        .iru2isu_instr0_is_imm       (iru2isu_instr0_is_imm),
        .iru2isu_instr0_is_load      (iru2isu_instr0_is_load),
        .iru2isu_instr0_is_store     (iru2isu_instr0_is_store),
        .iru2isu_instr0_ls_size      (iru2isu_instr0_ls_size),
        .iru2isu_instr0_prs1         (iru2isu_instr0_prs1),
        .iru2isu_instr0_prs2         (iru2isu_instr0_prs2),
        .iru2isu_instr0_prd          (iru2isu_instr0_prd),
        .iru2isu_instr0_old_prd      (iru2isu_instr0_old_prd),
        .iru2isu_instr0_predicttaken (iru2isu_instr0_predicttaken),
        .iru2isu_instr0_predicttarget(iru2isu_instr0_predicttarget),
        .debug_preg0                 (debug_preg0),
        .debug_preg1                 (debug_preg1),
        .debug_preg2                 (debug_preg2),
        .debug_preg3                 (debug_preg3),
        .debug_preg4                 (debug_preg4),
        .debug_preg5                 (debug_preg5),
        .debug_preg6                 (debug_preg6),
        .debug_preg7                 (debug_preg7),
        .debug_preg8                 (debug_preg8),
        .debug_preg9                 (debug_preg9),
        .debug_preg10                (debug_preg10),
        .debug_preg11                (debug_preg11),
        .debug_preg12                (debug_preg12),
        .debug_preg13                (debug_preg13),
        .debug_preg14                (debug_preg14),
        .debug_preg15                (debug_preg15),
        .debug_preg16                (debug_preg16),
        .debug_preg17                (debug_preg17),
        .debug_preg18                (debug_preg18),
        .debug_preg19                (debug_preg19),
        .debug_preg20                (debug_preg20),
        .debug_preg21                (debug_preg21),
        .debug_preg22                (debug_preg22),
        .debug_preg23                (debug_preg23),
        .debug_preg24                (debug_preg24),
        .debug_preg25                (debug_preg25),
        .debug_preg26                (debug_preg26),
        .debug_preg27                (debug_preg27),
        .debug_preg28                (debug_preg28),
        .debug_preg29                (debug_preg29),
        .debug_preg30                (debug_preg30),
        .debug_preg31                (debug_preg31)
    );


    isu_top u_isu_top (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .iru2isu_instr0_valid        (iru2isu_instr0_valid),
        .isu2iru_instr0_ready        (isu2iru_instr0_ready),
        .iru2isu_instr0_pc           (iru2isu_instr0_pc),
        .iru2isu_instr0_instr        (iru2isu_instr0_instr),
        .iru2isu_instr0_lrs1         (iru2isu_instr0_lrs1),
        .iru2isu_instr0_lrs2         (iru2isu_instr0_lrs2),
        .iru2isu_instr0_lrd          (iru2isu_instr0_lrd),
        .iru2isu_instr0_prd          (iru2isu_instr0_prd),
        .iru2isu_instr0_old_prd      (iru2isu_instr0_old_prd),
        .iru2isu_instr0_need_to_wb   (iru2isu_instr0_need_to_wb),
        .iru2isu_instr0_prs1         (iru2isu_instr0_prs1),
        .iru2isu_instr0_prs2         (iru2isu_instr0_prs2),
        .iru2isu_instr0_src1_is_reg  (iru2isu_instr0_src1_is_reg),
        .iru2isu_instr0_src2_is_reg  (iru2isu_instr0_src2_is_reg),
        .iru2isu_instr0_imm          (iru2isu_instr0_imm),
        .iru2isu_instr0_cx_type      (iru2isu_instr0_cx_type),
        .iru2isu_instr0_is_unsigned  (iru2isu_instr0_is_unsigned),
        .iru2isu_instr0_alu_type     (iru2isu_instr0_alu_type),
        .iru2isu_instr0_muldiv_type  (iru2isu_instr0_muldiv_type),
        .iru2isu_instr0_is_word      (iru2isu_instr0_is_word),
        .iru2isu_instr0_is_imm       (iru2isu_instr0_is_imm),
        .iru2isu_instr0_is_load      (iru2isu_instr0_is_load),
        .iru2isu_instr0_is_store     (iru2isu_instr0_is_store),
        .iru2isu_instr0_ls_size      (iru2isu_instr0_ls_size),
        .iru2isu_instr0_predicttaken (iru2isu_instr0_predicttaken),
        .iru2isu_instr0_predicttarget(iru2isu_instr0_predicttarget),
        .iru2isu_instr1_valid        (),
        .isu2iru_instr1_ready        (),
        .iru2isu_instr1_pc           (),
        .iru2isu_instr1_instr        (),
        .iru2isu_instr1_lrs1         (),
        .iru2isu_instr1_lrs2         (),
        .iru2isu_instr1_lrd          (),
        .iru2isu_instr1_prd          (),
        .iru2isu_instr1_old_prd      (),
        .iru2isu_instr1_need_to_wb   (),
        .iru2isu_instr1_prs1         (),
        .iru2isu_instr1_prs2         (),
        .iru2isu_instr1_src1_is_reg  (),
        .iru2isu_instr1_src2_is_reg  (),
        .iru2isu_instr1_imm          (),
        .iru2isu_instr1_cx_type      (),
        .iru2isu_instr1_is_unsigned  (),
        .iru2isu_instr1_alu_type     (),
        .iru2isu_instr1_muldiv_type  (),
        .iru2isu_instr1_is_word      (),
        .iru2isu_instr1_is_imm       (),
        .iru2isu_instr1_is_load      (),
        .iru2isu_instr1_is_store     (),
        .iru2isu_instr1_ls_size      (),
        .iru2isu_instr1_predicttaken (),
        .iru2isu_instr1_predicttarget(),
        .intwb0_instr_valid          (intwb0_instr_valid),            //input
        .intwb0_robid                (intwb0_robid),                  //input
        .intwb0_prd                  (intwb0_prd),                    //input
        .intwb0_need_to_wb           (intwb0_need_to_wb),             //input
        .intwb0_result               (intwb0_result),
        .memwb_instr_valid           (memwb_instr_valid),             //input
        .memwb_robid                 (memwb_robid),                   //input
        .memwb_prd                   (memwb_prd),                     //input
        .memwb_need_to_wb            (memwb_need_to_wb),              //input
        .memwb_mmio_valid            (memwb_mmio_valid),              //input
        .memwb_result                (memwb_result),
        .flush_valid                 (flush_valid),                   //input
        .flush_robid                 (flush_robid),                   //input
        .commit0_valid               (commit0_valid),                 //OUTUPT
        .commit0_pc                  (commit0_pc),                    //OUTUPT
        .commit0_instr               (commit0_instr),                 //OUTUPT
        .commit0_lrd                 (commit0_lrd),                   //OUTUPT
        .commit0_prd                 (commit0_prd),                   //OUTUPT
        .commit0_old_prd             (commit0_old_prd),               //OUTUPT
        .commit0_need_to_wb          (commit0_need_to_wb),            //OUTUPT
        .commit0_robid               (commit0_robid),                 //OUTUPT
        .commit0_skip                (commit0_skip),                  //OUTUPT
        .commit1_valid               (),
        .commit1_pc                  (),
        .commit1_instr               (),
        .commit1_lrd                 (),
        .commit1_prd                 (),
        .commit1_old_prd             (),
        .commit1_robid               (),
        .commit1_need_to_wb          (),
        .commit1_skip                (),
        .isu2exu_instr0_robid        (isu2exu_instr0_robid),
        .isu2exu_instr0_pc           (isu2exu_instr0_pc),
        .isu2exu_instr0_instr        (isu2exu_instr0_instr),
        .isu2exu_instr0_lrs1         (isu2exu_instr0_lrs1),
        .isu2exu_instr0_lrs2         (isu2exu_instr0_lrs2),
        .isu2exu_instr0_lrd          (isu2exu_instr0_lrd),
        .isu2exu_instr0_prd          (isu2exu_instr0_prd),
        .isu2exu_instr0_old_prd      (isu2exu_instr0_old_prd),
        .isu2exu_instr0_need_to_wb   (isu2exu_instr0_need_to_wb),
        .isu2exu_instr0_prs1         (isu2exu_instr0_prs1),
        .isu2exu_instr0_prs2         (isu2exu_instr0_prs2),
        .isu2exu_instr0_src1_is_reg  (isu2exu_instr0_src1_is_reg),
        .isu2exu_instr0_src2_is_reg  (isu2exu_instr0_src2_is_reg),
        .isu2exu_instr0_imm          (isu2exu_instr0_imm),
        .isu2exu_instr0_cx_type      (isu2exu_instr0_cx_type),
        .isu2exu_instr0_is_unsigned  (isu2exu_instr0_is_unsigned),
        .isu2exu_instr0_alu_type     (isu2exu_instr0_alu_type),
        .isu2exu_instr0_muldiv_type  (isu2exu_instr0_muldiv_type),
        .isu2exu_instr0_is_word      (isu2exu_instr0_is_word),
        .isu2exu_instr0_is_imm       (isu2exu_instr0_is_imm),
        .isu2exu_instr0_is_load      (isu2exu_instr0_is_load),
        .isu2exu_instr0_is_store     (isu2exu_instr0_is_store),
        .isu2exu_instr0_ls_size      (isu2exu_instr0_ls_size),
        .isu2exu_instr0_predicttaken (isu2exu_instr0_predicttaken),
        .isu2exu_instr0_predicttarget(isu2exu_instr0_predicttarget),
        .isu2exu_instr0_src1         (isu2exu_instr0_src1),
        .isu2exu_instr0_src2         (isu2exu_instr0_src2),
        .intisq_deq_valid            (isu2exu_instr0_valid),
        .intisq_deq_ready            (exu2isu_instr0_ready),
        .rob_state                   (rob_state),                     //OUTPUT
        .rob_walk0_valid             (rob_walk0_valid),               //OUTPUT
        .rob_walk0_complete          (rob_walk0_complete),            //OUTPUT
        .rob_walk0_lrd               (rob_walk0_lrd),                 //OUTPUT
        .rob_walk0_prd               (rob_walk0_prd),                 //OUTPUT
        .rob_walk1_valid             (rob_walk1_valid),               //OUTPUT
        .rob_walk1_lrd               (rob_walk1_lrd),                 //OUTPUT
        .rob_walk1_prd               (rob_walk1_prd),                 //OUTPUT
        .rob_walk1_complete          (rob_walk1_complete),            //OUTPUT
        .debug_preg0                 (debug_preg0),                   //input
        .debug_preg1                 (debug_preg1),                   //input
        .debug_preg2                 (debug_preg2),                   //input
        .debug_preg3                 (debug_preg3),                   //input
        .debug_preg4                 (debug_preg4),                   //input
        .debug_preg5                 (debug_preg5),                   //input
        .debug_preg6                 (debug_preg6),                   //input
        .debug_preg7                 (debug_preg7),                   //input
        .debug_preg8                 (debug_preg8),                   //input
        .debug_preg9                 (debug_preg9),                   //input
        .debug_preg10                (debug_preg10),                  //input
        .debug_preg11                (debug_preg11),                  //input
        .debug_preg12                (debug_preg12),                  //input
        .debug_preg13                (debug_preg13),                  //input
        .debug_preg14                (debug_preg14),                  //input
        .debug_preg15                (debug_preg15),                  //input
        .debug_preg16                (debug_preg16),                  //input
        .debug_preg17                (debug_preg17),                  //input
        .debug_preg18                (debug_preg18),                  //input
        .debug_preg19                (debug_preg19),                  //input
        .debug_preg20                (debug_preg20),                  //input
        .debug_preg21                (debug_preg21),                  //input
        .debug_preg22                (debug_preg22),                  //input
        .debug_preg23                (debug_preg23),                  //input
        .debug_preg24                (debug_preg24),                  //input
        .debug_preg25                (debug_preg25),                  //input
        .debug_preg26                (debug_preg26),                  //input
        .debug_preg27                (debug_preg27),                  //input
        .debug_preg28                (debug_preg28),                  //input
        .debug_preg29                (debug_preg29),                  //input
        .debug_preg30                (debug_preg30),                  //input
        .debug_preg31                (debug_preg31)
    );

    // intblock always can accept, mem can accept only when no operation in process
    wire exu_available = int_instr_ready && mem_instr_ready;
    wire exu2isu_instr0_ready = exu_available;
    wire exu2isu_instr1_ready = 'b0;
    wire instr_goto_memblock = isu2exu_instr0_is_store || isu2exu_instr0_is_load;
    wire int_instr_valid = isu2exu_instr0_valid && ~instr_goto_memblock;
    wire mem_instr_valid = isu2exu_instr0_valid && instr_goto_memblock;

    exu_top u_exu_top (
        .clock                          (clock),
        .reset_n                        (reset_n),
        .int_instr_valid                (int_instr_valid),
        .int_instr_ready                (int_instr_ready),
        .int_instr                      (isu2exu_instr0_instr),
        .int_pc                         (isu2exu_instr0_pc),
        .int_robid                      (isu2exu_instr0_robid),
        .int_src1                       (isu2exu_instr0_src1),
        .int_src2                       (isu2exu_instr0_src2),
        .int_prd                        (isu2exu_instr0_prd),
        .int_imm                        (isu2exu_instr0_imm),
        .int_need_to_wb                 (isu2exu_instr0_need_to_wb),
        .int_cx_type                    (isu2exu_instr0_cx_type),
        .int_is_unsigned                (isu2exu_instr0_is_unsigned),
        .int_alu_type                   (isu2exu_instr0_alu_type),
        .int_muldiv_type                (isu2exu_instr0_muldiv_type),
        .int_is_imm                     (isu2exu_instr0_is_imm),
        .int_is_word                    (isu2exu_instr0_is_word),
        .int_predict_taken              (isu2exu_instr0_predicttaken),
        .int_predict_target             (isu2exu_instr0_predicttarget),
        .mem_instr_valid                (mem_instr_valid),
        .mem_instr_ready                (mem_instr_ready),
        .mem_instr                      (isu2exu_instr0_instr),
        .mem_pc                         (isu2exu_instr0_pc),
        .mem_robid                      (isu2exu_instr0_robid),
        .mem_src1                       (isu2exu_instr0_src1),
        .mem_src2                       (isu2exu_instr0_src2),
        .mem_prd                        (isu2exu_instr0_prd),
        .mem_imm                        (isu2exu_instr0_imm),
        .mem_is_load                    (isu2exu_instr0_is_load),
        .mem_is_store                   (isu2exu_instr0_is_store),
        .mem_is_unsigned                (isu2exu_instr0_is_unsigned),
        .mem_ls_size                    (isu2exu_instr0_ls_size),
        .tbus_index_valid               (tbus_index_valid),
        .tbus_index_ready               (tbus_index_ready),
        .tbus_index                     (tbus_index),
        .tbus_write_data                (tbus_write_data),
        .tbus_write_mask                (tbus_write_mask),
        .tbus_read_data                 (tbus_read_data),
        .tbus_operation_done            (tbus_operation_done),
        .tbus_operation_type            (tbus_operation_type),
        .intwb0_instr_valid             (intwb0_instr_valid),
        .intwb0_need_to_wb              (intwb0_need_to_wb),
        .intwb0_prd                     (intwb0_prd),
        .intwb0_result                  (intwb0_result),
        .intwb0_bht_write_enable        (intwb0_bht_write_enable),
        .intwb0_bht_write_index         (intwb0_bht_write_index),
        .intwb0_bht_write_counter_select(intwb0_bht_write_counter_select),
        .intwb0_bht_write_inc           (intwb0_bht_write_inc),
        .intwb0_bht_write_dec           (intwb0_bht_write_dec),
        .intwb0_bht_valid_in            (intwb0_bht_valid_in),
        .intwb0_btb_ce                  (intwb0_btb_ce),
        .intwb0_btb_we                  (intwb0_btb_we),
        .intwb0_btb_wmask               (intwb0_btb_wmask),
        .intwb0_btb_write_index         (intwb0_btb_write_index),
        .intwb0_btb_din                 (intwb0_btb_din),
        .intwb0_robid                   (intwb0_robid),
        .intwb0_instr                   (),
        .intwb0_pc                      (),
        .mem2dcache_flush               (mem2dcache_flush),
        .flush_valid                    (flush_valid),                      //rename signal
        .flush_target                   (flush_target),                     //rename signal
        .flush_robid                    (flush_robid),
        .memwb_instr_valid              (memwb_instr_valid),
        .memwb_robid                    (memwb_robid),
        .memwb_prd                      (memwb_prd),
        .memwb_need_to_wb               (memwb_need_to_wb),
        .memwb_mmio_valid               (memwb_mmio_valid),
        .memwb_result                   (memwb_result),                     //rename signal
        .memwb_instr                    (),
        .memwb_pc                       ()
    );



endmodule
