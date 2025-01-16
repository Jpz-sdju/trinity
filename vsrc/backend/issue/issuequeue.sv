`include "defines.sv"
module issuequeue (
    input  wire               clock,
    input  wire               reset_n,
    input  wire               enq_instr0_valid,
    output wire               enq_instr0_ready,
    input  wire [`LREG_RANGE] enq_instr0_lrs1,
    input  wire [`LREG_RANGE] enq_instr0_lrs2,
    input  wire [`LREG_RANGE] enq_instr0_lrd,
    input  wire [  `PC_RANGE] enq_instr0_pc,
    input  wire [       31:0] enq_instr0,

    input wire [              63:0] enq_instr0_imm,
    input wire                      enq_instr0_src1_is_reg,
    input wire                      enq_instr0_src2_is_reg,
    input wire                      enq_instr0_need_to_wb,
    input wire [    `CX_TYPE_RANGE] enq_instr0_cx_type,
    input wire                      enq_instr0_is_unsigned,
    input wire [   `ALU_TYPE_RANGE] enq_instr0_alu_type,
    input wire [`MULDIV_TYPE_RANGE] enq_instr0_muldiv_type,
    input wire                      enq_instr0_is_word,
    input wire                      enq_instr0_is_imm,
    input wire                      enq_instr0_is_load,
    input wire                      enq_instr0_is_store,
    input wire [               3:0] enq_instr0_ls_size,

    input wire [`PREG_RANGE] enq_instr0_prs1,
    input wire [`PREG_RANGE] enq_instr0_prs2,
    input wire [`PREG_RANGE] enq_instr0_prd,
    input wire [`PREG_RANGE] enq_instr0_old_prd,

    input wire                     enq_instr0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_instr0_robidx,

    /* -------------------------------- src state ------------------------------- */
    input wire enq_instr0_src1_state,
    input wire enq_instr0_src2_state,

    /* ----------------------------- output to execute block ---------------------------- */
    output reg                deq_instr0_valid,
    //temp sig
    input  wire               deq_instr0_ready,
    output reg  [`PREG_RANGE] deq_instr0_prs1,
    output reg  [`PREG_RANGE] deq_instr0_prs2,
    output reg                deq_instr0_src1_is_reg,
    output reg                deq_instr0_src2_is_reg,

    output reg [`PREG_RANGE] deq_instr0_prd,
    output reg [`PREG_RANGE] deq_instr0_old_prd,

    output reg [`SRC_RANGE] deq_instr0_pc,
    // output reg [`INSTR_RANGE] deq_instr0,
    output reg [`SRC_RANGE] deq_instr0_imm,

    output reg                      deq_instr0_need_to_wb,
    output reg [    `CX_TYPE_RANGE] deq_instr0_cx_type,
    output reg                      deq_instr0_is_unsigned,
    output reg [   `ALU_TYPE_RANGE] deq_instr0_alu_type,
    output reg [`MULDIV_TYPE_RANGE] deq_instr0_muldiv_type,
    output reg                      deq_instr0_is_word,
    output reg                      deq_instr0_is_imm,
    output reg                      deq_instr0_is_load,
    output reg                      deq_instr0_is_store,
    output reg [               3:0] deq_instr0_ls_size,

    output reg                     deq_instr0_robidx_flag,
    output reg [`ROB_SIZE_LOG-1:0] deq_instr0_robidx,

    /* ---------------------------- write back wakeup --------------------------- */
    input wire               writeback0_valid,
    input wire               writeback0_need_to_wb,
    input wire [`PREG_RANGE] writeback0_prd,

    input wire               writeback1_valid,
    input wire               writeback1_need_to_wb,
    input wire [`PREG_RANGE] writeback1_prd
);

    // Internal queue storage
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_valid;
    reg [           `PREG_RANGE] queue_prs1        [`ISSUE_QUEUE_DEPTH-1:0];
    reg [           `PREG_RANGE] queue_prs2        [`ISSUE_QUEUE_DEPTH-1:0];
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_src1_is_reg;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_src2_is_reg;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_src1_state;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_src2_state;

    reg [           `PREG_RANGE] queue_prd         [`ISSUE_QUEUE_DEPTH-1:0];
    reg [           `PREG_RANGE] queue_old_prd     [`ISSUE_QUEUE_DEPTH-1:0];
    reg [             `PC_RANGE] queue_pc          [`ISSUE_QUEUE_DEPTH-1:0];
    reg [                  31:0] queue             [`ISSUE_QUEUE_DEPTH-1:0];
    reg [            `SRC_RANGE] queue_imm         [`ISSUE_QUEUE_DEPTH-1:0];

    reg                          queue_need_to_wb  [`ISSUE_QUEUE_DEPTH-1:0];
    reg [        `CX_TYPE_RANGE] queue_cx_type     [`ISSUE_QUEUE_DEPTH-1:0];
    reg                          queue_is_unsigned [`ISSUE_QUEUE_DEPTH-1:0];
    reg [       `ALU_TYPE_RANGE] queue_alu_type    [`ISSUE_QUEUE_DEPTH-1:0];
    reg [    `MULDIV_TYPE_RANGE] queue_muldiv_type [`ISSUE_QUEUE_DEPTH-1:0];
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_is_word;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_is_imm;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_is_load;
    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_is_store;
    reg [                   3:0] queue_ls_size     [`ISSUE_QUEUE_DEPTH-1:0];

    reg [`ISSUE_QUEUE_DEPTH-1:0] queue_robidx_flag;
    reg [     `ROB_SIZE_LOG-1:0] queue_robidx      [`ISSUE_QUEUE_DEPTH-1:0];

    reg [`ISSUE_QUEUE_LOG-1:0] head, tail;
    reg head_flag, tail_flag;
    reg [`ISSUE_QUEUE_LOG-1:0] head_next, tail_next;
    reg head_flag_next, tail_flag_next;



    // Enqueue logic
    assign enq_instr0_ready = (queue_valid[tail] == 0);

    //when head is ready,go issue
    wire head_is_ready = queue_valid[head] & (~queue_src1_state[head]) & (~queue_src2_state[head]) & deq_instr0_ready;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin

        end else if (enq_instr0_valid && enq_instr0_ready) begin
            queue_prs1[tail]        <= enq_instr0_prs1;
            queue_prs2[tail]        <= enq_instr0_prs2;
            queue_src1_is_reg[tail] <= enq_instr0_src1_is_reg;
            queue_src2_is_reg[tail] <= enq_instr0_src2_is_reg;
            queue_src1_state[tail]  <= enq_instr0_src1_state;
            queue_src2_state[tail]  <= enq_instr0_src2_state;
            queue_prd[tail]         <= enq_instr0_prd;
            queue_old_prd[tail]     <= enq_instr0_old_prd;
            queue_pc[tail]          <= enq_instr0_pc;
            queue[tail]             <= enq_instr0;
            queue_imm[tail]         <= enq_instr0_imm;
            queue_need_to_wb[tail]  <= enq_instr0_need_to_wb;
            queue_cx_type[tail]     <= enq_instr0_cx_type;
            queue_is_unsigned[tail] <= enq_instr0_is_unsigned;
            queue_alu_type[tail]    <= enq_instr0_alu_type;
            queue_muldiv_type[tail] <= enq_instr0_muldiv_type;
            queue_is_word[tail]     <= enq_instr0_is_word;
            queue_is_imm[tail]      <= enq_instr0_is_imm;
            queue_is_load[tail]     <= enq_instr0_is_load;
            queue_is_store[tail]    <= enq_instr0_is_store;
            queue_ls_size[tail]     <= enq_instr0_ls_size;
            queue_robidx_flag[tail] <= enq_instr0_robidx_flag;
            queue_robidx[tail]      <= enq_instr0_robidx;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_valid <= 'b0;
        end else begin
            if (enq_instr0_valid && enq_instr0_ready) begin
                queue_valid[tail] <= 1'b1;
            end
            if (head_is_ready) begin
                queue_valid[head] <= 1'b0;
            end

        end
    end



    /* -------------------------------------------------------------------------- */
    /*                                wakeup logic                                */
    /* -------------------------------------------------------------------------- */
    wire writeback0_to_wakeup;
    wire writeback1_to_wakeup;
    assign writeback0_to_wakeup = writeback0_valid & writeback0_need_to_wb;
    assign writeback1_to_wakeup = writeback1_valid & writeback1_need_to_wb;
    always @(posedge clock or negedge reset_n) begin
        integer i;
        if (~reset_n) begin
            queue_src1_state <= 'b0;
        end else begin
            if (enq_instr0_valid & enq_instr0_ready) begin
                queue_src1_state[tail] <= enq_instr0_src1_state;
            end
            for (i = 0; i < `ISSUE_QUEUE_LOG; i = i + 1) begin
                if (writeback0_to_wakeup & (queue_prs1[i] == writeback0_prd) & queue_src1_is_reg) begin
                    queue_src1_state[i] <= 'b0;
                end
                if (writeback1_to_wakeup & (queue_prs1[i] == writeback1_prd) & queue_src1_is_reg) begin
                    queue_src1_state[i] <= 'b0;
                end
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        integer i;
        if (~reset_n) begin
            queue_src2_state <= 'b0;
        end else begin
            if (enq_instr0_valid & enq_instr0_ready) begin
                queue_src2_state[tail] <= enq_instr0_src2_state;
            end
            for (i = 0; i < `ISSUE_QUEUE_LOG; i = i + 1) begin
                if (writeback0_to_wakeup & (queue_prs2[i] == writeback0_prd) & queue_src2_is_reg) begin
                    queue_src2_state[i] <= 'b0;
                end
                if (writeback1_to_wakeup & (queue_prs2[i] == writeback1_prd) & queue_src2_is_reg) begin
                    queue_src2_state[i] <= 'b0;
                end
            end
        end
    end
    /* -------------------------------------------------------------------------- */
    /*                                Dequeue logic                               */
    /* -------------------------------------------------------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            deq_instr0_valid <= 0;
        end else if (head_is_ready) begin
            deq_instr0_valid       <= 1;
            deq_instr0_prs1        <= queue_prs1[head];
            deq_instr0_prs2        <= queue_prs2[head];
            deq_instr0_src1_is_reg <= queue_src1_is_reg[head];
            deq_instr0_src2_is_reg <= queue_src2_is_reg[head];
            deq_instr0_prd         <= queue_prd[head];
            deq_instr0_old_prd     <= queue_old_prd[head];
            deq_instr0_pc          <= queue_pc[head];
            // deq_instr0             <= queue[head];
            deq_instr0_imm         <= queue_imm[head];
            deq_instr0_need_to_wb  <= queue_need_to_wb[head];
            deq_instr0_cx_type     <= queue_cx_type[head];
            deq_instr0_is_unsigned <= queue_is_unsigned[head];
            deq_instr0_alu_type    <= queue_alu_type[head];
            deq_instr0_muldiv_type <= queue_muldiv_type[head];
            deq_instr0_is_word     <= queue_is_word[head];
            deq_instr0_is_imm      <= queue_is_imm[head];
            deq_instr0_is_load     <= queue_is_load[head];
            deq_instr0_is_store    <= queue_is_store[head];
            deq_instr0_ls_size     <= queue_ls_size[head];
            deq_instr0_robidx_flag <= queue_robidx_flag[head];
            deq_instr0_robidx      <= queue_robidx[head];
        end else begin
            deq_instr0_valid <= 0;
        end
    end


    always @(*) begin
        if (head_is_ready) begin
            {head_flag_next, head_next} = {head_flag, head} + 'b1;
        end else begin
            {head_flag_next, head_next} = {head_flag, head};
        end
    end

    `MACRO_DFF_NONEN(head_flag, head_flag_next, 1)
    `MACRO_DFF_NONEN(head, head_next, `ISSUE_QUEUE_LOG)

    always @(*) begin
        if ((enq_instr0_valid & enq_instr0_ready)) begin
            {tail_flag_next, tail_next} = {tail_flag, tail} + 'b1;
        end else begin
            {tail_flag_next, tail_next} = {tail_flag, tail};
        end
    end

    `MACRO_DFF_NONEN(tail_flag, tail_flag_next, 1)
    `MACRO_DFF_NONEN(tail, tail_next, `ISSUE_QUEUE_LOG)


endmodule
