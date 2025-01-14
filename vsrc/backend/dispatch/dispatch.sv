`include "defines.sv"
module dispatch (
    input wire                   instr0_valid,
    input wire [    `LREG_RANGE] instr0_rs1,
    input wire [    `LREG_RANGE] instr0_rs2,
    input wire [    `LREG_RANGE] instr0_rd,
    input wire [           47:0] instr0_pc,

    input wire [           63:0] instr0_imm,
    input wire                   instr0_src1_is_reg,
    input wire                   instr0_src2_is_reg,
    input wire                   instr0_need_to_wb,
    input wire [ `CX_TYPE_RANGE] instr0_cx_type,
    input wire                   instr0_is_unsigned,
    input wire [`ALU_TYPE_RANGE] instr0_alu_type,
    input wire                   instr0_is_word,
    input wire                   instr0_is_imm,
    input wire                   instr0_is_load,
    input wire                   instr0_is_store,
    input wire [            3:0] instr0_ls_size,


    input wire [    `PREG_RANGE] instr0_prs1,
    input wire [    `PREG_RANGE] instr0_prs2,
    input wire [    `PREG_RANGE] instr0_prd,
    input wire [    `PREG_RANGE] instr0_old_prd
);
    
endmodule