/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

module robentry (
    input  wire               clock,
    input  wire               reset_n,
    input  wire               enq,
    input  wire [  `PC_RANGE] enq_pc,
    input  wire [       31:0] enq_instr,
    input  wire [`LREG_RANGE] enq_lrd,
    input  wire [`PREG_RANGE] enq_prd,
    input  wire [`PREG_RANGE] enq_old_prd,
    //debug
    input  wire               enq_need_to_wb,
    input  wire               enq_skip,
    /* -------------------------------- wireback -------------------------------- */
    input  wire               writeback,
    input  wire               writeback_skip,
    /* ------------------------------- entry valid ------------------------------ */
    output wire               valid,
    /* ------------------------------------ deq port ----------------------------------- */
    output wire               can_deq,
    output wire               deq_complete,
    output wire [  `PC_RANGE] deq_pc,
    output wire [       31:0] deq_instr,
    output wire [`LREG_RANGE] deq_lrd,
    output wire [`PREG_RANGE] deq_prd,
    output wire [`PREG_RANGE] deq_old_prd,
    //debug
    output wire               deq_need_to_wb,
    output wire               deq_skip,
    /* ------------------------------- commit port ------------------------------ */
    input  wire               commit,
    /* ------------------------------- flush logic ------------------------------ */
    input  wire               flush
);

    reg               rob_entries_valid;
    reg               rob_entries_complete;
    reg [  `PC_RANGE] rob_entries_pc;
    reg [       31:0] rob_entries_instr;
    reg [`LREG_RANGE] rob_entries_lrd;
    reg [`PREG_RANGE] rob_entries_prd;
    reg [`PREG_RANGE] rob_entries_old_prd;
    //debug
    reg               rob_entries_need_to_wb;
    reg               rob_entries_skip;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            rob_entries_valid <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_valid <= 1'b1;
        end else if (commit) begin
            rob_entries_valid <= 1'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            rob_entries_complete <= 1'b0;
        end else if (~rob_entries_complete & writeback) begin
            rob_entries_complete <= 1'b1;
        end else if (commit) begin
            rob_entries_complete <= 1'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_pc <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_pc <= enq_pc;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_instr <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_instr <= enq_instr;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_lrd <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_lrd <= enq_lrd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_prd <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_prd <= enq_prd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_old_prd <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_old_prd <= enq_old_prd;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_need_to_wb <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_need_to_wb <= enq_need_to_wb;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_entries_skip <= 'b0;
        end else if (~rob_entries_valid & enq) begin
            rob_entries_skip <= 'b0;
        end else if (writeback) begin
            rob_entries_skip <= writeback_skip;
        end
    end


    assign valid          = rob_entries_valid;

    assign can_deq            = rob_entries_valid & rob_entries_complete;
    assign deq_complete   = rob_entries_complete;
    assign deq_pc         = rob_entries_pc;
    assign deq_instr      = rob_entries_instr;
    assign deq_lrd        = rob_entries_lrd;
    assign deq_prd        = rob_entries_prd;
    assign deq_old_prd    = rob_entries_old_prd;
    assign deq_need_to_wb = rob_entries_need_to_wb;
    assign deq_skip       = rob_entries_skip;


endmodule

/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */


