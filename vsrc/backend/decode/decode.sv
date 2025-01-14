module decode (
    input wire clock,
    input wire reset_n,

    input wire        ibuffer_instr_valid,
    input wire [31:0] ibuffer_inst_out,
    input wire [47:0] ibuffer_pc_out,

    //decode result
    output wire [               4:0] rs1,
    output wire [               4:0] rs2,
    output wire [               4:0] rd,
    output wire [              63:0] src1,
    output wire [              63:0] src2,
    output wire [              63:0] imm,
    output wire                      src1_is_reg,
    output wire                      src2_is_reg,
    output wire                      need_to_wb,
    output wire [    `CX_TYPE_RANGE] cx_type,
    output wire                      is_unsigned,
    output wire [   `ALU_TYPE_RANGE] alu_type,
    output wire                      is_word,
    output wire                      is_imm,
    output wire                      is_load,
    output wire                      is_store,
    output wire [               3:0] ls_size,
    output wire [`MULDIV_TYPE_RANGE] muldiv_type,
    output wire                      decoder_instr_valid,
    output wire [              31:0] decoder_inst_out,
    output wire [              47:0] decoder_pc_out
);

    decoder u_decoder (
        .clock              (clock),
        .reset_n            (reset_n),
        .fifo_empty         (),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .rs1                (rs1),
        .rs2                (rs2),
        .rd                 (rd),
        .src1               (src1),
        .src2               (src2),
        .imm                (imm),
        .src1_is_reg        (src1_is_reg),
        .src2_is_reg        (src2_is_reg),
        .need_to_wb         (need_to_wb),
        .cx_type            (cx_type),
        .is_unsigned        (is_unsigned),
        .alu_type           (alu_type),
        .is_word            (is_word),
        .is_imm             (is_imm),
        .is_load            (is_load),
        .is_store           (is_store),
        .ls_size            (ls_size),
        .muldiv_type        (muldiv_type),
        .decoder_instr_valid(decoder_instr_valid),
        .decoder_inst_out   (decoder_inst_out),
        .decoder_pc_out     (decoder_pc_out)

    );

endmodule
