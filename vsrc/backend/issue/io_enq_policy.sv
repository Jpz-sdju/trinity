`include "defines.sv"
module io_enq_policy #(
    parameter QUEUE_SIZE = 8
) (
    input wire clock,
    input wire reset_n,
    input wire flush,

    input wire                     enq_fire,
    input wire [QUEUE_SIZE -1 : 0] valid_dec,

    input  wire [QUEUE_SIZE -1 : 0] enq_ptr_oh,
    output reg  [QUEUE_SIZE -1 : 0] enq_ptr_oh_next,
    input  wire [QUEUE_SIZE -1 : 0] enq_valid_oh,

    input wire [QUEUE_SIZE -1 : 0] deq_ptr_oh


);
    reg flush_flop;
    `MACRO_DFF_NONEN(flush_flop, flush, 1)


    wire [QUEUE_SIZE -1 : 0] data_out;
    wire [QUEUE_SIZE -1 : 0] valid_dec_except_enq;
    assign valid_dec_except_enq = valid_dec & (~enq_valid_oh);
    find_first1_base #(
        .WIDTH(QUEUE_SIZE)
    ) u_find_first1_base (
        .data_in (valid_dec_except_enq),
        .base    (enq_ptr_oh),
        .data_out(data_out)
    );

    always @(*) begin
        enq_ptr_oh_next = enq_ptr_oh;
        if (flush_flop) begin
            enq_ptr_oh_next = data_out_last1_shift_left;
        end else if (~(|valid_dec_except_enq)) begin  //align with deq ptr toselect next enq
            enq_ptr_oh_next = deq_ptr_oh;
        end else if (enq_fire) begin
            enq_ptr_oh_next = data_out;
        end
    end

    wire [QUEUE_SIZE -1 : 0] data_out_last1_shift_left;
    wire [QUEUE_SIZE -1 : 0] data_out_last1;

    assign data_out_last1_shift_left = {data_out_last1[QUEUE_SIZE-2:0], data_out_last1[QUEUE_SIZE-1]};
    find_last1 #(
        .WIDTH(QUEUE_SIZE)
    ) u_find_last1 (
        //means find first valid from left
        .data_in (~valid_dec),
        .data_out(data_out_last1)
    );

endmodule
