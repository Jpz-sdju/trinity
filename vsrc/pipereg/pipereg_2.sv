module pipereg_2 (
    input  wire               clock,
    input  wire               reset_n,
    // input  wire               stall,
    output wire                ready,
    input  wire [`LREG_RANGE] lrs1,
    input  wire [`LREG_RANGE] lrs2,
    input  wire [`LREG_RANGE] lrd,
    input  wire [ `SRC_RANGE] imm,
    input  wire               src1_is_reg,
    input  wire               src2_is_reg,
    input  wire               need_to_wb,

    //sig below is control transfer(xfer) type
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire                      is_word,
    input wire                      is_load,
    input wire                      is_imm,
    input wire                      is_store,
    input wire [               3:0] ls_size,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire                      instr_valid,
    input wire [         `PC_RANGE] pc,
    input wire [      `INSTR_RANGE] instr,

    //sig below is preg
    input wire [`PREG_RANGE] prs1,
    input wire [`PREG_RANGE] prs2,
    input wire [`PREG_RANGE] prd,
    input wire [`PREG_RANGE] old_prd,

    //note: sig below is emerge from exu
    input wire [`RESULT_RANGE] ls_address,
    input wire [`RESULT_RANGE] alu_result,
    input wire [`RESULT_RANGE] bju_result,
    input wire [`RESULT_RANGE] muldiv_result,

    //note: dont not to fill until mem stage done
    input wire [`RESULT_RANGE] opload_read_data_wb,

    //flush
    input redirect_flush,

    // outputs
    input  wire               out_ready,
    output reg  [`LREG_RANGE] out_lrs1,
    output reg  [`LREG_RANGE] out_lrs2,
    output reg  [`LREG_RANGE] out_lrd,
    output reg  [ `SRC_RANGE] out_imm,
    output reg                out_src1_is_reg,
    output reg                out_src2_is_reg,
    output reg                out_need_to_wb,


    output reg [    `CX_TYPE_RANGE] out_cx_type,
    output reg                      out_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] out_alu_type,
    output reg                      out_is_word,
    output reg                      out_is_load,
    output reg                      out_is_imm,
    output reg                      out_is_store,
    output reg [               3:0] out_ls_size,
    output reg [`MULDIV_TYPE_RANGE] out_muldiv_type,
    output reg                      out_instr_valid,
    output reg [         `PC_RANGE] out_pc,
    output reg [      `INSTR_RANGE] out_instr,

    output reg [`PREG_RANGE] out_prs1,
    output reg [`PREG_RANGE] out_prs2,
    output reg [`PREG_RANGE] out_prd,
    output reg [`PREG_RANGE] out_old_prd,


    output reg [`RESULT_RANGE] out_ls_address,
    output reg [`RESULT_RANGE] out_alu_result,
    output reg [`RESULT_RANGE] out_bju_result,
    output reg [`RESULT_RANGE] out_muldiv_result,

    output reg [`RESULT_RANGE] out_opload_read_data_wb
);
    wire in_fire = instr_valid & ready;
    wire out_fire = out_instr_valid & out_ready;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n || redirect_flush ) begin
            out_instr_valid         <= 'b0;
            out_lrs1                <= 'b0;
            out_lrs2                <= 'b0;
            out_lrd                 <= 'b0;
            out_imm                 <= 'b0;
            out_src1_is_reg         <= 'b0;
            out_src2_is_reg         <= 'b0;
            out_need_to_wb          <= 'b0;

            out_cx_type             <= 'b0;
            out_is_unsigned         <= 'b0;
            out_alu_type            <= 'b0;
            out_is_word             <= 'b0;
            out_is_load             <= 'b0;
            out_is_imm              <= 'b0;
            out_is_store            <= 'b0;
            out_ls_size             <= 'b0;
            out_muldiv_type         <= 'b0;
            out_pc                  <= 'b0;
            out_instr               <= 'b0;

            out_ls_address          <= 'b0;
            out_alu_result          <= 'b0;
            out_bju_result          <= 'b0;
            out_muldiv_result       <= 'b0;
            out_opload_read_data_wb <= 'b0;


            out_prs1                <= 'b0;
            out_prs2                <= 'b0;
            out_prd                 <= 'b0;
            out_old_prd             <= 'b0;
        end else if (in_fire) begin
            out_instr_valid         <= instr_valid;
            out_lrs1                <= lrs1;
            out_lrs2                <= lrs2;
            out_lrd                 <= lrd;
            out_imm                 <= imm;
            out_src1_is_reg         <= src1_is_reg;
            out_src2_is_reg         <= src2_is_reg;
            out_need_to_wb          <= need_to_wb;
            out_cx_type             <= cx_type;
            out_is_unsigned         <= is_unsigned;
            out_alu_type            <= alu_type;
            out_is_word             <= is_word;
            out_is_load             <= is_load;
            out_is_imm              <= is_imm;
            out_is_store            <= is_store;
            out_ls_size             <= ls_size;
            out_muldiv_type         <= muldiv_type;
            out_pc                  <= pc;
            out_instr               <= instr;
            out_ls_address          <= ls_address;
            out_alu_result          <= alu_result;
            out_bju_result          <= bju_result;
            out_muldiv_result       <= muldiv_result;
            out_opload_read_data_wb <= opload_read_data_wb;
            out_prs1                <= prs1;
            out_prs2                <= prs2;
            out_prd                 <= prd;
            out_old_prd             <= old_prd;
        end else if(out_fire)begin
            out_instr_valid         <= 'b0;
            // out_lrs1                <= lrs1;
            // out_lrs2                <= lrs2;
            // out_lrd                 <= lrd;
            // out_imm                 <= imm;
            // out_src1_is_reg         <= src1_is_reg;
            // out_src2_is_reg         <= src2_is_reg;
            // out_need_to_wb          <= need_to_wb;

            // out_cx_type             <= cx_type;
            // out_is_unsigned         <= is_unsigned;
            // out_alu_type            <= alu_type;
            // out_is_word             <= is_word;
            // out_is_load             <= is_load;
            // out_is_imm              <= is_imm;
            // out_is_store            <= is_store;
            // out_ls_size             <= ls_size;
            // out_muldiv_type         <= muldiv_type;
            // out_pc                  <= pc;
            // out_instr               <= instr;

            // out_ls_address          <= ls_address;
            // out_alu_result          <= alu_result;
            // out_bju_result          <= bju_result;
            // out_muldiv_result       <= muldiv_result;

            // out_opload_read_data_wb <= opload_read_data_wb;


            // out_prs1                <= prs1;
            // out_prs2                <= prs2;
            // out_prd                 <= prd;
            // out_old_prd             <= old_prd;


        end
    end

    assign ready = out_ready;
endmodule
