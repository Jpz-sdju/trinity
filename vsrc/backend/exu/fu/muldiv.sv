module muldiv (
    input  wire [        `SRC_RANGE] src1,
    input  wire [        `SRC_RANGE] src2,
    input  wire                      valid,
    input  wire [`MULDIV_TYPE_RANGE] muldiv_type,
    output wire [     `RESULT_RANGE] result
);

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
    wire                 is_mul = muldiv_type[0];
    wire                 is_mulh = muldiv_type[1];
    wire                 is_mulhsu = muldiv_type[2];
    wire                 is_mulhu = muldiv_type[3];
    wire                 is_div = muldiv_type[4];
    wire                 is_divu = muldiv_type[5];
    wire                 is_rem = muldiv_type[6];
    wire                 is_remu = muldiv_type[7];
    wire                 is_mulw = muldiv_type[8];
    wire                 is_divw = muldiv_type[9];
    wire                 is_divuw = muldiv_type[10];
    wire                 is_remw = muldiv_type[11];
    wire                 is_remuw = muldiv_type[12];

    wire [        127:0] product = src1 * src2;
    wire [`RESULT_RANGE] q = src1 / src2;
    wire [`RESULT_RANGE] remainder = src1 % src2;
    wire                 sign = src1[`SRC_LENGTH-1] ^ src2[`SRC_LENGTH-1];

    wire [`RESULT_RANGE] mul_result = {sign, product[62:0]};
    wire [`RESULT_RANGE] mulh_result = {sign, product[126:64]};
    wire [`RESULT_RANGE] mulhsu_result = {src1[`SRC_LENGTH-1], product[126:64]};
    wire [`RESULT_RANGE] mulhu_result = product[127:64];

    wire [`RESULT_RANGE] div_result = {sign, q[62:0]};
    wire [`RESULT_RANGE] divu_result = q;
    wire [`RESULT_RANGE] rem_result = {sign, remainder[62:0]};
    wire [`RESULT_RANGE] remu_result = remainder;

    wire [         31:0] w_product = src1[31:0] * src2[31:0];
    wire [         31:0] w_q = src1[31:0] / src2[31:0];
    wire [         31:0] w_remainder = src1[31:0] % src1[31:0];
    wire                 w_sign = src1[31] ^ src2[31];


    wire [`RESULT_RANGE] mulw_result = {{32{w_sign}}, w_product[31:0]};
    wire [`RESULT_RANGE] divw_result = {{32{w_sign}}, w_q[31:0]};
    wire [`RESULT_RANGE] divuw_result = {{32{w_q[31]}}, w_q[31:0]};
    wire [`RESULT_RANGE] remw_result = {{32{w_sign}}, w_remainder[31:0]};
    wire [`RESULT_RANGE] remuw_result = {{32{w_remainder[31]}}, w_remainder[31:0]};
    /* verilog_format: off */
    assign result = is_mul ? mul_result : 
    is_mulh ? mulh_result : 
    is_mulhsu ? mulhsu_result : 
    is_mulhu ? mulhu_result : 
    is_div ? div_result : 
    is_divu ? divu_result : 
    is_rem ? rem_result : 
    is_remu ? remu_result :
     is_mulw ? mulw_result : 
     is_divw ? divw_result : 
     is_remw ? remw_result : 
    is_divuw ? divuw_result :
     remuw_result;
    /* verilog_format: on */
endmodule
