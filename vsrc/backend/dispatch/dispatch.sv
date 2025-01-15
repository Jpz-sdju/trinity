`include "defines.sv"
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
module dispatch (
    input  wire               clock,
    input  wire               reset_n,
    /* --------------------------- from rename instr0 --------------------------- */
    input  wire               instr0_valid,
    output wire               instr0_ready,
    input  wire [`LREG_RANGE] instr0_lrs1,
    input  wire [`LREG_RANGE] instr0_lrs2,
    input  wire [`LREG_RANGE] instr0_lrd,
    input  wire [       `PC_RANGE] instr0_pc,
    input  wire [       31:0] instr0,

    input wire [              63:0] instr0_imm,
    input wire                      instr0_src1_is_reg,
    input wire                      instr0_src2_is_reg,
    input wire                      instr0_need_to_wb,
    input wire [    `CX_TYPE_RANGE] instr0_cx_type,
    input wire                      instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input wire                      instr0_is_word,
    input wire                      instr0_is_imm,
    input wire                      instr0_is_load,
    input wire                      instr0_is_store,
    input wire [               3:0] instr0_ls_size,

    input wire [`PREG_RANGE] instr0_prs1,
    input wire [`PREG_RANGE] instr0_prs2,
    input wire [`PREG_RANGE] instr0_prd,
    input wire [`PREG_RANGE] instr0_old_prd,

    /* --------------------------- from rename instr1 --------------------------- */
    input  wire               instr1_valid,
    output wire               instr1_ready,
    input  wire [`LREG_RANGE] instr1_lrs1,
    input  wire [`LREG_RANGE] instr1_lrs2,
    input  wire [`LREG_RANGE] instr1_lrd,
    input  wire [       `PC_RANGE] instr1_pc,
    input  wire [       31:0] instr1,

    input wire [              63:0] instr1_imm,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire                      instr1_need_to_wb,
    input wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,
    input wire                      instr1_is_word,
    input wire                      instr1_is_imm,
    input wire                      instr1_is_load,
    input wire                      instr1_is_store,
    input wire [               3:0] instr1_ls_size,

    input wire [`PREG_RANGE] instr1_prs1,
    input wire [`PREG_RANGE] instr1_prs2,
    input wire [`PREG_RANGE] instr1_prd,
    input wire [`PREG_RANGE] instr1_old_prd,

    /* ----------------------------------- rob ---------------------------------- */
    //counter(temp sig)
    input wire [`ROB_SIZE_LOG-1:0] counter,
    input wire                     enq_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_robidx,

    /* ------------------------ issue instr0 and enq rob ------------------------ */
    output wire               to_issue_instr0_valid,
    input  wire               to_issue_instr0_ready,
    output wire [`LREG_RANGE] to_issue_instr0_lrs1,
    output wire [`LREG_RANGE] to_issue_instr0_lrs2,
    output wire [`LREG_RANGE] to_issue_instr0_lrd,
    output wire [       `PC_RANGE] to_issue_instr0_pc,
    output wire [       31:0] to_issue_instr0,

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

    /* ------------------------ issue instr1 and enq rob ------------------------ */
    output wire               to_issue_instr1_valid,
    input  wire               to_issue_instr1_ready,
    output wire [`LREG_RANGE] to_issue_instr1_lrs1,
    output wire [`LREG_RANGE] to_issue_instr1_lrs2,
    output wire [`LREG_RANGE] to_issue_instr1_lrd,
    output wire [       `PC_RANGE] to_issue_instr1_pc,
    output wire [       31:0] to_issue_instr1,

    output wire [              63:0] to_issue_instr1_imm,
    output wire                      to_issue_instr1_src1_is_reg,
    output wire                      to_issue_instr1_src2_is_reg,
    output wire                      to_issue_instr1_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_issue_instr1_cx_type,
    output wire                      to_issue_instr1_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_issue_instr1_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_issue_instr1_muldiv_type,
    output wire                      to_issue_instr1_is_word,
    output wire                      to_issue_instr1_is_imm,
    output wire                      to_issue_instr1_is_load,
    output wire                      to_issue_instr1_is_store,
    output wire [               3:0] to_issue_instr1_ls_size,

    output wire [`PREG_RANGE] to_issue_instr1_prs1,
    output wire [`PREG_RANGE] to_issue_instr1_prs2,
    output wire [`PREG_RANGE] to_issue_instr1_prd,
    output wire [`PREG_RANGE] to_issue_instr1_old_prd,

    output wire                     to_issue_instr1_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] to_issue_instr1_robidx


);






    assign instr0_ready = 'b0;
    assign instr1_ready = 'b0;
endmodule
/* verilator lint_off UNUSEDSIGNAL */

/* verilator lint_off UNDRIVEN */

