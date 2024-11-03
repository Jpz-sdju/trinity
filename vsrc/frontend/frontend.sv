`include "defines.sv"
module frontend (
    input wire clock,
    input wire reset_n,

    //redirect
    input wire             redirect_valid,
    input wire [`PC_RANGE] redirect_target,

    //arb
    output wire         pc_index_valid,
    input  wire         pc_index_ready,     // Signal indicating DDR operation is complete
    input  wire         pc_operation_done,  // Signal indicating PC operation is done
    input  wire [511:0] pc_read_inst,       // 512-bit input data for instructions
    output wire [ 18:0] pc_index,           // Selected bits [21:3] of the PC for DDR index

    // Inputs for instruction buffer
    input wire fifo_read_en,      // External read enable signal for FIFO
    input wire clear_ibuffer_ext, // External clear signal for ibuffer


    //  Outputs from decoder
    output wire [ 4:0] rs1,
    output wire [ 4:0] rs2,
    output wire [ 4:0] rd,
    output wire [63:0] src1,
    output wire [63:0] src2,
    output wire [63:0] imm,
    output wire        src1_is_reg,
    output wire        src2_is_reg,
    output wire        need_to_wb,
    output wire [ 5:0] cx_type,
    output wire        is_unsigned,
    output wire [ 9:0] alu_type,
    output wire        is_word,
    output wire        is_imm,
    output wire        is_load,
    output wire        is_store,
    output wire [ 3:0] ls_size,
    output wire [12:0] muldiv_type,
    output wire [47:0] decoder_pc_out,
    output wire [47:0] decoder_inst_out,

    //write back enable
    input wire rd_write

);

    wire [31:0] ibuffer_inst_out;
    wire [47:0] ibuffer_pc_out;

    wire [63:0] rs1_read_data;
    wire [63:0] rs2_read_data;
    wire [63:0] rd_write_data;

    wire        fifo_empty;

    ifu_top u_ifu_top (
        .clock            (clock),
        .reset_n          (reset_n),
        .boot_addr        (48'h80000000),
        .interrupt_valid  (1'd0),
        .interrupt_addr   (48'd0),
        .redirect_valid   (1'd0),
        .redirect_target  (48'd0),
        .pc_index_valid   (pc_index_valid),
        .pc_index_ready   (pc_index_ready),
        .pc_operation_done(pc_operation_done),
        .pc_read_inst     (pc_read_inst),
        .fifo_read_en     (fifo_read_en),
        .clear_ibuffer_ext(clear_ibuffer_ext),
        .ibuffer_inst_out (ibuffer_inst_out),
        .ibuffer_pc_out   (ibuffer_pc_out),
        .fifo_empty       (fifo_empty),
        .pc_index         (pc_index)
    );


    decoder u_decoder (
        .clock           (clock),
        .reset_n         (reset_n),
        .fifo_empty      (fifo_empty),
        .ibuffer_inst_out(ibuffer_inst_out),
        .ibuffer_pc_out  (ibuffer_pc_out),
        .rs1_read_data   (rs1_read_data),
        .rs2_read_data   (rs2_read_data),
        .rs1             (rs1),
        .rs2             (rs2),
        .rd              (rd),
        .src1            (src1),
        .src2            (src2),
        .imm             (imm),
        .src1_is_reg     (src1_is_reg),
        .src2_is_reg     (src2_is_reg),
        .need_to_wb      (need_to_wb),
        .cx_type         (cx_type),
        .is_unsigned     (is_unsigned),
        .alu_type        (alu_type),
        .is_word         (is_word),
        .is_imm          (is_imm),
        .is_load         (is_load),
        .is_store        (is_store),
        .ls_size         (ls_size),
        .muldiv_type     (muldiv_type),
        .decoder_pc_out  (decoder_pc_out),
        .decoder_inst_out(decoder_inst_out)



    );



    regfile64 u_regfile64 (
        .clock        (clock),
        .reset_n      (reset_n),
        .rs1          (rs1),
        .rs2          (rs2),
        .rd           (rd),
        .rd_write_data(rd_write_data),
        .rd_write     (rd_write),
        .rs1_read_data(rs1_read_data),
        .rs2_read_data(rs2_read_data)
    );

endmodule
