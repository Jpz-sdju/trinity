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
    input wire [`PREG_RANGE] writeback1_prd,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                     flush_valid,
    input wire                     flush_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx
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

    reg deq_idx_flag, enq_idx_flag;
    reg [`ISSUE_QUEUE_LOG-1:0] deq_idx, enq_idx;
    reg deq_idx_flag_next, enq_idx_flag_next;
    reg [`ISSUE_QUEUE_LOG-1:0] deq_idx_next, enq_idx_next;

    // Enqueue logic
    assign enq_instr0_ready = (queue_valid[enq_idx] == 0);

    //when deq_idx is ready,go issue
    wire deq_is_ready = queue_valid[deq_idx] & (~queue_src1_state[deq_idx]) & (~queue_src2_state[deq_idx]) & deq_instr0_ready;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin

        end else if (enq_instr0_valid && enq_instr0_ready) begin
            queue_prs1[enq_idx]        <= enq_instr0_prs1;
            queue_prs2[enq_idx]        <= enq_instr0_prs2;
            queue_src1_is_reg[enq_idx] <= enq_instr0_src1_is_reg;
            queue_src2_is_reg[enq_idx] <= enq_instr0_src2_is_reg;
            queue_prd[enq_idx]         <= enq_instr0_prd;
            queue_old_prd[enq_idx]     <= enq_instr0_old_prd;
            queue_pc[enq_idx]          <= enq_instr0_pc;
            queue[enq_idx]             <= enq_instr0;
            queue_imm[enq_idx]         <= enq_instr0_imm;
            queue_need_to_wb[enq_idx]  <= enq_instr0_need_to_wb;
            queue_cx_type[enq_idx]     <= enq_instr0_cx_type;
            queue_is_unsigned[enq_idx] <= enq_instr0_is_unsigned;
            queue_alu_type[enq_idx]    <= enq_instr0_alu_type;
            queue_muldiv_type[enq_idx] <= enq_instr0_muldiv_type;
            queue_is_word[enq_idx]     <= enq_instr0_is_word;
            queue_is_imm[enq_idx]      <= enq_instr0_is_imm;
            queue_is_load[enq_idx]     <= enq_instr0_is_load;
            queue_is_store[enq_idx]    <= enq_instr0_is_store;
            queue_ls_size[enq_idx]     <= enq_instr0_ls_size;
            queue_robidx_flag[enq_idx] <= enq_instr0_robidx_flag;
            queue_robidx[enq_idx]      <= enq_instr0_robidx;
        end
    end

    reg [`ISSUE_QUEUE_DEPTH-1:0] enq_oh;
    reg [`ISSUE_QUEUE_DEPTH-1:0] deq_oh;
    reg [`ISSUE_QUEUE_DEPTH-1:0] flush_dec;

    always @(*) begin
        integer i;
        enq_oh = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (enq_idx == i[`ISSUE_QUEUE_LOG-1:0]) begin
                enq_oh[i] = 1'b1;
            end
        end
    end
    always @(*) begin
        integer i;
        deq_oh = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (deq_idx == i[`ISSUE_QUEUE_LOG-1:0]) begin
                deq_oh[i] = 1'b1;
            end
        end
    end
    always @(flush_valid or flush_robidx or flush_robidx_flag) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (flush_valid) begin
                if (flush_valid & queue_valid[i] & ((flush_robidx_flag ^ queue_robidx_flag[i]) ^ (flush_robidx < queue_robidx[i]))) begin
                    flush_dec[i] = 1'b1;
                end
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        integer i;
        for (i = 0; i < `ISSUE_QUEUE_DEPTH; i = i + 1) begin
            if (~reset_n) begin
                queue_valid[i] <= 1'b0;
            end else begin
                //not need to consider flush hit enq,cause dispatch will cover this situation
                if (enq_oh[i] & enq_instr0_valid && enq_instr0_ready) begin
                    queue_valid[i] <= 1'b1;
                end else if (flush_dec[i]) begin
                    queue_valid[i] <= 1'b0;
                end else if (deq_oh[i] & deq_is_ready) begin
                    queue_valid[i] <= 1'b0;
                end
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
                queue_src1_state[enq_idx] <= enq_instr0_src1_state & enq_instr0_src1_is_reg;
            end
            for (i = 0; i < `ISSUE_QUEUE_LOG; i = i + 1) begin
                if (writeback0_to_wakeup & (queue_prs1[i] == writeback0_prd) & queue_src1_is_reg[i]) begin
                    queue_src1_state[i] <= 'b0;
                end
                if (writeback1_to_wakeup & (queue_prs1[i] == writeback1_prd) & queue_src1_is_reg[i]) begin
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
                queue_src2_state[enq_idx] <= enq_instr0_src2_state & enq_instr0_src2_is_reg;
            end
            for (i = 0; i < `ISSUE_QUEUE_LOG; i = i + 1) begin
                if (writeback0_to_wakeup & (queue_prs2[i] == writeback0_prd) & queue_src2_is_reg[i]) begin
                    queue_src2_state[i] <= 'b0;
                end
                if (writeback1_to_wakeup & (queue_prs2[i] == writeback1_prd) & queue_src2_is_reg[i]) begin
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
        end else if (deq_is_ready) begin
            deq_instr0_valid       <= 1;
            deq_instr0_prs1        <= queue_prs1[deq_idx];
            deq_instr0_prs2        <= queue_prs2[deq_idx];
            deq_instr0_src1_is_reg <= queue_src1_is_reg[deq_idx];
            deq_instr0_src2_is_reg <= queue_src2_is_reg[deq_idx];
            deq_instr0_prd         <= queue_prd[deq_idx];
            deq_instr0_old_prd     <= queue_old_prd[deq_idx];
            deq_instr0_pc          <= queue_pc[deq_idx];
            // deq_instr0             <= queue[deq_idx];
            deq_instr0_imm         <= queue_imm[deq_idx];
            deq_instr0_need_to_wb  <= queue_need_to_wb[deq_idx];
            deq_instr0_cx_type     <= queue_cx_type[deq_idx];
            deq_instr0_is_unsigned <= queue_is_unsigned[deq_idx];
            deq_instr0_alu_type    <= queue_alu_type[deq_idx];
            deq_instr0_muldiv_type <= queue_muldiv_type[deq_idx];
            deq_instr0_is_word     <= queue_is_word[deq_idx];
            deq_instr0_is_imm      <= queue_is_imm[deq_idx];
            deq_instr0_is_load     <= queue_is_load[deq_idx];
            deq_instr0_is_store    <= queue_is_store[deq_idx];
            deq_instr0_ls_size     <= queue_ls_size[deq_idx];
            deq_instr0_robidx_flag <= queue_robidx_flag[deq_idx];
            deq_instr0_robidx      <= queue_robidx[deq_idx];
        end else begin
            deq_instr0_valid <= 0;
        end
    end

    //for now,cause in-order issue,flush could clear deq_idx and enq_idx
    always @(*) begin
        if (flush_valid) begin
            {deq_idx_flag_next, deq_idx_next} = 'b0;
        end else if (deq_is_ready) begin
            {deq_idx_flag_next, deq_idx_next} = {deq_idx_flag, deq_idx} + 'b1;
        end else begin
            {deq_idx_flag_next, deq_idx_next} = {deq_idx_flag, deq_idx};
        end
    end

    `MACRO_DFF_NONEN(deq_idx_flag, deq_idx_flag_next, 1)
    `MACRO_DFF_NONEN(deq_idx, deq_idx_next, `ISSUE_QUEUE_LOG)

    //for now,cause in-order issue,flush could clear deq_idx and enq_idx
    always @(*) begin
        if (flush_valid) begin
            {enq_idx_flag_next, enq_idx_next} = 'b0;
        end else if ((enq_instr0_valid & enq_instr0_ready)) begin
            {enq_idx_flag_next, enq_idx_next} = {enq_idx_flag, enq_idx} + 'b1;
        end else begin
            {enq_idx_flag_next, enq_idx_next} = {enq_idx_flag, enq_idx};
        end
    end

    `MACRO_DFF_NONEN(enq_idx_flag, enq_idx_flag_next, 1)
    `MACRO_DFF_NONEN(enq_idx, enq_idx_next, `ISSUE_QUEUE_LOG)


endmodule
