
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
    input wire                      write0_valid,     // Is write port 0 valid?
    input wire [PREG_IDX_WIDTH-1:0] write0_data,      // Register address written by write port 0
    input wire                      write1_valid,     // Is write port 1 valid?
    input wire [PREG_IDX_WIDTH-1:0] write1_data,      // Register address written by write port 1
    /* ------------------------------- walk logic ------------------------------- */
    input wire [               1:0] rob_state,
    input wire                      rob_walk0_valid,
    input wire                      rob_walk1_valid
);

    wire is_idle;
    wire is_ovwr;
    wire is_walking;
    assign is_idle    = (rob_state == `ROB_STATE_IDLE);
    assign is_ovwr    = (rob_state == `ROB_STATE_OVERWRITE_RAT);
    assign is_walking = (rob_state == `ROB_STATE_WALKING);

    integer                      i;

    // Queue implementation: Use FIFO (queue deq stores free register addresses)
    reg     [PREG_IDX_WIDTH-1:0] freelist_queue[0:NUM_REGS-1];  // Array of physical register addresses
    reg [LOG_NUM_REGS-1:0] deq_idx, enq_idx;  // LOG_NUM_REGS bit value
    reg [LOG_NUM_REGS-1:0] deq_idx_next, enq_idx_next;  // LOG_NUM_REGS bit value

    // Counter for available registers
    reg  [  LOG_NUM_REGS:0] available_count;  // Number of available registers (range from 0 to NUM_REGS)

    reg  [  LOG_NUM_REGS:0] enq_count;  // Number of available registers (range from 0 to NUM_REGS)
    reg  [  LOG_NUM_REGS:0] deq_count;  // Number of available registers (range from 0 to NUM_REGS)
    reg  [LOG_NUM_REGS-1:0] walk_count;  // Number of walk 

    wire [     ENQ_NUM-1:0] enq_vec;
    wire [     DEQ_NUM-1:0] deq_vec;
    wire [  `WALK_SIZE-1:0] walk_vec;

    assign enq_vec  = {write1_valid, write0_valid};
    assign deq_vec  = {req1_valid, req0_valid};
    assign walk_vec = {rob_walk1_valid, rob_walk0_valid};

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

    always @(*) begin
        walk_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (walk_vec[i]) begin
                walk_count = walk_count + 1'b1;
            end
        end
    end

    // Queue enq pointer update logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enq_idx <= 'h0;  // Reset enq on reset
        end else begin
            enq_idx <= enq_idx_next;
        end
    end

    always @(*) begin
        enq_idx_next = enq_idx + enq_count;
    end



    // Queue deq pointer update logic (dequeue logic)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            deq_idx <= 'h0;  // Reset deq on reset
            //when ovwr,taken deq_idx = enq_idx,then increase
        end else if (is_ovwr) begin
            deq_idx <= enq_idx;
        end else if (is_walking) begin
            deq_idx <= deq_idx + walk_count;
        end else begin
            deq_idx <= deq_idx_next;
        end
    end

    always @(*) begin
        deq_idx_next = deq_idx + deq_count;
    end


    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            available_count <= NUM_REGS;  // Reset enq on reset
        end else begin
            available_count <= available_count + enq_count - deq_count;
        end
    end

    // Request port logic
    always @(*) begin
        req0_data = {PREG_IDX_WIDTH{1'b0}};  // Default to invalid value
        req1_data = {PREG_IDX_WIDTH{1'b0}};  // Default to invalid value

        if (req0_valid ) begin
            // Allocate a register for req0 from the deq of the queue
            req0_data = freelist_queue[deq_idx[LOG_NUM_REGS-1 : 0]];
        end

        if (req1_valid ) begin
            // Allocate a register for req1 from the deq of the queue
            req1_data = freelist_queue[deq_idx[LOG_NUM_REGS-1 : 0]+1];
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
                freelist_queue[enq_idx[LOG_NUM_REGS-1 : 0]] <= write0_data;  // Add to the queue
            end
            if (write1_valid) begin
                // Write register back to the queue from write port 1
                freelist_queue[enq_idx[LOG_NUM_REGS-1 : 0]] <= write1_data;  // Add to the queue
            end
        end
    end

endmodule

