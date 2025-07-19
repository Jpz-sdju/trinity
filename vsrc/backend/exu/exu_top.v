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

    // Memblock Inputs
    input  wire                          mem_instr_valid,
    output wire                          mem_instr_ready,
    input  wire [          `INSTR_RANGE] mem_instr,
    input  wire [             `PC_RANGE] mem_pc,
    input  wire [       `ROB_SIZE_LOG:0] mem_robid,
    input  wire [`SQ_SIZE_LOG:0] mem_sqid,
    input  wire [            `SRC_RANGE] mem_src1,
    input  wire [            `SRC_RANGE] mem_src2,
    input  wire [           `PREG_RANGE] mem_prd,
    input  wire [            `SRC_RANGE] mem_imm,
    input  wire                          mem_is_load,
    input  wire                          mem_is_store,
    input  wire                          mem_is_unsigned,
    input  wire [        `LS_SIZE_RANGE] mem_ls_size,

    // Trinity Bus Interface
    output wire                           tbus_index_valid,
    input  wire                           tbus_index_ready,
    output wire [          `RESULT_RANGE] tbus_index,
    output wire [             `SRC_RANGE] tbus_write_data,
    output wire [                   63:0] tbus_write_mask,
    input  wire [          `RESULT_RANGE] tbus_read_data,
    input  wire                           tbus_operation_done,
    output wire [     `TBUS_OPTYPE_RANGE] tbus_operation_type,
    output wire                           arb2dcache_flush_valid,
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

    // Memblock Outputs
    output wire                            memwb_instr_valid,
    output wire [            `INSTR_RANGE] memwb_instr,
    output wire [               `PC_RANGE] memwb_pc,
    output wire [         `ROB_SIZE_LOG:0] memwb_robid,
    output wire [             `PREG_RANGE] memwb_prd,
    output wire                            memwb_need_to_wb,
    output wire                            memwb_mmio_valid,
    output wire [           `RESULT_RANGE] memwb_result,
    /* --------------------------------- to disp -------------------------------- */
    output wire [`SQ_SIZE_LOG : 0] sq2disp_sqid,
    /* ------------------------------ from dispatch ----------------------------- */
    input  wire                            disp2sq_valid,
    output wire                            sq_can_alloc,
    input  wire [         `ROB_SIZE_LOG:0] disp2sq_robid,
    //debug
    input  wire [               `PC_RANGE] disp2sq_pc,
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


    wire                           ldu2sq_forward_req_valid;
    wire [        `ROB_SIZE_LOG:0] ldu2sq_forward_req_sqid;
    wire [   `STOREQUEUE_SIZE-1:0] ldu2sq_forward_req_sqmask;
    wire [             `SRC_RANGE] ldu2sq_forward_req_load_addr;
    wire [         `LS_SIZE_RANGE] ldu2sq_forward_req_load_size;
    wire                           ldu2sq_forward_resp_valid;
    wire [             `SRC_RANGE] ldu2sq_forward_resp_data;
    wire [             `SRC_RANGE] ldu2sq_forward_resp_mask;

    wire [             `SRC_RANGE] memwb_store_addr;
    wire [             `SRC_RANGE] memwb_store_data;
    wire [             `SRC_RANGE] memwb_store_mask;
    wire [                    3:0] memwb_store_ls_size;

    wire [ `SQ_SIZE_LOG:0] flush_sqid;

    /* ------------------------------- dcache_arb ------------------------------- */
    // LSU Channel Inputs and Outputs : from lsu
    wire                           load2arb_tbus_index_valid;  // Valid signal for load2arb_tbus_index
    wire [                   63:0] load2arb_tbus_index;  // 64-bit input for load2arb_tbus_index (Channel 1)
    wire                           load2arb_tbus_index_ready;  // Ready signal for LSU channel
    wire [                   63:0] load2arb_tbus_read_data;  // Output burst read data for LSU channel
    wire                           load2arb_tbus_operation_done;

    //SQ bus channel : from SQ
    wire                           sq2arb_tbus_index_valid;
    wire                           sq2arb_tbus_index_ready;
    wire [          `RESULT_RANGE] sq2arb_tbus_index;
    wire [                   63:0] sq2arb_tbus_write_data;
    wire [                   63:0] sq2arb_tbus_write_mask;
    wire [                   63:0] sq2arb_tbus_read_data;
    wire                           sq2arb_tbus_operation_done;
    wire [     `TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type;

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
    mem_top u_memblock (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .instr_valid                 (mem_instr_valid),
        .instr_ready                 (mem_instr_ready),
        .instr                       (mem_instr),
        .pc                          (mem_pc),
        .robid                       (mem_robid),
        .sqid                        (mem_sqid),
        .src1                        (mem_src1),
        .src2                        (mem_src2),
        .prd                         (mem_prd),
        .imm                         (mem_imm),
        .is_load                     (mem_is_load),
        .is_store                    (mem_is_store),
        .is_unsigned                 (mem_is_unsigned),
        .ls_size                     (mem_ls_size),
        .load2arb_tbus_index_valid   (load2arb_tbus_index_valid),
        .load2arb_tbus_index_ready   (load2arb_tbus_index_ready),
        .load2arb_tbus_index         (load2arb_tbus_index),
        .load2arb_tbus_write_data    (),
        .load2arb_tbus_write_mask    (),
        .load2arb_tbus_read_data     (load2arb_tbus_read_data),
        .load2arb_tbus_operation_done(load2arb_tbus_operation_done),
        .load2arb_tbus_operation_type(),
        .memblock_out_instr_valid    (memblock_out_instr_valid),
        .memblock_out_robid          (memblock_out_robid),
        .memblock_out_prd            (memblock_out_prd),
        .memblock_out_need_to_wb     (memblock_out_need_to_wb),
        .memblock_out_mmio_valid     (memblock_out_mmio_valid),
        .memblock_out_load_data      (memblock_out_load_data),
        .memblock_out_instr          (memblock_out_instr),
        .memblock_out_pc             (memblock_out_pc),
        .memblock_out_store_addr     (memblock_out_store_addr),
        .memblock_out_store_data     (memblock_out_store_data),
        .memblock_out_store_mask     (memblock_out_store_mask),
        .memblock_out_store_ls_size  (memblock_out_store_ls_size),
        .flush_valid                 (flush_valid),
        .flush_robid                 (flush_robid),
        .load2arb_flush_valid        (load2arb_flush_valid),
        .ldu2sq_forward_req_valid    (ldu2sq_forward_req_valid),
        .ldu2sq_forward_req_sqid     (ldu2sq_forward_req_sqid),
        .ldu2sq_forward_req_sqmask   (ldu2sq_forward_req_sqmask),
        .ldu2sq_forward_req_load_addr(ldu2sq_forward_req_load_addr),
        .ldu2sq_forward_req_load_size(ldu2sq_forward_req_load_size),
        .ldu2sq_forward_resp_valid   (ldu2sq_forward_resp_valid),
        .ldu2sq_forward_resp_data    (ldu2sq_forward_resp_data),
        .ldu2sq_forward_resp_mask    (ldu2sq_forward_resp_mask)
    );





    // Instantiate pipereg_memwb
    pipereg_memwb pipereg_memwb_inst (
        .clock                     (clock),
        .reset_n                   (reset_n),
        .memblock_out_instr_valid  (memblock_out_instr_valid),
        .memblock_out_robid        (memblock_out_robid),
        .memblock_out_prd          (memblock_out_prd),
        .memblock_out_need_to_wb   (memblock_out_need_to_wb),
        .memblock_out_mmio_valid   (memblock_out_mmio_valid),
        .memblock_out_load_data    (memblock_out_load_data),
        .memblock_out_instr        (memblock_out_instr),
        .memblock_out_pc           (memblock_out_pc),
        //other info to store queue
        .memblock_out_store_addr   (memblock_out_store_addr),
        .memblock_out_store_data   (memblock_out_store_data),
        .memblock_out_store_mask   (memblock_out_store_mask),
        .memblock_out_store_ls_size(memblock_out_store_ls_size),
        .memwb_instr_valid         (memwb_instr_valid),
        .memwb_instr               (memwb_instr),
        .memwb_pc                  (memwb_pc),
        .memwb_robid               (memwb_robid),
        .memwb_prd                 (memwb_prd),
        .memwb_need_to_wb          (memwb_need_to_wb),
        .memwb_mmio_valid          (memwb_mmio_valid),
        .memwb_load_data           (memwb_result),
        //other info to store queue
        .memwb_store_addr          (memwb_store_addr),
        .memwb_store_data          (memwb_store_data),
        .memwb_store_mask          (memwb_store_mask),
        .memwb_store_ls_size       (memwb_store_ls_size)
    );



    dcache_arb u_dcache_arb (
        .clock                       (clock),
        .reset_n                     (reset_n),
        .load2arb_tbus_index_valid   (load2arb_tbus_index_valid),
        .load2arb_tbus_index         (load2arb_tbus_index),
        .load2arb_tbus_index_ready   (load2arb_tbus_index_ready),
        .load2arb_tbus_read_data     (load2arb_tbus_read_data),
        .load2arb_tbus_operation_done(load2arb_tbus_operation_done),
        .load2arb_flush_valid        (load2arb_flush_valid),
        .sq2arb_tbus_index_valid     (sq2arb_tbus_index_valid),
        .sq2arb_tbus_index_ready     (sq2arb_tbus_index_ready),
        .sq2arb_tbus_index           (sq2arb_tbus_index),
        .sq2arb_tbus_write_data      (sq2arb_tbus_write_data),
        .sq2arb_tbus_write_mask      (sq2arb_tbus_write_mask),
        .sq2arb_tbus_read_data       (sq2arb_tbus_read_data),
        .sq2arb_tbus_operation_done  (sq2arb_tbus_operation_done),
        .sq2arb_tbus_operation_type  (sq2arb_tbus_operation_type),
        .tbus_index_valid            (tbus_index_valid),
        .tbus_index_ready            (tbus_index_ready),
        .tbus_index                  (tbus_index),
        .tbus_write_mask             (tbus_write_mask),
        .tbus_write_data             (tbus_write_data),
        .tbus_read_data              (tbus_read_data),
        .tbus_operation_type         (tbus_operation_type),
        .tbus_operation_done         (tbus_operation_done),
        .arb2dcache_flush_valid      (arb2dcache_flush_valid)
    );


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
