`include "defines.sv"
module storeunit (
    input  wire                   clock,
    input  wire                   reset_n,
    input  wire                   issue_valid,
    output wire                   issue_ready,
    input  wire [`ROB_SIZE_LOG:0] robid,
    input  wire [ `SQ_SIZE_LOG:0] sqid,

    input wire [    `SRC_RANGE] src1,
    input wire [    `SRC_RANGE] src2,
    input wire [    `SRC_RANGE] imm,
    input wire [`LS_SIZE_RANGE] ls_size,


    /* --------------------------- output to complete -------------------------- */
    output wire                  st_agu_cmpl_valid,
    output wire [`SQ_SIZE_LOG:0] st_agu_cmpl_sqid,
    output wire                  st_agu_cmpl_mmio,
    output wire [    `SRC_RANGE] st_agu_cmpl_addr,
    output wire [           3:0] st_agu_cmpl_size,
    output wire [           7:0] st_agu_cmpl_mask,


    output wire                   st_dgu_cmpl_valid,
    output wire [     `SRC_RANGE] st_dgu_cmpl_data,
    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                   flush_valid,
    input  wire [`ROB_SIZE_LOG:0] flush_robid


);

    /* -------------------------------------------------------------------------- */
    /*                            store signal generate                            */
    /* -------------------------------------------------------------------------- */

    wire [`RESULT_RANGE] ls_address;
    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );


    wire size_1b;
    wire size_1h;
    wire size_1w;
    wire size_2w;
    assign size_1b = ls_size[0];
    assign size_1h = ls_size[1];
    assign size_1w = ls_size[2];
    assign size_2w = ls_size[3];
    wire [2:0] shift_size;
    wire [7:0] st_mask;

    wire [7:0] write_1b_mask = 8'b1;
    wire [7:0] write_1h_mask = 8'b11;
    wire [7:0] write_1w_mask = 8'b1111;
    wire [7:0] write_2w_mask = 8'b11111111;
    wire       mmio_valid;

    assign shift_size = ls_address[2:0];
    assign st_mask    = size_1b ? write_1b_mask << (shift_size) : size_1h ? write_1h_mask << (shift_size) : size_1w ? write_1w_mask << (shift_size) : write_2w_mask;
    assign mmio_valid = issue_valid & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);


    wire [`RESULT_RANGE] st_data;
    assign st_data           = src2 << {shift_size, 3'b0};

    /* ----------------------------- to store queue ----------------------------- */
    assign st_agu_cmpl_valid = issue_valid;
    assign st_agu_cmpl_mmio  = mmio_valid;
    assign st_agu_cmpl_sqid  = sqid;
    assign st_agu_cmpl_mask  = st_mask;
    assign st_agu_cmpl_size  = ls_size;


    assign st_dgu_cmpl_valid = issue_valid;
    assign st_dgu_cmpl_data  = st_data;


    assign issue_ready       = 1'b1;

endmodule
