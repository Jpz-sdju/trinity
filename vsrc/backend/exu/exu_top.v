`include "defines.sv"
module exu_top (
    input wire clock,
    input wire reset_n,

    // Intblock Inputs
    input  wire                          int_instr_valid,
    output wire                          int_instr_ready,
    input  wire [          `INSTR_RANGE] int_instr,
    input  wire [             `PC_RANGE] int_pc,
    input  wire [       `ROB_SIZE_LOG:0] int_robid,
    input  wire [`SQ_SIZE_LOG:0] int_sqid,
    input  wire [            `SRC_RANGE] int_src1,
    input  wire [            `SRC_RANGE] int_src2,
    input  wire [           `PREG_RANGE] int_prd,
    input  wire [            `SRC_RANGE] int_imm,
    input  wire                          int_need_to_wb,
    input  wire [        `CX_TYPE_RANGE] int_cx_type,
    input  wire                          int_is_unsigned,
    input  wire [       `ALU_TYPE_RANGE] int_alu_type,
    input  wire [    `MULDIV_TYPE_RANGE] int_muldiv_type,
    input  wire                          int_is_imm,
    input  wire                          int_is_word,
    input  wire                          int_predict_taken,
    input  wire [                  31:0] int_predict_target,


    // Intblock Outputs
    output wire                           intwb0_instr_valid,
    output wire [           `INSTR_RANGE] intwb0_instr,
    output wire [              `PC_RANGE] intwb0_pc,
    output wire                           intwb0_need_to_wb,
    output wire [            `PREG_RANGE] intwb0_prd,
    output wire [          `RESULT_RANGE] intwb0_result,
    output wire [        `ROB_SIZE_LOG:0] intwb0_robid,
    output wire [ `SQ_SIZE_LOG:0] intwb0_sqid,
    // BHT/BTB Update
    output wire                           intwb0_bht_write_enable,
    output wire [`BHTBTB_INDEX_WIDTH-1:0] intwb0_bht_write_index,
    output wire [                    1:0] intwb0_bht_write_counter_select,
    output wire                           intwb0_bht_write_inc,
    output wire                           intwb0_bht_write_dec,
    output wire                           intwb0_bht_valid_in,
    output wire                           intwb0_btb_ce,
    output wire                           intwb0_btb_we,
    output wire [                  128:0] intwb0_btb_wmask,
    output wire [                    8:0] intwb0_btb_write_index,
    output wire [                  128:0] intwb0_btb_din,

    /* --------------------------------- commit --------------------------------- */
    input  wire                   commit0_valid,
    input  wire [`ROB_SIZE_LOG:0] commit0_robid,
    input  wire                   commit1_valid,
    input  wire [`ROB_SIZE_LOG:0] commit1_robid,
    //flush
    output wire                   flush_valid,
    output wire [           63:0] flush_target,
    output wire [`ROB_SIZE_LOG:0] flush_robid,

    input  wire                            end_of_program

);

    assign flush_robid = intwb0_robid;
    assign flush_sqid  = intwb0_sqid;
    // Intblock internal signals
    wire                           intblock_out_instr_valid;
    wire                           intblock_out_need_to_wb;
    wire [            `PREG_RANGE] intblock_out_prd;
    wire [          `RESULT_RANGE] intblock_out_result;
    wire                           intblock_out_redirect_valid;
    wire [                   63:0] intblock_out_redirect_target;
    wire [        `ROB_SIZE_LOG:0] intblock_out_robid;
    wire [ `SQ_SIZE_LOG:0] intblock_out_sqid;
    wire [           `INSTR_RANGE] intblock_out_instr;
    wire [              `PC_RANGE] intblock_out_pc;

    wire                           bjusb_bht_write_enable;
    wire [`BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index;
    wire [                    1:0] bjusb_bht_write_counter_select;
    wire                           bjusb_bht_write_inc;
    wire                           bjusb_bht_write_dec;
    wire                           bjusb_bht_valid_in;
    wire                           bjusb_btb_ce;
    wire                           bjusb_btb_we;
    wire [                  128:0] bjusb_btb_wmask;
    wire [                    8:0] bjusb_btb_write_index;
    wire [                  128:0] bjusb_btb_din;
    // Memblock internal signals
    wire                           memblock_out_instr_valid;
    wire [        `ROB_SIZE_LOG:0] memblock_out_robid;
    wire [            `PREG_RANGE] memblock_out_prd;
    wire                           memblock_out_need_to_wb;
    wire                           memblock_out_mmio_valid;
    wire [          `RESULT_RANGE] memblock_out_load_data;
    wire [           `INSTR_RANGE] memblock_out_instr;
    wire [              `PC_RANGE] memblock_out_pc;

    wire [             `SRC_RANGE] memblock_out_store_addr;
    wire [             `SRC_RANGE] memblock_out_store_data;
    wire [             `SRC_RANGE] memblock_out_store_mask;
    wire [                    3:0] memblock_out_store_ls_size;


    wire [             `SRC_RANGE] memwb_store_addr;
    wire [             `SRC_RANGE] memwb_store_data;
    wire [             `SRC_RANGE] memwb_store_mask;
    wire [                    3:0] memwb_store_ls_size;

    wire [ `SQ_SIZE_LOG:0] flush_sqid;




    wire [                   31:0] bju_pmu_situation1_cnt_btype;
    wire [                   31:0] bju_pmu_situation2_cnt_btype;
    wire [                   31:0] bju_pmu_situation3_cnt_btype;
    wire [                   31:0] bju_pmu_situation4_cnt_btype;
    wire [                   31:0] bju_pmu_situation5_cnt_btype;

    wire [                   31:0] bju_pmu_situation1_cnt_jtype;
    wire [                   31:0] bju_pmu_situation2_cnt_jtype;
    wire [                   31:0] bju_pmu_situation3_cnt_jtype;
    wire [                   31:0] bju_pmu_situation4_cnt_jtype;
    wire [                   31:0] bju_pmu_situation5_cnt_jtype;


    // Instantiate intblock
    intblock intblock_inst (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .instr_valid                   (int_instr_valid),
        .instr_ready                   (int_instr_ready),
        .instr                         (int_instr),
        .pc                            (int_pc),
        .robid                         (int_robid),
        .sqid                          (int_sqid),
        .src1                          (int_src1),
        .src2                          (int_src2),
        .prd                           (int_prd),
        .imm                           (int_imm),
        .need_to_wb                    (int_need_to_wb),
        .cx_type                       (int_cx_type),
        .is_unsigned                   (int_is_unsigned),
        .alu_type                      (int_alu_type),
        .muldiv_type                   (int_muldiv_type),
        .is_imm                        (int_is_imm),
        .is_word                       (int_is_word),
        .predict_taken                 (int_predict_taken),
        .predict_target                (int_predict_target),
        .intblock_out_instr_valid      (intblock_out_instr_valid),
        .intblock_out_need_to_wb       (intblock_out_need_to_wb),
        .intblock_out_prd              (intblock_out_prd),
        .intblock_out_result           (intblock_out_result),
        .intblock_out_redirect_valid   (intblock_out_redirect_valid),
        .intblock_out_redirect_target  (intblock_out_redirect_target),
        .intblock_out_robid            (intblock_out_robid),
        .intblock_out_sqid             (intblock_out_sqid),
        .intblock_out_instr            (intblock_out_instr),
        .intblock_out_pc               (intblock_out_pc),
        .flush_valid                   (flush_valid),
        .flush_robid                   (flush_robid),
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

    // Instantiate pipereg_intwb0
    pipereg_intwb pipereg_intwb0_inst (
        .clock                               (clock),
        .reset_n                             (reset_n),
        .intblock_out_instr_valid            (intblock_out_instr_valid),
        .intblock_out_need_to_wb             (intblock_out_need_to_wb),
        .intblock_out_prd                    (intblock_out_prd),
        .intblock_out_result                 (intblock_out_result),
        .intblock_out_redirect_valid         (intblock_out_redirect_valid),
        .intblock_out_redirect_target        (intblock_out_redirect_target),
        .intblock_out_robid                  (intblock_out_robid),
        .intblock_out_sqid                   (intblock_out_sqid),
        .intblock_out_instr                  (intblock_out_instr),
        .intblock_out_pc                     (intblock_out_pc),
        .bjusb_bht_write_enable              (bjusb_bht_write_enable),
        .bjusb_bht_write_index               (bjusb_bht_write_index),
        .bjusb_bht_write_counter_select      (bjusb_bht_write_counter_select),
        .bjusb_bht_write_inc                 (bjusb_bht_write_inc),
        .bjusb_bht_write_dec                 (bjusb_bht_write_dec),
        .bjusb_bht_valid_in                  (bjusb_bht_valid_in),
        .bjusb_btb_ce                        (bjusb_btb_ce),
        .bjusb_btb_we                        (bjusb_btb_we),
        .bjusb_btb_wmask                     (bjusb_btb_wmask),
        .bjusb_btb_write_index               (bjusb_btb_write_index),
        .bjusb_btb_din                       (bjusb_btb_din),
        .intwb_instr_valid                   (intwb0_instr_valid),
        .intwb_instr                         (intwb0_instr),
        .intwb_pc                            (intwb0_pc),
        .intwb_need_to_wb                    (intwb0_need_to_wb),
        .intwb_prd                           (intwb0_prd),
        .intwb_result                        (intwb0_result),
        .intwb_redirect_valid                (flush_valid),
        .intwb_redirect_target               (flush_target),
        .intwb_robid                         (intwb0_robid),
        .intwb_sqid                          (intwb0_sqid),
        .intwb_bjusb_bht_write_enable        (intwb0_bht_write_enable),
        .intwb_bjusb_bht_write_index         (intwb0_bht_write_index),
        .intwb_bjusb_bht_write_counter_select(intwb0_bht_write_counter_select),
        .intwb_bjusb_bht_write_inc           (intwb0_bht_write_inc),
        .intwb_bjusb_bht_write_dec           (intwb0_bht_write_dec),
        .intwb_bjusb_bht_valid_in            (intwb0_bht_valid_in),
        .intwb_bjusb_btb_ce                  (intwb0_btb_ce),
        .intwb_bjusb_btb_we                  (intwb0_btb_we),
        .intwb_bjusb_btb_wmask               (intwb0_btb_wmask),
        .intwb_bjusb_btb_write_index         (intwb0_btb_write_index),
        .intwb_bjusb_btb_din                 (intwb0_btb_din)

    );
    wire load2arb_flush_valid;
   



    exu_pmu u_exu_pmu (
        .clock                 (clock),
        .end_of_program        (end_of_program),
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


endmodule
