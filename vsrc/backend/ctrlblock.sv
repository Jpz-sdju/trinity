`include "defines.sv"
module ctrlblock (
    input wire clock,
    input wire reset_n,

    input wire [31:0] ibuffer_instr_valid,
    input wire [31:0] ibuffer_inst_out,
    input wire [47:0] ibuffer_pc_out

);
    /* verilator lint_off PINCONNECTEMPTY */

    /* -------------------------------------------------------------------------- */
    /*                          stage 0: decode to rename ,read rat               */
    /* -------------------------------------------------------------------------- */
    wire [               4:0] rs1;
    wire [               4:0] rs2;
    wire [               4:0] rd;
    wire [              63:0] imm;
    wire                      src1_is_reg;
    wire                      src2_is_reg;
    wire                      need_to_wb;
    wire [    `CX_TYPE_RANGE] cx_type;
    wire                      is_unsigned;
    wire [   `ALU_TYPE_RANGE] alu_type;
    wire                      is_word;
    wire                      is_imm;
    wire                      is_load;
    wire                      is_store;
    wire [               3:0] ls_size;
    wire [`MULDIV_TYPE_RANGE] muldiv_type;
    wire                      decoder_instr_valid;
    wire [              31:0] decoder_inst_out;
    wire [              47:0] decoder_pc_out;
    decode u_decoder (
        .clock              (clock),
        .reset_n            (reset_n),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .rs1                (rs1),
        .rs2                (rs2),
        .rd                 (rd),
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

    wire [               4:0] fromdec_rs1;
    wire [               4:0] fromdec_rs2;
    wire [               4:0] fromdec_rd;
    wire [              63:0] fromdec_imm;
    wire                      fromdec_src1_is_reg;
    wire                      fromdec_src2_is_reg;
    wire                      fromdec_need_to_wb;
    wire [    `CX_TYPE_RANGE] fromdec_cx_type;
    wire                      fromdec_is_unsigned;
    wire [   `ALU_TYPE_RANGE] fromdec_alu_type;
    wire                      fromdec_is_word;
    wire                      fromdec_is_imm;
    wire                      fromdec_is_load;
    wire                      fromdec_is_store;
    wire [               3:0] fromdec_ls_size;
    wire [`MULDIV_TYPE_RANGE] fromdec_muldiv_type;
    wire                      fromdec_instr_valid;
    wire [              31:0] fromdec_instr;
    wire [              47:0] fromdec_pc;

    pipereg u_pipereg_dec2ra (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  (),                     //mem_stall latch output of this pipereg
        .rs1                    (rs1),
        .rs2                    (rs2),
        .rd                     (rd),
        .src1                   (),
        .src2                   (),
        .imm                    (imm),
        .src1_is_reg            (src1_is_reg),
        .src2_is_reg            (src2_is_reg),
        .need_to_wb             (need_to_wb),
        .cx_type                (cx_type),
        .is_unsigned            (is_unsigned),
        .alu_type               (alu_type),
        .is_word                (is_word),
        .is_load                (is_load),
        .is_imm                 (is_imm),
        .is_store               (is_store),
        .ls_size                (ls_size),
        .muldiv_type            (muldiv_type),
        .instr_valid            (decoder_instr_valid),
        .pc                     (decoder_pc_out),
        .instr                  (decoder_inst_out),
        .ls_address             ('b0),
        .alu_result             ('b0),
        .bju_result             ('b0),
        .muldiv_result          ('b0),
        .opload_read_data_wb    ('b0),
        .out_rs1                (fromdec_rs1),
        .out_rs2                (fromdec_rs2),
        .out_rd                 (fromdec_rd),
        .out_src1               (),
        .out_src2               (),
        .out_imm                (fromdec_imm),
        .out_src1_is_reg        (fromdec_src1_is_reg),
        .out_src2_is_reg        (fromdec_src2_is_reg),
        .out_need_to_wb         (fromdec_need_to_wb),
        .out_cx_type            (fromdec_cx_type),
        .out_is_unsigned        (fromdec_is_unsigned),
        .out_alu_type           (fromdec_alu_type),
        .out_is_word            (fromdec_is_word),
        .out_is_load            (fromdec_is_load),
        .out_is_imm             (fromdec_is_imm),
        .out_is_store           (fromdec_is_store),
        .out_ls_size            (fromdec_ls_size),
        .out_muldiv_type        (fromdec_muldiv_type),
        .out_instr_valid        (fromdec_instr_valid),
        .out_pc                 (fromdec_pc),
        .out_instr              (fromdec_instr),
        .out_ls_address         (),
        .out_alu_result         (),
        .out_bju_result         (),
        .out_muldiv_result      (),
        .out_opload_read_data_wb(),
        .redirect_flush         ()
    );

    /* --------------------------- rat read data to rename -------------------------- */
    wire [`PREG_RANGE] instr0_rat_prs1;
    wire [`PREG_RANGE] instr0_rat_prs2;
    wire [`PREG_RANGE] instr0_rat_prd;
    /* ------------------------ write request from rename ----------------------- */
    wire               instr0_rat_rename_valid;
    wire [        4:0] instr0_rat_rename_addr;
    wire [`PREG_RANGE] instr0_rat_rename_data;


    renametable u_renametable (
        .clock                  (clock),
        .reset_n                (reset_n),
        .instr0_src1_is_reg     (src1_is_reg),
        .instr0_rs1             (rs1),
        .instr0_src2_is_reg     (src2_is_reg),
        .instr0_rs2             (rs2),
        .instr0_need_to_wb      (need_to_wb),
        .instr0_rd              (rd),
        .instr1_src1_is_reg     (),
        .instr1_rs1             (),
        .instr1_src2_is_reg     (),
        .instr1_rs2             (),
        .instr1_need_to_wb      (),
        .instr1_rd              (),
        .instr0_rat_prs1        (instr0_rat_prs1),
        .instr0_rat_prs2        (instr0_rat_prs2),
        .instr0_rat_prd         (instr0_rat_prd),
        .instr1_rat_prs1        (),
        .instr1_rat_prs2        (),
        .instr1_rat_prd         (),
        .instr0_rat_rename_valid(instr0_rat_rename_valid),
        .instr0_rat_rename_addr (instr0_rat_rename_addr),
        .instr0_rat_rename_data (instr0_rat_rename_data),
        .instr1_rat_rename_valid(),
        .instr1_rat_rename_addr (),
        .instr1_rat_rename_data ()
    );

    /* -------------------------------------------------------------------------- */
    /*                               stage : rename                               */
    /* -------------------------------------------------------------------------- */

    /* --------------------------- to dispatch instr 0 -------------------------- */
    wire                      to_dispatch_instr0_valid;
    wire [       `LREG_RANGE] to_dispatch_instr0_rs1;
    wire [       `LREG_RANGE] to_dispatch_instr0_rs2;
    wire [       `LREG_RANGE] to_dispatch_instr0_rd;
    wire [              47:0] to_dispatch_instr0_pc;

    wire [              63:0] to_dispatch_instr0_imm;
    wire                      to_dispatch_instr0_src1_is_reg;
    wire                      to_dispatch_instr0_src2_is_reg;
    wire                      to_dispatch_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_dispatch_instr0_cx_type;
    wire                      to_dispatch_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_dispatch_instr0_alu_type;
    wire                      to_dispatch_instr0_is_word;
    wire                      to_dispatch_instr0_is_imm;
    wire                      to_dispatch_instr0_is_load;
    wire                      to_dispatch_instr0_is_store;
    wire [               3:0] to_dispatch_instr0_ls_size;


    wire [       `PREG_RANGE] to_dispatch_instr0_prs1;
    wire [       `PREG_RANGE] to_dispatch_instr0_prs2;
    wire [       `PREG_RANGE] to_dispatch_instr0_prd;
    wire [       `PREG_RANGE] to_dispatch_instr0_old_prd;

    /* -------------------------------- pipe out -------------------------------- */
    wire                      fromrename_instr0_valid;
    wire [       `LREG_RANGE] fromrename_instr0_rs1;
    wire [       `LREG_RANGE] fromrename_instr0_rs2;
    wire [       `LREG_RANGE] fromrename_instr0_rd;
    wire [              47:0] fromrename_instr0_pc;

    wire [              63:0] fromrename_instr0_imm;
    wire                      fromrename_instr0_src1_is_reg;
    wire                      fromrename_instr0_src2_is_reg;
    wire                      fromrename_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] fromrename_instr0_cx_type;
    wire                      fromrename_instr0_is_unsigned;
    wire [`MULDIV_TYPE_RANGE] fromrename_instr0_muldiv_type;
    wire [   `ALU_TYPE_RANGE] fromrename_instr0_alu_type;
    wire                      fromrename_instr0_is_word;
    wire                      fromrename_instr0_is_imm;
    wire                      fromrename_instr0_is_load;
    wire                      fromrename_instr0_is_store;
    wire [               3:0] fromrename_instr0_ls_size;


    wire [       `PREG_RANGE] fromrename_instr0_prs1;
    wire [       `PREG_RANGE] fromrename_instr0_prs2;
    wire [       `PREG_RANGE] fromrename_instr0_prd;
    wire [       `PREG_RANGE] fromrename_instr0_old_prd;
    rename u_rename (
        .instr0_valid                  (fromdec_instr_valid),
        .instr0                        (fromdec_instr),
        .instr0_rs1                    (fromdec_rs1),
        .instr0_rs2                    (fromdec_rs2),
        .instr0_rd                     (fromdec_rd),
        .instr0_pc                     (fromdec_pc),
        .instr0_imm                    (fromdec_imm),
        .instr0_src1_is_reg            (fromdec_src1_is_reg),
        .instr0_src2_is_reg            (fromdec_src2_is_reg),
        .instr0_need_to_wb             (fromdec_need_to_wb),
        .instr0_cx_type                (fromdec_cx_type),
        .instr0_is_unsigned            (fromdec_is_unsigned),
        .instr0_alu_type               (fromdec_alu_type),
        .instr0_is_word                (fromdec_is_word),
        .instr0_is_imm                 (fromdec_is_imm),
        .instr0_is_load                (fromdec_is_load),
        .instr0_is_store               (fromdec_is_store),
        .instr0_ls_size                (fromdec_ls_size),
        .instr1_valid                  (),
        .instr1                        (),
        .instr1_rs1                    (),
        .instr1_rs2                    (),
        .instr1_rd                     (),
        .instr1_pc                     (),
        .instr1_imm                    (),
        .instr1_src1_is_reg            (),
        .instr1_src2_is_reg            (),
        .instr1_need_to_wb             (),
        .instr1_cx_type                (),
        .instr1_is_unsigned            (),
        .instr1_alu_type               (),
        .instr1_is_word                (),
        .instr1_is_imm                 (),
        .instr1_is_load                (),
        .instr1_is_store               (),
        .instr1_ls_size                (),
        .instr0_rat_prs1               (instr0_rat_prs1),
        .instr0_rat_prs2               (instr0_rat_prs2),
        .instr0_rat_prd                (instr0_rat_prd),
        .instr1_rat_prs1               (),
        .instr1_rat_prs2               (),
        .instr1_rat_prd                (),
        .instr0_rat_rename_valid       (instr0_rat_rename_valid),
        .instr0_rat_rename_addr        (instr0_rat_rename_addr),
        .instr0_rat_rename_data        (instr0_rat_rename_data),
        .instr1_rat_rename_valid       (),
        .instr1_rat_rename_addr        (),
        .instr1_rat_rename_data        (),
        .instr0_freelist_req           (instr0_freelist_req),
        .instr0_freelist_resp          (instr0_freelist_resp),
        .instr1_freelist_req           (),
        .instr1_freelist_resp          (),
        .to_dispatch_instr0_valid      (to_dispatch_instr0_valid),
        .to_dispatch_instr0_rs1        (to_dispatch_instr0_rs1),
        .to_dispatch_instr0_rs2        (to_dispatch_instr0_rs2),
        .to_dispatch_instr0_rd         (to_dispatch_instr0_rd),
        .to_dispatch_instr0_pc         (to_dispatch_instr0_pc),
        .to_dispatch_instr0            (to_dispatch_instr0),
        .to_dispatch_instr0_imm        (to_dispatch_instr0_imm),
        .to_dispatch_instr0_src1_is_reg(to_dispatch_instr0_src1_is_reg),
        .to_dispatch_instr0_src2_is_reg(to_dispatch_instr0_src2_is_reg),
        .to_dispatch_instr0_need_to_wb (to_dispatch_instr0_need_to_wb),
        .to_dispatch_instr0_cx_type    (to_dispatch_instr0_cx_type),
        .to_dispatch_instr0_is_unsigned(to_dispatch_instr0_is_unsigned),
        .to_dispatch_instr0_alu_type   (to_dispatch_instr0_alu_type),
        .to_dispatch_instr0_is_word    (to_dispatch_instr0_is_word),
        .to_dispatch_instr0_is_imm     (to_dispatch_instr0_is_imm),
        .to_dispatch_instr0_is_load    (to_dispatch_instr0_is_load),
        .to_dispatch_instr0_is_store   (to_dispatch_instr0_is_store),
        .to_dispatch_instr0_ls_size    (to_dispatch_instr0_ls_size),
        .to_dispatch_instr0_prs1       (to_dispatch_instr0_prs1),
        .to_dispatch_instr0_prs2       (to_dispatch_instr0_prs2),
        .to_dispatch_instr0_prd        (to_dispatch_instr0_prd),
        .to_dispatch_instr0_old_prd    (to_dispatch_instr0_old_prd),
        .to_dispatch_instr1_valid      (),
        .to_dispatch_instr1_rs1        (),
        .to_dispatch_instr1_rs2        (),
        .to_dispatch_instr1_rd         (),
        .to_dispatch_instr1_pc         (),
        .to_dispatch_instr1            (),
        .to_dispatch_instr1_imm        (),
        .to_dispatch_instr1_src1_is_reg(),
        .to_dispatch_instr1_src2_is_reg(),
        .to_dispatch_instr1_need_to_wb (),
        .to_dispatch_instr1_cx_type    (),
        .to_dispatch_instr1_is_unsigned(),
        .to_dispatch_instr1_alu_type   (),
        .to_dispatch_instr1_is_word    (),
        .to_dispatch_instr1_is_imm     (),
        .to_dispatch_instr1_is_load    (),
        .to_dispatch_instr1_is_store   (),
        .to_dispatch_instr1_ls_size    (),
        .to_dispatch_instr1_prs1       (),
        .to_dispatch_instr1_prs2       (),
        .to_dispatch_instr1_prd        (),
        .to_dispatch_instr1_old_prd    ()
    );

    `PIPE(fromrename_instr0, to_dispatch_instr0, 1'b0, 1'b0)



endmodule

/* verilator lint_off PINCONNECTEMPTY */

