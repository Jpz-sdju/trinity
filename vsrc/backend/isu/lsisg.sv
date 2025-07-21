`include "defines.sv"
module lsisg (
    input wire clock,
    input wire reset_n,

    output wire iq_load0_can_alloc,
    output wire iq_st0_can_alloc,

    input wire                   disp2memisg_instr0_valid,
    input wire [      `PC_RANGE] disp2memisg_instr0_pc,
    input wire [           31:0] disp2memisg_instr0,
    input wire [           63:0] disp2memisg_instr0_imm,
    input wire                   disp2memisg_instr0_is_unsigned,
    input wire                   disp2memisg_instr0_is_imm,
    input wire                   disp2memisg_instr0_is_load,
    input wire                   disp2memisg_instr0_is_store,
    input wire [            3:0] disp2memisg_instr0_size,
    input wire [    `PREG_RANGE] disp2memisg_instr0_prs1,
    input wire [    `PREG_RANGE] disp2memisg_instr0_prs2,
    input wire [    `PREG_RANGE] disp2memisg_instr0_prd,
    input wire [`ROB_SIZE_LOG:0] disp2memisg_instr0_robid,
    input wire [ `SQ_SIZE_LOG:0] disp2memisg_instr0_sqid,
    input wire                   disp2memisg_instr0_src1_state,
    input wire                   disp2memisg_instr0_src2_state,



    /* ------------------------------- output to execute block ------------------------------- */
    output reg                    issue_st0_valid,
    input  wire                   issue_st0_ready,
    output reg  [    `PREG_RANGE] issue_st0_prs1,
    output reg  [    `PREG_RANGE] issue_st0_prs2,
    output reg  [    `PREG_RANGE] issue_st0_prd,
    output reg  [     `SRC_RANGE] issue_st0_pc,
    output reg  [           31:0] issue_st0_instr,
    output reg  [     `SRC_RANGE] issue_st0_imm,
    output reg                    issue_st0_is_unsigned,
    output reg                    issue_st0_is_load,
    output reg                    issue_st0_is_store,
    output reg  [            3:0] issue_st0_ls_size,
    output reg  [`ROB_SIZE_LOG:0] issue_st0_robid,
    output reg  [ `SQ_SIZE_LOG:0] issue_st0_sqid,


    output reg                    issue_load0_valid,
    input  wire                   issue_load0_ready,
    output reg  [    `PREG_RANGE] issue_load0_prs1,
    output reg  [    `PREG_RANGE] issue_load0_prs2,
    output reg  [    `PREG_RANGE] issue_load0_prd,
    output reg  [     `SRC_RANGE] issue_load0_pc,
    output reg  [           31:0] issue_load0_instr,
    output reg  [     `SRC_RANGE] issue_load0_imm,
    output reg                    issue_load0_is_unsigned,
    output reg                    issue_load0_is_load,
    output reg                    issue_load0_is_store,
    output reg  [            3:0] issue_load0_ls_size,
    output reg  [`ROB_SIZE_LOG:0] issue_load0_robid,
    output reg  [ `SQ_SIZE_LOG:0] issue_load0_sqid,


        //-----------------------------------------------------
    // writeback to set condition to 1
    //-----------------------------------------------------
    input wire               writeback0_valid,
    input wire               writeback0_need_to_wb,
    input wire [`PREG_RANGE] writeback0_prd,

    input wire                    writeback1_valid,
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






endmodule
