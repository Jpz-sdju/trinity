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

`define TBUS_INDEX_RANGE 63:0
`define TBUS_DATA_RANGE 63:0
`define TBUS_OPTYPE_RANGE 1:0
`define TBUS_READ 2'b00
`define TBUS_WRITE 2'b01
`define TBUS_RESERVED0 2'b10
`define TBUS_RESERVED1 2'b11

`define DBUS_INDEX_RANGE 63:0
`define DBUS_DATA_RANGE 63:0
`define DBUS_OPTYPE_RANGE 1:0
`define DBUS_READ 2'b00
`define DBUS_WRITE 2'b01
`define DBUS_RESERVED0 2'b10
`define DBUS_RESERVED1 2'b11

`define TAGRAM_RANGE 37:0
`define TAGRAM_LENGTH 38
`define TAGRAM_TAG_RANGE 16:0
`define TAGRAM_VALID_RANGE 18:18
`define TAGRAM_DIRTY_RANGE 17:17 
`define TAGRAM_WAYNUM 2
`define DATARAM_BANKNUM 8

`define ADDR_RANGE 63:0
`define CACHELINE512_RANGE 511:0

`define ICACHE_FETCHWIDTH128_RANGE 127:0

`define ROB_SIZE_LOG 6
`define ROB_SIZE 64

`define MACRO_DFF_NONEN(dff_data_q, dff_data_in, dff_data_width) \
always @(posedge clock or negedge reset_n) begin \
    if(reset_n == 1'b0) \
        dff_data_q <= {dff_data_width{1'b0}}; \
    else \
        dff_data_q <= dff_data_in; \
end

`define PIPE(out,in,clear,pause)\
pipereg_2 u_pipereg_2(\
    .clock                   (clock                   ),\
    .reset_n                 (reset_n                 ),\
    .stall                   (pause                   ),\
    .rs1                     (in``_rs1                     ),\
    .rs2                     (in``_rs2                     ),\
    .rd                      (in``_rd                      ),\
    .imm                     (in``_imm                     ),\
    .src1_is_reg             (in``_src1_is_reg             ),\
    .src2_is_reg             (in``_src2_is_reg             ),\
    .need_to_wb              (in``_need_to_wb              ),\
    .cx_type                 (in``_cx_type                 ),\
    .is_unsigned             (in``_is_unsigned             ),\
    .alu_type                (in``_alu_type                ),\
    .is_word                 (in``_is_word                 ),\
    .is_load                 (in``_is_load                 ),\
    .is_imm                  (in``_is_imm                  ),\
    .is_store                (in``_is_store                ),\
    .ls_size                 (in``_ls_size                 ),\
    .muldiv_type             (in``_muldiv_type             ),\
    .instr_valid             (in``_instr_valid             ),\
    .pc                      (in``_pc                      ),\
    .instr                   (in``_instr                   ),\
    .prs1                    (in``_prs1                    ),\
    .prs2                    (in``_prs2                    ),\
    .prd                     (in``_prd                     ),\
    .old_prd                 (in``_old_prd                 ),\
    .ls_address              (in``_ls_address              ),\
    .alu_result              (in``_alu_result              ),\
    .bju_result              (in``_bju_result              ),\
    .muldiv_result           (in``_muldiv_result           ),\
    .opload_read_data_wb     (in``_opload_read_data_wb     ),\
    .redirect_flush          (clear          ),\
    .out_rs1                 (in``_rs1                 ),\
    .out_rs2                 (in``_rs2                 ),\
    .out_rd                  (in``_rd                  ),\
    .out_imm                 (in``_imm                 ),\
    .out_src1_is_reg         (in``_src1_is_reg         ),\
    .out_src2_is_reg         (in``_src2_is_reg         ),\
    .out_need_to_wb          (in``_need_to_wb          ),\
    .out_cx_type             (in``_cx_type             ),\
    .out_is_unsigned         (in``_is_unsigned         ),\
    .out_alu_type            (in``_alu_type            ),\
    .out_is_word             (in``_is_word             ),\
    .out_is_load             (in``_is_load             ),\
    .out_is_imm              (in``_is_imm              ),\
    .out_is_store            (in``_is_store            ),\
    .out_ls_size             (in``_ls_size             ),\
    .out_muldiv_type         (in``_muldiv_type         ),\
    .out_instr_valid         (in``_instr_valid         ),\
    .out_pc                  (in``_pc                  ),\
    .out_instr               (in``_instr               ),\
    .out_prs1                (in``_prs1                ),\
    .out_prs2                (in``_prs2                ),\
    .out_prd                 (in``_prd                 ),\
    .out_old_prd             (in``_old_prd             ),\
    .out_ls_address          (in``_ls_address          ),\
    .out_alu_result          (in``_alu_result          ),\
    .out_bju_result          (in``_bju_result          ),\
    .out_muldiv_result       (in``_muldiv_result       ),\
    .out_opload_read_data_wb (in``_opload_read_data_wb )\
);
