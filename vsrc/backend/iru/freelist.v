
module freelist #(
    parameter ENQ_NUM = 2,
    parameter DEQ_NUM = 2
) (
    input wire clock,
    input wire reset_n,

    // rename alloc ports
    input  wire               req0_valid,  // Is request 0 valid?
    output reg  [`PREG_RANGE] req0_data,   // Register address returned to request 0
    input  wire               req1_valid,  // Is request 1 valid?
    output reg  [`PREG_RANGE] req1_data,   // Register address returned to request 1

    // commit free ports
    input wire               write0_valid,     // Is write port 0 valid?
    input wire [`PREG_RANGE] write0_data,      // Register address written by write port 0
    input wire               write1_valid,     // Is write port 1 valid?
    input wire [`PREG_RANGE] write1_data,      // Register address written by write port 1
    /* ------------------------------- walk logic ------------------------------- */
    input wire [        1:0] rob_state,
    input wire               rob_walk0_valid,
    input wire               rob_walk1_valid,

    output wire freelist_can_alloc
);

    wire is_idle;
    wire is_rollback;
    wire is_walking;
    assign is_idle     = (rob_state == `ROB_STATE_IDLE);
    assign is_rollback = (rob_state == `ROB_STATE_ROLLBACK);
    assign is_walking  = (rob_state == `ROB_STATE_WALK);



    // Queue implementation: Use FIFO (queue deq stores free register addresses)
    reg [       `PREG_RANGE] freelist_queue [0:`FREELIST_SIZE-1];  // Array of physical register addresses
    reg [`FREELIST_SIZE-1:0] freelist_valid;
    reg [`FREELIST_SIZE_LOG:0] deq_ptr_next, enq_ptr_next;
    reg [`FREELIST_SIZE_LOG:0] deq_ptr, enq_ptr;

    // Counter for available registers
    reg  [`FREELIST_SIZE_LOG:0] available_count;  // Number of available registers (range from 0 to `FREELIST_SIZE)

    reg  [`FREELIST_SIZE_LOG:0] enq_count;  // Number of available registers (range from 0 to `FREELIST_SIZE)
    reg  [`FREELIST_SIZE_LOG:0] deq_count;  // Number of available registers (range from 0 to `FREELIST_SIZE)
    reg  [`FREELIST_SIZE_LOG:0] walk_count;  // Number of walk 

    wire [         ENQ_NUM-1:0] enq_vec;
    wire [         DEQ_NUM-1:0] deq_vec;
    wire [      `WALK_SIZE-1:0] walk_vec;

    assign enq_vec  = {write1_valid, write0_valid};
    assign deq_vec  = {req1_valid, req0_valid};
    assign walk_vec = {rob_walk1_valid, rob_walk0_valid};

    always @(*) begin
        integer i;
        enq_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (enq_vec[i]) begin
                enq_count = enq_count + 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        deq_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (deq_vec[i] & freelist_can_alloc) begin
                deq_count = deq_count + 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        walk_count = 'b0;
        for (i = 0; i < ENQ_NUM; i = i + 1) begin
            if (walk_vec[i]) begin
                walk_count = walk_count + 1'b1;
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                               enq ptr region                               */
    /* -------------------------------------------------------------------------- */
    // Queue enq pointer update logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enq_ptr <= {1'b1, {`FREELIST_SIZE_LOG'b0}};  // Reset enq on reset
        end else begin
            enq_ptr <= enq_ptr_next;
        end
    end

    always @(*) begin
        enq_ptr_next = enq_ptr + enq_count;
    end

    /* -------------------------------------------------------------------------- */
    /*                               deq ptr region                               */
    /* -------------------------------------------------------------------------- */

    // Queue deq pointer update logic (dequeue logic)
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            deq_ptr <= 'h0;  // Reset deq on reset
            //when ovwr,taken deq_ptr = enq_ptr,then increase
        end else if (is_rollback) begin
 //           if (deq_ptr[`FREELIST_SIZE_LOG:0] == enq_ptr[`FREELIST_SIZE_LOG:0]) begin
 //               deq_ptr <= enq_ptr;
 //           end else begin
                deq_ptr <= {deq_ptr[`FREELIST_SIZE_LOG], enq_ptr[`FREELIST_SIZE_LOG-1:0]};
 //           end
        end else if (is_walking) begin
            deq_ptr <= deq_ptr + walk_count;
        end else begin
            deq_ptr <= deq_ptr_next;
        end
    end

    always @(*) begin
        deq_ptr_next = deq_ptr + deq_count;
    end


    /* -------------------------------------------------------------------------- */
    /*                             freelist valid vec                             */
    /* -------------------------------------------------------------------------- */
    reg [`FREELIST_SIZE-1:0] enq_ptr_oh;
    reg [`FREELIST_SIZE-1:0] deq_ptr_oh;
    reg [`FREELIST_SIZE-1:0] walk_ptr_dec;
    always @(*) begin
        integer i;
        enq_ptr_oh = 'b0;
        if (|enq_vec) begin
            for (i = 0; i < `FREELIST_SIZE; i = i + 1) begin
                if (enq_ptr[`FREELIST_SIZE_LOG-1:0] == i) begin
                    enq_ptr_oh[i] = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        integer i;
        deq_ptr_oh = 'b0;
        if (|deq_vec) begin
            for (i = 0; i < `FREELIST_SIZE; i = i + 1) begin
                if (deq_ptr[`FREELIST_SIZE_LOG-1:0] == i) begin
                    deq_ptr_oh[i] = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        integer i;
        walk_ptr_dec = 'b0;

    end




    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            freelist_valid <= {`FREELIST_SIZE{1'b1}};  // Reset deq on reset
            //when ovwr,taken deq_ptr = enq_ptr,then increase
        end else if (is_rollback) begin
            freelist_valid <= {`FREELIST_SIZE{1'b1}};
        end else if (is_walking) begin
            if (walk_count == 1) begin
                freelist_valid[deq_ptr[`FREELIST_SIZE_LOG-1:0]] <= 'b0;
            end else if (walk_count == 2) begin
                freelist_valid[deq_ptr[`FREELIST_SIZE_LOG-1:0]]   <= 'b0;
                freelist_valid[deq_ptr[`FREELIST_SIZE_LOG-1:0]+1] <= 'b0;
            end
        end else begin
            if (write0_valid) begin
                freelist_valid[enq_ptr[`FREELIST_SIZE_LOG-1:0]] <= 1'b1;
            end
            if (req0_valid) begin
                freelist_valid[deq_ptr[`FREELIST_SIZE_LOG-1:0]] <= 1'b0;
            end
        end
    end
    assign freelist_can_alloc = |freelist_valid;




    wire is_full;
    wire is_empty;
    assign is_full  = (deq_ptr[`FREELIST_SIZE_LOG] != enq_ptr[`FREELIST_SIZE_LOG]) & (deq_ptr[`FREELIST_SIZE_LOG-1:0] == enq_ptr[`FREELIST_SIZE_LOG-1:0]);
    assign is_empty = deq_ptr == enq_ptr;
    always @(*) begin
        available_count = 'b0;
        if (is_full) begin
            available_count = 'd`FREELIST_SIZE;
        end else if (is_empty) begin
            available_count = 'h0;
        end else if (deq_ptr[`FREELIST_SIZE_LOG] == enq_ptr[`FREELIST_SIZE_LOG]) begin
            available_count = enq_ptr[`FREELIST_SIZE_LOG-1:0] - deq_ptr[`FREELIST_SIZE_LOG-1:0];
        end else begin
            available_count = `FREELIST_SIZE - deq_ptr[`FREELIST_SIZE_LOG-1:0] + enq_ptr[`FREELIST_SIZE_LOG-1:0];
        end
    end

    // Request port logic
    always @(*) begin
        req0_data = 'b0;  // Default to invalid value
        req1_data = 'b0;  // Default to invalid value

        if (req0_valid) begin
            // Allocate a register for req0 from the deq of the queue
            req0_data = freelist_queue[deq_ptr[`FREELIST_SIZE_LOG-1 : 0]];
        end

        if (req1_valid) begin
            // Allocate a register for req1 from the deq of the queue
            req1_data = freelist_queue[deq_ptr[`FREELIST_SIZE_LOG-1 : 0]+1];
        end
    end

    // Write-back logic (handles writing registers back to the queue)
    always @(posedge clock or negedge reset_n) begin
        integer i;
        if (!reset_n) begin
            // Initialize freelist and available_count on reset
            for (i = 0; i < `FREELIST_SIZE; i = i + 1) begin
                freelist_queue[i] <= (i[5:0] + 'd32);
            end
        end else begin
            if (write0_valid) begin
                // Write register back to the queue from write port 0
                freelist_queue[enq_ptr[`FREELIST_SIZE_LOG-1 : 0]] <= write0_data;  // Add to the queue
            end
            if (write1_valid) begin
                // Write register back to the queue from write port 1
                freelist_queue[enq_ptr[`FREELIST_SIZE_LOG-1 : 0]] <= write1_data;  // Add to the queue
            end
        end
    end

endmodule

