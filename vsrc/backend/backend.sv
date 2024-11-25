`include "defines.sv"
module backend (
    input wire               clock,
    input wire               reset_n,
    input wire [`LREG_RANGE] rs1,
    input wire [`LREG_RANGE] rs2,
    input wire [`LREG_RANGE] rd,
    input wire [ `SRC_RANGE] src1,
    input wire [ `SRC_RANGE] src2,
    input wire [ `SRC_RANGE] imm,
    input wire               src1_is_reg,
    input wire               src2_is_reg,
    input wire               need_to_wb,
    input wire [    `CX_TYPE_RANGE] cx_type,
    input wire                      is_unsigned,
    input wire [   `ALU_TYPE_RANGE] alu_type,
    input wire                      is_word,
    input wire                      is_load,
    input wire                      is_imm,
    input wire                      is_store,
    input wire [               3:0] ls_size,
    input wire [`MULDIV_TYPE_RANGE] muldiv_type,
    input wire               instr_valid,
    input wire [         `PC_RANGE] pc,
    input wire [      `INSTR_RANGE] instr,
    //write back lreg 
    output wire                 regfile_write_valid,
    output wire [`RESULT_RANGE] regfile_write_data,
    output wire [          4:0] regfile_write_rd,
    //redirect
    output wire             redirect_valid,
    output wire [`PC_RANGE] redirect_target,
    //stall pipeline
    output wire mem_stall,

    /*
        TO L1 D$/MEM
    */

    // LSU store Channel Inputs and Outputs
    output wire        opstore_index_valid,    // Valid signal for opstore_index
    output wire [18:0] opstore_index,          // 19-bit output for opstore_index (Channel 2)
    input  reg         opstore_index_ready,    // Ready signal for opstore channel
    output wire [63:0] opstore_write_mask,     // Write Mask for opstore channel
    output wire [63:0] opstore_write_data,     // 64-bit data output for opstore channel write
    input  wire        opstore_operation_done,

    // LSU load Channel outputs and inputs
    output wire        opload_index_valid,     // Valid signal for opload_index
    output wire [18:0] opload_index,           // 19-bit output for opload_index (Channel 3)
    input  reg         opload_index_ready,     // Ready signal for lw channel
    input  reg  [63:0] opload_read_data,       // input read data for lw channel
    input  wire        opload_operation_done,
    // output instrcnt pulse
    output reg         flop_commit_valid,
    output wire [  `LREG_RANGE] exe_byp_rd,
    output wire                 exe_byp_need_to_wb,
    output wire [`RESULT_RANGE] exe_byp_result
);

//input mux logic : issue intsr to exu or mem
    reg                      instr_valid_to_mem;
    reg [         `PC_RANGE] pc_to_mem;
    reg [      `INSTR_RANGE] instr_to_mem;

    reg                      instr_valid_to_exu;
    reg [         `PC_RANGE] pc_to_exu;
    reg [      `INSTR_RANGE] instr_to_exu;

//output mux logic : collect exu/mem result 
    //pexe2wb stands for pipereg_exe2wb
    reg                       instr_valid_to_pexe2wb;
    reg [         `PC_RANGE]  pc_to_pexe2wb;
    reg [      `INSTR_RANGE]  instr_to_pexe2wb;
    //exu output valid,pc,instr
    reg                       exu_instr_valid_out;
    reg [         `PC_RANGE]  exu_pc_out;
    reg [      `INSTR_RANGE]  exu_instr_out;
    //mem output valid,pc,instr
    reg                       mem_instr_valid_out;
    reg [         `PC_RANGE]  mem_pc_out;
    reg [      `INSTR_RANGE]  mem_instr_out;

//exu internal output:
    wire exu_redirect_valid;
    //when redirect hit mem_stall ,could cause false redirect fetch
    assign redirect_valid = exu_redirect_valid & instr_valid_to_exu & ~mem_stall;
    wire [     `RESULT_RANGE] alu_result   ;
    wire [     `RESULT_RANGE] bju_result   ;
    wire [     `RESULT_RANGE] muldiv_result;
    wire [     `RESULT_RANGE] ex_byp_result;
//mem internal output:
    wire [     `RESULT_RANGE] mem_opload_read_data_wb;
    wire [     `RESULT_RANGE] mem_ls_address;
//pipereg_exe2wb internal output:    
    wire                      wb_valid;
    wire [       `LREG_RANGE] wb_rs1;
    wire [       `LREG_RANGE] wb_rs2;
    wire [       `LREG_RANGE] wb_rd;
    wire [        `SRC_RANGE] wb_src1;
    wire [        `SRC_RANGE] wb_src2;
    wire [        `SRC_RANGE] wb_imm;
    wire                      wb_src1_is_reg;
    wire                      wb_src2_is_reg;
    wire                      wb_need_to_wb;
    wire [    `CX_TYPE_RANGE] wb_cx_type;
    wire                      wb_is_unsigned;
    wire [   `ALU_TYPE_RANGE] wb_alu_type;
    wire                      wb_is_word;
    wire                      wb_is_load;
    wire                      wb_is_imm;
    wire                      wb_is_store;
    wire [               3:0] wb_ls_size;
    wire [`MULDIV_TYPE_RANGE] wb_muldiv_type;
    wire [         `PC_RANGE] wb_pc;
    wire [      `INSTR_RANGE] wb_instr;
    wire [     `RESULT_RANGE] wb_ls_address;
    wire [     `RESULT_RANGE] wb_alu_result;
    wire [     `RESULT_RANGE] wb_bju_result;
    wire [     `RESULT_RANGE] wb_muldiv_result;
    wire [     `RESULT_RANGE] wb_opload_read_data_wb;


    always @(*) begin
        if(is_load | is_store)begin
            instr_valid_to_exu = 1'b0;
            pc_to_exu = 0;
            instr_to_exu = 0;
            instr_valid_to_mem = instr_valid;
            pc_to_mem = pc;
            instr_to_mem = instr;
        end else begin
            instr_valid_to_exu = instr_valid;
            pc_to_exu = pc;
            instr_to_exu = instr;
            instr_valid_to_mem = 1'b0;
            pc_to_mem = 0;
            instr_to_mem = 0;            
        end
    end

//can use instr_valid to control a clock gate here to save power
exu u_exu(
    .clock             (clock             ),
    .reset_n           (reset_n           ),
    .rs1               (rs1               ),
    .rs2               (rs2               ),
    .rd                (rd                ),
    .src1              (src1              ),
    .src2              (src2              ),
    .imm               (imm               ),
    .src1_is_reg       (src1_is_reg       ),
    .src2_is_reg       (src2_is_reg       ),
    .need_to_wb        (need_to_wb        ),
    .cx_type           (cx_type           ),
    .is_unsigned       (is_unsigned       ),
    .alu_type          (alu_type          ),
    .is_word           (is_word           ),
    .is_load           (is_load           ),
    .is_imm            (is_imm            ),
    .is_store          (is_store          ),
    .ls_size           (ls_size           ),
    .muldiv_type       (muldiv_type       ),
    .instr_valid       (instr_valid_to_exu       ),
    .pc                (pc_to_exu                ),
    .instr             (instr_to_exu             ),
    //output
    .instr_valid_out   (exu_instr_valid_out   ),
    .pc_out            (exu_pc_out            ),
    .instr_out         (exu_instr_out         ),
    .alu_result        (alu_result        ),
    .bju_result        (bju_result        ),
    .muldiv_result     (muldiv_result     ),
    .redirect_valid    (exu_redirect_valid    ),
    .redirect_target   (redirect_target   ),
    //.ex_byp_rd         (ex_byp_rd         ),
    //.ex_byp_need_to_wb (ex_byp_need_to_wb ),
    .ex_byp_result     (ex_byp_result     )
);

//can use instr_valid to control a clock gate here to save power
mem u_mem(
    .clock                  (clock                  ),
    .reset_n                (reset_n                ),
    .is_load                (is_load                ),
    .is_store               (is_store               ),
    .is_unsigned            (is_unsigned            ),
    .imm                    (imm                    ),
    .src1                   (src1                   ),
    .src2                   (src2                   ),
    .ls_size                (ls_size                ),
    .instr_valid            (instr_valid_to_mem            ),
    .pc                     (pc_to_mem                     ),
    .instr                  (instr_to_mem                  ),
    .opload_index_valid     (opload_index_valid     ),
    .opload_index_ready     (opload_index_ready     ),
    .opload_index           (opload_index           ),
    .opload_operation_done  (opload_operation_done  ),
    .opload_read_data       (opload_read_data       ),
    .opstore_index_valid    (opstore_index_valid    ),
    .opstore_index_ready    (opstore_index_ready    ),
    .opstore_index          (opstore_index          ),
    .opstore_write_data     (opstore_write_data     ),
    .opstore_write_mask     (opstore_write_mask     ),
    .opstore_operation_done (opstore_operation_done ),
    .instr_valid_out        (mem_instr_valid_out        ),
    .pc_out                 (mem_pc_out                 ),
    .instr_out              (mem_instr_out              ),
    .ls_address             (mem_ls_address                 ),
    .opload_read_data_wb    (mem_opload_read_data_wb    ),
    .mem_stall              (mem_stall              )
);


    always @(*) begin
        if(mem_instr_valid_out)begin
            instr_valid_to_pexe2wb = 1'b1;
            pc_to_pexe2wb = mem_pc_out;
            instr_to_pexe2wb = mem_instr_out;
        end else if (exu_instr_valid_out) begin
            instr_valid_to_pexe2wb = 1'b1;
            pc_to_pexe2wb = exu_pc_out;
            instr_to_pexe2wb = exu_instr_out;
        end else begin
            instr_valid_to_pexe2wb = 1'b0;            
            pc_to_pexe2wb = 0;
            instr_to_pexe2wb = 0;
        end
    end

    //bypass logic
    assign exe_byp_rd = rd;
    assign exe_byp_need_to_wb = need_to_wb & instr_valid & ((|alu_type) | (|muldiv_type) | (|cx_type) | is_load);
    assign exe_byp_result = exu_instr_valid_out? ex_byp_result : mem_instr_valid_out? mem_opload_read_data_wb : 64'hDEADBEEF;


    pipe_reg u_pipe_reg_exe2wb (
        .clock                  (clock),
        .reset_n                (reset_n),
        .stall                  (1'b0),
        .redirect_flush         (1'b0),
        //pipe input meterial
        .rs1                    (rs1),
        .rs2                    (rs2),
        .rd                     (rd),
        .src1                   (src1),
        .src2                   (src2),
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
        //valid,pc,instr
        .instr_valid            (instr_valid_to_pexe2wb & ~mem_stall),
        .pc                     (pc_to_pexe2wb),
        .instr                  (instr_to_pexe2wb),
        //result
        .ls_address             (mem_ls_address),
        .alu_result             (alu_result),
        .bju_result             (bju_result),
        .muldiv_result          (muldiv_result),
        .opload_read_data_wb    (mem_opload_read_data_wb),//fill the load wb data
        //piped values
        .out_rs1                (wb_rs1),
        .out_rs2                (wb_rs2),
        .out_rd                 (wb_rd),
        .out_src1               (wb_src1),
        .out_src2               (wb_src2),
        .out_imm                (wb_imm),
        .out_src1_is_reg        (wb_src1_is_reg),
        .out_src2_is_reg        (wb_src2_is_reg),
        .out_need_to_wb         (wb_need_to_wb),
        .out_cx_type            (wb_cx_type),
        .out_is_unsigned        (wb_is_unsigned),
        .out_alu_type           (wb_alu_type),
        .out_is_word            (wb_is_word),
        .out_is_load            (wb_is_load),
        .out_is_imm             (wb_is_imm),
        .out_is_store           (wb_is_store),
        .out_ls_size            (wb_ls_size),
        .out_muldiv_type        (wb_muldiv_type),
        .out_instr_valid        (wb_valid),
        .out_pc                 (wb_pc),
        .out_instr              (wb_instr),
        .out_ls_address         (wb_ls_address),
        .out_alu_result         (wb_alu_result),
        .out_bju_result         (wb_bju_result),
        .out_muldiv_result      (wb_muldiv_result),
        .out_opload_read_data_wb(wb_opload_read_data_wb)

    );

    //if mmio load,dont not to modify regfile to pass difftest
    assign regfile_write_valid = wb_valid & wb_need_to_wb & ~(wb_mmio_valid & wb_is_load);
    assign regfile_write_data  = (|wb_alu_type) ? wb_alu_result : (|wb_cx_type) ? wb_bju_result : (|wb_muldiv_type) ? wb_muldiv_result : wb_is_load ? wb_opload_read_data_wb : 64'hDEADBEEF;
    assign regfile_write_rd    = wb_rd;

    wire   commit_valid = ((|wb_alu_type) | (|wb_cx_type) | (|wb_muldiv_type) | wb_is_load | wb_is_store) & wb_valid;

    // reg                 flop_commit_valid;
    reg                 flop_wb_need_to_wb;
    reg  [         4:0] flop_wb_rd;
    reg  [   `PC_RANGE] flop_wb_pc;
    reg  [`INSTR_RANGE] flop_wb_instr;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_commit_valid <= 'b0;
        end else begin
            flop_commit_valid <= commit_valid;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_need_to_wb <= 'b0;
        end else begin
            flop_wb_need_to_wb <= regfile_write_valid;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_rd <= 'b0;
        end else begin
            flop_wb_rd <= wb_rd;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_pc <= 'b0;
        end else begin
            flop_wb_pc <= wb_pc;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_wb_instr <= 'b0;
        end else begin
            flop_wb_instr <= wb_instr;
        end
    end

    wire wb_mmio_valid = (wb_is_load | wb_is_store) & wb_valid & ('h30000000 <= wb_ls_address) & (wb_ls_address <= 'h40700000);
    reg  flop_mmio_valid;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flop_mmio_valid <= 'b0;
        end else begin
            flop_mmio_valid <= wb_mmio_valid;
        end
    end

    DifftestInstrCommit u_DifftestInstrCommit (
        .clock     (clock),
        .enable    (flop_commit_valid),
        .io_valid  ('b0),                 //unuse!!!!
        .io_skip   (flop_mmio_valid),
        .io_isRVC  (1'b0),
        .io_rfwen  (flop_wb_need_to_wb),
        .io_fpwen  (1'b0),
        .io_vecwen (1'b0),
        .io_wpdest (flop_wb_rd),
        .io_wdest  (flop_wb_rd),
        .io_pc     (flop_wb_pc),
        .io_instr  (flop_wb_instr),
        .io_robIdx ('b0),
        .io_lqIdx  ('b0),
        .io_sqIdx  ('b0),
        .io_isLoad ('b0),
        .io_isStore('b0),
        .io_nFused ('b0),
        .io_special('b0),
        .io_coreid ('b0),
        .io_index  ('b0)
    );





endmodule