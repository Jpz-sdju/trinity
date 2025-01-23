`include "defines.sv"
module io_policy (
    input wire clock,
    input wire reset_n,
    input wire flush,

    input wire                             enq_fire,
    input wire [`ISSUE_QUEUE_DEPTH -1 : 0] valid_dec,

    input  wire [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh,
    output reg  [`ISSUE_QUEUE_DEPTH -1 : 0] enq_ptr_oh_next,
    input  wire [`ISSUE_QUEUE_DEPTH -1 : 0] enq_valid_oh,

    input wire [`ISSUE_QUEUE_DEPTH -1 : 0] deq_ptr_oh


);
    reg flush_flop;
    `MACRO_DFF_NONEN(flush_flop, flush, 1)


    wire [`ISSUE_QUEUE_DEPTH -1 : 0] data_out;
    wire [`ISSUE_QUEUE_DEPTH -1 : 0] valid_dec_except_enq;
    assign valid_dec_except_enq = valid_dec & (~enq_valid_oh);
    find_first1_base #(
        .WIDTH(`ISSUE_QUEUE_DEPTH)
    ) u_find_first1_base (
        .data_in (valid_dec_except_enq),
        .base    (enq_ptr_oh),
        .data_out(data_out)
    );

    always @(*) begin
        enq_ptr_oh_next = enq_ptr_oh;
        if (flush_flop) begin
            enq_ptr_oh_next = data_out_last1_shift_left;
        end else if (~(|valid_dec_except_enq)) begin //align with deq ptr toselect next enq
            enq_ptr_oh_next = deq_ptr_oh;
        end else if (enq_fire) begin
            enq_ptr_oh_next = data_out;
        end
    end

    wire [`ISSUE_QUEUE_DEPTH -1 : 0] data_out_last1_shift_left;
    wire [`ISSUE_QUEUE_DEPTH -1 : 0] data_out_last1;

    assign data_out_last1_shift_left = {data_out_last1[`ISSUE_QUEUE_DEPTH-2:0], data_out_last1[`ISSUE_QUEUE_DEPTH-1]};
    find_last1 #(
        .WIDTH(`ISSUE_QUEUE_DEPTH)
    ) u_find_last1 (
        .data_in (valid_dec),
        .data_out(data_out_last1)
    );

endmodule
