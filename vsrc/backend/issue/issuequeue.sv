`include "defines.sv"
module issuequeue (
    input  wire               clock,
    input  wire               reset_n,
    input  wire               all_iq_ready,
    input  wire               enq_instr0_valid,
    output wire               enq_instr0_ready,
    input  wire [`LREG_RANGE] enq_instr0_lrs1,
    input  wire [`LREG_RANGE] enq_instr0_lrs2,
    input  wire [`LREG_RANGE] enq_instr0_lrd,
    input  wire [  `PC_RANGE] enq_instr0_pc,
    input  wire [       31:0] enq_instr0,

    input wire [              63:0] enq_instr0_imm,
    input wire                      enq_instr0_src1_is_reg,
    input wire                      enq_instr0_src2_is_reg,
    input wire                      enq_instr0_need_to_wb,
    input wire [    `CX_TYPE_RANGE] enq_instr0_cx_type,
    input wire                      enq_instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] enq_instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] enq_instr0_muldiv_type,
    input wire                      enq_instr0_is_word,
    input wire                      enq_instr0_is_imm,
    input wire                      enq_instr0_is_load,
    input wire                      enq_instr0_is_store,
    input wire [               3:0] enq_instr0_ls_size,

    input wire [`PREG_RANGE] enq_instr0_prs1,
    input wire [`PREG_RANGE] enq_instr0_prs2,
    input wire [`PREG_RANGE] enq_instr0_prd,
    input wire [`PREG_RANGE] enq_instr0_old_prd,

    input wire                     enq_instr0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_instr0_robidx,
    /* -------------------------------- src state ------------------------------- */
    input wire                     enq_instr0_src1_state,
    input wire                     enq_instr0_src2_state,

    /* ------------------------------- output to execute block ------------------------------- */
    output wire               deq_instr0_valid,
    //temp sig
    input  wire               deq_instr0_ready,
    output reg  [`PREG_RANGE] deq_instr0_prs1,
    output reg  [`PREG_RANGE] deq_instr0_prs2,
    output reg                deq_instr0_src1_is_reg,
    output reg                deq_instr0_src2_is_reg,

    output reg [`PREG_RANGE] deq_instr0_prd,
    output reg [`PREG_RANGE] deq_instr0_old_prd,

    output reg [`SRC_RANGE] deq_instr0_pc,
    // output reg [`INSTR_RANGE] deq_instr0,
    output reg [`SRC_RANGE] deq_instr0_imm,

    output reg                      deq_instr0_need_to_wb,
    output reg [    `CX_TYPE_RANGE] deq_instr0_cx_type,
    output reg                      deq_instr0_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] deq_instr0_alu_type,
    output reg [`MULDIV_TYPE_RANGE] deq_instr0_muldiv_type,
    output reg                      deq_instr0_is_word,
    output reg                      deq_instr0_is_imm,
    output reg                      deq_instr0_is_load,
    output reg                      deq_instr0_is_store,
    output reg [               3:0] deq_instr0_ls_size,

    output reg                     deq_instr0_robidx_flag,
    output reg [`ROB_SIZE_LOG-1:0] deq_instr0_robidx,

    /* ---------------------------- write back wakeup --------------------------- */
    input wire               writeback0_valid,
    input wire               writeback0_need_to_wb,
    input wire [`PREG_RANGE] writeback0_prd,

    input wire               writeback1_valid,
    input wire               writeback1_need_to_wb,
    input wire [`PREG_RANGE] writeback1_prd,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                     flush_valid,
    input wire                     flush_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx
);

    /* -------------------------------------------------------------------------- */
    /*                                   enq dec                                  */
    /* -------------------------------------------------------------------------- */

    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_valid_dec;
    reg  [                `PC_RANGE] iq_entries_enq_pc_dec          [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_prs1_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_prs2_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_is_reg_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_is_reg_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_state_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_state_dec;
    reg  [              `PREG_RANGE] iq_entries_enq_prd_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_old_prd_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [                     31:0] iq_entries_enq_instr_dec       [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [               `SRC_RANGE] iq_entries_enq_imm_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    reg                              iq_entries_enq_need_to_wb_dec  [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [           `CX_TYPE_RANGE] iq_entries_enq_cx_type_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg                              iq_entries_enq_is_unsigned_dec [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [          `ALU_TYPE_RANGE] iq_entries_enq_alu_type_dec    [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [       `MULDIV_TYPE_RANGE] iq_entries_enq_muldiv_type_dec [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_word_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_imm_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_load_dec;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_store_dec;
    reg  [                      3:0] iq_entries_enq_ls_size_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_robidx_flag_dec;
    reg  [        `ROB_SIZE_LOG-1:0] iq_entries_enq_robidx_dec      [`ISSUE_QUEUE_DEPTH-1:0];

    /* -------------------------------------------------------------------------- */
    /*                                   deq dec                                  */
    /* -------------------------------------------------------------------------- */
    wire [              `PREG_RANGE] iq_entries_deq_prs1_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    wire [              `PREG_RANGE] iq_entries_deq_prs2_dec        [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src1_is_reg_dec;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src2_is_reg_dec;
    wire [              `PREG_RANGE] iq_entries_deq_prd_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    wire [              `PREG_RANGE] iq_entries_deq_old_prd_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [                `PC_RANGE] iq_entries_deq_pc_dec          [`ISSUE_QUEUE_DEPTH-1:0];
    wire [                     31:0] iq_entries_deq_instr_dec       [`ISSUE_QUEUE_DEPTH-1:0];
    wire [               `SRC_RANGE] iq_entries_deq_imm_dec         [`ISSUE_QUEUE_DEPTH-1:0];
    wire                             iq_entries_deq_need_to_wb_dec  [`ISSUE_QUEUE_DEPTH-1:0];
    wire [           `CX_TYPE_RANGE] iq_entries_deq_cx_type_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire                             iq_entries_deq_is_unsigned_dec [`ISSUE_QUEUE_DEPTH-1:0];
    wire [          `ALU_TYPE_RANGE] iq_entries_deq_alu_type_dec    [`ISSUE_QUEUE_DEPTH-1:0];
    wire [       `MULDIV_TYPE_RANGE] iq_entries_deq_muldiv_type_dec [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_word_dec;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_imm_dec;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_load_dec;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_store_dec;
    wire [                      3:0] iq_entries_deq_ls_size_dec     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_robidx_flag_dec;
    wire [        `ROB_SIZE_LOG-1:0] iq_entries_deq_robidx_dec      [`ISSUE_QUEUE_DEPTH-1:0];

    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_ready_to_go_dec;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_valid_dec;


    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh_next;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh_next;

    wire                             enq_has_avail_entry;
    wire                             enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~iq_entries_valid_dec);
    assign enq_fire            = enq_has_avail_entry & enq_instr0_valid;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enq_ptr_oh <= 'b1;
        end else begin
            enq_ptr_oh <= enq_ptr_oh_next;
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                 enq decode region                          */
    /* -------------------------------------------------------------------------- */
    always @(*) begin
        integer i;
        iq_entries_enq_valid_dec = 'b0;
        if (enq_fire) begin
            for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
                iq_entries_enq_valid_dec[i] = enq_ptr_oh[i];
            end
        end
    end
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_pc_dec, enq_instr0_pc)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prs1_dec, enq_instr0_prs1)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prs2_dec, enq_instr0_prs2)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src1_is_reg_dec, enq_instr0_src1_is_reg)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src2_is_reg_dec, enq_instr0_src2_is_reg)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src1_state_dec, enq_instr0_src1_state)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src2_state_dec, enq_instr0_src2_state)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prd_dec, enq_instr0_prd)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_old_prd_dec, enq_instr0_old_prd)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_instr_dec, enq_instr0)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_imm_dec, enq_instr0_imm)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_need_to_wb_dec, enq_instr0_need_to_wb)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_cx_type_dec, enq_instr0_cx_type)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_unsigned_dec, enq_instr0_is_unsigned)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_alu_type_dec, enq_instr0_alu_type)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_muldiv_type_dec, enq_instr0_muldiv_type)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_word_dec, enq_instr0_is_word)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_imm_dec, enq_instr0_is_imm)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_load_dec, enq_instr0_is_load)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_store_dec, enq_instr0_is_store)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_ls_size_dec, enq_instr0_ls_size)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_robidx_flag_dec, enq_instr0_robidx_flag)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_robidx_dec, enq_instr0_robidx)


    io_policy enq_io_policy (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (flush_valid),
        .enq_fire       (enq_fire),
        .valid_dec      (~iq_entries_valid_dec),
        .enq_ptr_oh     (enq_ptr_oh),
        .enq_ptr_oh_next(enq_ptr_oh_next),
        .enq_valid_oh   (iq_entries_enq_valid_dec),
        .deq_ptr_oh     (deq_ptr_oh)
    );


    /* -------------------------------------------------------------------------- */
    /*                          write back wakeup region                          */
    /* -------------------------------------------------------------------------- */
    reg [`ISSUE_QUEUE_DEPTH -1 : 0] writeback_wakeup_src1_dec;
    reg [`ISSUE_QUEUE_DEPTH -1 : 0] writeback_wakeup_src2_dec;


    always @(*) begin
        integer i;
        writeback_wakeup_src1_dec = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (iq_entries_deq_src1_is_reg_dec[i] & (writeback0_valid & writeback0_need_to_wb & (writeback0_prd == iq_entries_deq_prs1_dec[i]) | writeback1_valid & writeback1_need_to_wb & (writeback1_prd == iq_entries_deq_prs1_dec[i]))) begin
                writeback_wakeup_src1_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        writeback_wakeup_src2_dec = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (iq_entries_deq_src2_is_reg_dec[i] & (writeback0_valid & writeback0_need_to_wb & (writeback0_prd == iq_entries_deq_prs2_dec[i]) | writeback1_valid & writeback1_need_to_wb & (writeback1_prd == iq_entries_deq_prs2_dec[i]))) begin
                writeback_wakeup_src2_dec[i] = 1'b1;
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                flush region                                */
    /* -------------------------------------------------------------------------- */
    reg [`ISSUE_QUEUE_DEPTH-1:0] flush_dec;
    always @(flush_valid or flush_robidx or flush_robidx_flag) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (flush_valid) begin
                if (flush_valid & iq_entries_valid_dec[i] & ((flush_robidx_flag ^ iq_entries_deq_robidx_flag_dec[i]) ^ (flush_robidx < iq_entries_deq_robidx_dec[i]))) begin
                    flush_dec[i] = 1'b1;
                end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                 deq region                                 */
    /* -------------------------------------------------------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            deq_ptr_oh <= 'b1;
        end else begin
            deq_ptr_oh <= deq_ptr_oh_next;
        end
    end

    wire deq_fire;
    assign deq_fire = (|(deq_ptr_oh & iq_entries_valid_dec & iq_entries_ready_to_go_dec)) & deq_instr0_ready;
    io_deq_policy io_deq_policy (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (flush_valid),
        .enq_fire       (enq_fire),
        .deq_fire       (deq_fire),
        .valid_dec      (iq_entries_valid_dec),
        .enq_ptr_oh     (enq_ptr_oh),
        .enq_valid_oh   (iq_entries_enq_valid_dec),
        .deq_ptr_oh     (deq_ptr_oh),
        .deq_ptr_oh_next(deq_ptr_oh_next),
        .deq_valid_oh   (iq_entries_issuing_dec)
    );


    reg [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_issuing_dec;
    always @(*) begin
        integer i;
        iq_entries_issuing_dec = 'b0;
        if (deq_fire) begin
            for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
                iq_entries_issuing_dec[i] = deq_ptr_oh[i];
            end
        end
    end
    assign deq_instr0_valid = |iq_entries_issuing_dec;
    /* -------------------------------------------------------------------------- */
    /*                               deq dec region                               */
    /* -------------------------------------------------------------------------- */

    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_pc, iq_entries_deq_pc_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_prs1, iq_entries_deq_prs1_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_prs2, iq_entries_deq_prs2_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_src1_is_reg, iq_entries_deq_src1_is_reg_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_src2_is_reg, iq_entries_deq_src2_is_reg_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_prd, iq_entries_deq_prd_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_old_prd, iq_entries_deq_old_prd_dec)
    // `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0, iq_entries_deq_instr_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_imm, iq_entries_deq_imm_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_need_to_wb, iq_entries_deq_need_to_wb_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_cx_type, iq_entries_deq_cx_type_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_is_unsigned, iq_entries_deq_is_unsigned_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_alu_type, iq_entries_deq_alu_type_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_muldiv_type, iq_entries_deq_muldiv_type_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_is_word, iq_entries_deq_is_word_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_is_imm, iq_entries_deq_is_imm_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_is_load, iq_entries_deq_is_load_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_is_store, iq_entries_deq_is_store_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_ls_size, iq_entries_deq_ls_size_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_robidx_flag, iq_entries_deq_robidx_flag_dec)
    `MACRO_DEQ_DEC(iq_entries_issuing_dec, deq_instr0_robidx, iq_entries_deq_robidx_dec)


    assign enq_instr0_ready = enq_has_avail_entry;
    genvar i;
    generate
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin : iq_entity
            iq_entry u_iq_entry (
                .clock                (clock),
                .reset_n              (reset_n),
                .enq_valid            (iq_entries_enq_valid_dec[i]),
                .enq_pc               (iq_entries_enq_pc_dec[i]),
                .enq_instr            (iq_entries_enq_instr_dec[i]),
                .enq_imm              (iq_entries_enq_imm_dec[i]),
                .enq_src1_is_reg      (iq_entries_enq_src1_is_reg_dec[i]),
                .enq_src2_is_reg      (iq_entries_enq_src2_is_reg_dec[i]),
                .enq_need_to_wb       (iq_entries_enq_need_to_wb_dec[i]),
                .enq_cx_type          (iq_entries_enq_cx_type_dec[i]),
                .enq_is_unsigned      (iq_entries_enq_is_unsigned_dec[i]),
                .enq_alu_type         (iq_entries_enq_alu_type_dec[i]),
                .enq_muldiv_type      (iq_entries_enq_muldiv_type_dec[i]),
                .enq_is_word          (iq_entries_enq_is_word_dec[i]),
                .enq_is_imm           (iq_entries_enq_is_imm_dec[i]),
                .enq_is_load          (iq_entries_enq_is_load_dec[i]),
                .enq_is_store         (iq_entries_enq_is_store_dec[i]),
                .enq_ls_size          (iq_entries_enq_ls_size_dec[i]),
                .enq_prs1             (iq_entries_enq_prs1_dec[i]),
                .enq_prs2             (iq_entries_enq_prs2_dec[i]),
                .enq_prd              (iq_entries_enq_prd_dec[i]),
                .enq_old_prd          (iq_entries_enq_old_prd_dec[i]),
                .enq_robidx_flag      (iq_entries_enq_robidx_flag_dec[i]),
                .enq_robidx           (iq_entries_enq_robidx_dec[i]),
                .enq_src1_state       (iq_entries_enq_src1_state_dec[i]),
                .enq_src2_state       (iq_entries_enq_src2_state_dec[i]),
                .ready_to_go          (iq_entries_ready_to_go_dec[i]),
                .writeback_wakeup_src1(writeback_wakeup_src1_dec[i]),
                .writeback_wakeup_src2(writeback_wakeup_src2_dec[i]),
                .issuing              (iq_entries_issuing_dec[i]),
                .flush                (flush_dec[i]),
                .valid                (iq_entries_valid_dec[i]),
                .deq_pc               (iq_entries_deq_pc_dec[i]),
                .deq_instr            (iq_entries_deq_instr_dec[i]),
                .deq_imm              (iq_entries_deq_imm_dec[i]),
                .deq_src1_is_reg      (iq_entries_deq_src1_is_reg_dec[i]),
                .deq_src2_is_reg      (iq_entries_deq_src2_is_reg_dec[i]),
                .deq_need_to_wb       (iq_entries_deq_need_to_wb_dec[i]),
                .deq_cx_type          (iq_entries_deq_cx_type_dec[i]),
                .deq_is_unsigned      (iq_entries_deq_is_unsigned_dec[i]),
                .deq_alu_type         (iq_entries_deq_alu_type_dec[i]),
                .deq_muldiv_type      (iq_entries_deq_muldiv_type_dec[i]),
                .deq_is_word          (iq_entries_deq_is_word_dec[i]),
                .deq_is_imm           (iq_entries_deq_is_imm_dec[i]),
                .deq_is_load          (iq_entries_deq_is_load_dec[i]),
                .deq_is_store         (iq_entries_deq_is_store_dec[i]),
                .deq_ls_size          (iq_entries_deq_ls_size_dec[i]),
                .deq_prs1             (iq_entries_deq_prs1_dec[i]),
                .deq_prs2             (iq_entries_deq_prs2_dec[i]),
                .deq_prd              (iq_entries_deq_prd_dec[i]),
                .deq_old_prd          (iq_entries_deq_old_prd_dec[i]),
                .deq_robidx_flag      (iq_entries_deq_robidx_flag_dec[i]),
                .deq_robidx           (iq_entries_deq_robidx_dec[i])
            );
        end
    endgenerate
endmodule
