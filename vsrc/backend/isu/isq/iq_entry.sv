`include "defines.sv"
module iq_entry (
    input wire                      clock,
    input wire                      reset_n,
    input wire                      enq_valid,
    input wire [         `PC_RANGE] enq_pc,
    input wire [              31:0] enq_instr,
    input wire [              63:0] enq_imm,
    input wire                      enq_src1_is_reg,
    input wire                      enq_src2_is_reg,
    input wire                      enq_need_to_wb,
    input wire [    `CX_TYPE_RANGE] enq_cx_type,
    input wire                      enq_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] enq_alu_type,
    input wire [`MULDIV_TYPE_RANGE] enq_muldiv_type,
    input wire                      enq_is_word,
    input wire                      enq_is_imm,
    input wire                      enq_is_load,
    input wire                      enq_is_store,
    input wire [               3:0] enq_ls_size,

    input wire [`PREG_RANGE] enq_prs1,
    input wire [`PREG_RANGE] enq_prs2,
    input wire [`PREG_RANGE] enq_prd,
    input wire [`PREG_RANGE] enq_old_prd,
    input wire               enq_predicttaken,
    input wire [  `PC_RANGE] enq_predicttarget,

    input wire [  `ROB_SIZE_LOG:0] enq_robid,
    input wire [`SQ_SIZE_LOG:0] enq_sqid,

    /* -------------------------------- src state ------------------------------- */
    input wire enq_src1_state,
    input wire enq_src2_state,

    /* ------------------------------- ready to go ------------------------------ */
    output wire ready_to_go,

    /* ------------------------------- write back ------------------------------- */
    input wire writeback_wakeup_src1,
    input wire writeback_wakeup_src2,

    /* ---------------------------------- issue --------------------------------- */
    input wire issuing,

    /* ---------------------------------- flush --------------------------------- */
    input wire flush,

    /* --------------------------------- output --------------------------------- */
    output wire                      valid,
    output wire [         `PC_RANGE] deq_pc,
    output wire [              31:0] deq_instr,
    output wire [              63:0] deq_imm,
    output wire                      deq_src1_is_reg,
    output wire                      deq_src2_is_reg,
    output wire                      deq_need_to_wb,
    output wire [    `CX_TYPE_RANGE] deq_cx_type,
    output wire                      deq_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] deq_alu_type,
    output wire [`MULDIV_TYPE_RANGE] deq_muldiv_type,
    output wire                      deq_is_word,
    output wire                      deq_is_imm,
    output wire                      deq_is_load,
    output wire                      deq_is_store,
    output wire [               3:0] deq_ls_size,

    output wire [`PREG_RANGE] deq_prs1,
    output wire [`PREG_RANGE] deq_prs2,
    output wire [`PREG_RANGE] deq_prd,
    output wire [`PREG_RANGE] deq_old_prd,
    output wire               deq_predicttaken,
    output wire [  `PC_RANGE] deq_predicttarget,

    output wire [  `ROB_SIZE_LOG:0] deq_robid,
    output wire [`SQ_SIZE_LOG:0] deq_sqid
);
    // Internal queue storage
    reg                      queue_valid;
    reg [         `PC_RANGE] queue_pc;
    reg [              31:0] queue_instr;
    reg [       `PREG_RANGE] queue_prs1;
    reg [       `PREG_RANGE] queue_prs2;
    reg                      queue_src1_is_reg;
    reg                      queue_src2_is_reg;
    reg                      queue_src1_state;
    reg                      queue_src2_state;
    reg [       `PREG_RANGE] queue_prd;
    reg [       `PREG_RANGE] queue_old_prd;
    reg [        `SRC_RANGE] queue_imm;
    reg                      queue_need_to_wb;
    reg [    `CX_TYPE_RANGE] queue_cx_type;
    reg                      queue_is_unsigned;
    reg [   `ALU_TYPE_RANGE] queue_alu_type;
    reg [`MULDIV_TYPE_RANGE] queue_muldiv_type;
    reg                      queue_is_word;
    reg                      queue_is_imm;
    reg                      queue_is_load;
    reg                      queue_is_store;
    reg [               3:0] queue_ls_size;
    reg                      queue_predicttaken;
    reg [         `PC_RANGE] queue_predicttarget;
    reg [   `ROB_SIZE_LOG:0] queue_robid;
    reg [ `SQ_SIZE_LOG:0] queue_sqid;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n | flush) begin
            queue_valid <= 1'b0;
        end else if (enq_valid) begin
            queue_valid <= enq_valid;
        end else if (issuing) begin
            queue_valid <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src1_state <= 1'b0;
        end else if (enq_valid) begin
            queue_src1_state <= enq_src1_state;
        end else if (writeback_wakeup_src1) begin
            queue_src1_state <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src2_state <= 1'b0;
        end else if (enq_valid) begin
            queue_src2_state <= enq_src2_state;
        end else if (writeback_wakeup_src2) begin
            queue_src2_state <= 'b0;
        end
    end

    `MACRO_LATCH_NONEN(queue_pc, enq_pc, enq_valid, `PC_LENGTH)
    `MACRO_LATCH_NONEN(queue_instr, enq_instr, enq_valid, 32)
    `MACRO_LATCH_NONEN(queue_prs1, enq_prs1, enq_valid, `PREG_LENGTH)
    `MACRO_LATCH_NONEN(queue_prs2, enq_prs2, enq_valid, `PREG_LENGTH)
    `MACRO_LATCH_NONEN(queue_src1_is_reg, enq_src1_is_reg, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_src2_is_reg, enq_src2_is_reg, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_prd, enq_prd, enq_valid, `PREG_LENGTH)
    `MACRO_LATCH_NONEN(queue_old_prd, enq_old_prd, enq_valid, `PREG_LENGTH)
    `MACRO_LATCH_NONEN(queue_imm, enq_imm, enq_valid, `SRC_LENGTH)
    `MACRO_LATCH_NONEN(queue_need_to_wb, enq_need_to_wb, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_cx_type, enq_cx_type, enq_valid, 6)
    `MACRO_LATCH_NONEN(queue_is_unsigned, enq_is_unsigned, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_alu_type, enq_alu_type, enq_valid, `ALU_TYPE_LENGTH)
    `MACRO_LATCH_NONEN(queue_muldiv_type, enq_muldiv_type, enq_valid, 13)
    `MACRO_LATCH_NONEN(queue_is_word, enq_is_word, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_is_imm, enq_is_imm, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_is_imm, enq_is_imm, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_is_load, enq_is_load, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_is_store, enq_is_store, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_ls_size, enq_ls_size, enq_valid, 4)
    `MACRO_LATCH_NONEN(queue_predicttaken, enq_predicttaken, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_predicttarget, enq_predicttarget, enq_valid, `PC_LENGTH)
    `MACRO_LATCH_NONEN(queue_robid, enq_robid, enq_valid, `ROB_SIZE_LOG + 1)
    `MACRO_LATCH_NONEN(queue_sqid, enq_sqid, enq_valid, `SQ_SIZE_LOG + 1)

    assign valid             = queue_valid;
    assign deq_pc            = queue_pc;
    assign deq_instr         = queue_instr;
    assign deq_prs1          = queue_prs1;
    assign deq_prs2          = queue_prs2;
    assign deq_src1_is_reg   = queue_src1_is_reg;
    assign deq_src2_is_reg   = queue_src2_is_reg;
    assign deq_prd           = queue_prd;
    assign deq_old_prd       = queue_old_prd;
    assign deq_imm           = queue_imm;
    assign deq_need_to_wb    = queue_need_to_wb;
    assign deq_cx_type       = queue_cx_type;
    assign deq_is_unsigned   = queue_is_unsigned;
    assign deq_alu_type      = queue_alu_type;
    assign deq_muldiv_type   = queue_muldiv_type;
    assign deq_is_word       = queue_is_word;
    assign deq_is_imm        = queue_is_imm;
    assign deq_is_load       = queue_is_load;
    assign deq_is_store      = queue_is_store;
    assign deq_ls_size       = queue_ls_size;
    assign deq_predicttaken  = queue_predicttaken;
    assign deq_predicttarget = queue_predicttarget;
    assign deq_robid         = queue_robid;
    assign deq_sqid          = queue_sqid;
    assign ready_to_go       = (~queue_src1_state) & (~queue_src2_state) & queue_valid;





endmodule
