`define LREG_RANGE 4:0
`define PREG_RANGE 5:0
`define SRC_RANGE 63:0
`define SRC_WIDTH 64

`define RESULT_RANGE 63:0
`define RESULT_WIDTH 64
`define ALU_TYPE_RANGE 10:0

`define IBUFFER_FIFO_WIDTH 32+48
`define INST_CACHE_WIDTH 512
/*
    0 = ADD
    1 = SET LESS THAN
    2 = XOR
    3 = OR
    4 = AND
    5 = SHIFT LEFT LOGICAL
    6 = SHIFT RIGHT LOGICAL
    7 = SHIFT RIGHT ARH
    8 = SUB
    9 = LUI
    10 = AUIPC
*/
`define ALU_TYPE_WIDTH 11
`define PC_RANGE 47:0
`define PC_WIDTH 48
`define INSTR_RANGE 31:0
`define CX_TYPE_RANGE 5:0
/*
    0 = JAL
    1 = JALR
    2 = BEQ
    3 = BNE
    4 = BLT
    5 = BGE
*/

`define MULDIV_TYPE_RANGE 12:0
/*
    0 = MUL
    1 = MULH
    2 = MULHSU
    3 = MULHU
    4 = DIV
    5 = DIVU
    6 = REM
    7 = REMU
    8 = MULW
    9 = DIVW
    10 = DIVUW
    11 = REMW
    12 = REMUW
*/
`define LS_SIZE_RANGE 3:0
/*
    0 = B
    1 = HALF WORD
    2 = WORD
    3 = DOUBLE WORD
*/

`define IS_ADD 0
`define IS_SLT 1
`define IS_XOR 2
`define IS_OR 3
`define IS_AND 4 
`define IS_SLL 5 
`define IS_SRL 6
`define IS_SRA 7
`define IS_SUB 8
`define IS_LUI 9
`define IS_AUIPC 10

`define IS_JAL 0
`define IS_JALR 1
`define IS_BEQ 2
`define IS_BNE 3
`define IS_BLT 4
`define IS_BGE 5


`define IS_MUL 0 
`define IS_MULH 1 
`define IS_MULHSU 2 
`define IS_MULHU 3 
`define IS_DIV 4 
`define IS_DIVU 5 
`define IS_REM 6 
`define IS_REMU 7 
`define IS_MULW 8 
`define IS_DIVW 9 
`define IS_DIVUW 10
`define IS_REMW 11
`define IS_REMUW 12

`define IS_B 0 
`define IS_H 1 
`define IS_W 2 
`define IS_D 3 

