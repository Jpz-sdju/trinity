`include "defines.sv"
`include "pipedefines.sv"
/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
module ctrlblock (
    input wire clock,
    input wire reset_n,


    input  wire                ibuffer_instr_valid,
    input  wire [`INSTR_RANGE] ibuffer_inst_out,
    input  wire [   `PC_RANGE] ibuffer_pc_out,
    output wire                ibuffer_ready,
    /* ---------------------------- issue information --------------------------- */
    input  wire                to_issue_instr0_ready,
    output wire                to_issue_instr0_valid,
    output wire [ `LREG_RANGE] to_issue_instr0_lrs1,
    output wire [ `LREG_RANGE] to_issue_instr0_lrs2,
    output wire [ `LREG_RANGE] to_issue_instr0_lrd,
    output wire [   `PC_RANGE] to_issue_instr0_pc,
    output wire [        31:0] to_issue_instr0,

    output wire [              63:0] to_issue_instr0_imm,
    output wire                      to_issue_instr0_src1_is_reg,
    output wire                      to_issue_instr0_src2_is_reg,
    output wire                      to_issue_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_issue_instr0_cx_type,
    output wire                      to_issue_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_issue_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_issue_instr0_muldiv_type,
    output wire                      to_issue_instr0_is_word,
    output wire                      to_issue_instr0_is_imm,
    output wire                      to_issue_instr0_is_load,
    output wire                      to_issue_instr0_is_store,
    output wire [               3:0] to_issue_instr0_ls_size,

    output wire [`PREG_RANGE] to_issue_instr0_prs1,
    output wire [`PREG_RANGE] to_issue_instr0_prs2,
    output wire [`PREG_RANGE] to_issue_instr0_prd,
    output wire [`PREG_RANGE] to_issue_instr0_old_prd,

    output wire                     to_issue_instr0_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] to_issue_instr0_robidx,

    //src state
    output wire to_issue_instr0_src1_state,
    output wire to_issue_instr0_src2_state,

    /* ------------------------------ redirect sigs ----------------------------- */
    input wire                     redirect_valid,
    input wire [             63:0] redirect_target,
    input wire                     redirect_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] redirect_robidx,

    /* -------------------------------- writeback ------------------------------- */
    input wire                     writeback0_valid,
    input wire                     writeback0_need_to_wb,
    input wire [      `PREG_RANGE] writeback0_prd,
    // input wire  [    `RESULT_RANGE] writeback0_result,
    input wire                     writeback0_redirect_valid,
    input wire [    `RESULT_RANGE] writeback0_redirect_target,
    input wire                     writeback0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback0_robidx,


    input wire                     writeback1_valid,
    input wire                     writeback1_need_to_wb,
    input wire [      `PREG_RANGE] writeback1_prd,
    // input wire  [    `RESULT_RANGE] writeback1_result,
    input wire                     writeback1_mmio,
    input wire                     writeback1_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback1_robidx,

    //debug
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
    output wire [`PREG_RANGE] debug_preg31
);

    /* -------------------------------------------------------------------------- */
    /*                          stage 0: decode to rename ,read rat               */
    /* -------------------------------------------------------------------------- */
    wire                      from_dec_instr0_valid;
    wire                      from_dec_instr0_ready;
    wire [               4:0] from_dec_instr0_lrs1;
    wire [               4:0] from_dec_instr0_lrs2;
    wire [               4:0] from_dec_instr0_lrd;
    wire [              63:0] from_dec_instr0_imm;
    wire                      from_dec_instr0_src1_is_reg;
    wire                      from_dec_instr0_src2_is_reg;
    wire                      from_dec_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] from_dec_instr0_cx_type;
    wire                      from_dec_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] from_dec_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] from_dec_instr0_muldiv_type;
    wire                      from_dec_instr0_is_word;
    wire                      from_dec_instr0_is_imm;
    wire                      from_dec_instr0_is_load;
    wire                      from_dec_instr0_is_store;
    wire [               3:0] from_dec_instr0_ls_size;
    wire [              31:0] from_dec_instr0;
    wire [         `PC_RANGE] from_dec_instr0_pc;

    assign ibuffer_ready = from_dec_instr0_ready;
    decode u_decoder (
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .lrs1               (from_dec_instr0_lrs1),
        .lrs2               (from_dec_instr0_lrs2),
        .lrd                (from_dec_instr0_lrd),
        .imm                (from_dec_instr0_imm),
        .src1_is_reg        (from_dec_instr0_src1_is_reg),
        .src2_is_reg        (from_dec_instr0_src2_is_reg),
        .need_to_wb         (from_dec_instr0_need_to_wb),
        .cx_type            (from_dec_instr0_cx_type),
        .is_unsigned        (from_dec_instr0_is_unsigned),
        .alu_type           (from_dec_instr0_alu_type),
        .is_word            (from_dec_instr0_is_word),
        .is_imm             (from_dec_instr0_is_imm),
        .is_load            (from_dec_instr0_is_load),
        .is_store           (from_dec_instr0_is_store),
        .ls_size            (from_dec_instr0_ls_size),
        .muldiv_type        (from_dec_instr0_muldiv_type),
        .decoder_instr_valid(from_dec_instr0_valid),
        .decoder_inst_out   (from_dec_instr0),
        .decoder_pc_out     (from_dec_instr0_pc)

    );

    wire                      to_rename_instr0_valid;
    wire                      to_rename_instr0_ready;
    wire [               4:0] to_rename_instr0_lrs1;
    wire [               4:0] to_rename_instr0_lrs2;
    wire [               4:0] to_rename_instr0_lrd;
    wire [              63:0] to_rename_instr0_imm;
    wire                      to_rename_instr0_src1_is_reg;
    wire                      to_rename_instr0_src2_is_reg;
    wire                      to_rename_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_rename_instr0_cx_type;
    wire                      to_rename_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_rename_instr0_alu_type;
    wire                      to_rename_instr0_is_word;
    wire                      to_rename_instr0_is_imm;
    wire                      to_rename_instr0_is_load;
    wire                      to_rename_instr0_is_store;
    wire [               3:0] to_rename_instr0_ls_size;
    wire [`MULDIV_TYPE_RANGE] to_rename_instr0_muldiv_type;
    wire [              31:0] to_rename_instr0;
    wire [         `PC_RANGE] to_rename_instr0_pc;


    `PIPE_BEFORE_RENAME(to_rename_instr0, from_dec_instr0, 1'b0)
    /* --------------------------- rat read data to rename -------------------------- */
    wire [      `PREG_RANGE] instr0_rat_prs1;
    wire [      `PREG_RANGE] instr0_rat_prs2;
    wire [      `PREG_RANGE] instr0_rat_prd;
    /* ------------------------ write request from rename ----------------------- */
    wire                     instr0_rat_rename_valid;
    wire [              4:0] instr0_rat_rename_addr;
    wire [      `PREG_RANGE] instr0_rat_rename_data;


    /* ---------------------------- commit & redirect --------------------------- */
    //commit port
    wire                     commits0_valid;
    wire [      `PREG_RANGE] commits0_old_prd;
    wire [      `LREG_RANGE] commits0_lrd;
    wire [      `PREG_RANGE] commits0_prd;
    wire [             31:0] commits0_instr;
    wire [        `PC_RANGE] commits0_pc;
    //debug
    wire [`ROB_SIZE_LOG-1:0] commits0_robidx;
    wire                     commits0_need_to_wb;
    wire                     commits0_skip;

    wire                     commits1_valid;
    wire [      `PREG_RANGE] commits1_old_prd;
    wire [      `LREG_RANGE] commits1_lrd;
    wire [      `PREG_RANGE] commits1_prd;
    wire [             31:0] commits1_instr;
    wire [        `PC_RANGE] commits1_pc;
    //debug
    wire [`ROB_SIZE_LOG-1:0] commits1_robidx;
    wire                     commits1_need_to_wb;
    wire                     commits1_skip;


    renametable u_renametable (
        .clock                  (clock),
        .reset_n                (reset_n),
        .instr0_src1_is_reg     (to_rename_instr0_src1_is_reg),
        .instr0_lrs1            (to_rename_instr0_lrs1),
        .instr0_src2_is_reg     (to_rename_instr0_src2_is_reg),
        .instr0_lrs2            (to_rename_instr0_lrs2),
        .instr0_need_to_wb      (to_rename_instr0_need_to_wb),
        .instr0_lrd             (to_rename_instr0_lrd),
        .instr1_src1_is_reg     (),
        .instr1_lrs1            (),
        .instr1_src2_is_reg     (),
        .instr1_lrs2            (),
        .instr1_need_to_wb      (),
        .instr1_lrd             (),
        .instr0_rat_prs1        (instr0_rat_prs1),
        .instr0_rat_prs2        (instr0_rat_prs2),
        .instr0_rat_prd         (instr0_rat_prd),
        .instr1_rat_prs1        (),
        .instr1_rat_prs2        (),
        .instr1_rat_prd         (),
        .instr0_rat_rename_valid(instr0_rat_rename_valid),
        .instr0_rat_rename_addr (instr0_rat_rename_addr),
        .instr0_rat_rename_data (instr0_rat_rename_data),
        .instr1_rat_rename_valid(),
        .instr1_rat_rename_addr (),
        .instr1_rat_rename_data (),
        //arch rat write 
        .commits0_valid         (commits0_valid),
        .commits0_need_to_wb    (commits0_need_to_wb),
        .commits0_lrd           (commits0_lrd),
        .commits0_prd           (commits0_prd),
        .commits1_valid         (commits1_valid),
        .commits1_need_to_wb    (commits1_need_to_wb),
        .commits1_lrd           (commits1_lrd),
        .commits1_prd           (commits1_prd),
        //debug
        .debug_preg0            (debug_preg0),
        .debug_preg1            (debug_preg1),
        .debug_preg2            (debug_preg2),
        .debug_preg3            (debug_preg3),
        .debug_preg4            (debug_preg4),
        .debug_preg5            (debug_preg5),
        .debug_preg6            (debug_preg6),
        .debug_preg7            (debug_preg7),
        .debug_preg8            (debug_preg8),
        .debug_preg9            (debug_preg9),
        .debug_preg10           (debug_preg10),
        .debug_preg11           (debug_preg11),
        .debug_preg12           (debug_preg12),
        .debug_preg13           (debug_preg13),
        .debug_preg14           (debug_preg14),
        .debug_preg15           (debug_preg15),
        .debug_preg16           (debug_preg16),
        .debug_preg17           (debug_preg17),
        .debug_preg18           (debug_preg18),
        .debug_preg19           (debug_preg19),
        .debug_preg20           (debug_preg20),
        .debug_preg21           (debug_preg21),
        .debug_preg22           (debug_preg22),
        .debug_preg23           (debug_preg23),
        .debug_preg24           (debug_preg24),
        .debug_preg25           (debug_preg25),
        .debug_preg26           (debug_preg26),
        .debug_preg27           (debug_preg27),
        .debug_preg28           (debug_preg28),
        .debug_preg29           (debug_preg29),
        .debug_preg30           (debug_preg30),
        .debug_preg31           (debug_preg31)
    );

    /* -------------------------------------------------------------------------- */
    /*                               stage : rename                               */
    /* -------------------------------------------------------------------------- */

    /* -------------------------------- rename out  -------------------------------- */
    wire                      from_rename_instr0_valid;
    wire                      from_rename_instr0_ready;
    wire [       `LREG_RANGE] from_rename_instr0_lrs1;
    wire [       `LREG_RANGE] from_rename_instr0_lrs2;
    wire [       `LREG_RANGE] from_rename_instr0_lrd;
    wire [         `PC_RANGE] from_rename_instr0_pc;
    wire [      `INSTR_RANGE] from_rename_instr0;


    wire [              63:0] from_rename_instr0_imm;
    wire                      from_rename_instr0_src1_is_reg;
    wire                      from_rename_instr0_src2_is_reg;
    wire                      from_rename_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] from_rename_instr0_cx_type;
    wire                      from_rename_instr0_is_unsigned;
    wire [`MULDIV_TYPE_RANGE] from_rename_instr0_muldiv_type;
    wire [   `ALU_TYPE_RANGE] from_rename_instr0_alu_type;
    wire                      from_rename_instr0_is_word;
    wire                      from_rename_instr0_is_imm;
    wire                      from_rename_instr0_is_load;
    wire                      from_rename_instr0_is_store;
    wire [               3:0] from_rename_instr0_ls_size;


    wire [       `PREG_RANGE] from_rename_instr0_prs1;
    wire [       `PREG_RANGE] from_rename_instr0_prs2;
    wire [       `PREG_RANGE] from_rename_instr0_prd;
    wire [       `PREG_RANGE] from_rename_instr0_old_prd;

    /* ----------------------------- freelist alloc ----------------------------- */
    wire                      instr0_freelist_req;
    wire [       `PREG_RANGE] instr0_freelist_resp;

    freelist u_freelist (
        .clock       (clock),
        .reset_n     (reset_n),
        .req0_valid  (instr0_freelist_req),
        .req0_data   (instr0_freelist_resp),
        .req1_valid  (),
        .req1_data   (),
        .write0_valid(),
        .write0_data (),
        .write1_valid(),
        .write1_data ()
    );



    rename u_rename (
        .instr0_valid                  (to_rename_instr0_valid),
        .instr0_ready                  (to_rename_instr0_ready),
        .instr0                        (to_rename_instr0),
        .instr0_lrs1                   (to_rename_instr0_lrs1),
        .instr0_lrs2                   (to_rename_instr0_lrs2),
        .instr0_lrd                    (to_rename_instr0_lrd),
        .instr0_pc                     (to_rename_instr0_pc),
        .instr0_imm                    (to_rename_instr0_imm),
        .instr0_src1_is_reg            (to_rename_instr0_src1_is_reg),
        .instr0_src2_is_reg            (to_rename_instr0_src2_is_reg),
        .instr0_need_to_wb             (to_rename_instr0_need_to_wb),
        .instr0_cx_type                (to_rename_instr0_cx_type),
        .instr0_is_unsigned            (to_rename_instr0_is_unsigned),
        .instr0_alu_type               (to_rename_instr0_alu_type),
        .instr0_muldiv_type            (to_rename_instr0_muldiv_type),
        .instr0_is_word                (to_rename_instr0_is_word),
        .instr0_is_imm                 (to_rename_instr0_is_imm),
        .instr0_is_load                (to_rename_instr0_is_load),
        .instr0_is_store               (to_rename_instr0_is_store),
        .instr0_ls_size                (to_rename_instr0_ls_size),
        .instr1_valid                  (),
        .instr1                        (),
        .instr1_lrs1                   (),
        .instr1_lrs2                   (),
        .instr1_lrd                    (),
        .instr1_pc                     (),
        .instr1_imm                    (),
        .instr1_src1_is_reg            (),
        .instr1_src2_is_reg            (),
        .instr1_need_to_wb             (),
        .instr1_cx_type                (),
        .instr1_is_unsigned            (),
        .instr1_alu_type               (),
        .instr1_muldiv_type            (),
        .instr1_is_word                (),
        .instr1_is_imm                 (),
        .instr1_is_load                (),
        .instr1_is_store               (),
        .instr1_ls_size                (),
        .instr0_rat_prs1               (instr0_rat_prs1),
        .instr0_rat_prs2               (instr0_rat_prs2),
        .instr0_rat_prd                (instr0_rat_prd),
        .instr1_rat_prs1               (),
        .instr1_rat_prs2               (),
        .instr1_rat_prd                (),
        .instr0_rat_rename_valid       (instr0_rat_rename_valid),
        .instr0_rat_rename_addr        (instr0_rat_rename_addr),
        .instr0_rat_rename_data        (instr0_rat_rename_data),
        .instr1_rat_rename_valid       (),
        .instr1_rat_rename_addr        (),
        .instr1_rat_rename_data        (),
        .instr0_freelist_req           (instr0_freelist_req),
        .instr0_freelist_resp          (instr0_freelist_resp),
        .instr1_freelist_req           (),
        .instr1_freelist_resp          (),
        .to_dispatch_instr0_valid      (from_rename_instr0_valid),
        .to_dispatch_instr0_ready      (from_rename_instr0_ready),
        .to_dispatch_instr0_lrs1       (from_rename_instr0_lrs1),
        .to_dispatch_instr0_lrs2       (from_rename_instr0_lrs2),
        .to_dispatch_instr0_lrd        (from_rename_instr0_lrd),
        .to_dispatch_instr0_pc         (from_rename_instr0_pc),
        .to_dispatch_instr0            (from_rename_instr0),
        .to_dispatch_instr0_imm        (from_rename_instr0_imm),
        .to_dispatch_instr0_src1_is_reg(from_rename_instr0_src1_is_reg),
        .to_dispatch_instr0_src2_is_reg(from_rename_instr0_src2_is_reg),
        .to_dispatch_instr0_need_to_wb (from_rename_instr0_need_to_wb),
        .to_dispatch_instr0_cx_type    (from_rename_instr0_cx_type),
        .to_dispatch_instr0_is_unsigned(from_rename_instr0_is_unsigned),
        .to_dispatch_instr0_alu_type   (from_rename_instr0_alu_type),
        .to_dispatch_instr0_muldiv_type(from_rename_instr0_muldiv_type),
        .to_dispatch_instr0_is_word    (from_rename_instr0_is_word),
        .to_dispatch_instr0_is_imm     (from_rename_instr0_is_imm),
        .to_dispatch_instr0_is_load    (from_rename_instr0_is_load),
        .to_dispatch_instr0_is_store   (from_rename_instr0_is_store),
        .to_dispatch_instr0_ls_size    (from_rename_instr0_ls_size),
        .to_dispatch_instr0_prs1       (from_rename_instr0_prs1),
        .to_dispatch_instr0_prs2       (from_rename_instr0_prs2),
        .to_dispatch_instr0_prd        (from_rename_instr0_prd),
        .to_dispatch_instr0_old_prd    (from_rename_instr0_old_prd),
        .to_dispatch_instr1_valid      (),
        .to_dispatch_instr1_lrs1       (),
        .to_dispatch_instr1_lrs2       (),
        .to_dispatch_instr1_lrd        (),
        .to_dispatch_instr1_pc         (),
        .to_dispatch_instr1            (),
        .to_dispatch_instr1_imm        (),
        .to_dispatch_instr1_src1_is_reg(),
        .to_dispatch_instr1_src2_is_reg(),
        .to_dispatch_instr1_need_to_wb (),
        .to_dispatch_instr1_cx_type    (),
        .to_dispatch_instr1_is_unsigned(),
        .to_dispatch_instr1_alu_type   (),
        .to_dispatch_instr1_muldiv_type(),
        .to_dispatch_instr1_is_word    (),
        .to_dispatch_instr1_is_imm     (),
        .to_dispatch_instr1_is_load    (),
        .to_dispatch_instr1_is_store   (),
        .to_dispatch_instr1_ls_size    (),
        .to_dispatch_instr1_prs1       (),
        .to_dispatch_instr1_prs2       (),
        .to_dispatch_instr1_prd        (),
        .to_dispatch_instr1_old_prd    ()
    );


    /* --------------------------- to dispatch instr 0 -------------------------- */
    wire                      to_dispatch_instr0_valid;
    wire                      to_dispatch_instr0_ready;
    wire [       `LREG_RANGE] to_dispatch_instr0_lrs1;
    wire [       `LREG_RANGE] to_dispatch_instr0_lrs2;
    wire [       `LREG_RANGE] to_dispatch_instr0_lrd;
    wire [         `PC_RANGE] to_dispatch_instr0_pc;
    wire [      `INSTR_RANGE] to_dispatch_instr0;

    wire [              63:0] to_dispatch_instr0_imm;
    wire                      to_dispatch_instr0_src1_is_reg;
    wire                      to_dispatch_instr0_src2_is_reg;
    wire                      to_dispatch_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_dispatch_instr0_cx_type;
    wire                      to_dispatch_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_dispatch_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] to_dispatch_instr0_muldiv_type;

    wire                      to_dispatch_instr0_is_word;
    wire                      to_dispatch_instr0_is_imm;
    wire                      to_dispatch_instr0_is_load;
    wire                      to_dispatch_instr0_is_store;
    wire [               3:0] to_dispatch_instr0_ls_size;


    wire [       `PREG_RANGE] to_dispatch_instr0_prs1;
    wire [       `PREG_RANGE] to_dispatch_instr0_prs2;
    wire [       `PREG_RANGE] to_dispatch_instr0_prd;
    wire [       `PREG_RANGE] to_dispatch_instr0_old_prd;



    `PIPE_BEFORE_WB(to_dispatch_instr0, from_rename_instr0, 1'b0)


    /* -------------------------------------------------------------------------- */
    /*                                state:  dispatch                            */
    /* -------------------------------------------------------------------------- */
    wire [`ROB_SIZE_LOG-1:0] counter;
    wire                     enq_robidx_flag;
    wire [`ROB_SIZE_LOG-1:0] enq_robidx;
    dispatch u_dispatch (
        .clock                      (clock),
        .reset_n                    (reset_n),
        .instr0_valid               (to_dispatch_instr0_valid),
        .instr0_ready               (to_dispatch_instr0_ready),
        .instr0_lrs1                (to_dispatch_instr0_lrs1),
        .instr0_lrs2                (to_dispatch_instr0_lrs2),
        .instr0_lrd                 (to_dispatch_instr0_lrd),
        .instr0_pc                  (to_dispatch_instr0_pc),
        .instr0                     (to_dispatch_instr0),
        .instr0_imm                 (to_dispatch_instr0_imm),
        .instr0_src1_is_reg         (to_dispatch_instr0_src1_is_reg),
        .instr0_src2_is_reg         (to_dispatch_instr0_src2_is_reg),
        .instr0_need_to_wb          (to_dispatch_instr0_need_to_wb),
        .instr0_cx_type             (to_dispatch_instr0_cx_type),
        .instr0_is_unsigned         (to_dispatch_instr0_is_unsigned),
        .instr0_alu_type            (to_dispatch_instr0_alu_type),
        .instr0_muldiv_type         (to_dispatch_instr0_muldiv_type),
        .instr0_is_word             (to_dispatch_instr0_is_word),
        .instr0_is_imm              (to_dispatch_instr0_is_imm),
        .instr0_is_load             (to_dispatch_instr0_is_load),
        .instr0_is_store            (to_dispatch_instr0_is_store),
        .instr0_ls_size             (to_dispatch_instr0_ls_size),
        .instr0_prs1                (to_dispatch_instr0_prs1),
        .instr0_prs2                (to_dispatch_instr0_prs2),
        .instr0_prd                 (to_dispatch_instr0_prd),
        .instr0_old_prd             (to_dispatch_instr0_old_prd),
        .instr1_valid               (),
        .instr1_ready               (),
        .instr1_lrs1                (),
        .instr1_lrs2                (),
        .instr1_lrd                 (),
        .instr1_pc                  (),
        .instr1                     (),
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
        .instr1_prs1                (),
        .instr1_prs2                (),
        .instr1_prd                 (),
        .instr1_old_prd             (),
        .to_issue_instr0_ready      (to_issue_instr0_ready),
        .to_issue_instr1_ready      (),
        .counter                    (counter),
        .enq_robidx_flag            (enq_robidx_flag),
        .enq_robidx                 (enq_robidx),
        .to_issue_instr0_valid      (to_issue_instr0_valid),
        .to_issue_instr0_lrs1       (to_issue_instr0_lrs1),
        .to_issue_instr0_lrs2       (to_issue_instr0_lrs2),
        .to_issue_instr0_lrd        (to_issue_instr0_lrd),
        .to_issue_instr0_pc         (to_issue_instr0_pc),
        .to_issue_instr0            (to_issue_instr0),
        .to_issue_instr0_imm        (to_issue_instr0_imm),
        .to_issue_instr0_src1_is_reg(to_issue_instr0_src1_is_reg),
        .to_issue_instr0_src2_is_reg(to_issue_instr0_src2_is_reg),
        .to_issue_instr0_need_to_wb (to_issue_instr0_need_to_wb),
        .to_issue_instr0_cx_type    (to_issue_instr0_cx_type),
        .to_issue_instr0_is_unsigned(to_issue_instr0_is_unsigned),
        .to_issue_instr0_alu_type   (to_issue_instr0_alu_type),
        .to_issue_instr0_muldiv_type(to_issue_instr0_muldiv_type),
        .to_issue_instr0_is_word    (to_issue_instr0_is_word),
        .to_issue_instr0_is_imm     (to_issue_instr0_is_imm),
        .to_issue_instr0_is_load    (to_issue_instr0_is_load),
        .to_issue_instr0_is_store   (to_issue_instr0_is_store),
        .to_issue_instr0_ls_size    (to_issue_instr0_ls_size),
        .to_issue_instr0_prs1       (to_issue_instr0_prs1),
        .to_issue_instr0_prs2       (to_issue_instr0_prs2),
        .to_issue_instr0_prd        (to_issue_instr0_prd),
        .to_issue_instr0_old_prd    (to_issue_instr0_old_prd),
        .to_issue_instr0_robidx_flag(to_issue_instr0_robidx_flag),
        .to_issue_instr0_robidx     (to_issue_instr0_robidx),
        .to_issue_instr1_valid      (),
        .to_issue_instr1_lrs1       (),
        .to_issue_instr1_lrs2       (),
        .to_issue_instr1_lrd        (),
        .to_issue_instr1_pc         (),
        .to_issue_instr1            (),
        .to_issue_instr1_imm        (),
        .to_issue_instr1_src1_is_reg(),
        .to_issue_instr1_src2_is_reg(),
        .to_issue_instr1_need_to_wb (),
        .to_issue_instr1_cx_type    (),
        .to_issue_instr1_is_unsigned(),
        .to_issue_instr1_alu_type   (),
        .to_issue_instr1_muldiv_type(),
        .to_issue_instr1_is_word    (),
        .to_issue_instr1_is_imm     (),
        .to_issue_instr1_is_load    (),
        .to_issue_instr1_is_store   (),
        .to_issue_instr1_ls_size    (),
        .to_issue_instr1_prs1       (),
        .to_issue_instr1_prs2       (),
        .to_issue_instr1_prd        (),
        .to_issue_instr1_old_prd    (),
        .to_issue_instr1_robidx_flag(),
        .to_issue_instr1_robidx     ()
    );


    /* -------------------------------------------------------------------------- */
    /*                                 busy table                                 */
    /* -------------------------------------------------------------------------- */
    wire commits0_free;
    wire commits1_free;
    assign commits0_free = commits0_valid & commits0_need_to_wb;
    assign commits1_free = commits1_valid & commits1_need_to_wb;
    busytable u_busytable (
        .clock      (clock),
        .reset_n    (reset_n),
        .read_addr0 (to_issue_instr0_prs1),
        .read_addr1 (to_issue_instr0_prs2),
        .read_addr2 (),
        .read_addr3 (),
        .busy_out0  (to_issue_instr0_src1_state),
        .busy_out1  (to_issue_instr0_src2_state),
        .busy_out2  (),
        .busy_out3  (),
        .alloc_en0  (to_issue_instr0_need_to_wb),
        .alloc_addr0(to_issue_instr0_prd),
        .alloc_en1  (),
        .alloc_addr1(),
        .free_en0   (commits0_free),
        .free_addr0 (commits0_prd),
        .free_en1   (commits1_free),
        .free_addr1 (commits1_prd)
    );
    /* -------------------------------------------------------------------------- */
    /*                                     rob                                    */
    /* -------------------------------------------------------------------------- */
    rob u_rob (
        .clock                 (clock),
        .reset_n               (reset_n),
        .instr0_enq_valid      (to_issue_instr0_valid),
        .instr0_pc             (to_issue_instr0_pc),
        .instr0                (to_issue_instr0),
        .instr0_lrs1           (to_issue_instr0_lrs1),
        .instr0_lrs2           (to_issue_instr0_lrs2),
        .instr0_lrd            (to_issue_instr0_lrd),
        .instr0_prd            (to_issue_instr0_prd),
        .instr0_old_prd        (to_issue_instr0_old_prd),
        .instr0_need_to_wb     (to_issue_instr0_need_to_wb),
        .instr1_enq_valid      (),
        .instr1_pc             (),
        .instr1                (),
        .instr1_lrs1           (),
        .instr1_lrs2           (),
        .instr1_lrd            (),
        .instr1_prd            (),
        .instr1_old_prd        (),
        .instr1_need_to_wb     (),
        .counter               (counter),
        .enq_robidx_flag       (enq_robidx_flag),
        .enq_robidx            (enq_robidx),
        .writeback0_valid      (writeback0_valid),
        .writeback0_robidx_flag(writeback0_robidx_flag),
        .writeback0_robidx     (writeback0_robidx),
        .writeback0_need_to_wb (writeback0_need_to_wb),
        .writeback1_valid      (writeback1_valid),
        .writeback1_robidx_flag(writeback1_robidx_flag),
        .writeback1_robidx     (writeback1_robidx),
        .writeback1_need_to_wb (writeback1_need_to_wb),
        .writeback1_mmio       (writeback1_mmio),
        .writeback2_valid      (),
        .writeback2_robidx_flag(),
        .writeback2_robidx     (),
        .writeback2_need_to_wb (),
        .commits0_valid        (commits0_valid),
        .commits0_pc           (commits0_pc),
        .commits0_instr        (commits0_instr),
        .commits0_lrd          (commits0_lrd),
        .commits0_prd          (commits0_prd),
        .commits0_old_prd      (commits0_old_prd),
        .commits0_robidx       (commits0_robidx),
        .commits0_need_to_wb   (commits0_need_to_wb),
        .commits0_skip         (commits0_skip),
        .commits1_valid        (commits1_valid),
        .commits1_pc           (commits1_pc),
        .commits1_instr        (commits1_instr),
        .commits1_lrd          (commits1_lrd),
        .commits1_prd          (commits1_prd),
        .commits1_old_prd      (commits1_old_prd),
        .commits1_robidx       (commits1_robidx),
        .commits1_need_to_wb   (commits1_need_to_wb),
        .commits1_skip         (commits1_skip),
        .redirect_valid        (redirect_valid),
        .redirect_target       (redirect_target),
        .redirect_robidx_flag  (redirect_robidx_flag),
        .redirect_robidx       (redirect_robidx)
    );

    /* -------------------------------------------------------------------------- */
    /*                               difftest region                              */
    /* -------------------------------------------------------------------------- */
    reg                     flop_commits0_valid;
    reg                     flop_commits0_skip;
    reg                     flop_commits0_need_to_wb;
    reg [      `LREG_RANGE] flop_commits0_lrd;
    reg [        `PC_RANGE] flop_commits0_pc;
    reg [     `INSTR_RANGE] flop_commits0_instr;
    reg [`ROB_SIZE_LOG-1:0] flop_commits0_robidx;

    `MACRO_DFF_NONEN(flop_commits0_valid, commits0_valid, 1)
    `MACRO_DFF_NONEN(flop_commits0_skip, commits0_skip, 1)
    `MACRO_DFF_NONEN(flop_commits0_need_to_wb, commits0_need_to_wb, 1)
    `MACRO_DFF_NONEN(flop_commits0_lrd, commits0_lrd, 5)
    `MACRO_DFF_NONEN(flop_commits0_pc, commits0_pc, `PC_WIDTH)
    `MACRO_DFF_NONEN(flop_commits0_instr, commits0_instr, 32)
    `MACRO_DFF_NONEN(flop_commits0_robidx, commits0_robidx, `ROB_SIZE_LOG)


    DifftestInstrCommit u_DifftestInstrCommit (
        .clock     (clock),
        .enable    (flop_commits0_valid),
        .io_valid  ('b0),                       //unuse!!!!
        .io_skip   (flop_commits0_skip),
        .io_isRVC  (1'b0),
        .io_rfwen  (flop_commits0_need_to_wb),
        .io_fpwen  (1'b0),
        .io_vecwen (1'b0),
        .io_wpdest ('b0),
        .io_wdest  (flop_commits0_lrd),
        .io_pc     (flop_commits0_pc),
        .io_instr  (flop_commits0_instr),
        .io_robIdx (flop_commits0_robidx),
        .io_lqIdx  ('b0),
        .io_sqIdx  ('b0),
        .io_isLoad ('b0),                       //load queue idx
        .io_isStore('b0),                       //store queue idx
        .io_nFused ('b0),
        .io_special('b0),
        .io_coreid ('b0),
        .io_index  ('b0)
    );


    reg [63:0] commit_cnt;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            commit_cnt <= 0;
        end else if (commits0_valid) begin
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
        .io_pc      ('b0),
        .io_coreid  ('b0)
    );


    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off PINCONNECTEMPTY */
endmodule



