
module freelist #(
    parameter NUM_REGS = 32,  // Assume there are 32 physical registers
    parameter LOG_NUM_REGS = 5,  // Assume there are 32 physical registers
    parameter PREG_IDX_WIDTH = 6,  // 6-bit address width
    parameter ENQ_NUM = 2,
    parameter DEQ_NUM = 2
) (
    input wire clock,
    input wire reset_n,

    // rename alloc ports
    input  wire                      req0_valid,  // Is request 0 valid?
    output reg  [PREG_IDX_WIDTH-1:0] req0_data,   // Register address returned to request 0
    input  wire                      req1_valid,  // Is request 1 valid?
    output reg  [PREG_IDX_WIDTH-1:0] req1_data,   // Register address returned to request 1

    // commit free ports
    input wire                      write0_valid,  // Is write port 0 valid?
    input wire [PREG_IDX_WIDTH-1:0] write0_data,   // Register address written by write port 0
    input wire                      write1_valid,  // Is write port 1 valid?
    input wire [PREG_IDX_WIDTH-1:0] write1_data    // Register address written by write port 1
);
    integer                      i;

    // Queue implementation: Use FIFO (queue head stores free register addresses)
    reg     [PREG_IDX_WIDTH-1:0] freelist_queue[0:NUM_REGS-1];  // Array of physical register addresses
    reg [LOG_NUM_REGS:0] queue_head, queue_tail;  // 1 bit flag, LOG_NUM_REGS bit value
    reg [LOG_NUM_REGS:0] queue_head_next, queue_tail_next;  // 1 bit flag, LOG_NUM_REGS bit value

    // Counter for available registers
    reg  [LOG_NUM_REGS:0] available_count;  // Number of available registers (range from 0 to NUM_REGS)

    reg  [LOG_NUM_REGS:0] enq_count;  // Number of available registers (range from 0 to NUM_REGS)
    reg  [LOG_NUM_REGS:0] deq_count;  // Number of available registers (range from 0 to NUM_REGS)

    wire [   ENQ_NUM-1:0] enq_vec;
    wire [   DEQ_NUM-1:0] deq_vec;

    assign enq_vec = {write1_valid, write0_valid};
    assign deq_vec = {req1_valid, req0_valid};

    always @(*) begin
        enq_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (enq_vec[i]) begin
                enq_count = enq_count + 1'b1;
            end
        end
    end

    always @(*) begin
        deq_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (deq_vec[i]) begin
                deq_count = deq_count + 1'b1;
            end
        end
    end

    // Queue tail pointer update logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_tail <= 'h31;  // Reset tail on reset
        end else begin
            queue_tail <= queue_tail_next;
        end
    end

    always @(*) begin
        queue_tail_next = queue_tail + enq_count;
    end



    // Queue head pointer update logic (dequeue logic)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_head <= 'h0;  // Reset head on reset
        end else begin
            queue_head <= queue_head_next;
        end
    end

    always @(*) begin
        queue_head_next = queue_head + deq_count;
    end


    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            available_count <= NUM_REGS;  // Reset tail on reset
        end else begin
            available_count <= available_count + enq_count - deq_count;
        end
    end


    // Request port logic
    always @(*) begin
        req0_data = {PREG_IDX_WIDTH{1'bx}};  // Default to invalid value
        req1_data = {PREG_IDX_WIDTH{1'bx}};  // Default to invalid value

        if (req0_valid && available_count > 0) begin
            // Allocate a register for req0 from the head of the queue
            req0_data = freelist_queue[queue_head[LOG_NUM_REGS-1 :0 ]];
        end

        if (req1_valid && available_count > 1) begin
            // Allocate a register for req1 from the head of the queue
            req1_data = freelist_queue[queue_head[LOG_NUM_REGS-1 :0 ]+1];
        end
    end

    // Write-back logic (handles writing registers back to the queue)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Initialize freelist and available_count on reset
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                freelist_queue[i] <= (i[5:0] + 6'd32);
            end
        end else begin
            if (write0_valid) begin
                // Write register back to the queue from write port 0
                freelist_queue[queue_tail[LOG_NUM_REGS-1 :0 ]] <= write0_data;  // Add to the queue
            end
            if (write1_valid) begin
                // Write register back to the queue from write port 1
                freelist_queue[queue_tail[LOG_NUM_REGS-1 :0 ]] <= write1_data;  // Add to the queue
            end
        end
    end

endmodule

