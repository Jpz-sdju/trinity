`include "defines.sv"
module intblock #(
    parameter BHTBTB_INDEX_WIDTH = 9  // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
) (
    input  wire                          clock,
    input  wire                          reset_n,
    input  wire                          instr_valid,
    output wire                          instr_ready,
    input  wire [          `INSTR_RANGE] instr,        //for debug
    input  wire [             `PC_RANGE] pc,
    input  wire [   `INSTR_ID_WIDTH-1:0] robid,
    input  wire [`SQ_SIZE_LOG:0] sqid,


    /* -------------------------- calculation meterial -------------------------- */
    input  wire [            `SRC_RANGE] src1,
    input  wire [            `SRC_RANGE] src2,
    input  wire [           `PREG_RANGE] prd,
    input  wire [            `SRC_RANGE] imm,
    input  wire                          need_to_wb,
    input  wire [        `CX_TYPE_RANGE] cx_type,
    input  wire                          is_unsigned,
    input  wire [       `ALU_TYPE_RANGE] alu_type,
    input  wire [    `MULDIV_TYPE_RANGE] muldiv_type,
    input  wire                          is_imm,
    input  wire                          is_word,
    /* ------------------------------ bhtbtb input info ------------------------------ */
    input  wire                          predict_taken,
    input  wire [                  31:0] predict_target,
    /* ----------------------- output result to wb pipereg ---------------------- */
    // output valid, pc, inst, robid
    output wire                          intblock_out_instr_valid,
    output wire                          intblock_out_need_to_wb,
    output wire [           `PREG_RANGE] intblock_out_prd,
    output wire [         `RESULT_RANGE] intblock_out_result,
    //redirect
    output wire                          intblock_out_redirect_valid,
    output wire [             `PC_RANGE] intblock_out_redirect_target,
    output wire [   `INSTR_ID_WIDTH-1:0] intblock_out_robid,
    output wire [`SQ_SIZE_LOG:0] intblock_out_sqid,

    output wire [       `INSTR_RANGE] intblock_out_instr,  //for debug
    output wire [          `PC_RANGE] intblock_out_pc,     //for debug
    /* ---------------------- flush signal from wb pipereg ---------------------- */
    input  wire                       flush_valid,
    input  wire [`INSTR_ID_WIDTH-1:0] flush_robid,


    /* --------------------------- btbbht update port -------------------------- */
    //BHT Write Interface
    output wire                          bjusb_bht_write_enable,          // Write enable signal
    output wire [BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,           // Set index for write operation
    output wire [                   1:0] bjusb_bht_write_counter_select,  // Counter select (0 to 3) within the set
    output wire                          bjusb_bht_write_inc,             // Increment signal for the counter
    output wire                          bjusb_bht_write_dec,             // Decrement signal for the counter
    output wire                          bjusb_bht_valid_in,              // Valid signal for the write operation

    //BTB Write Interface
    output wire         bjusb_btb_ce,            // Chip enable
    output wire         bjusb_btb_we,            // Write enable
    output wire [128:0] bjusb_btb_wmask,
    output wire [  8:0] bjusb_btb_write_index,   // Write address (9 bits for 512 sets)
    output wire [128:0] bjusb_btb_din,           // Data input (1 valid bit + 4 targets * 32 bits)
    output reg [ 31:0] bju_pmu_situation1_cnt_btype,  //b-type
    output reg [ 31:0] bju_pmu_situation2_cnt_btype,
    output reg [ 31:0] bju_pmu_situation3_cnt_btype,
    output reg [ 31:0] bju_pmu_situation4_cnt_btype,
    output reg [ 31:0] bju_pmu_situation5_cnt_btype,
    output reg [ 31:0] bju_pmu_situation1_cnt_jtype, //j-type
    output reg [ 31:0] bju_pmu_situation2_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation3_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation4_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation5_cnt_jtype

);
    wire                 redirect_valid_internal;
    wire [`RESULT_RANGE] alu_result;
    wire [`RESULT_RANGE] muldiv_result;
    wire [`RESULT_RANGE] bju_result;

    assign instr_ready = 1'b1;
    //when redirect instr from wb pipereg is older than current instr in exu, flush instr in exu
    wire need_flush;
    assign need_flush                  = flush_valid && ((flush_robid[6] ^ intblock_out_robid[6]) ^ (flush_robid[5:0] < intblock_out_robid[5:0]));

    assign intblock_out_instr_valid    = need_flush ? 0 : instr_valid;
    assign intblock_out_pc             = pc;  //for debug
    assign intblock_out_instr          = instr;  //for debug
    assign intblock_out_robid          = robid;
    assign intblock_out_sqid           = sqid;
    assign intblock_out_prd            = prd;
    assign intblock_out_redirect_valid = need_flush ? 0 : redirect_valid_internal;

    //exu logic
    wire alu_valid = (|alu_type) & instr_valid;
    wire bju_valid = (|cx_type) & instr_valid;
    wire muldiv_valid = (|muldiv_type) & instr_valid;
    assign intblock_out_result     = (|alu_type) ? alu_result : (|cx_type) ? bju_result : (|muldiv_type) ? muldiv_result : 64'hDEADBEEF;
    assign intblock_out_need_to_wb = need_to_wb;


    alu u_alu (
        .src1       (src1),
        .src2       (src2),
        .imm        (imm),
        .pc         (pc),
        .valid      (alu_valid),
        .alu_type   (alu_type),
        .is_word    (is_word),
        .is_unsigned(is_unsigned),
        .is_imm     (is_imm),
        .result     (alu_result)
    );

    bju u_bju (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .src1                          (src1),
        .src2                          (src2),
        .imm                           (imm),
        .predict_taken                 (predict_taken),
        .predict_target                (predict_target),
        .pc                            (pc),
        .cx_type                       (cx_type),
        .valid                         (bju_valid),
        .is_unsigned                   (is_unsigned),
        .dest                          (bju_result),
        .redirect_valid                (redirect_valid_internal),
        .redirect_target               (intblock_out_redirect_target),
        .bjusb_bht_write_enable        (bjusb_bht_write_enable),
        .bjusb_bht_write_index         (bjusb_bht_write_index),
        .bjusb_bht_write_counter_select(bjusb_bht_write_counter_select),
        .bjusb_bht_write_inc           (bjusb_bht_write_inc),
        .bjusb_bht_write_dec           (bjusb_bht_write_dec),
        .bjusb_bht_valid_in            (bjusb_bht_valid_in),
        .bjusb_btb_ce                  (bjusb_btb_ce),
        .bjusb_btb_we                  (bjusb_btb_we),
        .bjusb_btb_wmask               (bjusb_btb_wmask),
        .bjusb_btb_write_index         (bjusb_btb_write_index),
        .bjusb_btb_din                 (bjusb_btb_din),
        .bju_pmu_situation1_cnt_btype        (bju_pmu_situation1_cnt_btype),
        .bju_pmu_situation2_cnt_btype        (bju_pmu_situation2_cnt_btype),
        .bju_pmu_situation3_cnt_btype        (bju_pmu_situation3_cnt_btype),
        .bju_pmu_situation4_cnt_btype        (bju_pmu_situation4_cnt_btype),
        .bju_pmu_situation5_cnt_btype        (bju_pmu_situation5_cnt_btype),
        .bju_pmu_situation1_cnt_jtype        (bju_pmu_situation1_cnt_jtype),
        .bju_pmu_situation2_cnt_jtype        (bju_pmu_situation2_cnt_jtype),
        .bju_pmu_situation3_cnt_jtype        (bju_pmu_situation3_cnt_jtype),
        .bju_pmu_situation4_cnt_jtype        (bju_pmu_situation4_cnt_jtype),
        .bju_pmu_situation5_cnt_jtype        (bju_pmu_situation5_cnt_jtype)

    );

    muldiv u_muldiv (
        .src1       (src1),
        .src2       (src2),
        .valid      (muldiv_valid),
        .muldiv_type(muldiv_type),
        .result     (muldiv_result)
    );

endmodule
