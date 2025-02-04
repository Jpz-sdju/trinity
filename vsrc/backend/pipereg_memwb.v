`include "defines.sv"
module pipereg_memwb (
    input  wire                          clock,
    input  wire                          reset_n,
    input wire                          memblock_out_instr_valid,
    input wire [`INSTR_ID_WIDTH-1:0]    memblock_out_robid,
    input wire [`PREG_RANGE]            memblock_out_prd,
    input wire                          memblock_out_need_to_wb,
    input wire                          memblock_out_mmio_valid,
    input wire [`RESULT_RANGE]          memblock_out_opload_rddata, 
    input wire [      `INSTR_RANGE ]    memblock_out_instr,//for debug
    input wire [         `PC_RANGE ]    memblock_out_pc, //for debug
   
    //output
    output reg                            memwb_instr_valid,
    output reg  [           `INSTR_RANGE] memwb_instr,
    output reg  [              `PC_RANGE] memwb_pc,
    output reg [`INSTR_ID_WIDTH-1:0]      memwb_robid,
    output reg [`PREG_RANGE]              memwb_prd,
    output reg                            memwb_need_to_wb,
    output reg                            memwb_mmio_valid,
    output reg [`RESULT_RANGE]            memwb_opload_rddata 
);

    `MACRO_DFF_NONEN(memwb_instr_valid  , memblock_out_instr_valid, 1)
    `MACRO_DFF_NONEN(memwb_instr        , memblock_out_instr, 32)
    `MACRO_DFF_NONEN(memwb_pc           , memblock_out_pc, 64)
    `MACRO_DFF_NONEN(memwb_robid        , memblock_out_robid, `INSTR_ID_WIDTH)
    `MACRO_DFF_NONEN(memwb_prd          , memblock_out_prd, 6)
    `MACRO_DFF_NONEN(memwb_need_to_wb   , memblock_out_need_to_wb, 1)
    `MACRO_DFF_NONEN(memwb_mmio_valid   , memblock_out_mmio_valid, 1)
    `MACRO_DFF_NONEN(memwb_opload_rddata, memblock_out_opload_rddata, 64)

endmodule