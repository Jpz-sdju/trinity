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
    // 输入信号定义
    reg                      instr0_enq_valid;
    reg  [             31:0] instr0;
    reg  [      `LREG_RANGE] instr0_lrs1;
    reg  [      `LREG_RANGE] instr0_lrs2;
    reg  [      `LREG_RANGE] instr0_lrd;
    reg  [      `PREG_RANGE] instr0_prd;
    reg  [      `PREG_RANGE] instr0_old_prd;
    reg  [             47:0] instr0_pc;

    reg                      instr1_enq_valid;
    reg  [             31:0] instr1;
    reg  [      `LREG_RANGE] instr1_lrs1;
    reg  [      `LREG_RANGE] instr1_lrs2;
    reg  [      `LREG_RANGE] instr1_lrd;
    reg  [      `PREG_RANGE] instr1_prd;
    reg  [      `PREG_RANGE] instr1_old_prd;
    reg  [             47:0] instr1_pc;

    reg                      writebacks0_valid;
    reg                      writebacks0_robflag;
    reg  [`ROB_SIZE_LOG-1:0] writebacks0_robidx;
    reg                      writebacks0_need_to_wb;

    reg                      writebacks1_valid;
    reg                      writebacks1_robflag;
    reg  [`ROB_SIZE_LOG-1:0] writebacks1_robidx;
    reg                      writebacks1_need_to_wb;

    reg                      writebacks2_valid;
    reg                      writebacks2_robflag;
    reg  [`ROB_SIZE_LOG-1:0] writebacks2_robidx;
    reg                      writebacks2_need_to_wb;

    

    reg                      redirect_valid;
    reg  [             63:0] redirect_target;
    reg                      redirect_robflag;
    reg  [`ROB_SIZE_LOG-1:0] redirect_robidx;

    // 输出信号定义
    wire                     enq_robidx_flag;
    wire [`ROB_SIZE_LOG-1:0] enq_robidx;

    wire                     commits0_valid;
    wire [      `PREG_RANGE] commits0_old_prd;
    wire [      `LREG_RANGE] commits0_lrd;
    wire [      `PREG_RANGE] commits0_prd;
    wire [             31:0] commits0_instr;
    wire [             47:0] commits0_pc;

    wire                     commits1_valid;
    wire [      `PREG_RANGE] commits1_old_prd;
    wire [      `LREG_RANGE] commits1_lrd;
    wire [      `PREG_RANGE] commits1_prd;
    wire [             31:0] commits1_instr;
    wire [             47:0] commits1_pc;

    // 实例化 rob 模块
    rob u_rob (
        .clock           (clock),
        .reset_n         (reset_n),
        .instr0_enq_valid(instr0_enq_valid),
        .instr0          (instr0),
        .instr0_lrs1     (instr0_lrs1),
        .instr0_lrs2     (instr0_lrs2),
        .instr0_lrd      (instr0_lrd),
        .instr0_prd      (instr0_prd),
        .instr0_old_prd  (instr0_old_prd),
        .instr0_pc       (instr0_pc),

        .instr1_enq_valid(instr1_enq_valid),
        .instr1          (instr1),
        .instr1_lrs1     (instr1_lrs1),
        .instr1_lrs2     (instr1_lrs2),
        .instr1_lrd      (instr1_lrd),
        .instr1_prd      (instr1_prd),
        .instr1_old_prd  (instr1_old_prd),
        .instr1_pc       (instr1_pc),

        .enq_robidx_flag(enq_robidx_flag),
        .enq_robidx     (enq_robidx),

        .writebacks0_valid     (writebacks0_valid),
        .writebacks0_robflag   (writebacks0_robflag),
        .writebacks0_robidx    (writebacks0_robidx),
        .writebacks0_need_to_wb(writebacks0_need_to_wb),

        .writebacks1_valid     (writebacks1_valid),
        .writebacks1_robflag   (writebacks1_robflag),
        .writebacks1_robidx    (writebacks1_robidx),
        .writebacks1_need_to_wb(writebacks1_need_to_wb),

        .writebacks2_valid     (writebacks2_valid),
        .writebacks2_robflag   (writebacks2_robflag),
        .writebacks2_robidx    (writebacks2_robidx),
        .writebacks2_need_to_wb(writebacks2_need_to_wb),

        .commits0_valid  (commits0_valid),
        .commits0_old_prd(commits0_old_prd),
        .commits0_lrd    (commits0_lrd),
        .commits0_prd    (commits0_prd),
        .commits0_instr  (commits0_instr),
        .commits0_pc     (commits0_pc),

        .commits1_valid  (commits1_valid),
        .commits1_old_prd(commits1_old_prd),
        .commits1_lrd    (commits1_lrd),
        .commits1_prd    (commits1_prd),
        .commits1_instr  (commits1_instr),
        .commits1_pc     (commits1_pc),

        .redirect_valid  (redirect_valid),
        .redirect_target (redirect_target),
        .redirect_robflag(redirect_robflag),
        .redirect_robidx (redirect_robidx)
    );
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
endmodule
