`include "defines.sv"
module issuequeue (
    input  wire               clock,
    input  wire               reset_n,
    input  wire               enq_instr0_valid,
    output wire               enq_instr0_ready,
    input  wire [`LREG_RANGE] enq_instr0_lrs1,
    input  wire [`LREG_RANGE] enq_instr0_lrs2,
    input  wire [`LREG_RANGE] enq_instr0_lrd,
    input  wire [       `PC_RANGE] enq_instr0_pc,
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
    input wire enq_instr0_src1_state,
    input wire enq_instr0_src2_state,

    /* ----------------------------- output to block ---------------------------- */
    output wire               deq_instr0_valid,
    output wire [`PREG_RANGE] deq_instr0_prs1,
    output wire [`PREG_RANGE] deq_instr0_prs2,
    output wire               deq_instr0_src1_is_reg,
    output wire               deq_instr0_src2_is_reg,

    output wire [`PREG_RANGE] deq_instr0_prd,
    output wire [`PREG_RANGE] deq_instr0_old_prd,

    output wire [`SRC_RANGE] deq_instr0_pc,
    output wire [`SRC_RANGE] deq_instr0_imm,

    output wire                      deq_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] deq_instr0_cx_type,
    output wire                      deq_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] deq_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] deq_instr0_muldiv_type,
    output wire                      deq_instr0_is_word,
    output wire                      deq_instr0_is_imm,
    output wire                      deq_instr0_is_load,
    output wire                      deq_instr0_is_store,
    output wire [               3:0] deq_instr0_ls_size,

    output wire                     deq_instr0_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] deq_instr0_robidx


);



endmodule
