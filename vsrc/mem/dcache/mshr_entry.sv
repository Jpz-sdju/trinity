`include "defines.sv"
module mshr_entry #(
    parameter MSHR_ID = 0
) (
    input wire                   clock,          // Clock signal
    input wire                   reset_n,        // Active low reset
    input wire                   install_valid,
    input wire [   `PADDR_RANGE] install_paddr,
    input wire [`ROB_SIZE_LOG:0] install_robid,


    input wire                   merge_valid,
    // we use oldest ROBID to represent this MSHR entry.
    input wire [`ROB_SIZE_LOG:0] merge_robid,


    output wire                     rpt_entry_valid,
    output wire [  `ROB_SIZE_LOG:0] rpt_entry_robid,
    output wire [     `PADDR_RANGE] rpt_entry_paddr,
    output wire [            511:0] rpt_entry_refilldata,
    output wire [`MSHR_NUM_LOG-1:0] rpt_entry_mshrid,
    output wire                     rpt_entry_rdy2refill,

    // arb to L2/MEM
    output wire         chi_arb_req_valid,
    input  wire         chi_arb_req_ready,
    input  wire         chi_arb_resp_valid,
    input  wire [511:0] chi_arb_resp_data,

    //win arb to refill
    input wire win_refill_arb

);
    localparam IDLE = 0;
    localparam S_CHIREQ = 1;
    localparam W_CHIRESP = 2;
    localparam S_REFILL = 3;
    localparam W_RESP = 4;

    // Internal signals for MSHR entry
    reg                    entry_valid;
    reg  [   `PADDR_RANGE] entry_paddr;
    reg  [`ROB_SIZE_LOG:0] entry_robid;
    reg  [          511:0] entry_refilldata;
    reg                    rdy2refill;
    reg  [            2:0] state;
    reg  [            2:0] nxt_state;

    wire                   is_idle = state == IDLE;
    wire                   is_s_chireq = state == S_CHIREQ;
    wire                   is_w_chiresp = state == W_CHIRESP;
    wire                   is_s_refill = state == S_REFILL;
    wire                   is_w_resp = state == W_RESP;

    wire                   need_flush;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_valid <= 'b0;
        end else begin
            if (is_idle & install_valid) begin
                entry_valid <= 1'b1;
            end else if (need_flush) begin
                entry_valid <= 'b0;
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_paddr <= 'b0;
        end else begin
            if (is_idle & install_valid) begin
                entry_paddr <= install_paddr;
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_robid <= 'b0;
        end else begin
            if (is_idle & install_valid) begin
                entry_robid <= install_robid;
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            entry_refilldata <= 'b0;
        end else begin
            if (chi_arb_resp_valid) begin
                entry_refilldata <= chi_arb_resp_data;
            end
        end
    end



    assign rpt_entry_valid      = entry_valid;
    assign rpt_entry_paddr      = entry_paddr;
    assign rpt_entry_robid      = entry_robid;
    assign rpt_entry_refilldata = entry_refilldata;



    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            state <= 'b0;
        end else begin
            state <= nxt_state;
        end
    end



    always @(*) begin
        if (install_valid && is_idle) begin
            nxt_state = S_CHIREQ;
        end else if (chi_arb_req_valid & chi_arb_req_ready) begin
            nxt_state = W_CHIRESP;
        end else if (chi_arb_resp_valid) begin
            nxt_state = S_REFILL;
        end else if (win_refill_arb) begin
            nxt_state = W_RESP;
        end
    end


    assign rpt_entry_rdy2refill = is_s_refill;
    assign rpt_entry_mshrid     = MSHR_ID;
    assign chi_arb_req_valid = is_s_chireq;


endmodule
