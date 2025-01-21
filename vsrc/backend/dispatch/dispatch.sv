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
    input  wire [  `PC_RANGE] instr0_pc,
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
    input  wire [  `PC_RANGE] instr1_pc,
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
    output wire               to_iq_instr0_valid,
    input  wire               to_iq_instr0_ready,
    output wire [`LREG_RANGE] to_iq_instr0_lrs1,
    output wire [`LREG_RANGE] to_iq_instr0_lrs2,
    output wire [`LREG_RANGE] to_iq_instr0_lrd,
    output wire [  `PC_RANGE] to_iq_instr0_pc,
    output wire [       31:0] to_iq_instr0,

    output wire [              63:0] to_iq_instr0_imm,
    output wire                      to_iq_instr0_src1_is_reg,
    output wire                      to_iq_instr0_src2_is_reg,
    output wire                      to_iq_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_iq_instr0_cx_type,
    output wire                      to_iq_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_iq_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_iq_instr0_muldiv_type,
    output wire                      to_iq_instr0_is_word,
    output wire                      to_iq_instr0_is_imm,
    output wire                      to_iq_instr0_is_load,
    output wire                      to_iq_instr0_is_store,
    output wire [               3:0] to_iq_instr0_ls_size,

    output wire [`PREG_RANGE] to_iq_instr0_prs1,
    output wire [`PREG_RANGE] to_iq_instr0_prs2,
    output wire [`PREG_RANGE] to_iq_instr0_prd,
    output wire [`PREG_RANGE] to_iq_instr0_old_prd,

    output wire                     to_iq_instr0_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] to_iq_instr0_robidx,

    /* ------------------------ issue instr1 and enq rob ------------------------ */
    output wire               to_iq_instr1_valid,
    input  wire               to_iq_instr1_ready,
    output wire [`LREG_RANGE] to_iq_instr1_lrs1,
    output wire [`LREG_RANGE] to_iq_instr1_lrs2,
    output wire [`LREG_RANGE] to_iq_instr1_lrd,
    output wire [  `PC_RANGE] to_iq_instr1_pc,
    output wire [       31:0] to_iq_instr1,

    output wire [              63:0] to_iq_instr1_imm,
    output wire                      to_iq_instr1_src1_is_reg,
    output wire                      to_iq_instr1_src2_is_reg,
    output wire                      to_iq_instr1_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_iq_instr1_cx_type,
    output wire                      to_iq_instr1_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_iq_instr1_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_iq_instr1_muldiv_type,
    output wire                      to_iq_instr1_is_word,
    output wire                      to_iq_instr1_is_imm,
    output wire                      to_iq_instr1_is_load,
    output wire                      to_iq_instr1_is_store,
    output wire [               3:0] to_iq_instr1_ls_size,

    output wire [`PREG_RANGE] to_iq_instr1_prs1,
    output wire [`PREG_RANGE] to_iq_instr1_prs2,
    output wire [`PREG_RANGE] to_iq_instr1_prd,
    output wire [`PREG_RANGE] to_iq_instr1_old_prd,

    output wire                     to_iq_instr1_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] to_iq_instr1_robidx,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                     flush_valid,
    input wire                     flush_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    input wire [1:0] rob_state


);

    //temp sigs
    wire is_lsu = instr0_is_load | instr0_is_store;
    wire is_alu = ~is_lsu;

    //redirect flush!
    assign to_iq_instr0_valid       = instr0_valid & ~flush_valid ;
    assign to_iq_instr0_lrs1        = instr0_lrs1;
    assign to_iq_instr0_lrs2        = instr0_lrs2;
    assign to_iq_instr0_lrd         = instr0_lrd;
    assign to_iq_instr0_pc          = instr0_pc;
    assign to_iq_instr0             = instr0;

    assign to_iq_instr0_imm         = instr0_imm;
    assign to_iq_instr0_src1_is_reg = instr0_src1_is_reg;
    assign to_iq_instr0_src2_is_reg = instr0_src2_is_reg;
    assign to_iq_instr0_need_to_wb  = instr0_need_to_wb;
    assign to_iq_instr0_cx_type     = instr0_cx_type;
    assign to_iq_instr0_is_unsigned = instr0_is_unsigned;
    assign to_iq_instr0_alu_type    = instr0_alu_type;
    assign to_iq_instr0_muldiv_type = instr0_muldiv_type;
    assign to_iq_instr0_is_word     = instr0_is_word;
    assign to_iq_instr0_is_imm      = instr0_is_imm;
    assign to_iq_instr0_is_load     = instr0_is_load;
    assign to_iq_instr0_is_store    = instr0_is_store;
    assign to_iq_instr0_ls_size     = instr0_ls_size;

    assign to_iq_instr0_prs1        = instr0_prs1;
    assign to_iq_instr0_prs2        = instr0_prs2;
    assign to_iq_instr0_prd         = instr0_prd;
    assign to_iq_instr0_old_prd     = instr0_old_prd;

    assign to_iq_instr0_robidx_flag = enq_robidx_flag;
    assign to_iq_instr0_robidx      = enq_robidx;

    // assign to_iq_instr1_valid = instr0_valid & ~flush_valid & is_lsu;

    assign instr0_ready                = (counter < `ROB_SIZE) & to_iq_instr0_ready & ~flush_valid & (rob_state == `ROB_STATE_IDLE);
    assign instr1_ready                = 'b0;
endmodule
/* verilator lint_off UNUSEDSIGNAL */

/* verilator lint_off UNDRIVEN */

