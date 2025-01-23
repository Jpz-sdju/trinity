`define LREG_RANGE 4:0
`define PREG_RANGE 5:0
`define PREG_LENGTH 6
`define PREG_SIZE 64

`define SRC_RANGE 63:0
`define SRC_LENGTH 64

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
`define ALU_TYPE_LENGTH 11
`define PC_RANGE 63:0
`define PC_LENGTH 64
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

`define ISSUE_QUEUE_DEPTH 8
`define ISSUE_QUEUE_LOG 3

`define ROB_STATE_IDLE 2'b00
`define ROB_STATE_OVERWRITE_RAT 2'b01
`define ROB_STATE_WALKING 2'b10

`define WALK_SIZE 2
`define COMMIT_SIZE 2

`define STOREQUEUE_DEPTH 4
`define STOREQUEUE_LOG 2

`define MACRO_DFF_NONEN(dff_data_q, dff_data_in, dff_data_width) \
always @(posedge clock or negedge reset_n) begin \
    if(reset_n == 1'b0) \
        dff_data_q <= {dff_data_width{1'b0}}; \
    else \
        dff_data_q <= dff_data_in; \
end

`define MACRO_LATCH_NONEN(dff_data_q, dff_data_in, dff_enable, dff_data_width) \
always @(posedge clock or negedge reset_n) begin \
    if(reset_n == 1'b0) \
        dff_data_q <= {dff_data_width{1'b0}}; \
    else if(dff_enable)\
        dff_data_q <= dff_data_in; \
end

`define MACRO_ENQ_DEC(enq_ptr_oh, enq_dec_reg, enq_entity,length) \
    always @(*) begin\
        integer i;\
        for (i = 0; i < length; i = i + 1) begin\
            enq_dec_reg[i] = 'b0;\
            if (enq_ptr_oh[i]) begin\
                enq_dec_reg[i] = enq_entity;\
            end\
        end\
    end

`define MACRO_DEQ_DEC(deq_ptr_oh, deq_entity,  deq_dec_reg, length) \
    always @(*) begin\
        integer i;\
        deq_entity = 'b0;\
        for (i = 0; i < length; i = i + 1) begin\
            if (deq_ptr_oh[i]) begin\
                deq_entity = deq_dec_reg[i];\
            end\
        end\
    end
