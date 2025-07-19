module rename (
    //instr 0 from decoder after pipereg
    input  wire               instr0_valid,
    output wire               instr0_ready,
    input  wire [       31:0] instr0_instr,
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
    input wire                      instr0_predicttaken,
    input wire [              31:0] instr0_predicttarget,

    //instr 1 from decoder after pipereg
    input  wire               instr1_valid,
    output wire               instr1_ready,
    input  wire [       31:0] instr1_instr,
    input  wire [`LREG_RANGE] instr1_lrs1,
    input  wire [`LREG_RANGE] instr1_lrs2,
    input  wire [`LREG_RANGE] instr1_lrd,
    input  wire [  `PC_RANGE] instr1_pc,

    input wire [              63:0] instr1_imm,
    input wire                      instr1_src1_is_reg,
    input wire                      instr1_src2_is_reg,
    input wire                      instr1_need_to_wb,
    input wire [    `CX_TYPE_RANGE] instr1_cx_type,
    input wire                      instr1_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] instr1_alu_type,
    input wire [`MULDIV_TYPE_RANGE] instr1_muldiv_type,

    input wire        instr1_is_word,
    input wire        instr1_is_imm,
    input wire        instr1_is_load,
    input wire        instr1_is_store,
    input wire [ 3:0] instr1_ls_size,
    input wire        instr1_predicttaken,
    input wire [31:0] instr1_predicttarget,

    /* --------------------------- port with spec_rat --------------------------- */
    //instr0
    // 3 read port to spec_rat for instr0
    output wire               rn2specrat_instr0_lrs1_rden,
    output wire [`LREG_RANGE] rn2specrat_instr0_lrs1,
    output wire               rn2specrat_instr0_lrs2_rden,
    output wire [`LREG_RANGE] rn2specrat_instr0_lrs2,
    output wire               rn2specrat_instr0_lrd_rden,
    output wire [`LREG_RANGE] rn2specrat_instr0_lrd,
    //instr0 read result
    input  wire [`PREG_RANGE] specrat2rn_instr0prs1,
    input  wire [`PREG_RANGE] specrat2rn_instr0prs2,
    input  wire [`PREG_RANGE] specrat2rn_instr0prd,
    //rename write port to spec_rat : to write rd new physical reg number of instr0
    output wire               rn2specrat_instr0_lrd_wren,
    output wire [`LREG_RANGE] rn2specrat_instr0_lrd_wraddr,
    output wire [`PREG_RANGE] rn2specrat_instr0_lrd_wrdata,
    // instr1
    // 3 read port to spec_rat for instr1    
    output wire               rn2specrat_instr1_lrs1_rden,
    output wire [`LREG_RANGE] rn2specrat_instr1_lrs1,
    output wire               rn2specrat_instr1_lrs2_rden,
    output wire [`LREG_RANGE] rn2specrat_instr1_lrs2,
    output wire               rn2specrat_instr1_lrd_rden,
    output wire [`LREG_RANGE] rn2specrat_instr1_lrd,
    //instr1 read result
    input  wire [`PREG_RANGE] specrat2rn_instr1prs1,
    input  wire [`PREG_RANGE] specrat2rn_instr1prs2,
    input  wire [`PREG_RANGE] specrat2rn_instr1prd,
    //rename write port to spec_rat : to write rd new physical reg number of instr1 
    output wire               rn2specrat_instr1_lrd_wren,
    output wire [`LREG_RANGE] rn2specrat_instr1_lrd_wraddr,
    output wire [`PREG_RANGE] rn2specrat_instr1_lrd_wrdata,

    /* --------------------------- port with freelist --------------------------- */
    // 2 read port to freelist
    output wire               rn2fl_instr0_lrd_valid,
    input  wire [`PREG_RANGE] fl2rn_instr0prd,
    output wire               rn2fl_instr1_lrd_valid,
    input  wire [`PREG_RANGE] fl2rn_instr1prd,

    //flush signal
    input  wire                      flush_valid,
    /* ---------------------------- output to pipereg --------------------------- */
    //prs1/prs2/prd
    output wire [       `PREG_RANGE] rn2pipe_instr0_prs1,
    output wire [       `PREG_RANGE] rn2pipe_instr0_prs2,
    output wire [       `PREG_RANGE] rn2pipe_instr0_prd,
    //other info of instr0
    output wire                      rn2pipe_instr0_valid,
    input  wire                      rn2pipe_instr0_ready,
    output wire [       `LREG_RANGE] rn2pipe_instr0_lrs1,
    output wire [       `LREG_RANGE] rn2pipe_instr0_lrs2,
    output wire [       `LREG_RANGE] rn2pipe_instr0_lrd,
    output wire [         `PC_RANGE] rn2pipe_instr0_pc,
    output wire [      `INSTR_RANGE] rn2pipe_instr0_instr,
    output wire [              63:0] rn2pipe_instr0_imm,
    output wire                      rn2pipe_instr0_src1_is_reg,
    output wire                      rn2pipe_instr0_src2_is_reg,
    output wire                      rn2pipe_instr0_need_to_wb,
    output wire [    `CX_TYPE_RANGE] rn2pipe_instr0_cx_type,
    output wire                      rn2pipe_instr0_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] rn2pipe_instr0_alu_type,
    output wire [`MULDIV_TYPE_RANGE] rn2pipe_instr0_muldiv_type,
    output wire                      rn2pipe_instr0_is_word,
    output wire                      rn2pipe_instr0_is_imm,
    output wire                      rn2pipe_instr0_is_load,
    output wire                      rn2pipe_instr0_is_store,
    output wire [               3:0] rn2pipe_instr0_ls_size,
    output wire [       `PREG_RANGE] rn2pipe_instr0_old_prd,
    output wire                      rn2pipe_instr0_predicttaken,
    output wire [              31:0] rn2pipe_instr0_predicttarget,


    //prs1/prs2/prd
    output wire [       `PREG_RANGE] rn2pipe_instr1_prs1,
    output wire [       `PREG_RANGE] rn2pipe_instr1_prs2,
    output wire [       `PREG_RANGE] rn2pipe_instr1_prd,
    //other info of instr1
    output wire                      rn2pipe_instr1_valid,
    input  wire                      pipe2rn_instr1_ready,
    output wire [       `LREG_RANGE] rn2pipe_instr1_lrs1,
    output wire [       `LREG_RANGE] rn2pipe_instr1_lrs2,
    output wire [       `LREG_RANGE] rn2pipe_instr1_lrd,
    output wire [         `PC_RANGE] rn2pipe_instr1_pc,
    output wire [      `INSTR_RANGE] rn2pipe_instr1_instr,
    output wire [              63:0] rn2pipe_instr1_imm,
    output wire                      rn2pipe_instr1_src1_is_reg,
    output wire                      rn2pipe_instr1_src2_is_reg,
    output wire                      rn2pipe_instr1_need_to_wb,
    output wire [    `CX_TYPE_RANGE] rn2pipe_instr1_cx_type,
    output wire                      rn2pipe_instr1_is_unsigned,
    output wire [   `ALU_TYPE_RANGE] rn2pipe_instr1_alu_type,
    output wire [`MULDIV_TYPE_RANGE] rn2pipe_instr1_muldiv_type,
    output wire                      rn2pipe_instr1_is_word,
    output wire                      rn2pipe_instr1_is_imm,
    output wire                      rn2pipe_instr1_is_load,
    output wire                      rn2pipe_instr1_is_store,
    output wire [               3:0] rn2pipe_instr1_ls_size,
    output wire [       `PREG_RANGE] rn2pipe_instr1_old_prd,
    output wire                      rn2pipe_instr1_predicttaken,
    output wire [              31:0] rn2pipe_instr1_predicttarget,
    /* ------------------------------ from freelist ----------------------------- */
    input  wire                      freelist_can_alloc

);

    assign instr0_ready = rn2pipe_instr0_ready & freelist_can_alloc;
    //assign instr1_ready = pipe2rn_instr1_ready;

    /* --------------------------- determine if 6 reg is valid or not -------------------------- */
    wire instr0_lrs1_valid = instr0_valid & instr0_src1_is_reg;
    wire instr0_lrs2_valid = instr0_valid & instr0_src2_is_reg;
    wire instr0_lrd_valid = instr0_valid & instr0_need_to_wb;

    wire instr1_lrs1_valid = instr1_valid & instr1_src1_is_reg;
    wire instr1_lrs2_valid = instr1_valid & instr1_src2_is_reg;
    wire instr1_lrd_valid = instr1_valid & instr1_need_to_wb;


    /* --------------------------- hazardchecker logic -------------------------- */

    wire raw_hazard_rs1;
    wire raw_hazard_rs2;
    wire waw_hazard;

    hazardchecker u_hazardchecker (
        .instr0_lrs1      (instr0_lrs1),
        .instr0_lrs1_valid(instr0_lrs1_valid),
        .instr0_lrs2      (instr0_lrs2),
        .instr0_lrs2_valid(instr0_lrs2_valid),
        .instr0_lrd       (instr0_lrd),
        .instr0_lrd_valid (instr0_lrd_valid),
        .instr1_lrs1      (instr1_lrs1),
        .instr1_lrs1_valid(instr1_lrs1_valid),
        .instr1_lrs2      (instr1_lrs2),
        .instr1_lrs2_valid(instr1_lrs2_valid),
        .instr1_lrd       (instr1_lrd),
        .instr1_lrd_valid (instr1_lrd_valid),
        .raw_hazard_rs1   (raw_hazard_rs1),     //output //when truly 2 instr comes, this need to send to int_isq to set sleep bit = 1
        .raw_hazard_rs2   (raw_hazard_rs2),     //output 
        .waw_hazard       (waw_hazard)          //output
    );


    /* -------------------- read 6 physical reg number from spec_rat when valid-------------------- */
    //6 read req:
    assign rn2specrat_instr0_lrs1_rden  = instr0_lrs1_valid;
    assign rn2specrat_instr0_lrs1       = instr0_lrs1;
    assign rn2specrat_instr0_lrs2_rden  = instr0_lrs2_valid;
    assign rn2specrat_instr0_lrs2       = instr0_lrs2;
    assign rn2specrat_instr0_lrd_rden   = instr0_lrd_valid;
    assign rn2specrat_instr0_lrd        = instr0_lrd;
    assign rn2specrat_instr1_lrs1_rden  = instr1_lrs1_valid;
    assign rn2specrat_instr1_lrs1       = instr1_lrs1;
    assign rn2specrat_instr1_lrs2_rden  = instr1_lrs2_valid;
    assign rn2specrat_instr1_lrs2       = instr1_lrs2;
    assign rn2specrat_instr1_lrd_rden   = instr1_lrd_valid;
    assign rn2specrat_instr1_lrd        = instr1_lrd;





    /* ------- read 2 rd available free physical reg number from freelist ------- */
    //fl2rn stands for "freelist to rename"
    //read req:
    //handshake means rename need to fetch 2 free physical reg number from freelist
    //when flush, no need to fetch
    assign rn2fl_instr0_lrd_valid       = instr0_lrd_valid && rn2pipe_instr0_ready && ~flush_valid;
    assign rn2fl_instr1_lrd_valid       = instr1_lrd_valid && ~flush_valid;  //&& pipe2rn_instr1_ready;//issue queue accept instr1 abililty due to implement future



    /* ------------------------------ rename and output renamed physical number of 6 reg to dispatch ------------------------------ */

    // raw_hazard_rs1 situation:   use freelist result to rename and output to disp          write specrat
    // instr0 : add r1,r2,r3   ->  add p51,p42,p43                                           : r1->p51
    // instr1 : add r4,r1,r3   ->  add p52,p51,p43                                           : r4->p52
    //                          
    // waw_hazard situation:                                                                 //only need to write back instr1 rd preg to specrat
    // instr0 : add r1,r2,r3   ->  add p51,p42,p43                                           :
    // instr1 : add r1,r2,r3   ->  add p52,p42,p43                                           : r1->p52
    //

    assign rn2pipe_instr0_prs1          = specrat2rn_instr0prs1;
    assign rn2pipe_instr0_prs2          = specrat2rn_instr0prs2;
    assign rn2pipe_instr0_prd           = fl2rn_instr0prd;
    assign rn2pipe_instr1_prs1          = raw_hazard_rs1 ? fl2rn_instr0prd : specrat2rn_instr1prs1;
    assign rn2pipe_instr1_prs2          = raw_hazard_rs2 ? fl2rn_instr0prd : specrat2rn_instr1prs2;
    assign rn2pipe_instr1_prd           = fl2rn_instr1prd;


    /* ------------ write renamed physical number of 2 rd to spec_rat ----------- */

    assign rn2specrat_instr0_lrd_wren   = waw_hazard ? 0 : instr0_lrd_valid & rn2pipe_instr0_ready & freelist_can_alloc;
    assign rn2specrat_instr0_lrd_wraddr = instr0_lrd;
    assign rn2specrat_instr0_lrd_wrdata = fl2rn_instr0prd;

    assign rn2specrat_instr1_lrd_wren   = instr1_lrd_valid;
    assign rn2specrat_instr1_lrd_wraddr = instr1_lrd;
    assign rn2specrat_instr1_lrd_wrdata = fl2rn_instr1prd;


    /* --------------------------- other info of instr -------------------------- */
    assign rn2pipe_instr0_valid         = instr0_valid & freelist_can_alloc;
    assign rn2pipe_instr0_lrs1          = instr0_lrs1;
    assign rn2pipe_instr0_lrs2          = instr0_lrs2;
    assign rn2pipe_instr0_lrd           = instr0_lrd;
    assign rn2pipe_instr0_pc            = instr0_pc;
    assign rn2pipe_instr0_instr         = instr0_instr;
    assign rn2pipe_instr0_old_prd       = specrat2rn_instr0prd;

    assign rn2pipe_instr0_imm           = instr0_imm;
    assign rn2pipe_instr0_src1_is_reg   = instr0_src1_is_reg;
    assign rn2pipe_instr0_src2_is_reg   = instr0_src2_is_reg;
    assign rn2pipe_instr0_need_to_wb    = instr0_need_to_wb;
    assign rn2pipe_instr0_cx_type       = instr0_cx_type;
    assign rn2pipe_instr0_is_unsigned   = instr0_is_unsigned;
    assign rn2pipe_instr0_alu_type      = instr0_alu_type;
    assign rn2pipe_instr0_muldiv_type   = instr0_muldiv_type;
    assign rn2pipe_instr0_is_word       = instr0_is_word;
    assign rn2pipe_instr0_is_imm        = instr0_is_imm;
    assign rn2pipe_instr0_is_load       = instr0_is_load;
    assign rn2pipe_instr0_is_store      = instr0_is_store;
    assign rn2pipe_instr0_ls_size       = instr0_ls_size;
    assign rn2pipe_instr0_predicttaken  = instr0_predicttaken;
    assign rn2pipe_instr0_predicttarget = instr0_predicttarget;




    assign rn2pipe_instr1_valid         = instr1_valid;
    assign rn2pipe_instr1_lrs1          = instr1_lrs1;
    assign rn2pipe_instr1_lrs2          = instr1_lrs2;
    assign rn2pipe_instr1_lrd           = instr1_lrd;
    assign rn2pipe_instr1_pc            = instr1_pc;
    assign rn2pipe_instr1_instr         = instr1_instr;
    assign rn2pipe_instr1_old_prd       = specrat2rn_instr1prd;

    assign rn2pipe_instr1_imm           = instr1_imm;
    assign rn2pipe_instr1_src1_is_reg   = instr1_src1_is_reg;
    assign rn2pipe_instr1_src2_is_reg   = instr1_src2_is_reg;
    assign rn2pipe_instr1_need_to_wb    = instr1_need_to_wb;
    assign rn2pipe_instr1_cx_type       = instr1_cx_type;
    assign rn2pipe_instr1_is_unsigned   = instr1_is_unsigned;
    assign rn2pipe_instr1_alu_type      = instr1_alu_type;
    assign rn2pipe_instr1_muldiv_type   = instr1_muldiv_type;
    assign rn2pipe_instr1_is_word       = instr1_is_word;
    assign rn2pipe_instr1_is_imm        = instr1_is_imm;
    assign rn2pipe_instr1_is_load       = instr1_is_load;
    assign rn2pipe_instr1_is_store      = instr1_is_store;
    assign rn2pipe_instr1_ls_size       = instr1_ls_size;
    assign rn2pipe_instr1_predicttaken  = instr1_predicttaken;
    assign rn2pipe_instr1_predicttarget = instr1_predicttarget;


endmodule
