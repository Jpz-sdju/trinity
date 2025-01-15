`include "defines.sv"
`include "pipedefines.sv"
/* verilator lint_off UNUSEDSIGNAL */
module ctrlblock (
    input wire clock,
    input wire reset_n,

    input wire                ibuffer_instr_valid,
    input wire [`INSTR_RANGE] ibuffer_inst_out,
    input wire [        47:0] ibuffer_pc_out

);
    /* verilator lint_off PINCONNECTEMPTY */

    /* -------------------------------------------------------------------------- */
    /*                          stage 0: decode to rename ,read rat               */
    /* -------------------------------------------------------------------------- */
    wire [               4:0] from_dec_instr0_rs1;
    wire [               4:0] from_dec_instr0_rs2;
    wire [               4:0] from_dec_instr0_rd;
    wire [              63:0] from_dec_instr0_imm;
    wire                      from_dec_instr0_src1_is_reg;
    wire                      from_dec_instr0_src2_is_reg;
    wire                      from_dec_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] from_dec_instr0_cx_type;
    wire                      from_dec_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] from_dec_instr0_alu_type;
    wire                      from_dec_instr0_is_word;
    wire                      from_dec_instr0_is_imm;
    wire                      from_dec_instr0_is_load;
    wire                      from_dec_instr0_is_store;
    wire [               3:0] from_dec_instr0_ls_size;
    wire [`MULDIV_TYPE_RANGE] from_dec_instr0_muldiv_type;
    wire                      from_dec_instr0_valid;
    wire [              31:0] from_dec_instr0;
    wire [              47:0] from_dec_instr0_pc;
    decode u_decoder (
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .rs1                (from_dec_instr0_rs1),
        .rs2                (from_dec_instr0_rs2),
        .rd                 (from_dec_instr0_rd),
        .imm                (from_dec_instr0_imm),
        .src1_is_reg        (from_dec_instr0_src1_is_reg),
        .src2_is_reg        (from_dec_instr0_src2_is_reg),
        .need_to_wb         (from_dec_instr0_need_to_wb),
        .cx_type            (from_dec_instr0_cx_type),
        .is_unsigned        (from_dec_instr0_is_unsigned),
        .alu_type           (from_dec_instr0_alu_type),
        .is_word            (from_dec_instr0_is_word),
        .is_imm             (from_dec_instr0_is_imm),
        .is_load            (from_dec_instr0_is_load),
        .is_store           (from_dec_instr0_is_store),
        .ls_size            (from_dec_instr0_ls_size),
        .muldiv_type        (from_dec_instr0_muldiv_type),
        .decoder_instr_valid(from_dec_instr0_valid),
        .decoder_inst_out   (from_dec_instr0),
        .decoder_pc_out     (from_dec_instr0_pc)

    );

    wire [               4:0] to_rename_instr0_rs1;
    wire [               4:0] to_rename_instr0_rs2;
    wire [               4:0] to_rename_instr0_rd;
    wire [              63:0] to_rename_instr0_imm;
    wire                      to_rename_instr0_src1_is_reg;
    wire                      to_rename_instr0_src2_is_reg;
    wire                      to_rename_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_rename_instr0_cx_type;
    wire                      to_rename_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_rename_instr0_alu_type;
    wire                      to_rename_instr0_is_word;
    wire                      to_rename_instr0_is_imm;
    wire                      to_rename_instr0_is_load;
    wire                      to_rename_instr0_is_store;
    wire [               3:0] to_rename_instr0_ls_size;
    wire [`MULDIV_TYPE_RANGE] to_rename_instr0_muldiv_type;
    wire                      to_rename_instr0_valid;
    wire [              31:0] to_rename_instr0;
    wire [              47:0] to_rename_instr0_pc;


    `PIPE_BEFORE_RENAME(to_rename_instr0, from_dec_instr0, 1'b0, 1'b0)
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
        .instr0_src1_is_reg     (to_rename_instr0_src1_is_reg),
        .instr0_rs1             (to_rename_instr0_rs1),
        .instr0_src2_is_reg     (to_rename_instr0_src2_is_reg),
        .instr0_rs2             (to_rename_instr0_rs2),
        .instr0_need_to_wb      (to_rename_instr0_need_to_wb),
        .instr0_rd              (to_rename_instr0_rd),
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

    /* -------------------------------- rename out  -------------------------------- */
    wire                      from_rename_instr0_valid;
    wire [       `LREG_RANGE] from_rename_instr0_rs1;
    wire [       `LREG_RANGE] from_rename_instr0_rs2;
    wire [       `LREG_RANGE] from_rename_instr0_rd;
    wire [              47:0] from_rename_instr0_pc;
    wire [      `INSTR_RANGE] from_rename_instr0;


    wire [              63:0] from_rename_instr0_imm;
    wire                      from_rename_instr0_src1_is_reg;
    wire                      from_rename_instr0_src2_is_reg;
    wire                      from_rename_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] from_rename_instr0_cx_type;
    wire                      from_rename_instr0_is_unsigned;
    wire [`MULDIV_TYPE_RANGE] from_rename_instr0_muldiv_type;
    wire [   `ALU_TYPE_RANGE] from_rename_instr0_alu_type;
    wire                      from_rename_instr0_is_word;
    wire                      from_rename_instr0_is_imm;
    wire                      from_rename_instr0_is_load;
    wire                      from_rename_instr0_is_store;
    wire [               3:0] from_rename_instr0_ls_size;


    wire [       `PREG_RANGE] from_rename_instr0_prs1;
    wire [       `PREG_RANGE] from_rename_instr0_prs2;
    wire [       `PREG_RANGE] from_rename_instr0_prd;
    wire [       `PREG_RANGE] from_rename_instr0_old_prd;

    /* ----------------------------- freelist alloc ----------------------------- */
    wire                      instr0_freelist_req;
    wire [       `PREG_RANGE] instr0_freelist_resp;

    freelist u_freelist (
        .clock       (clock),
        .reset_n     (reset_n),
        .req0_valid  (instr0_freelist_req),
        .req0_data   (instr0_freelist_resp),
        .req1_valid  (),
        .req1_data   (),
        .write0_valid(),
        .write0_data (),
        .write1_valid(),
        .write1_data ()
    );



    rename u_rename (
        .instr0_valid                  (to_rename_instr0_valid),
        .instr0                        (to_rename_instr0),
        .instr0_rs1                    (to_rename_instr0_rs1),
        .instr0_rs2                    (to_rename_instr0_rs2),
        .instr0_rd                     (to_rename_instr0_rd),
        .instr0_pc                     (to_rename_instr0_pc),
        .instr0_imm                    (to_rename_instr0_imm),
        .instr0_src1_is_reg            (to_rename_instr0_src1_is_reg),
        .instr0_src2_is_reg            (to_rename_instr0_src2_is_reg),
        .instr0_need_to_wb             (to_rename_instr0_need_to_wb),
        .instr0_cx_type                (to_rename_instr0_cx_type),
        .instr0_is_unsigned            (to_rename_instr0_is_unsigned),
        .instr0_alu_type               (to_rename_instr0_alu_type),
        .instr0_is_word                (to_rename_instr0_is_word),
        .instr0_is_imm                 (to_rename_instr0_is_imm),
        .instr0_is_load                (to_rename_instr0_is_load),
        .instr0_is_store               (to_rename_instr0_is_store),
        .instr0_ls_size                (to_rename_instr0_ls_size),
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
        .to_dispatch_instr0_valid      (from_rename_instr0_valid),
        .to_dispatch_instr0_rs1        (from_rename_instr0_rs1),
        .to_dispatch_instr0_rs2        (from_rename_instr0_rs2),
        .to_dispatch_instr0_rd         (from_rename_instr0_rd),
        .to_dispatch_instr0_pc         (from_rename_instr0_pc),
        .to_dispatch_instr0            (from_rename_instr0),
        .to_dispatch_instr0_imm        (from_rename_instr0_imm),
        .to_dispatch_instr0_src1_is_reg(from_rename_instr0_src1_is_reg),
        .to_dispatch_instr0_src2_is_reg(from_rename_instr0_src2_is_reg),
        .to_dispatch_instr0_need_to_wb (from_rename_instr0_need_to_wb),
        .to_dispatch_instr0_cx_type    (from_rename_instr0_cx_type),
        .to_dispatch_instr0_is_unsigned(from_rename_instr0_is_unsigned),
        .to_dispatch_instr0_alu_type   (from_rename_instr0_alu_type),
        .to_dispatch_instr0_is_word    (from_rename_instr0_is_word),
        .to_dispatch_instr0_is_imm     (from_rename_instr0_is_imm),
        .to_dispatch_instr0_is_load    (from_rename_instr0_is_load),
        .to_dispatch_instr0_is_store   (from_rename_instr0_is_store),
        .to_dispatch_instr0_ls_size    (from_rename_instr0_ls_size),
        .to_dispatch_instr0_prs1       (from_rename_instr0_prs1),
        .to_dispatch_instr0_prs2       (from_rename_instr0_prs2),
        .to_dispatch_instr0_prd        (from_rename_instr0_prd),
        .to_dispatch_instr0_old_prd    (from_rename_instr0_old_prd),
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


    /* --------------------------- to dispatch instr 0 -------------------------- */
    wire                      to_dispatch_instr0_valid;
    wire [       `LREG_RANGE] to_dispatch_instr0_rs1;
    wire [       `LREG_RANGE] to_dispatch_instr0_rs2;
    wire [       `LREG_RANGE] to_dispatch_instr0_rd;
    wire [              47:0] to_dispatch_instr0_pc;
    wire [      `INSTR_RANGE] to_dispatch_instr0;

    wire [              63:0] to_dispatch_instr0_imm;
    wire                      to_dispatch_instr0_src1_is_reg;
    wire                      to_dispatch_instr0_src2_is_reg;
    wire                      to_dispatch_instr0_need_to_wb;
    wire [    `CX_TYPE_RANGE] to_dispatch_instr0_cx_type;
    wire                      to_dispatch_instr0_is_unsigned;
    wire [   `ALU_TYPE_RANGE] to_dispatch_instr0_alu_type;
    wire [`MULDIV_TYPE_RANGE] to_dispatch_instr0_muldiv_type;

    wire                      to_dispatch_instr0_is_word;
    wire                      to_dispatch_instr0_is_imm;
    wire                      to_dispatch_instr0_is_load;
    wire                      to_dispatch_instr0_is_store;
    wire [               3:0] to_dispatch_instr0_ls_size;


    wire [       `PREG_RANGE] to_dispatch_instr0_prs1;
    wire [       `PREG_RANGE] to_dispatch_instr0_prs2;
    wire [       `PREG_RANGE] to_dispatch_instr0_prd;
    wire [       `PREG_RANGE] to_dispatch_instr0_old_prd;
    `PIPE_BEFORE_WB(fromrename_instr0, to_dispatch_instr0, 1'b0, 1'b0)


    /* -------------------------------------------------------------------------- */
    /*                                state:  dispatch                            */
    /* -------------------------------------------------------------------------- */


    /* verilator lint_off PINCONNECTEMPTY */
    /* verilator lint_off UNUSEDSIGNAL */

endmodule



