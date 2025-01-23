`include "defines.sv"
module alu (
    input  wire [     `SRC_RANGE] src1,
    input  wire [     `SRC_RANGE] src2,
    input  wire [     `SRC_RANGE] imm,
    input  wire [      `PC_RANGE] pc,
    input  wire                   valid,
    input  wire [`ALU_TYPE_RANGE] alu_type,
    input  wire                   is_word,
    input  wire                   is_unsigned,
    input  wire                   is_imm,
    output wire [     `SRC_RANGE] result
);
    /*
    0 = ADD
    1 = SET LESS THAN
    2 = SET LESS THEN UNSIGNED
    3 = XOR
    4 = OR
    5 = AND
    6 = SHIFT LEFT LOGICAL
    7 = SHIFT RIGHT LOGICAL
    8 = SHIFT RIGHT ARH
    9 = SUB
*/
    wire              is_add = alu_type[0];
    wire              is_set_lt = alu_type[1];
    wire              is_set_ltu = alu_type[1] & is_unsigned;
    wire              is_xor = alu_type[2];
    wire              is_or = alu_type[3];
    wire              is_and = alu_type[4];
    wire              is_sll = alu_type[5];
    wire              is_srl = alu_type[6];
    wire              is_sra = alu_type[7];
    wire              is_sub = alu_type[8];
    wire              is_lui = alu_type[9];
    wire              is_auipc = alu_type[10];

    wire [`SRC_RANGE] src1_qual = is_auipc ? pc : src1;

    reg  [`SRC_RANGE] src2_qual;
    always @(*) begin
        src2_qual = 'b0;
        if (is_imm | is_auipc) begin
            if (is_word) begin
                src2_qual[31:0] = imm[31:0];
            end else begin
                src2_qual = imm;
            end
        end else begin
            if (is_sub) begin
                if (is_word) begin
                    src2_qual = {32'b0, ~src2[31:0] + 32'b1};
                end else begin
                    src2_qual = ~src2 + 64'b1;
                end
            end else begin
                src2_qual = src2;
            end
        end
    end

    wire [      31:0] add_sub_result_w = src1[31:0] + src2_qual[31:0];
    wire [`SRC_RANGE] add_sub_result = is_word ? {{32{add_sub_result_w[31]}}, add_sub_result_w[31:0]} : src1_qual + src2_qual;

    reg               is_less;
    wire              is_lessu = src1 < src2_qual;

    always @(*) begin
        case ({
            src1[`SRC_LENGTH-1], src2_qual[`SRC_LENGTH-1]
        })
            2'b00: is_less = src1[`SRC_LENGTH-2:0] < src2_qual[`SRC_LENGTH-2:0];
            2'b01: is_less = 1'b0;
            2'b10: is_less = 1'b1;
            2'b11: is_less = src1[`SRC_LENGTH-2:0] < src2_qual[`SRC_LENGTH-2:0];
        endcase
    end

    wire       [`SRC_RANGE] xor_result = src1 ^ src2_qual;
    wire       [`SRC_RANGE] or_result = src1 | src2_qual;
    wire       [`SRC_RANGE] and_result = src1 & src2_qual;

    wire       [      31:0] sll_result_w = src1[31:0] << src2_qual[4:0];
    wire       [      31:0] srl_result_w = src1[31:0] >> src2_qual[4:0];
    reg signed [      31:0] sra_result_w;
    reg signed [      31:0] signed_src1;
    reg        [       4:0] signed_src2_qual;

    //assign sra_result_w = signed_src1[31:0] >>> src2_qual[4:0] ;

    always @(*) begin
        signed_src2_qual = src2_qual[4:0];
        signed_src1      = src1[31:0];
        sra_result_w     = signed_src1 >>> signed_src2_qual;
    end

    wire [`SRC_RANGE] sll_result = is_word ? {{32{sll_result_w[31]}}, sll_result_w[31:0]} : src1 << src2_qual[5:0];
    wire [`SRC_RANGE] srl_result = is_word ? {{32{srl_result_w[31]}}, srl_result_w[31:0]} : src1 >> src2_qual[5:0];
    wire [`SRC_RANGE] sra_result = is_word ? {{32{sra_result_w[31]}}, sra_result_w[31:0]} : src1 >>> src2_qual[5:0];

    assign result[`RESULT_RANGE] = (is_set_lt ? {63'b0, is_less} :
                    is_set_ltu ? {63'b0, is_lessu} :
                    (is_add | is_sub | is_auipc)? add_sub_result :
                    is_xor ? xor_result :
                    is_or ? or_result :
                    is_and ? and_result :
                    is_sll ? sll_result :
                    is_srl ? srl_result :
                    is_sra ? sra_result :
                    is_lui ? imm : 'b0) & {64{valid}}  ;
endmodule
