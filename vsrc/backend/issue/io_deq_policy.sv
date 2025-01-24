`include "defines.sv"
module io_deq_policy #(
    parameter QUEUE_SIZE = 8
) (
    input wire clock,
    input wire reset_n,
    input wire flush,

    input wire                     enq_fire,
    input wire                     deq_fire,
    input wire [QUEUE_SIZE -1 : 0] valid_dec,

    input wire [QUEUE_SIZE -1 : 0] enq_ptr_oh,
    input wire [QUEUE_SIZE -1 : 0] enq_valid_oh,

    input  wire [QUEUE_SIZE -1 : 0] deq_ptr_oh,
    output reg  [QUEUE_SIZE -1 : 0] deq_ptr_oh_next,
    input  wire [QUEUE_SIZE -1 : 0] deq_valid_oh


);
    reg flush_flop;
    `MACRO_DFF_NONEN(flush_flop, flush, 1)
    reg enq_fire_flop;
    `MACRO_DFF_NONEN(enq_fire_flop, enq_fire, 1)

    wire [QUEUE_SIZE -1 : 0] data_out;
    wire [QUEUE_SIZE -1 : 0] valid_dec_except_deq_inc_enq;
    assign valid_dec_except_deq_inc_enq = valid_dec & (~deq_valid_oh) | enq_valid_oh;
    find_first1_base #(
        .WIDTH(QUEUE_SIZE)
    ) u_find_first1_base (
        .data_in (valid_dec_except_deq_inc_enq),
        .base    (deq_ptr_oh),
        .data_out(data_out)
    );

    always @(*) begin
        deq_ptr_oh_next = deq_ptr_oh;
        if (flush_flop) begin
            // deq_ptr_oh_next = data_out_last1_shift_left;
            deq_ptr_oh_next = data_out_last1;
        end else if (~(|valid_dec_except_deq_inc_enq)) begin  //align with enq ptr
            deq_ptr_oh_next = enq_ptr_oh;
        end else if (deq_fire) begin
            deq_ptr_oh_next = data_out;
        end
    end

    wire [QUEUE_SIZE -1 : 0] data_out_last1_shift_left;
    wire [QUEUE_SIZE -1 : 0] data_out_last1;

    // assign data_out_last1_shift_left = {data_out_last1[`IISSUE_QUEUE_DEPTH-2:0], data_out_last1[`IISSUE_QUEUE_DEPTH-1]};
    find_first1 #(
        .WIDTH(QUEUE_SIZE)
    ) u_find_last1 (
        .data_in (valid_dec),
        .data_out(data_out_last1)
    );

endmodule
