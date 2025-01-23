module sq_entry (
    input wire                     clock,
    input wire                     reset_n,
    input wire                     enq_valid,
    input wire                     enq_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_robidx,
    //debug
    input wire [        `PC_RANGE] enq_pc,

    /* -------------------------- writeback fill field -------------------------- */
    input wire              writeback_valid,
    input wire              writeback_mmio,
    input wire [`SRC_RANGE] writeback_store_addr,
    input wire [`SRC_RANGE] writeback_store_data,
    input wire [`SRC_RANGE] writeback_store_mask,
    input wire [       3:0] writeback_store_ls_size,

    output wire                     robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] robidx,
    /* ---------------------------- commit to wakeup ---------------------------- */
    input  wire                     commit,
    /* ------------------------------ deq to dcache ----------------------------- */
    input  wire                     issuing,
    /* ---------------------------------- flush --------------------------------- */
    input  wire                     flush,
    /* ---------------------------- output deq region --------------------------- */
    output wire                     ready_to_go,
    output wire                     valid,
    output wire                     mmio,
    output wire [       `SRC_RANGE] deq_store_addr,
    output wire [       `SRC_RANGE] deq_store_data,
    output wire [       `SRC_RANGE] deq_store_mask,
    output wire [              3:0] deq_store_ls_size


);
    reg                     queue_valid;
    reg [        `PC_RANGE] queue_pc;
    reg                     queue_robidx_flag;
    reg [`ROB_SIZE_LOG-1:0] queue_robidx;
    reg                     queue_commited;
    //sig below wait for wb update
    reg                     queue_mmio;
    reg [       `SRC_RANGE] queue_store_addr;
    reg [       `SRC_RANGE] queue_store_data;
    reg [       `SRC_RANGE] queue_store_mask;
    reg [              3:0] queue_store_ls_size;


    `MACRO_LATCH_NONEN(queue_pc, enq_pc, enq_valid, `PC_LENGTH)
    `MACRO_LATCH_NONEN(queue_robidx_flag, enq_robidx_flag, enq_valid, 1)
    `MACRO_LATCH_NONEN(queue_robidx, enq_robidx, enq_valid, `ROB_SIZE_LOG)

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
        end else if (writeback_valid & writeback_mmio) begin
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
            queue_store_addr <= 'b0;
        end else if (writeback_valid & ~writeback_mmio) begin
            queue_store_addr <= writeback_store_addr;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_data <= 'b0;
        end else if (writeback_valid & ~writeback_mmio) begin
            queue_store_data <= writeback_store_data;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_mask <= 'b0;
        end else if (writeback_valid & ~writeback_mmio) begin
            queue_store_mask <= writeback_store_mask;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | flush) begin
            queue_store_ls_size <= 'b0;
        end else if (writeback_valid & ~writeback_mmio) begin
            queue_store_ls_size <= writeback_store_ls_size;
        end
    end

    assign valid             = queue_valid;
    assign mmio              = queue_mmio;

    assign robidx_flag       = queue_robidx_flag;
    assign robidx            = queue_robidx;

    assign deq_store_addr    = queue_store_addr;
    assign deq_store_data    = queue_store_data;
    assign deq_store_mask    = queue_store_mask;
    assign deq_store_ls_size = queue_store_ls_size;

    assign ready_to_go       = queue_valid & queue_commited;
endmodule
