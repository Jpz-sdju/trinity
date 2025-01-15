`include "defines.sv"
module tb_top (
    input  wire [3:0] a,
    output wire [3:0] b,

    input wire clock,
    input wire reset_n
);
    assign b[3:0] = a + 4'b1;
    initial begin
        $display("heell");
        // $finish;
    end
    /* verilator lint_off UNDRIVEN */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off PINMISSING */
    
        reg         ibuffer_instr_valid;
    wire        ibuffer_ready;
    reg  [31:0] ibuffer_inst_out;
    reg  [`PC_RANGE] ibuffer_pc_out;

    wire            redirect_valid;
    wire [`PC_RANGE] redirect_target;
    wire            mem_stall;

    // Trinity Bus Signals
    reg                  tbus_index_valid;
    wire                 tbus_index_ready;
    reg  [`RESULT_RANGE] tbus_index;
    reg  [`SRC_RANGE]    tbus_write_data;
    reg  [63:0]          tbus_write_mask;

    wire [`RESULT_RANGE] tbus_read_data;
    wire                 tbus_operation_done;
    wire [`TBUS_OPTYPE_RANGE] tbus_operation_type;

    backend uut (
        .clock(clock),
        .reset_n(reset_n),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_ready(ibuffer_ready),
        .ibuffer_inst_out(ibuffer_inst_out),
        .ibuffer_pc_out(ibuffer_pc_out),

        .redirect_valid(redirect_valid),
        .redirect_target(redirect_target),
        .mem_stall(mem_stall),

        .tbus_index_valid(tbus_index_valid),
        .tbus_index_ready(tbus_index_ready),
        .tbus_index(tbus_index),
        .tbus_write_data(tbus_write_data),
        .tbus_write_mask(tbus_write_mask),

        .tbus_read_data(tbus_read_data),
        .tbus_operation_done(tbus_operation_done),
        .tbus_operation_type(tbus_operation_type)
    );
    /* verilator lint_off PINMISSING */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
endmodule
