module int_isq #(
    parameter OUT_OF_ORDER = 0
) (
    input  wire clock,
    input  wire reset_n,
    //ready sigs,cause dispathc only can dispatch when rob,IQ,SQ both have avail entry
    output wire iq_can_alloc0,
    input  wire all_iq_ready,

    input wire               enq_instr0_valid,
    input wire [`LREG_RANGE] enq_instr0_lrs1,
    input wire [`LREG_RANGE] enq_instr0_lrs2,
    input wire [`LREG_RANGE] enq_instr0_lrd,
    input wire [  `PC_RANGE] enq_instr0_pc,
    input wire [       31:0] enq_instr0,

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
    input wire               enq_instr0_predicttaken,
    input wire [  `PC_RANGE] enq_instr0_predicttarget,

    input wire [  `ROB_SIZE_LOG:0] enq_instr0_robid,
    input wire [`SQ_SIZE_LOG:0] enq_instr0_sqid,
    /* -------------------------------- src state ------------------------------- */
    input wire                     enq_instr0_src1_state,
    input wire                     enq_instr0_src2_state,

    /* ------------------------------- output to execute block ------------------------------- */
    output wire                      issue0_valid,
    input  wire                      issue0_ready,
    output reg  [       `PREG_RANGE] issue0_prs1,
    output reg  [       `PREG_RANGE] issue0_prs2,
    output reg                       issue0_src1_is_reg,
    output reg                       issue0_src2_is_reg,
    output reg  [       `PREG_RANGE] issue0_prd,
    output reg  [       `PREG_RANGE] issue0_old_prd,
    output reg  [        `SRC_RANGE] issue0_pc,
    output reg  [              31:0] issue0_instr,
    output reg  [        `SRC_RANGE] issue0_imm,
    output reg                       issue0_need_to_wb,
    output reg  [    `CX_TYPE_RANGE] issue0_cx_type,
    output reg                       issue0_is_unsigned,
    output reg  [   `ALU_TYPE_RANGE] issue0_alu_type,
    output reg  [`MULDIV_TYPE_RANGE] issue0_muldiv_type,
    output reg                       issue0_is_word,
    output reg                       issue0_is_imm,
    output reg                       issue0_is_load,
    output reg                       issue0_is_store,
    output reg  [               3:0] issue0_ls_size,
    output reg                       issue0_predicttaken,
    output reg  [         `PC_RANGE] issue0_predicttarget,

    output reg [  `ROB_SIZE_LOG:0] issue0_robid,
    output reg [`SQ_SIZE_LOG:0] issue0_sqid,

    //-----------------------------------------------------
    // writeback to set condition to 1
    //-----------------------------------------------------
    input wire               writeback0_valid,
    input wire               writeback0_need_to_wb,
    input wire [`PREG_RANGE] writeback0_prd,

    input wire                    writeback1_valid,
    input wire                    writeback1_need_to_wb,
    input wire  [    `PREG_RANGE] writeback1_prd,
    //-----------------------------------------------------
    // Flush interface
    //-----------------------------------------------------
    input logic [            1:0] rob_state,
    input logic                   flush_valid,
    input logic [`ROB_SIZE_LOG:0] flush_robid,
    /* -------------------------------------------------------------------------- */
    /*                                  pmu logic                                 */
    /* -------------------------------------------------------------------------- */
    output reg [31:0] intisq_pmu_block_enq_cycle_cnt,
    output reg [31:0] intisq_pmu_can_issue_more

);


    /* -------------------------------------------------------------------------- */
    /*                                   enq dec                                  */
    /* -------------------------------------------------------------------------- */

    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_wren_oh;
    reg  [                `PC_RANGE] iq_entries_enq_pc_oh           [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_prs1_oh         [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_prs2_oh         [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_is_reg_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_is_reg_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src1_state_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_src2_state_oh;
    reg  [              `PREG_RANGE] iq_entries_enq_prd_oh          [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [              `PREG_RANGE] iq_entries_enq_old_prd_oh      [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [                     31:0] iq_entries_enq_instr_oh        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [               `SRC_RANGE] iq_entries_enq_imm_oh          [`ISSUE_QUEUE_DEPTH-1:0];
    reg                              iq_entries_enq_need_to_wb_oh   [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [           `CX_TYPE_RANGE] iq_entries_enq_cx_type_oh      [`ISSUE_QUEUE_DEPTH-1:0];
    reg                              iq_entries_enq_is_unsigned_oh  [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [          `ALU_TYPE_RANGE] iq_entries_enq_alu_type_oh     [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [       `MULDIV_TYPE_RANGE] iq_entries_enq_muldiv_type_oh  [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_word_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_imm_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_load_oh;
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_is_store_oh;
    reg  [                      3:0] iq_entries_enq_ls_size_oh      [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_enq_predicttaken_oh;
    reg  [                `PC_RANGE] iq_entries_enq_predicttarget_oh[`ISSUE_QUEUE_DEPTH-1:0];
    reg  [          `ROB_SIZE_LOG:0] iq_entries_enq_robid_oh        [`ISSUE_QUEUE_DEPTH-1:0];
    reg  [        `SQ_SIZE_LOG:0] iq_entries_enq_sqid_oh         [`ISSUE_QUEUE_DEPTH-1:0];

    /* -------------------------------------------------------------------------- */
    /*                                   deq dec                                  */
    /* -------------------------------------------------------------------------- */
    wire [              `PREG_RANGE] iq_entries_deq_prs1            [`ISSUE_QUEUE_DEPTH-1:0];
    wire [              `PREG_RANGE] iq_entries_deq_prs2            [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src1_is_reg;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_src2_is_reg;
    wire [              `PREG_RANGE] iq_entries_deq_prd             [`ISSUE_QUEUE_DEPTH-1:0];
    wire [              `PREG_RANGE] iq_entries_deq_old_prd         [`ISSUE_QUEUE_DEPTH-1:0];
    wire [                `PC_RANGE] iq_entries_deq_pc              [`ISSUE_QUEUE_DEPTH-1:0];
    wire [                     31:0] iq_entries_deq_instr           [`ISSUE_QUEUE_DEPTH-1:0];
    wire [               `SRC_RANGE] iq_entries_deq_imm             [`ISSUE_QUEUE_DEPTH-1:0];
    wire                             iq_entries_deq_need_to_wb      [`ISSUE_QUEUE_DEPTH-1:0];
    wire [           `CX_TYPE_RANGE] iq_entries_deq_cx_type         [`ISSUE_QUEUE_DEPTH-1:0];
    wire                             iq_entries_deq_is_unsigned     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [          `ALU_TYPE_RANGE] iq_entries_deq_alu_type        [`ISSUE_QUEUE_DEPTH-1:0];
    wire [       `MULDIV_TYPE_RANGE] iq_entries_deq_muldiv_type     [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_word;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_imm;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_load;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_is_store;
    wire [                      3:0] iq_entries_deq_ls_size         [`ISSUE_QUEUE_DEPTH-1:0];
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_deq_predicttaken;
    wire [                `PC_RANGE] iq_entries_deq_predicttarget   [`ISSUE_QUEUE_DEPTH-1:0];
    wire [          `ROB_SIZE_LOG:0] iq_entries_deq_robid           [`ISSUE_QUEUE_DEPTH-1:0];
    wire [        `SQ_SIZE_LOG:0] iq_entries_deq_sqid            [`ISSUE_QUEUE_DEPTH-1:0];

    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_ready_to_go;
    wire [   `ISSUE_QUEUE_DEPTH-1:0] iq_entries_valid;



    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh;
    reg  [  `ISSUE_QUEUE_LOG -1 : 0] enq_ptr;
    reg  [  `ISSUE_QUEUE_LOG -1 : 0] deq_ptr;
    reg  [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh;

    wire                             enq_has_avail_entry;
    wire                             enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~iq_entries_valid);
    assign enq_fire            = enq_has_avail_entry & enq_instr0_valid;

    findfirstone u_findfirstone (
        .in_vector(~iq_entries_valid),
        .onehot   (enq_ptr_oh),
        .enc      (enq_ptr),
        .valid    ()
    );



    /* -------------------------------------------------------------------------- */
    /*                                 enq decode region                          */
    /* -------------------------------------------------------------------------- */
    always @(*) begin
        integer i;
        iq_entries_wren_oh = 'b0;
        if (enq_fire) begin
            for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
                iq_entries_wren_oh[i] = enq_ptr_oh[i];
            end
        end
    end
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_pc_oh, enq_instr0_pc, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prs1_oh, enq_instr0_prs1, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prs2_oh, enq_instr0_prs2, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src1_is_reg_oh, enq_instr0_src1_is_reg, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src2_is_reg_oh, enq_instr0_src2_is_reg, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src1_state_oh, enq_instr0_src1_state, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_src2_state_oh, enq_instr0_src2_state, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_prd_oh, enq_instr0_prd, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_old_prd_oh, enq_instr0_old_prd, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_instr_oh, enq_instr0, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_imm_oh, enq_instr0_imm, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_need_to_wb_oh, enq_instr0_need_to_wb, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_cx_type_oh, enq_instr0_cx_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_unsigned_oh, enq_instr0_is_unsigned, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_alu_type_oh, enq_instr0_alu_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_muldiv_type_oh, enq_instr0_muldiv_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_word_oh, enq_instr0_is_word, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_imm_oh, enq_instr0_is_imm, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_load_oh, enq_instr0_is_load, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_is_store_oh, enq_instr0_is_store, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_ls_size_oh, enq_instr0_ls_size, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_predicttaken_oh, enq_instr0_predicttaken, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_predicttarget_oh, enq_instr0_predicttarget, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_robid_oh, enq_instr0_robid, `ISSUE_QUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, iq_entries_enq_sqid_oh, enq_instr0_sqid, `ISSUE_QUEUE_DEPTH)






    /* -------------------------------------------------------------------------- */
    /*                          write back wakeup region                          */
    /* -------------------------------------------------------------------------- */
    reg [`ISSUE_QUEUE_DEPTH -1 : 0] writeback_wakeup_src1;
    reg [`ISSUE_QUEUE_DEPTH -1 : 0] writeback_wakeup_src2;


    always @(*) begin
        integer i;
        writeback_wakeup_src1 = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (iq_entries_deq_src1_is_reg[i] & (writeback0_valid & writeback0_need_to_wb & (writeback0_prd == iq_entries_deq_prs1[i]) | writeback1_valid & writeback1_need_to_wb & (writeback1_prd == iq_entries_deq_prs1[i]))) begin
                writeback_wakeup_src1[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        writeback_wakeup_src2 = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (iq_entries_deq_src2_is_reg[i] & (writeback0_valid & writeback0_need_to_wb & (writeback0_prd == iq_entries_deq_prs2[i]) | writeback1_valid & writeback1_need_to_wb & (writeback1_prd == iq_entries_deq_prs2[i]))) begin
                writeback_wakeup_src2[i] = 1'b1;
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                flush region                                */
    /* -------------------------------------------------------------------------- */
    reg [`ISSUE_QUEUE_DEPTH-1:0] flush_dec;
    always @(flush_valid or flush_robid) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (flush_valid) begin
                if (flush_valid & iq_entries_valid[i] & ((flush_robid[`ROB_SIZE_LOG] ^ iq_entries_deq_robid[i][`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] < iq_entries_deq_robid[i][`ROB_SIZE_LOG-1:0]))) begin
                    flush_dec[i] = 1'b1;
                end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                 deq region                                 */
    /* -------------------------------------------------------------------------- */

    wire deq_fire;
    wire oldest_found;

    assign issue0_valid = ((|deq_ptr_oh) & oldest_found);
    assign deq_fire     = issue0_valid & issue0_ready;

    if (OUT_OF_ORDER == 1) begin
        age_deq_policy_ooo u_ooo_deq_policy (
            .clock                 (clock),
            .reset_n               (reset_n),
            .iq_entries_wren_oh    (iq_entries_wren_oh),
            .enq_ptr               (enq_ptr),
            .iq_entries_ready_to_go(iq_entries_ready_to_go),
            .iq_entries_valid      (iq_entries_valid),
            .iq_entries_clear_entry(iq_entries_clear_entry),
            .deq_ptr               (deq_ptr),
            .oldest_found          (oldest_found),
            .oldest_idx_oh         (deq_ptr_oh)
        );
    end else begin
        age_deq_policy u_age_deq_policy (
            .clock                 (clock),
            .reset_n               (reset_n),
            .iq_entries_wren_oh    (iq_entries_wren_oh),
            .enq_ptr               (enq_ptr),
            .iq_entries_ready_to_go(iq_entries_ready_to_go),
            .iq_entries_valid      (iq_entries_valid),
            .iq_entries_clear_entry(iq_entries_clear_entry),
            .deq_ptr               (deq_ptr),
            .oldest_found          (oldest_found),
            .oldest_idx_oh         (deq_ptr_oh)
        );
    end


    //check if age buffer have available entry
    assign iq_can_alloc0 = enq_has_avail_entry;


    always @(*) begin
        integer i;
        deq_ptr = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (deq_fire) begin
                if (iq_entries_clear_entry[i]) begin
                    deq_ptr = i;
                end
            end
        end
    end



    reg [`ISSUE_QUEUE_DEPTH-1:0] iq_entries_clear_entry;
    always @(*) begin
        integer i;
        iq_entries_clear_entry = 'b0;
        if (deq_fire) begin
            for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
                iq_entries_clear_entry[i] = deq_ptr_oh[i];
            end
        end
    end



    /* -------------------------------------------------------------------------- */
    /*                               deq dec region                               */
    /* -------------------------------------------------------------------------- */

    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_pc, iq_entries_deq_pc, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_prs1, iq_entries_deq_prs1, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_prs2, iq_entries_deq_prs2, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_src1_is_reg, iq_entries_deq_src1_is_reg, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_src2_is_reg, iq_entries_deq_src2_is_reg, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_prd, iq_entries_deq_prd, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_old_prd, iq_entries_deq_old_prd, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_instr, iq_entries_deq_instr, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_imm, iq_entries_deq_imm, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_need_to_wb, iq_entries_deq_need_to_wb, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_cx_type, iq_entries_deq_cx_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_is_unsigned, iq_entries_deq_is_unsigned, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_alu_type, iq_entries_deq_alu_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_muldiv_type, iq_entries_deq_muldiv_type, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_is_word, iq_entries_deq_is_word, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_is_imm, iq_entries_deq_is_imm, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_is_load, iq_entries_deq_is_load, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_is_store, iq_entries_deq_is_store, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_ls_size, iq_entries_deq_ls_size, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_predicttaken, iq_entries_deq_predicttaken, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_predicttarget, iq_entries_deq_predicttarget, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_robid, iq_entries_deq_robid, `ISSUE_QUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, issue0_sqid, iq_entries_deq_sqid, `ISSUE_QUEUE_DEPTH)



    genvar i;
    generate
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin : iq_entity
            iq_entry u_iq_entry (
                .clock                (clock),
                .reset_n              (reset_n),
                .enq_valid            (iq_entries_wren_oh[i]),
                .enq_pc               (iq_entries_enq_pc_oh[i]),
                .enq_instr            (iq_entries_enq_instr_oh[i]),
                .enq_imm              (iq_entries_enq_imm_oh[i]),
                .enq_src1_is_reg      (iq_entries_enq_src1_is_reg_oh[i]),
                .enq_src2_is_reg      (iq_entries_enq_src2_is_reg_oh[i]),
                .enq_need_to_wb       (iq_entries_enq_need_to_wb_oh[i]),
                .enq_cx_type          (iq_entries_enq_cx_type_oh[i]),
                .enq_is_unsigned      (iq_entries_enq_is_unsigned_oh[i]),
                .enq_alu_type         (iq_entries_enq_alu_type_oh[i]),
                .enq_muldiv_type      (iq_entries_enq_muldiv_type_oh[i]),
                .enq_is_word          (iq_entries_enq_is_word_oh[i]),
                .enq_is_imm           (iq_entries_enq_is_imm_oh[i]),
                .enq_is_load          (iq_entries_enq_is_load_oh[i]),
                .enq_is_store         (iq_entries_enq_is_store_oh[i]),
                .enq_ls_size          (iq_entries_enq_ls_size_oh[i]),
                .enq_prs1             (iq_entries_enq_prs1_oh[i]),
                .enq_prs2             (iq_entries_enq_prs2_oh[i]),
                .enq_prd              (iq_entries_enq_prd_oh[i]),
                .enq_old_prd          (iq_entries_enq_old_prd_oh[i]),
                .enq_predicttaken     (iq_entries_enq_predicttaken_oh[i]),
                .enq_predicttarget    (iq_entries_enq_predicttarget_oh[i]),
                .enq_robid            (iq_entries_enq_robid_oh[i]),
                .enq_sqid             (iq_entries_enq_sqid_oh[i]),
                .enq_src1_state       (iq_entries_enq_src1_state_oh[i]),
                .enq_src2_state       (iq_entries_enq_src2_state_oh[i]),
                .ready_to_go          (iq_entries_ready_to_go[i]),
                .writeback_wakeup_src1(writeback_wakeup_src1[i]),
                .writeback_wakeup_src2(writeback_wakeup_src2[i]),
                .issuing              (iq_entries_clear_entry[i]),
                .flush                (flush_dec[i]),
                .valid                (iq_entries_valid[i]),                 //output ,as deq_valid
                .deq_pc               (iq_entries_deq_pc[i]),
                .deq_instr            (iq_entries_deq_instr[i]),
                .deq_imm              (iq_entries_deq_imm[i]),
                .deq_src1_is_reg      (iq_entries_deq_src1_is_reg[i]),
                .deq_src2_is_reg      (iq_entries_deq_src2_is_reg[i]),
                .deq_need_to_wb       (iq_entries_deq_need_to_wb[i]),
                .deq_cx_type          (iq_entries_deq_cx_type[i]),
                .deq_is_unsigned      (iq_entries_deq_is_unsigned[i]),
                .deq_alu_type         (iq_entries_deq_alu_type[i]),
                .deq_muldiv_type      (iq_entries_deq_muldiv_type[i]),
                .deq_is_word          (iq_entries_deq_is_word[i]),
                .deq_is_imm           (iq_entries_deq_is_imm[i]),
                .deq_is_load          (iq_entries_deq_is_load[i]),
                .deq_is_store         (iq_entries_deq_is_store[i]),
                .deq_ls_size          (iq_entries_deq_ls_size[i]),
                .deq_prs1             (iq_entries_deq_prs1[i]),
                .deq_prs2             (iq_entries_deq_prs2[i]),
                .deq_prd              (iq_entries_deq_prd[i]),
                .deq_old_prd          (iq_entries_deq_old_prd[i]),
                .deq_predicttaken     (iq_entries_deq_predicttaken[i]),
                .deq_predicttarget    (iq_entries_deq_predicttarget[i]),
                .deq_robid            (iq_entries_deq_robid[i]),
                .deq_sqid             (iq_entries_deq_sqid[i])
            );
        end
    endgenerate

 /* -------------------------------- pmu logic ------------------------------- */
    //count cycles when int_isq refuse to accept req due to entries full  
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            intisq_pmu_block_enq_cycle_cnt <= 'b0;
        end else if(~iq_can_alloc0 && enq_instr0_valid) begin
            intisq_pmu_block_enq_cycle_cnt <= intisq_pmu_block_enq_cycle_cnt + 1;
        end
    end

    //count cycles when int_isq issue req while it can actually issue more
    reg [4:0] ready_to_go_cnt;
    always @(*) begin
        integer i;
        ready_to_go_cnt = 'b0;
        for ( i=0 ; i<`ISSUE_QUEUE_DEPTH;i=i+1 ) begin
            ready_to_go_cnt = ready_to_go_cnt + iq_entries_ready_to_go[i];
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            intisq_pmu_can_issue_more <= 'b0;
        end else if(issue0_valid && (ready_to_go_cnt>1)) begin
            intisq_pmu_can_issue_more <= intisq_pmu_can_issue_more + 1;
        end
    end

endmodule
