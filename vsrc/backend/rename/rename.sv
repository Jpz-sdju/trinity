`include "defines.sv"
/* verilator lint_off UNUSEDSIGNAL */
module rename (

    //instr 0
    input  wire               instr0_valid,
    output wire               instr0_ready,
    input  wire [       31:0] instr0,
    input  wire [`LREG_RANGE] instr0_lrs1,
    input  wire [`LREG_RANGE] instr0_lrs2,
    input  wire [`LREG_RANGE] instr0_lrd,
    input  wire [  `PC_RANGE] instr0_pc,

    input wire [              63:0] instr0_imm,
    input wire                      instr0_src1_is_reg,
    input wire                      instr0_src2_is_reg,
    input wire                      instr0_need_to_wb,
    input wire [    `CX_TYPE_RANGE] instr0_cx_type,
    input wire                      instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr0_muldiv_type,
    input wire                      instr0_is_word,
    input wire                      instr0_is_imm,
    input wire                      instr0_is_load,
    input wire                      instr0_is_store,
    input wire [               3:0] instr0_ls_size,

    //instr 1
    input wire               instr1_valid,
    input wire [       31:0] instr1,
    input wire [`LREG_RANGE] instr1_lrs1,
    input wire [`LREG_RANGE] instr1_lrs2,
    input wire [`LREG_RANGE] instr1_lrd,
    input wire [  `PC_RANGE] instr1_pc,

    input wire [              63:0] instr1_imm,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire                      instr1_need_to_wb,
    input wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,

    input wire       instr1_is_word,
    input wire       instr1_is_imm,
    input wire       instr1_is_load,
    input wire       instr1_is_store,
    input wire [3:0] instr1_ls_size,



    //read data from rat
    input wire [`PREG_RANGE] instr0_rat_prs1,
    input wire [`PREG_RANGE] instr0_rat_prs2,
    input wire [`PREG_RANGE] instr0_rat_prd,

    input wire [`PREG_RANGE] instr1_rat_prs1,
    input wire [`PREG_RANGE] instr1_rat_prs2,
    input wire [`PREG_RANGE] instr1_rat_prd,

    //write request to rat
    output wire               instr0_rat_rename_valid,
    output wire [`LREG_RANGE] instr0_rat_rename_addr,
    output wire [`PREG_RANGE] instr0_rat_rename_data,

    output wire               instr1_rat_rename_valid,
    output wire [`LREG_RANGE] instr1_rat_rename_addr,
    output wire [`PREG_RANGE] instr1_rat_rename_data,


    //alloc reqeust to freelist
    output wire               instr0_freelist_req,
    input  wire [`PREG_RANGE] instr0_freelist_resp,

    output wire               instr1_freelist_req,
    input  wire [`PREG_RANGE] instr1_freelist_resp,


    //to dispatch instr 0
    output wire                to_dispatch_instr0_valid,
    input  wire                to_dispatch_instr0_ready,
    output wire [ `LREG_RANGE] to_dispatch_instr0_lrs1,
    output wire [ `LREG_RANGE] to_dispatch_instr0_lrs2,
    output wire [ `LREG_RANGE] to_dispatch_instr0_lrd,
    output wire [   `PC_RANGE] to_dispatch_instr0_pc,
    output wire [`INSTR_RANGE] to_dispatch_instr0,

    output wire [              63:0] to_dispatch_instr0_imm,
    output wire                      to_dispatch_instr0_src1_is_reg,
    output wire                      to_dispatch_instr0_src2_is_reg,
    output wire                      to_dispatch_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_dispatch_instr0_cx_type,
    output wire                      to_dispatch_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_dispatch_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_dispatch_instr0_muldiv_type,
    output wire                      to_dispatch_instr0_is_word,
    output wire                      to_dispatch_instr0_is_imm,
    output wire                      to_dispatch_instr0_is_load,
    output wire                      to_dispatch_instr0_is_store,
    output wire [               3:0] to_dispatch_instr0_ls_size,


    output wire [`PREG_RANGE] to_dispatch_instr0_prs1,
    output wire [`PREG_RANGE] to_dispatch_instr0_prs2,
    output wire [`PREG_RANGE] to_dispatch_instr0_prd,
    output wire [`PREG_RANGE] to_dispatch_instr0_old_prd,



    //to dispatch instr 1
    output wire                to_dispatch_instr1_valid,
    output wire [ `LREG_RANGE] to_dispatch_instr1_lrs1,
    output wire [ `LREG_RANGE] to_dispatch_instr1_lrs2,
    output wire [ `LREG_RANGE] to_dispatch_instr1_lrd,
    output wire [   `PC_RANGE] to_dispatch_instr1_pc,
    output wire [`INSTR_RANGE] to_dispatch_instr1,

    output wire [              63:0] to_dispatch_instr1_imm,
    output wire                      to_dispatch_instr1_src1_is_reg,
    output wire                      to_dispatch_instr1_src2_is_reg,
    output wire                      to_dispatch_instr1_need_to_wb,
    output wire [    `CX_TYPE_RANGE] to_dispatch_instr1_cx_type,
    output wire                      to_dispatch_instr1_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] to_dispatch_instr1_alu_type,
    output wire [`MULDIV_TYPE_RANGE] to_dispatch_instr1_muldiv_type,
    output wire                      to_dispatch_instr1_is_word,
    output wire                      to_dispatch_instr1_is_imm,
    output wire                      to_dispatch_instr1_is_load,
    output wire                      to_dispatch_instr1_is_store,
    output wire [               3:0] to_dispatch_instr1_ls_size,


    output wire [`PREG_RANGE] to_dispatch_instr1_prs1,
    output wire [`PREG_RANGE] to_dispatch_instr1_prs2,
    output wire [`PREG_RANGE] to_dispatch_instr1_prd,
    output wire [`PREG_RANGE] to_dispatch_instr1_old_prd

);

    //assign through
    assign to_dispatch_instr0_valid       = instr0_valid;
    assign to_dispatch_instr0_lrs1        = instr0_lrs1;
    assign to_dispatch_instr0_lrs2        = instr0_lrs2;
    assign to_dispatch_instr0_lrd         = instr0_lrd;
    assign to_dispatch_instr0_pc          = instr0_pc;
    assign to_dispatch_instr0             = instr0;
    assign to_dispatch_instr0_old_prd     = instr0_rat_prd;


    assign to_dispatch_instr0_imm         = instr0_imm;
    assign to_dispatch_instr0_src1_is_reg = instr0_src1_is_reg;
    assign to_dispatch_instr0_src2_is_reg = instr0_src2_is_reg;
    assign to_dispatch_instr0_need_to_wb  = instr0_need_to_wb;
    assign to_dispatch_instr0_cx_type     = instr0_cx_type;
    assign to_dispatch_instr0_is_unsigned = instr0_is_unsigned;
    assign to_dispatch_instr0_alu_type    = instr0_alu_type;
    assign to_dispatch_instr0_muldiv_type = instr0_muldiv_type;
    assign to_dispatch_instr0_is_word     = instr0_is_word;
    assign to_dispatch_instr0_is_imm      = instr0_is_imm;
    assign to_dispatch_instr0_is_load     = instr0_is_load;
    assign to_dispatch_instr0_is_store    = instr0_is_store;
    assign to_dispatch_instr0_ls_size     = instr0_ls_size;



    assign to_dispatch_instr1_valid       = instr1_valid;
    assign to_dispatch_instr1_lrs1        = instr1_lrs1;
    assign to_dispatch_instr1_lrs2        = instr1_lrs2;
    assign to_dispatch_instr1_lrd         = instr1_lrd;
    assign to_dispatch_instr1_pc          = instr1_pc;
    assign to_dispatch_instr1             = instr1;

    assign to_dispatch_instr1_old_prd     = instr1_rat_prd;


    assign to_dispatch_instr1_imm         = instr1_imm;
    assign to_dispatch_instr1_src1_is_reg = instr1_src1_is_reg;
    assign to_dispatch_instr1_src2_is_reg = instr1_src2_is_reg;
    assign to_dispatch_instr1_need_to_wb  = instr1_need_to_wb;
    assign to_dispatch_instr1_cx_type     = instr1_cx_type;
    assign to_dispatch_instr1_is_unsigned = instr1_is_unsigned;
    assign to_dispatch_instr1_alu_type    = instr1_alu_type;
    assign to_dispatch_instr1_muldiv_type = instr1_muldiv_type;
    assign to_dispatch_instr1_is_word     = instr1_is_word;
    assign to_dispatch_instr1_is_imm      = instr1_is_imm;
    assign to_dispatch_instr1_is_load     = instr1_is_load;
    assign to_dispatch_instr1_is_store    = instr1_is_store;
    assign to_dispatch_instr1_ls_size     = instr1_ls_size;



    wire instr0_lrd_valid;
    wire instr1_lrd_valid;

    assign instr0_lrd_valid = instr0_valid & instr0_need_to_wb;
    assign instr1_lrd_valid = instr1_valid & instr1_need_to_wb;

    wire instr0_lrs1_valid = instr0_valid & instr0_src1_is_reg;
    wire instr1_lrs1_valid = instr1_valid & instr1_src1_is_reg;

    wire instr0_lrs2_valid = instr0_valid & instr0_src2_is_reg;
    wire instr1_lrs2_valid = instr1_valid & instr1_src2_is_reg;


    wire waw_detect = instr0_lrd_valid & instr1_lrd_valid & (instr0_lrd == instr1_lrd);  //jpz note :Will multiple AND gates be generated?

    wire raw_detect_rs1 = instr0_lrd_valid & instr1_lrs1_valid & ((instr0_lrd == instr1_lrs1));
    wire raw_detect_rs2 = instr0_lrd_valid & instr1_lrs2_valid & ((instr0_lrd == instr1_lrs2));


    //req to freelist 
    assign instr0_freelist_req     = instr0_lrd_valid;
    assign instr1_freelist_req     = instr1_lrd_valid;


    //rename register
    assign to_dispatch_instr0_prs1 = instr0_rat_prs1;
    assign to_dispatch_instr0_prs2 = instr0_rat_prs2;
    assign to_dispatch_instr0_prd  = instr0_freelist_resp;

    assign to_dispatch_instr1_prs1 = raw_detect_rs1 ? instr1_freelist_resp : instr1_rat_prs1;
    assign to_dispatch_instr1_prs2 = raw_detect_rs2 ? instr1_freelist_resp : instr1_rat_prs2;
    assign to_dispatch_instr1_prd  = instr1_freelist_resp;



    //modify rat
    assign instr0_rat_rename_valid = instr0_lrd_valid;
    assign instr0_rat_rename_addr  = instr0_lrd;
    assign instr0_rat_rename_data  = instr0_freelist_resp;

    assign instr1_rat_rename_valid = instr1_lrd_valid;
    assign instr1_rat_rename_addr  = instr1_lrd;
    assign instr1_rat_rename_data  = instr1_freelist_resp;


    //assign ready
    assign instr0_ready            = to_dispatch_instr0_ready;
endmodule

/* verilator lint_off UNUSEDSIGNAL */


