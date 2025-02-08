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
    input wire                           wb_bht_write_enable,
    input wire [`BHTBTB_INDEX_WIDTH-1:0] wb_bht_write_index,
    input wire [                    1:0] wb_bht_write_counter_select,
    input wire                           wb_bht_write_inc,
    input wire                           wb_bht_write_dec,
    input wire                           wb_bht_valid_in,
    input wire                           wb_btb_ce,
    input wire                           wb_btb_we,
    input wire [                  128:0] wb_btb_wmask,
    input wire [                    8:0] wb_btb_write_index,
    input wire [                  128:0] wb_btb_din,
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
    output reg                           entry_bht_write_enable,
    output reg [`BHTBTB_INDEX_WIDTH-1:0] entry_bht_write_index,
    output reg [                    1:0] entry_bht_write_counter_select,
    output reg                           entry_bht_write_inc,
    output reg                           entry_bht_write_dec,
    output reg                           entry_bht_valid_in,
    output reg                           entry_btb_ce,
    output reg                           entry_btb_we,
    output reg [                  128:0] entry_btb_wmask,
    output reg [                    8:0] entry_btb_write_index,
    output reg [                  128:0] entry_btb_din,
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

    /* ------------------------- write back bhtbtb info ------------------------- */
    //bht info
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_write_enable <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_write_enable <= wb_bht_write_enable;
        end else if (commit_vld) begin
            entry_bht_write_enable <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_write_index <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_write_index <= wb_bht_write_index;
        end else if (commit_vld) begin
            entry_bht_write_index <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_write_counter_select <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_write_counter_select <= wb_bht_write_counter_select;
        end else if (commit_vld) begin
            entry_bht_write_counter_select <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_write_inc <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_write_inc <= wb_bht_write_inc;
        end else if (commit_vld) begin
            entry_bht_write_inc <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_write_dec <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_write_dec <= wb_bht_write_dec;
        end else if (commit_vld) begin
            entry_bht_write_dec <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_bht_valid_in <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_bht_valid_in <= wb_bht_valid_in;
        end else if (commit_vld) begin
            entry_bht_valid_in <= 'b0;
        end
    end
    //btb info
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_btb_ce <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_btb_ce <= wb_btb_ce;
        end else if (commit_vld) begin
            entry_btb_ce <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_btb_we <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_btb_we <= wb_btb_we;
        end else if (commit_vld) begin
            entry_btb_we <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_btb_wmask <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_btb_wmask <= wb_btb_wmask;
        end else if (commit_vld) begin
            entry_btb_wmask <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_btb_write_index <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_btb_write_index <= wb_btb_write_index;
        end else if (commit_vld) begin
            entry_btb_write_index <= 'b0;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush_vld) begin
            entry_btb_din <= 'b0;
        end else if (~entry_complete & wb_set_complete & entry_valid) begin
            entry_btb_din <= wb_btb_din;
        end else if (commit_vld) begin
            entry_btb_din <= 'b0;
        end
    end

endmodule

