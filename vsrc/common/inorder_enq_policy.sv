`include "defines.sv"
module inorder_enq_policy #(
    parameter QUEUE_SIZE = 8,
    parameter QUEUE_SIZE_LOG = 3
) (
    input  wire                      clock,
    input  wire                      reset_n,
    input  wire                      flush_valid,
    input  wire [  QUEUE_SIZE_LOG:0] flush_cnt,
    input  wire                      enq_fire,
    output reg  [ QUEUE_SIZE -1 : 0] enq_ptr_oh,   //onehot form enqueue pointer
    output reg  [QUEUE_SIZE_LOG : 0] enq_ptr

);

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enq_ptr <= 'b0;
        end else if (flush_valid) begin
            enq_ptr <= enq_ptr - flush_cnt;  
        end else if (enq_fire) begin
            enq_ptr <= enq_ptr + 1;
        end
    end

    always @(*) begin
        integer i;
        enq_ptr_oh = 'b0;
        for (i = 0; i < QUEUE_SIZE; i = i + 1) begin
            if (enq_ptr[QUEUE_SIZE_LOG-1:0] == i) begin
                enq_ptr_oh[i] = 'b1;
            end
        end
    end



endmodule
