`include "defines.sv"
module sq_entry (
    input wire                   clock,
    input wire                   reset_n,
    input wire                   enq_valid,
    input wire [`ROB_SIZE_LOG:0] enq_robid,
    //debug
    input wire [      `PC_RANGE] enq_pc,

    /* -------------------------- writeback fill field -------------------------- */
    input wire              agu_cmpl_valid,
    input wire              agu_cmpl_mmio,
    input wire [`SRC_RANGE] agu_cmpl_addr,

    input wire              dgu_cmpl_valid,
    input wire [`SRC_RANGE] dgu_cmpl_data,
    input wire [`SRC_RANGE] dgu_cmpl_mask,
    input wire [       3:0] dgu_cmpl_size,

    /* ---------------------------- commit to wakeup ---------------------------- */
    input  wire                   commit,
    /* ------------------------------ deq to dcache ----------------------------- */
    input  wire                   issuing,
    /* ---------------------------------- flush --------------------------------- */
    input  wire                   flush,
    /* ---------------------------- output deq region --------------------------- */
    output wire [`ROB_SIZE_LOG:0] robid,
    output wire                   ready_to_deq,
    output wire                   valid,
    output wire                   complete,
    output wire                   mmio,
    output wire [     `SRC_RANGE] deq_store_addr,
    output wire [     `SRC_RANGE] deq_store_data,
    output wire [     `SRC_RANGE] deq_store_mask,
    output wire [            3:0] deq_store_ls_size


);
    reg                   queue_valid;
    reg [      `PC_RANGE] queue_pc;
    reg [`ROB_SIZE_LOG:0] queue_robid;
    reg                   queue_commited;
    reg                   queue_complete;
    //sig below wait for wb update
    reg                   queue_mmio;
    reg [     `SRC_RANGE] queue_store_addr;
    reg [     `SRC_RANGE] queue_store_data;
    reg [     `SRC_RANGE] queue_store_mask;
    reg [            3:0] queue_store_ls_size;


    `MACRO_LATCH_NONEN(queue_pc, enq_pc, enq_valid, `PC_LENGTH)
    `MACRO_LATCH_NONEN(queue_robid, enq_robid, enq_valid, `ROB_SIZE_LOG + 1)

    /* -------------------------------------------------------------------------- */
    /*                      enq and writeback  wakeup region                      */
    /* -------------------------------------------------------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_valid <= 'b0;
        end else if (enq_valid) begin
            queue_valid <= enq_valid;
        end else if (issuing) begin
            queue_valid <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_mmio <= 'b0;
        end else if (enq_valid) begin
            queue_mmio <= 'b0;
        end else if (agu_cmpl_valid & agu_cmpl_mmio) begin
            queue_mmio <= 'b1;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_pc <= 'b0;
        end else if (enq_valid) begin
            queue_pc <= enq_pc;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_commited <= 'b0;
        end else if (enq_valid) begin
            queue_commited <= 'b0;
        end else if (commit) begin
            queue_commited <= 1'b1;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_complete <= 'b0;
        end else if (enq_valid) begin
            queue_complete <= 'b0;
        end else if (agu_cmpl_valid) begin
            queue_complete <= 1'b1;
        end
    end



    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_addr <= 'b0;
        end else if (agu_cmpl_valid & ~agu_cmpl_mmio) begin
            queue_store_addr <= agu_cmpl_addr;
        end
    end



    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_data <= 'b0;
        end else if (dgu_cmpl_valid ) begin
            queue_store_data <= dgu_cmpl_data;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_mask <= 'b0;
        end else if (dgu_cmpl_valid ) begin
            queue_store_mask <= dgu_cmpl_mask;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_ls_size <= 'b0;
        end else if (dgu_cmpl_valid ) begin
            queue_store_ls_size <= dgu_cmpl_size;
        end
    end

    assign valid             = queue_valid;
    assign mmio              = queue_mmio;
    assign robid             = queue_robid;
    assign complete          = queue_complete;
    assign deq_store_addr    = queue_store_addr;
    assign deq_store_data    = queue_store_data;
    assign deq_store_mask    = queue_store_mask;
    assign deq_store_ls_size = queue_store_ls_size;

    assign ready_to_deq       = queue_valid & queue_commited;
endmodule
