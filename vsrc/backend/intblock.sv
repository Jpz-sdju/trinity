`include "defines.sv"
module intblock (
    input  wire                      clock,
    input  wire                      reset_n,
    input  wire                      instr_valid,
    input  wire [       `PREG_RANGE] prd,
    input  wire [        `SRC_RANGE] src1,
    input  wire [        `SRC_RANGE] src2,
    input  wire [        `SRC_RANGE] imm,
    input  wire                      need_to_wb,
    input  wire [    `CX_TYPE_RANGE] cx_type,
    input  wire                      is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] alu_type,
    input  wire                      is_word,
    input  wire                      is_imm,
    // input  wire [               3:0] ls_size,
    input  wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input  wire [         `PC_RANGE] pc,
    input  wire                      robidx_flag,
    input  wire [ `ROB_SIZE_LOG-1:0] robidx,
    // output valid, pc, inst
    output wire                      out_instr_valid,
    output wire                      out_need_to_wb,
    output wire [       `PREG_RANGE] out_prd,
    output wire                      out_robidx_flag,
    output wire [ `ROB_SIZE_LOG-1:0] out_robidx,
    //exu result
    output wire [     `RESULT_RANGE] out_result,
    //redirect
    output wire                      redirect_valid,
    output wire [         `PC_RANGE] redirect_target

);


    assign out_instr_valid = instr_valid;



    //exu logic
    wire        alu_valid = (|alu_type) & instr_valid;
    wire        bju_valid = (|cx_type) & instr_valid;
    wire        muldiv_valid = (|muldiv_type) & instr_valid;


    wire [63:0] alu_result;
    wire [63:0] bju_result;
    wire [63:0] muldiv_result;

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
        .src1           (src1),
        .src2           (src2),
        .imm            (imm),
        .pc             (pc),
        .cx_type        (cx_type),
        .valid          (bju_valid),
        .is_unsigned    (is_unsigned),
        .dest           (bju_result),
        .redirect_valid (redirect_valid),
        .redirect_target(redirect_target)
    );

    muldiv u_muldiv (
        .src1       (src1),
        .src2       (src2),
        .valid      (muldiv_valid),
        .muldiv_type(muldiv_type),
        .result     (muldiv_result)
    );

    assign out_prd         = prd;
    assign out_need_to_wb  = need_to_wb;
    assign out_result      = (|alu_type) ? alu_result : (|cx_type) ? bju_result : (|muldiv_type) ? muldiv_result : 64'hDEADBEEF;


    assign out_robidx_flag = robidx_flag;
    assign out_robidx      = robidx;
endmodule
