`include "defines.sv"
module backend (
    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire             clock,
    input  wire             reset_n,
    //from frontend
    input  wire             ibuffer_instr_valid,
    output wire             ibuffer_ready,
    input  wire [     31:0] ibuffer_inst_out,
    input  wire [`PC_RANGE] ibuffer_pc_out,

    /* ------------------------------ redirect sigs ----------------------------- */
    output wire                     redirect_valid,
    output wire [             63:0] redirect_target,
    output wire                     redirect_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] redirect_robidx,
    //stall pipeline
    output wire                     mem_stall,

    /* -------------------------------------------------------------------------- */
    /*                                TO L1 D$/MEM                                */
    /* -------------------------------------------------------------------------- */
    // LSU store Channel Inputs and Outputs
    //trinity bus channel
    output reg                  tbus_index_valid,
    input  wire                 tbus_index_ready,
    output reg  [`RESULT_RANGE] tbus_index,
    output reg  [   `SRC_RANGE] tbus_write_data,
    output reg  [         63:0] tbus_write_mask,

    input  wire [     `RESULT_RANGE] tbus_read_data,
    input  wire                      tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] tbus_operation_type,

    /* --------------------------- memblock to dcache --------------------------- */
    output wire memblock2dcache_flush
);

    /* ---------------------------- issue information --------------------------- */
    wire                      to_iq_instr0_ready;
    wire                      to_iq_instr0_valid;
    //used to memIQ
    wire                      to_iq_instr1_valid;
    wire [       `LREG_RANGE] to_iq_instr0_lrs1;
    wire [       `LREG_RANGE] to_iq_instr0_lrs2;
    wire [       `LREG_RANGE] to_iq_instr0_lrd;
    wire [         `PC_RANGE] to_iq_instr0_pc;
    wire [              31:0] to_iq_instr0;

    wire [              63:0] to_iq_instr0_imm;
    wire                      to_iq_instr0_src1_is_reg;
    wire                      to_iq_instr0_src2_is_reg;
    wire                      to_iq_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_iq_instr0_cx_type;
    wire                      to_iq_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_iq_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] to_iq_instr0_muldiv_type;
    wire                      to_iq_instr0_is_word;
    wire                      to_iq_instr0_is_imm;
    wire                      to_iq_instr0_is_load;
    wire                      to_iq_instr0_is_store;
    wire [               3:0] to_iq_instr0_ls_size;

    wire [       `PREG_RANGE] to_iq_instr0_prs1;
    wire [       `PREG_RANGE] to_iq_instr0_prs2;
    wire [       `PREG_RANGE] to_iq_instr0_prd;
    wire [       `PREG_RANGE] to_iq_instr0_old_prd;

    wire                      to_iq_instr0_robidx_flag;
    wire [ `ROB_SIZE_LOG-1:0] to_iq_instr0_robidx;

    wire                      to_iq_instr0_src1_state;
    wire                      to_iq_instr0_src2_state;

    /* ------------------- debug:to pregfile read for difftest ------------------ */
    wire [       `PREG_RANGE] debug_preg0;
    wire [       `PREG_RANGE] debug_preg1;
    wire [       `PREG_RANGE] debug_preg2;
    wire [       `PREG_RANGE] debug_preg3;
    wire [       `PREG_RANGE] debug_preg4;
    wire [       `PREG_RANGE] debug_preg5;
    wire [       `PREG_RANGE] debug_preg6;
    wire [       `PREG_RANGE] debug_preg7;
    wire [       `PREG_RANGE] debug_preg8;
    wire [       `PREG_RANGE] debug_preg9;
    wire [       `PREG_RANGE] debug_preg10;
    wire [       `PREG_RANGE] debug_preg11;
    wire [       `PREG_RANGE] debug_preg12;
    wire [       `PREG_RANGE] debug_preg13;
    wire [       `PREG_RANGE] debug_preg14;
    wire [       `PREG_RANGE] debug_preg15;
    wire [       `PREG_RANGE] debug_preg16;
    wire [       `PREG_RANGE] debug_preg17;
    wire [       `PREG_RANGE] debug_preg18;
    wire [       `PREG_RANGE] debug_preg19;
    wire [       `PREG_RANGE] debug_preg20;
    wire [       `PREG_RANGE] debug_preg21;
    wire [       `PREG_RANGE] debug_preg22;
    wire [       `PREG_RANGE] debug_preg23;
    wire [       `PREG_RANGE] debug_preg24;
    wire [       `PREG_RANGE] debug_preg25;
    wire [       `PREG_RANGE] debug_preg26;
    wire [       `PREG_RANGE] debug_preg27;
    wire [       `PREG_RANGE] debug_preg28;
    wire [       `PREG_RANGE] debug_preg29;
    wire [       `PREG_RANGE] debug_preg30;
    wire [       `PREG_RANGE] debug_preg31;

    /* -------------------------------------------------------------------------- */
    /*                                ctrl block                                  */
    /* -------------------------------------------------------------------------- */

    ctrlblock u_ctrlblock (
        .clock                   (clock),
        .reset_n                 (reset_n),
        .ibuffer_instr_valid     (ibuffer_instr_valid),
        .ibuffer_inst_out        (ibuffer_inst_out),
        .ibuffer_pc_out          (ibuffer_pc_out),
        .ibuffer_ready           (ibuffer_ready),
        .to_iq_instr0_ready      (to_iq_instr0_ready),
        .to_iq_instr0_valid      (to_iq_instr0_valid),
        .to_iq_instr0_lrs1       (to_iq_instr0_lrs1),
        .to_iq_instr0_lrs2       (to_iq_instr0_lrs2),
        .to_iq_instr0_lrd        (to_iq_instr0_lrd),
        .to_iq_instr0_pc         (to_iq_instr0_pc),
        .to_iq_instr0            (to_iq_instr0),
        .to_iq_instr0_imm        (to_iq_instr0_imm),
        .to_iq_instr0_src1_is_reg(to_iq_instr0_src1_is_reg),
        .to_iq_instr0_src2_is_reg(to_iq_instr0_src2_is_reg),
        .to_iq_instr0_need_to_wb (to_iq_instr0_need_to_wb),
        .to_iq_instr0_cx_type    (to_iq_instr0_cx_type),
        .to_iq_instr0_is_unsigned(to_iq_instr0_is_unsigned),
        .to_iq_instr0_alu_type   (to_iq_instr0_alu_type),
        .to_iq_instr0_muldiv_type(to_iq_instr0_muldiv_type),
        .to_iq_instr0_is_word    (to_iq_instr0_is_word),
        .to_iq_instr0_is_imm     (to_iq_instr0_is_imm),
        .to_iq_instr0_is_load    (to_iq_instr0_is_load),
        .to_iq_instr0_is_store   (to_iq_instr0_is_store),
        .to_iq_instr0_ls_size    (to_iq_instr0_ls_size),
        .to_iq_instr0_prs1       (to_iq_instr0_prs1),
        .to_iq_instr0_prs2       (to_iq_instr0_prs2),
        .to_iq_instr0_prd        (to_iq_instr0_prd),
        .to_iq_instr0_old_prd    (to_iq_instr0_old_prd),
        .to_iq_instr0_robidx_flag(to_iq_instr0_robidx_flag),
        .to_iq_instr0_robidx     (to_iq_instr0_robidx),
        .to_iq_instr1_ready      (),
        .to_iq_instr1_valid      (),
        .to_iq_instr1_lrs1       (),
        .to_iq_instr1_lrs2       (),
        .to_iq_instr1_lrd        (),
        .to_iq_instr1_pc         (),
        .to_iq_instr1            (),
        .to_iq_instr1_imm        (),
        .to_iq_instr1_src1_is_reg(),
        .to_iq_instr1_src2_is_reg(),
        .to_iq_instr1_need_to_wb (),
        .to_iq_instr1_cx_type    (),
        .to_iq_instr1_is_unsigned(),
        .to_iq_instr1_alu_type   (),
        .to_iq_instr1_muldiv_type(),
        .to_iq_instr1_is_word    (),
        .to_iq_instr1_is_imm     (),
        .to_iq_instr1_is_load    (),
        .to_iq_instr1_is_store   (),
        .to_iq_instr1_ls_size    (),
        .to_iq_instr1_prs1       (),
        .to_iq_instr1_prs2       (),
        .to_iq_instr1_prd        (),
        .to_iq_instr1_old_prd    (),
        .to_iq_instr1_robidx_flag(),
        .to_iq_instr1_robidx     (),

        //src state
        .to_iq_instr0_src1_state   (to_iq_instr0_src1_state),
        .to_iq_instr0_src2_state   (to_iq_instr0_src2_state),
        .to_iq_instr1_src1_state   (),
        .to_iq_instr1_src2_state   (),
        .flush_valid               (redirect_valid),
        .flush_target              (redirect_target),
        .flush_robidx_flag         (redirect_robidx_flag),
        .flush_robidx              (redirect_robidx),
        /* -------------------------------- writeback ------------------------------- */
        .writeback0_valid          (writeback0_instr_valid),
        .writeback0_need_to_wb     (writeback0_need_to_wb),
        .writeback0_prd            (writeback0_prd),
        .writeback0_redirect_valid (writeback0_redirect_valid),
        .writeback0_redirect_target(writeback0_redirect_target),
        .writeback0_robidx_flag    (writeback0_robidx_flag),
        .writeback0_robidx         (writeback0_robidx),

        .writeback1_valid      (writeback1_instr_valid),
        .writeback1_need_to_wb (writeback1_need_to_wb),
        .writeback1_prd        (writeback1_prd),
        .writeback1_mmio       (writeback1_mmio),
        .writeback1_robidx_flag(writeback1_robidx_flag),
        .writeback1_robidx     (writeback1_robidx),
        //debug
        .debug_preg0           (debug_preg0),
        .debug_preg1           (debug_preg1),
        .debug_preg2           (debug_preg2),
        .debug_preg3           (debug_preg3),
        .debug_preg4           (debug_preg4),
        .debug_preg5           (debug_preg5),
        .debug_preg6           (debug_preg6),
        .debug_preg7           (debug_preg7),
        .debug_preg8           (debug_preg8),
        .debug_preg9           (debug_preg9),
        .debug_preg10          (debug_preg10),
        .debug_preg11          (debug_preg11),
        .debug_preg12          (debug_preg12),
        .debug_preg13          (debug_preg13),
        .debug_preg14          (debug_preg14),
        .debug_preg15          (debug_preg15),
        .debug_preg16          (debug_preg16),
        .debug_preg17          (debug_preg17),
        .debug_preg18          (debug_preg18),
        .debug_preg19          (debug_preg19),
        .debug_preg20          (debug_preg20),
        .debug_preg21          (debug_preg21),
        .debug_preg22          (debug_preg22),
        .debug_preg23          (debug_preg23),
        .debug_preg24          (debug_preg24),
        .debug_preg25          (debug_preg25),
        .debug_preg26          (debug_preg26),
        .debug_preg27          (debug_preg27),
        .debug_preg28          (debug_preg28),
        .debug_preg29          (debug_preg29),
        .debug_preg30          (debug_preg30),
        .debug_preg31          (debug_preg31)
    );

    /* -------------------------------------------------------------------------- */
    /*                                 issue queue                                */
    /* -------------------------------------------------------------------------- */

    /* ------------------------------- to intBlock ------------------------------ */
    wire                      deq_instr0_valid;
    wire                      deq_instr0_ready;
    wire [       `PREG_RANGE] deq_instr0_prs1;
    wire [       `PREG_RANGE] deq_instr0_prs2;
    wire                      deq_instr0_src1_is_reg;
    wire                      deq_instr0_src2_is_reg;

    wire [       `PREG_RANGE] deq_instr0_prd;
    wire [       `PREG_RANGE] deq_instr0_old_prd;

    wire [        `SRC_RANGE] deq_instr0_pc;
    wire [        `SRC_RANGE] deq_instr0_imm;

    wire                      deq_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] deq_instr0_cx_type;
    wire                      deq_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] deq_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] deq_instr0_muldiv_type;
    wire                      deq_instr0_is_word;
    wire                      deq_instr0_is_imm;
    wire                      deq_instr0_is_load;
    wire                      deq_instr0_is_store;
    wire [               3:0] deq_instr0_ls_size;

    wire                      deq_instr0_robidx_flag;
    wire [ `ROB_SIZE_LOG-1:0] deq_instr0_robidx;

    /* ------------------------------- to memBlock ------------------------------ */
    wire                      to_memblock_instr0_valid;
    wire                      to_memblock_instr0_ready;
    wire [       `PREG_RANGE] to_memblock_instr0_prs1;
    wire [       `PREG_RANGE] to_memblock_instr0_prs2;
    wire                      to_memblock_instr0_src1_is_reg;
    wire                      to_memblock_instr0_src2_is_reg;

    wire [       `PREG_RANGE] to_memblock_instr0_prd;
    wire [       `PREG_RANGE] to_memblock_instr0_old_prd;

    wire [        `SRC_RANGE] to_memblock_instr0_pc;
    wire [        `SRC_RANGE] to_memblock_instr0_imm;

    wire                      to_memblock_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_memblock_instr0_cx_type;
    wire                      to_memblock_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_memblock_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] to_memblock_instr0_muldiv_type;
    wire                      to_memblock_instr0_is_word;
    wire                      to_memblock_instr0_is_imm;
    wire                      to_memblock_instr0_is_load;
    wire                      to_memblock_instr0_is_store;
    wire [               3:0] to_memblock_instr0_ls_size;

    wire                      to_memblock_instr0_robidx_flag;
    wire [ `ROB_SIZE_LOG-1:0] to_memblock_instr0_robidx;


    /* -------------------------------------------------------------------------- */
    /*                                 issue queue                                */
    /* -------------------------------------------------------------------------- */

    wire                      is_lsu = to_iq_instr0_is_load | to_iq_instr0_is_store;
    wire                      is_alu = ~is_lsu;
    wire                      intiq_ready;
    wire                      memiq_ready;

    assign to_iq_instr0_ready = intiq_ready & memiq_ready;
    ooo_issuequeue intIQ (
        .clock                 (clock),
        .reset_n               (reset_n),
        .all_iq_ready          (intiq_ready & memiq_ready),
        .enq_instr0_valid      (to_iq_instr0_valid & is_alu),
        .enq_instr0_ready      (intiq_ready),
        .enq_instr0_lrs1       (to_iq_instr0_lrs1),
        .enq_instr0_lrs2       (to_iq_instr0_lrs2),
        .enq_instr0_lrd        (to_iq_instr0_lrd),
        .enq_instr0_pc         (to_iq_instr0_pc),
        .enq_instr0            (to_iq_instr0),
        .enq_instr0_imm        (to_iq_instr0_imm),
        .enq_instr0_src1_is_reg(to_iq_instr0_src1_is_reg),
        .enq_instr0_src2_is_reg(to_iq_instr0_src2_is_reg),
        .enq_instr0_need_to_wb (to_iq_instr0_need_to_wb),
        .enq_instr0_cx_type    (to_iq_instr0_cx_type),
        .enq_instr0_is_unsigned(to_iq_instr0_is_unsigned),
        .enq_instr0_alu_type   (to_iq_instr0_alu_type),
        .enq_instr0_muldiv_type(to_iq_instr0_muldiv_type),
        .enq_instr0_is_word    (to_iq_instr0_is_word),
        .enq_instr0_is_imm     (to_iq_instr0_is_imm),
        .enq_instr0_is_load    (to_iq_instr0_is_load),
        .enq_instr0_is_store   (to_iq_instr0_is_store),
        .enq_instr0_ls_size    (to_iq_instr0_ls_size),
        .enq_instr0_prs1       (to_iq_instr0_prs1),
        .enq_instr0_prs2       (to_iq_instr0_prs2),
        .enq_instr0_prd        (to_iq_instr0_prd),
        .enq_instr0_old_prd    (to_iq_instr0_old_prd),
        .enq_instr0_robidx_flag(to_iq_instr0_robidx_flag),
        .enq_instr0_robidx     (to_iq_instr0_robidx),
        .enq_instr0_src1_state (to_iq_instr0_src1_state),
        .enq_instr0_src2_state (to_iq_instr0_src2_state),
        /* --------------------------------- output --------------------------------- */
        .deq_instr0_valid      (deq_instr0_valid),
        .deq_instr0_ready      (intblock_instr_ready),
        .deq_instr0_prs1       (deq_instr0_prs1),
        .deq_instr0_prs2       (deq_instr0_prs2),
        .deq_instr0_src1_is_reg(deq_instr0_src1_is_reg),
        .deq_instr0_src2_is_reg(deq_instr0_src2_is_reg),
        .deq_instr0_prd        (deq_instr0_prd),
        .deq_instr0_old_prd    (  /*not used*/),
        .deq_instr0_pc         (deq_instr0_pc),
        .deq_instr0_imm        (deq_instr0_imm),
        .deq_instr0_need_to_wb (deq_instr0_need_to_wb),
        .deq_instr0_cx_type    (deq_instr0_cx_type),
        .deq_instr0_is_unsigned(deq_instr0_is_unsigned),
        .deq_instr0_alu_type   (deq_instr0_alu_type),
        .deq_instr0_muldiv_type(deq_instr0_muldiv_type),
        .deq_instr0_is_word    (deq_instr0_is_word),
        .deq_instr0_is_imm     (deq_instr0_is_imm),
        .deq_instr0_is_load    (deq_instr0_is_load),
        .deq_instr0_is_store   (deq_instr0_is_store),
        .deq_instr0_ls_size    (deq_instr0_ls_size),
        .deq_instr0_robidx_flag(deq_instr0_robidx_flag),
        .deq_instr0_robidx     (deq_instr0_robidx),
        /* ------------------------- writeback wakeup logic ------------------------- */
        .writeback0_valid      (writeback0_instr_valid),
        .writeback0_need_to_wb (writeback0_need_to_wb),
        .writeback0_prd        (writeback0_prd),
        .writeback1_valid      (writeback1_instr_valid),
        .writeback1_need_to_wb (writeback1_need_to_wb),
        .writeback1_prd        (writeback1_prd),
        /* -------------------------- redirect flush logic -------------------------- */
        .flush_valid           (redirect_valid),
        .flush_robidx_flag     (redirect_robidx_flag),
        .flush_robidx          (redirect_robidx)
    );

    io_issuequeue memIQ (
        .clock                 (clock),
        .reset_n               (reset_n),
        .all_iq_ready          (intiq_ready & memiq_ready),
        .enq_instr0_valid      (to_iq_instr0_valid & is_lsu),
        .enq_instr0_ready      (memiq_ready),
        .enq_instr0_lrs1       (to_iq_instr0_lrs1),
        .enq_instr0_lrs2       (to_iq_instr0_lrs2),
        .enq_instr0_lrd        (to_iq_instr0_lrd),
        .enq_instr0_pc         (to_iq_instr0_pc),
        .enq_instr0            (to_iq_instr0),
        .enq_instr0_imm        (to_iq_instr0_imm),
        .enq_instr0_src1_is_reg(to_iq_instr0_src1_is_reg),
        .enq_instr0_src2_is_reg(to_iq_instr0_src2_is_reg),
        .enq_instr0_need_to_wb (to_iq_instr0_need_to_wb),
        .enq_instr0_cx_type    (to_iq_instr0_cx_type),
        .enq_instr0_is_unsigned(to_iq_instr0_is_unsigned),
        .enq_instr0_alu_type   (to_iq_instr0_alu_type),
        .enq_instr0_muldiv_type(to_iq_instr0_muldiv_type),
        .enq_instr0_is_word    (to_iq_instr0_is_word),
        .enq_instr0_is_imm     (to_iq_instr0_is_imm),
        .enq_instr0_is_load    (to_iq_instr0_is_load),
        .enq_instr0_is_store   (to_iq_instr0_is_store),
        .enq_instr0_ls_size    (to_iq_instr0_ls_size),
        .enq_instr0_prs1       (to_iq_instr0_prs1),
        .enq_instr0_prs2       (to_iq_instr0_prs2),
        .enq_instr0_prd        (to_iq_instr0_prd),
        .enq_instr0_old_prd    (to_iq_instr0_old_prd),
        .enq_instr0_robidx_flag(to_iq_instr0_robidx_flag),
        .enq_instr0_robidx     (to_iq_instr0_robidx),
        .enq_instr0_src1_state (to_iq_instr0_src1_state),
        .enq_instr0_src2_state (to_iq_instr0_src2_state),
        /* --------------------------------- output --------------------------------- */
        .deq_instr0_valid      (to_memblock_instr0_valid),
        .deq_instr0_ready      (memblock_instr_ready),
        .deq_instr0_prs1       (to_memblock_instr0_prs1),
        .deq_instr0_prs2       (to_memblock_instr0_prs2),
        .deq_instr0_src1_is_reg(to_memblock_instr0_src1_is_reg),
        .deq_instr0_src2_is_reg(to_memblock_instr0_src2_is_reg),
        .deq_instr0_prd        (to_memblock_instr0_prd),
        .deq_instr0_old_prd    (  /*not used*/),
        .deq_instr0_pc         (to_memblock_instr0_pc),
        .deq_instr0_imm        (to_memblock_instr0_imm),
        .deq_instr0_need_to_wb (to_memblock_instr0_need_to_wb),
        .deq_instr0_cx_type    (to_memblock_instr0_cx_type),
        .deq_instr0_is_unsigned(to_memblock_instr0_is_unsigned),
        .deq_instr0_alu_type   (to_memblock_instr0_alu_type),
        .deq_instr0_muldiv_type(to_memblock_instr0_muldiv_type),
        .deq_instr0_is_word    (to_memblock_instr0_is_word),
        .deq_instr0_is_imm     (to_memblock_instr0_is_imm),
        .deq_instr0_is_load    (to_memblock_instr0_is_load),
        .deq_instr0_is_store   (to_memblock_instr0_is_store),
        .deq_instr0_ls_size    (to_memblock_instr0_ls_size),
        .deq_instr0_robidx_flag(to_memblock_instr0_robidx_flag),
        .deq_instr0_robidx     (to_memblock_instr0_robidx),
        /* ------------------------- writeback wakeup logic ------------------------- */
        .writeback0_valid      (writeback0_instr_valid),
        .writeback0_need_to_wb (writeback0_need_to_wb),
        .writeback0_prd        (writeback0_prd),
        .writeback1_valid      (writeback1_instr_valid),
        .writeback1_need_to_wb (writeback1_need_to_wb),
        .writeback1_prd        (writeback1_prd),
        /* -------------------------- redirect flush logic -------------------------- */
        .flush_valid           (redirect_valid),
        .flush_robidx_flag     (redirect_robidx_flag),
        .flush_robidx          (redirect_robidx)
    );


    //pregfile read data
    wire [             63:0] deq_instr0_src1;
    wire [             63:0] deq_instr0_src2;
    wire [             63:0] to_memblock_instr0_src1;
    wire [             63:0] to_memblock_instr0_src2;


    reg                      writeback0_instr_valid;
    reg                      writeback0_need_to_wb;
    reg  [      `PREG_RANGE] writeback0_prd;
    reg  [    `RESULT_RANGE] writeback0_result;
    reg                      writeback0_redirect_valid;
    reg  [    `RESULT_RANGE] writeback0_redirect_target;
    reg                      writeback0_robidx_flag;
    reg  [`ROB_SIZE_LOG-1:0] writeback0_robidx;

    reg                      writeback1_instr_valid;
    reg                      writeback1_need_to_wb;
    reg  [      `PREG_RANGE] writeback1_prd;
    reg  [    `RESULT_RANGE] writeback1_result;
    reg                      writeback1_mmio;
    reg                      writeback1_robidx_flag;
    reg  [`ROB_SIZE_LOG-1:0] writeback1_robidx;
    regfile64 u_regfile64 (
        .clock       (clock),
        .reset_n     (reset_n),
        .read0_en    (deq_instr0_src1_is_reg),
        .read1_en    (deq_instr0_src2_is_reg),
        .read0_idx   (deq_instr0_prs1),
        .read1_idx   (deq_instr0_prs2),
        .read0_data  (deq_instr0_src1),
        .read1_data  (deq_instr0_src2),
        /* -------------------------------- port two -------------------------------- */
        .read2_en    (to_memblock_instr0_src1_is_reg),
        .read3_en    (to_memblock_instr0_src2_is_reg),
        .read2_idx   (to_memblock_instr0_prs1),
        .read3_idx   (to_memblock_instr0_prs2),
        .read2_data  (to_memblock_instr0_src1),
        .read3_data  (to_memblock_instr0_src2),
        .write0_en   (writeback0_instr_valid & writeback0_need_to_wb),
        .write0_idx  (writeback0_prd),
        .write0_data (writeback0_result),
        // .write1_en   (writeback1_instr_valid & writeback1_need_to_wb & ~writeback1_mmio),
        .write1_en   (writeback1_instr_valid & writeback1_need_to_wb),
        .write1_idx  (writeback1_prd),
        .write1_data (writeback1_result),
        //debug
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

    //assign intblock valid
    wire                     intblock_instr_ready;
    wire                     memblock_instr_ready;
    /* -------------------------------------------------------------------------- */
    /*                                execute stage                               */
    /* -------------------------------------------------------------------------- */
    wire                     intblock_out_instr_valid;
    wire                     intblock_out_need_to_wb;
    wire [      `PREG_RANGE] intblock_out_prd;
    wire [             63:0] intblock_out_result;
    wire                     intblock_out_robidx_flag;
    wire [`ROB_SIZE_LOG-1:0] intblock_out_robidx;
    wire                     intblock_out_redirect_valid;
    wire [             63:0] intblock_out_redirect_target;

    //assign issue ready to all ready!

    //can use instr_valid to control a clock gate here to save power
    intblock u_intblock (
        .clock      (clock),
        .reset_n    (reset_n),
        .instr_valid(deq_instr0_valid),
        .instr_ready(intblock_instr_ready),
        .prd        (deq_instr0_prd),
        .src1       (deq_instr0_src1),
        .src2       (deq_instr0_src2),
        .imm        (deq_instr0_imm),
        .need_to_wb (deq_instr0_need_to_wb),
        .cx_type    (deq_instr0_cx_type),
        .is_unsigned(deq_instr0_is_unsigned),
        .alu_type   (deq_instr0_alu_type),
        .is_word    (deq_instr0_is_word),
        .is_imm     (deq_instr0_is_imm),
        .muldiv_type(deq_instr0_muldiv_type),
        .pc         (deq_instr0_pc),
        .robidx_flag(deq_instr0_robidx_flag),
        .robidx     (deq_instr0_robidx),

        //output
        .out_instr_valid  (intblock_out_instr_valid),
        .out_need_to_wb   (intblock_out_need_to_wb),
        .out_prd          (intblock_out_prd),
        .out_result       (intblock_out_result),
        .out_robidx_flag  (intblock_out_robidx_flag),
        .out_robidx       (intblock_out_robidx),
        .redirect_valid   (intblock_out_redirect_valid),
        .redirect_target  (intblock_out_redirect_target),
        /* -------------------------- redirect flush logic -------------------------- */
        .flush_valid      (redirect_valid),
        .flush_robidx_flag(redirect_robidx_flag),
        .flush_robidx     (redirect_robidx)
    );


    wire                     memblock_out_instr_valid;
    wire                     memblock_out_need_to_wb;
    wire [      `PREG_RANGE] memblock_out_prd;
    wire [    `RESULT_RANGE] memblock_out_opload_read_data_wb;
    wire                     memblock_out_mmio;
    wire                     memblock_out_robidx_flag;
    wire [`ROB_SIZE_LOG-1:0] memblock_out_robidx;
    wire                     memblock_out_stall;
    //can use instr_valid to control a clock gate here to save power
    memblock u_memblock (
        .clock      (clock),
        .reset_n    (reset_n),
        .instr_valid(to_memblock_instr0_valid),
        .instr_ready(memblock_instr_ready),
        .prd        (to_memblock_instr0_prd),
        .is_load    (to_memblock_instr0_is_load),
        .is_store   (to_memblock_instr0_is_store),
        .is_unsigned(to_memblock_instr0_is_unsigned),
        .imm        (to_memblock_instr0_imm),
        .src1       (to_memblock_instr0_src1),
        .src2       (to_memblock_instr0_src2),
        .ls_size    (to_memblock_instr0_ls_size),
        .robidx_flag(to_memblock_instr0_robidx_flag),
        .robidx     (to_memblock_instr0_robidx),

        //trinity bus channel
        .tbus_index_valid     (tbus_index_valid),
        .tbus_index_ready     (tbus_index_ready),
        .tbus_index           (tbus_index),
        .tbus_write_data      (tbus_write_data),
        .tbus_write_mask      (tbus_write_mask),
        .tbus_read_data       (tbus_read_data),
        .tbus_operation_done  (tbus_operation_done),
        .tbus_operation_type  (tbus_operation_type),
        //output 
        .out_instr_valid      (memblock_out_instr_valid),
        .out_need_to_wb       (memblock_out_need_to_wb),
        .out_prd              (memblock_out_prd),
        .opload_read_data_wb  (memblock_out_opload_read_data_wb),
        .out_mmio             (memblock_out_mmio),
        .out_robidx_flag      (memblock_out_robidx_flag),
        .out_robidx           (memblock_out_robidx),
        .mem_stall            (memblock_out_stall),
        /* -------------------------- redirect flush logic -------------------------- */
        .flush_valid          (redirect_valid),
        .flush_robidx_flag    (redirect_robidx_flag),
        .flush_robidx         (redirect_robidx),
        /* --------------------------- memblock to dcache --------------------------- */
        .memblock2dcache_flush(memblock2dcache_flush)
    );
    assign mem_stall = memblock_out_stall;

    /* -------------------------------------------------------------------------- */
    /*                              stage:   write back                           */
    /* -------------------------------------------------------------------------- */
    `MACRO_DFF_NONEN(writeback0_instr_valid, intblock_out_instr_valid, 1)
    `MACRO_DFF_NONEN(writeback0_need_to_wb, intblock_out_need_to_wb, 1)
    `MACRO_DFF_NONEN(writeback0_prd, intblock_out_prd, `PREG_LENGTH)
    `MACRO_DFF_NONEN(writeback0_result, intblock_out_result, 64)
    `MACRO_DFF_NONEN(writeback0_redirect_valid, intblock_out_redirect_valid, 1)
    `MACRO_DFF_NONEN(writeback0_redirect_target, intblock_out_redirect_target, 64)
    `MACRO_DFF_NONEN(writeback0_robidx_flag, intblock_out_robidx_flag, 1)
    `MACRO_DFF_NONEN(writeback0_robidx, intblock_out_robidx, `ROB_SIZE_LOG)

    assign redirect_valid       = writeback0_redirect_valid;
    assign redirect_target      = writeback0_redirect_target;
    assign redirect_robidx_flag = writeback0_robidx_flag;
    assign redirect_robidx      = writeback0_robidx;

    `MACRO_DFF_NONEN(writeback1_instr_valid, memblock_out_instr_valid, 1)
    `MACRO_DFF_NONEN(writeback1_need_to_wb, memblock_out_need_to_wb, 1)
    `MACRO_DFF_NONEN(writeback1_prd, memblock_out_prd, `PREG_LENGTH)
    `MACRO_DFF_NONEN(writeback1_result, memblock_out_opload_read_data_wb, 64)
    `MACRO_DFF_NONEN(writeback1_mmio, memblock_out_mmio, 1)
    `MACRO_DFF_NONEN(writeback1_robidx_flag, memblock_out_robidx_flag, 1)
    `MACRO_DFF_NONEN(writeback1_robidx, memblock_out_robidx, `ROB_SIZE_LOG)

    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off UNUSEDSIGNAL */
endmodule
