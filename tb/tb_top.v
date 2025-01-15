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
    // 输入信号定义
    // ibuffer 输出信号
    reg         ibuffer_instr_valid;  // 指令有效信号
    reg  [31:0] ibuffer_inst_out;  // 指令输出
    reg  [47:0] ibuffer_pc_out;  // 指令地址（PC）
    wire        ibuffer_ready;

    wire        to_issue_instr0_valid;
    wire        to_issue_instr0_ready;
    wire        to_issue_instr1_valid;
    wire        to_issue_instr1_ready;

    // 实例化 ctrlblock 模块
    ctrlblock u_ctrlblock (
        .clock                (clock),
        .reset_n              (reset_n),
        .ibuffer_instr_valid  (ibuffer_instr_valid),
        .ibuffer_inst_out     (ibuffer_inst_out),
        .ibuffer_pc_out       (ibuffer_pc_out),
        .ibuffer_ready        (ibuffer_ready),
        .to_issue_instr0_valid(to_issue_instr0_valid),
        .to_issue_instr0_ready(to_issue_instr0_ready)
    );

    /* verilator lint_off PINMISSING */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
endmodule
