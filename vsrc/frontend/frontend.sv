`include "defines.sv"
module frontend (
    input wire clock,
    input wire reset_n,

    //redirect
    input wire             redirect_valid,
    input wire [`PC_RANGE] redirect_target,

    //arb
    output wire                               pc_index_valid,
    input  wire                               pc_index_ready,     // Signal indicating DDR operation is complete
    input  wire                               pc_operation_done,  // Signal indicating PC operation is done
    input  wire [`ICACHE_FETCHWIDTH128_RANGE] pc_read_inst,       // 128-bit input data for instructions
    output wire [                       63:0] pc_index,           // Selected bits [21:3] of the PC for DDR index

    // Inputs for instruction buffer
    input wire fifo_read_en,  // External read enable signal for FIFO

    //to backend
    output wire        ibuffer_instr_valid,
    output wire [31:0] ibuffer_inst_out,
    output wire [`PC_RANGE] ibuffer_pc_out,


    //mem stall: to stop all op in frontend
    input wire mem_stall

);

    wire [63:0] rs1_read_data;
    wire [63:0] rs2_read_data;
    wire [63:0] rd_write_data;

    wire        fifo_empty;


    wire [63:0] src1;
    wire [63:0] src2;
    ifu_top u_ifu_top (
        .clock              (clock),
        .reset_n            (reset_n),
        .boot_addr          (48'h80000000),
        .interrupt_valid    (1'd0),
        .interrupt_addr     (48'd0),
        .redirect_valid     (redirect_valid),
        .redirect_target    (redirect_target),
        .pc_index_valid     (pc_index_valid),
        .pc_index_ready     (pc_index_ready),
        .pc_operation_done  (pc_operation_done),
        .pc_read_inst       (pc_read_inst),
        .fifo_read_en       (fifo_read_en),
        //.clear_ibuffer_ext (clear_ibuffer_ext),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .fifo_empty         (fifo_empty),
        .pc_index           (pc_index),
        .mem_stall          (mem_stall)
    );






endmodule
