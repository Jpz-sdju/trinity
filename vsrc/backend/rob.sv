`include "defines.sv"
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
module rob (
    input wire               clock,
    input wire               reset_n,
    //rob enq logic
    input wire               instr0_enq_valid,
    input wire [       31:0] instr0,
    input wire [`LREG_RANGE] instr0_lrs1,
    input wire [`LREG_RANGE] instr0_lrs2,
    input wire [`LREG_RANGE] instr0_lrd,
    input wire [`PREG_RANGE] instr0_prd,
    input wire [`PREG_RANGE] instr0_old_prd,
    input wire [       47:0] instr0_pc,

    input wire               instr1_enq_valid,
    input wire [       31:0] instr1,
    input wire [`LREG_RANGE] instr1_lrs1,
    input wire [`LREG_RANGE] instr1_lrs2,
    input wire [`LREG_RANGE] instr1_lrd,
    input wire [`PREG_RANGE] instr1_prd,
    input wire [`PREG_RANGE] instr1_old_prd,
    input wire [       47:0] instr1_pc,

    //robidx output put

    output reg                     enq_robidx_flag,
    output reg [`ROB_SIZE_LOG-1:0] enq_robidx,

    //write back port
    input wire                     writebacks0_valid,
    input wire                     writebacks0_robflag,
    input wire [`ROB_SIZE_LOG-1:0] writebacks0_robidx,
    input wire                     writebacks0_need_to_wb,

    input wire                     writebacks1_valid,
    input wire                     writebacks1_robflag,
    input wire [`ROB_SIZE_LOG-1:0] writebacks1_robidx,
    input wire                     writebacks1_need_to_wb,

    input wire                     writebacks2_valid,
    input wire                     writebacks2_robflag,
    input wire [`ROB_SIZE_LOG-1:0] writebacks2_robidx,
    input wire                     writebacks2_need_to_wb,

    //commit port
    output wire               commits0_valid,
    output wire [`PREG_RANGE] commits0_old_prd,
    output wire [`LREG_RANGE] commits0_lrd,
    output wire [`PREG_RANGE] commits0_prd,
    output wire [       31:0] commits0_instr,
    output wire [       47:0] commits0_pc,

    output wire               commits1_valid,
    output wire [`PREG_RANGE] commits1_old_prd,
    output wire [`LREG_RANGE] commits1_lrd,
    output wire [`PREG_RANGE] commits1_prd,
    output wire [       31:0] commits1_instr,
    output wire [       47:0] commits1_pc,

    //redirect
    input wire                     redirect_valid,
    input wire [             63:0] redirect_target,
    input wire                     redirect_robflag,
    input wire [`ROB_SIZE_LOG-1:0] redirect_robidx

    //

);


    reg                      enq_flag;
    reg  [`ROB_SIZE_LOG-1:0] enq_idx;
    reg                      enq_flag_next;
    reg  [`ROB_SIZE_LOG-1:0] enq_idx_next;
    reg  [  `ROB_SIZE_LOG:0] enq_num;  //add one bit to adapt flag bit

    reg                      deq_flag;
    reg  [`ROB_SIZE_LOG-1:0] deq_idx;
    reg                      deq_flag_next;
    reg  [`ROB_SIZE_LOG-1:0] deq_idx_next;
    reg  [  `ROB_SIZE_LOG:0] deq_num;  //add one bit to adapt flag bit

    reg  [    `ROB_SIZE-1:0] rob_entries_enq_dec;
    reg  [             47:0] rob_entries_enq_pc_dec                   [0:`ROB_SIZE-1];
    reg  [             31:0] rob_entries_enq_instr_dec                [0:`ROB_SIZE-1];
    reg  [      `LREG_RANGE] rob_entries_enq_lrd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] rob_entries_enq_prd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] rob_entries_enq_old_prd_dec              [0:`ROB_SIZE-1];


    wire [    `ROB_SIZE-1:0] rob_entries_deq_dec;
    wire [             47:0] rob_entries_deq_pc_dec                   [0:`ROB_SIZE-1];
    wire [             31:0] rob_entries_deq_instr_dec                [0:`ROB_SIZE-1];
    wire [      `LREG_RANGE] rob_entries_deq_lrd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] rob_entries_deq_prd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] rob_entries_deq_old_prd_dec              [0:`ROB_SIZE-1];

    /* -------------------------------------------------------------------------- */
    /*                        enq information to dec format                       */
    /* -------------------------------------------------------------------------- */
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_dec[i] = 1'b1;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_dec[i] = 1'b1;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_pc_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_pc_dec[i] = instr0_pc;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_pc_dec[i] = instr1_pc;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_instr_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_instr_dec[i] = instr0;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_instr_dec[i] = instr1;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_prd_dec[i] = instr0_prd;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_prd_dec[i] = instr1_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_old_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_old_prd_dec[i] = instr0_old_prd;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_old_prd_dec[i] = instr1_old_prd;
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                  enq logic                                 */
    /* -------------------------------------------------------------------------- */


    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_num = 'b0;
            if (rob_entries_enq_dec[i]) begin
                enq_num = enq_num + 1;
            end
        end
    end

    always @(*) begin
        {enq_flag_next, enq_idx_next} = {enq_flag, enq_idx} + enq_num;
    end


    `MACRO_DFF_NONEN(enq_flag, enq_flag_next, 1)
    `MACRO_DFF_NONEN(enq_idx, enq_idx_next, `ROB_SIZE_LOG)


    /* -------------------------------------------------------------------------- */
    /*                               writeback logic                              */
    /* -------------------------------------------------------------------------- */
    reg [`ROB_SIZE-1:0] rob_entries_writeback_dec;
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_writeback_dec[i] = 'b0;
            if (writebacks0_valid & (writebacks0_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
            if (writebacks1_valid & (writebacks1_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
            if (writebacks2_valid & (writebacks2_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                commit logic (deq)                          */
    /* -------------------------------------------------------------------------- */
    reg [`ROB_SIZE-1:0] go_commit;  //max hot = 2,cause commit width is 2


    //jpz note:below is a very ugly logic!!
    always @(*) begin
        go_commit[`ROB_SIZE-1:0] = 'b0;
        go_commit[deq_idx]       = rob_entries_deq_dec[deq_idx];
        go_commit[deq_idx+1]     = rob_entries_deq_dec[deq_idx+1] & go_commit[deq_idx];
    end


    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            deq_num = 'b0;
            if (go_commit[i]) begin
                deq_num = deq_num + 1;
            end
        end
    end

    always @(*) begin
        {deq_flag_next, deq_idx_next} = {deq_flag, deq_idx} + deq_num;
    end


    `MACRO_DFF_NONEN(deq_flag, deq_flag_next, 1)
    `MACRO_DFF_NONEN(deq_idx, deq_idx_next, `ROB_SIZE_LOG)



    genvar i;
    generate
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin : rob_entity
            robentry u_robentry (
                .clock      (clock),
                .reset_n    (reset_n),
                .enq        (rob_entries_enq_dec[i]),
                .enq_pc     (rob_entries_enq_pc_dec[i]),
                .enq_instr  (rob_entries_enq_instr_dec[i]),
                .enq_lrd    (rob_entries_enq_lrd_dec[i]),
                .enq_prd    (rob_entries_enq_prd_dec[i]),
                .enq_old_prd(rob_entries_enq_old_prd_dec[i]),
                .writeback  (rob_entries_writeback_dec[i]),
                .deq        (rob_entries_deq_dec[i]),
                .deq_pc     (rob_entries_deq_pc_dec[i]),
                .deq_instr  (rob_entries_deq_instr_dec[i]),
                .deq_lrd    (rob_entries_deq_lrd_dec[i]),
                .deq_prd    (rob_entries_deq_prd_dec[i]),
                .deq_old_prd(rob_entries_deq_old_prd_dec[i])
            );

        end
    endgenerate
endmodule
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

