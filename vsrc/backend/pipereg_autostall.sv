`include "defines.sv"
module pipereg_autostall (
    input  wire               clock,
    input  wire               reset_n,
    input wire                instr_valid_from_upper,
    output wire               instr_ready_to_upper,
    input wire [      `INSTR_RANGE] instr,
    input wire [         `PC_RANGE] pc,
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
    input wire [`RESULT_RANGE] opload_read_data_wb,

    input  wire                predicttaken,
    input  wire [31:0]         predicttarget,
 

    // outputs
    output reg                instr_valid_to_lower,
    input  wire               instr_ready_from_lower,
    output reg [      `INSTR_RANGE] lower_instr,
    output reg [         `PC_RANGE] lower_pc,
    output reg  [`LREG_RANGE] lower_lrs1,
    output reg  [`LREG_RANGE] lower_lrs2,
    output reg  [`LREG_RANGE] lower_lrd,
    output reg  [ `SRC_RANGE] lower_imm,
    output reg                lower_src1_is_reg,
    output reg                lower_src2_is_reg,
    output reg                lower_need_to_wb,


    output reg [    `CX_TYPE_RANGE] lower_cx_type,
    output reg                      lower_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] lower_alu_type,
    output reg                      lower_is_word,
    output reg                      lower_is_load,
    output reg                      lower_is_imm,
    output reg                      lower_is_store,
    output reg [               3:0] lower_ls_size,
    output reg [`MULDIV_TYPE_RANGE] lower_muldiv_type,

    output reg [`PREG_RANGE] lower_prs1   ,
    output reg [`PREG_RANGE] lower_prs2   ,
    output reg [`PREG_RANGE] lower_prd    ,
    output reg [`PREG_RANGE] lower_old_prd,

    output reg [`RESULT_RANGE] lower_ls_address         ,
    output reg [`RESULT_RANGE] lower_alu_result         ,
    output reg [`RESULT_RANGE] lower_bju_result         ,
    output reg [`RESULT_RANGE] lower_muldiv_result      ,
    output reg [`RESULT_RANGE] lower_opload_read_data_wb,
    
    output  wire                lower_predicttaken,
    output  wire [31:0]         lower_predicttarget,
    //flush
    input flush_valid

);
    wire in_fire = instr_valid_from_upper & instr_ready_to_upper;
    wire lower_fire = instr_valid_to_lower & instr_ready_from_lower;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n || flush_valid ) begin
            instr_valid_to_lower         <= 'b0;
            lower_lrs1                <= 'b0;
            lower_lrs2                <= 'b0;
            lower_lrd                 <= 'b0;
            lower_imm                 <= 'b0;
            lower_src1_is_reg         <= 'b0;
            lower_src2_is_reg         <= 'b0;
            lower_need_to_wb          <= 'b0;

            lower_cx_type             <= 'b0;
            lower_is_unsigned         <= 'b0;
            lower_alu_type            <= 'b0;
            lower_is_word             <= 'b0;
            lower_is_load             <= 'b0;
            lower_is_imm              <= 'b0;
            lower_is_store            <= 'b0;
            lower_ls_size             <= 'b0;
            lower_muldiv_type         <= 'b0;
            lower_pc                  <= 'b0;
            lower_instr               <= 'b0;

            lower_ls_address          <= 'b0;
            lower_alu_result          <= 'b0;
            lower_bju_result          <= 'b0;
            lower_muldiv_result       <= 'b0;
            lower_opload_read_data_wb <= 'b0;

            lower_prs1                <= 'b0;
            lower_prs2                <= 'b0;
            lower_prd                 <= 'b0;
            lower_old_prd             <= 'b0;

            lower_predicttaken          <= 'b0;
            lower_predicttarget         <= 'b0;
        end else if (in_fire) begin
            instr_valid_to_lower      <= instr_valid_from_upper;
            lower_lrs1                <= lrs1;
            lower_lrs2                <= lrs2;
            lower_lrd                 <= lrd;
            lower_imm                 <= imm;
            lower_src1_is_reg         <= src1_is_reg;
            lower_src2_is_reg         <= src2_is_reg;
            lower_need_to_wb          <= need_to_wb;
            lower_cx_type             <= cx_type;
            lower_is_unsigned         <= is_unsigned;
            lower_alu_type            <= alu_type;
            lower_is_word             <= is_word;
            lower_is_load             <= is_load;
            lower_is_imm              <= is_imm;
            lower_is_store            <= is_store;
            lower_ls_size             <= ls_size;
            lower_muldiv_type         <= muldiv_type;
            lower_pc                  <= pc;
            lower_instr               <= instr;
            lower_ls_address          <= ls_address;
            lower_alu_result          <= alu_result;
            lower_bju_result          <= bju_result;
            lower_muldiv_result       <= muldiv_result;
            lower_opload_read_data_wb <= opload_read_data_wb;
            lower_prs1                <= prs1;
            lower_prs2                <= prs2;
            lower_prd                 <= prd;
            lower_old_prd             <= old_prd;
            
            lower_predicttaken    <= predicttaken;
            lower_predicttarget   <= predicttarget;
        end else if(lower_fire)begin
            instr_valid_to_lower         <= 'b0;
            //not need to assign other output signals, so they are automatically stalled(latched)
        end
    end

    assign instr_ready_to_upper = instr_ready_from_lower;
endmodule
