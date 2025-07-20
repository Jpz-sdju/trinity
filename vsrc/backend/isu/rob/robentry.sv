module robentry
(
    input  wire               clock,
    input  wire               reset_n,
    /* ------------------------------ enqeue logic ------------------------------ */
    input  wire               enq_valid,//enq_valid
    input  wire [  `PC_RANGE] enq_pc,
    input  wire [       31:0] enq_instr,
    input  wire [`LREG_RANGE] enq_lrd,
    input  wire [`PREG_RANGE] enq_prd,
    input  wire [`PREG_RANGE] enq_old_prd,
    //debug
    input  wire               enq_need_to_wb,
    // input  wire               enq_skip,
    /* -------------------------------- wireback -------------------------------- */
    input  wire               wb_set_complete,//
    input  wire               wb_set_skip,//
    /* ------------------------------- entry valid ------------------------------ */
    output reg               entry_ready_to_commit,
    output reg               entry_valid,
    output reg               entry_complete,
    output reg [  `PC_RANGE] entry_pc,
    output reg [       31:0] entry_instr,
    output reg [`LREG_RANGE] entry_lrd,
    output reg [`PREG_RANGE] entry_prd,
    output reg [`PREG_RANGE] entry_old_prd,
    //debug
    output reg               entry_need_to_wb,
    output reg               entry_skip,
    /* ------------------------------- commit port ------------------------------ */
    input  wire               commit_vld,//commit
    /* ------------------------------- flush logic ------------------------------ */
    input  wire               flush_vld
);
    assign entry_ready_to_commit = entry_valid & entry_complete;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_valid <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_valid <= 1'b1;
        end else if (commit_vld) begin
            entry_valid <= 1'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_complete <= 1'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_complete <= 1'b1;
        end else if (commit_vld) begin
            entry_complete <= 1'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_pc <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_pc <= enq_pc;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_instr <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_instr <= enq_instr;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_lrd <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_lrd <= enq_lrd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_prd <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_prd <= enq_prd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_old_prd <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_old_prd <= enq_old_prd;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_need_to_wb <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_need_to_wb <= enq_need_to_wb;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_skip <= 'b0;
        end else if (~entry_valid & enq_valid) begin
            entry_skip <= 'b0;
        end else if (wb_set_complete) begin
            entry_skip <= wb_set_skip;
        end
    end

endmodule

