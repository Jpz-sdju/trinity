`include "defines.sv"
module rob (
    input wire               clock,
    input wire               reset_n,
    /* ----------------------------- rob write logic ---------------------------- */
    input wire               instr0_enq_valid,
    input wire [  `PC_RANGE] instr0_pc,
    input wire [       31:0] instr0_instr,
    input wire [`LREG_RANGE] instr0_lrd,
    input wire [`PREG_RANGE] instr0_prd,
    input wire [`PREG_RANGE] instr0_old_prd,
    input wire               instr0_need_to_wb,

    input wire                   instr1_enq_valid,
    input wire [      `PC_RANGE] instr1_pc,
    input wire [           31:0] instr1_instr,
    input wire [    `LREG_RANGE] instr1_lrd,
    input wire [    `PREG_RANGE] instr1_prd,
    input wire [    `PREG_RANGE] instr1_old_prd,
    input wire                   instr1_need_to_wb,
    /* ---------------------------- write back logic from wb pipe---------------------------- */
    //write back port
    input wire                   intwb0_instr_valid,
    input wire [`ROB_SIZE_LOG:0] intwb0_robid,
    /* --------------------------- mem_top to complete -------------------------- */
    input wire                   sq2rob_cmpl_valid,
    input wire [`ROB_SIZE_LOG:0] sq2rob_cmpl_robid,
    input wire                   sq2rob_cmpl_mmio,

    /* --------------------------- output commit port --------------------------- */
    output wire                   commit0_valid,
    output wire [      `PC_RANGE] commit0_pc,
    output wire [           31:0] commit0_instr,
    output wire [    `LREG_RANGE] commit0_lrd,
    output wire [    `PREG_RANGE] commit0_prd,
    output wire [    `PREG_RANGE] commit0_old_prd,
    output wire                   commit0_need_to_wb,  //used to write arch rat
    output wire [`ROB_SIZE_LOG:0] commit0_robid,       //used to wakeup storequeue
    // debug
    output wire                   commit0_skip,

    output wire                   commit1_valid,
    output wire [      `PC_RANGE] commit1_pc,
    output wire [           31:0] commit1_instr,
    output wire [    `LREG_RANGE] commit1_lrd,
    output wire [    `PREG_RANGE] commit1_prd,
    output wire [    `PREG_RANGE] commit1_old_prd,
    output wire [`ROB_SIZE_LOG:0] commit1_robid,
    output wire                   commit1_need_to_wb,
    // debug
    output wire                   commit1_skip,

    /* ------------------------------- flush and walk logic ------------------------------ */
    input wire                   flush_valid,
    input wire [`ROB_SIZE_LOG:0] flush_robid,

    output reg  [        1:0] rob_state,
    output wire               rob_walk0_valid,
    output wire               rob_walk0_complete,
    output wire [`LREG_RANGE] rob_walk0_lrd,
    output wire [`PREG_RANGE] rob_walk0_prd,
    output wire               rob_walk1_valid,
    output wire [`LREG_RANGE] rob_walk1_lrd,
    output wire [`PREG_RANGE] rob_walk1_prd,
    output wire               rob_walk1_complete,


    /* ------------------------------ enq relevant ------------------------------ */
    output reg                    rob_can_enq,
    output reg  [`ROB_SIZE_LOG:0] rob2disp_instr_robid,
    output wire                   end_of_program

);
    reg [6:0] rob_counter;
    assign rob_can_enq          = 1'b1;
    assign rob2disp_instr_robid = enqueue_ptr;

    /* ----------------------------- internal signal ---------------------------- */
    //robentry input
    reg  [  `ROB_SIZE-1:0] enq_valid_dec;  //act as wren signal in robentry
    reg  [      `PC_RANGE] enq_pc_dec                                      [0:`ROB_SIZE-1];
    reg  [           31:0] enq_instr_dec                                   [0:`ROB_SIZE-1];
    reg  [    `LREG_RANGE] enq_lrd_dec                                     [0:`ROB_SIZE-1];
    reg  [    `PREG_RANGE] enq_prd_dec                                     [0:`ROB_SIZE-1];
    reg  [    `PREG_RANGE] enq_old_prd_dec                                 [0:`ROB_SIZE-1];
    reg  [  `ROB_SIZE-1:0] enq_need_to_wb_dec;
    reg  [  `ROB_SIZE-1:0] wb_set_complete_dec;
    reg  [  `ROB_SIZE-1:0] wb_set_skip_dec;
    //robentry output
    wire [  `ROB_SIZE-1:0] entry_ready_to_commit_dec;
    wire [  `ROB_SIZE-1:0] entry_valid_dec;
    wire [  `ROB_SIZE-1:0] entry_complete_dec;
    wire [      `PC_RANGE] entry_pc_dec                                    [0:`ROB_SIZE-1];
    wire [           31:0] entry_instr_dec                                 [0:`ROB_SIZE-1];
    wire [    `LREG_RANGE] entry_lrd_dec                                   [0:`ROB_SIZE-1];
    wire [    `PREG_RANGE] entry_prd_dec                                   [0:`ROB_SIZE-1];
    wire [    `PREG_RANGE] entry_old_prd_dec                               [0:`ROB_SIZE-1];
    wire [  `ROB_SIZE-1:0] entry_need_to_wb_dec;
    wire [  `ROB_SIZE-1:0] entry_skip_dec;
    reg  [  `ROB_SIZE-1:0] commit_vld_dec;
    reg  [  `ROB_SIZE-1:0] flush_dec;

    wire                   instr0_actually_enq;
    wire                   instr1_actually_enq;

    reg  [`ROB_SIZE_LOG:0] enqueue_ptr;  // 7bit:contain flag
    reg  [`ROB_SIZE_LOG:0] dequeue_ptr;  // 7bit:contain flag
    reg  [`ROB_SIZE_LOG:0] walking_ptr;  // 7bit:contain flag

    reg  [`ROB_SIZE_LOG:0] enq_num;
    reg  [`ROB_SIZE_LOG:0] deq_num;



    /* ------------------------ update enqueue_ptr logic ------------------------ */
    //when instr0/1 comes from disp, calculate enq_num 
    //enq_valid_dec[i] also act as wren for robentry
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_valid_dec[i] = 'b0;
            if (instr0_actually_enq & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_valid_dec[i] = 1'b1;
            end
            if (instr1_actually_enq & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_valid_dec[i+1] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        enq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (enq_valid_dec[i]) begin
                enq_num = enq_num + 1;
            end
        end
    end
    //use enq_num to update enqeue_ptr
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enqueue_ptr <= 0;
        end else if (is_rollback) begin
            enqueue_ptr <= flush_robid_latch + 1;
        end else begin
            enqueue_ptr <= enqueue_ptr + enq_num;
        end
    end



    /* -------------------------------------------------------------------------- */
    /*                       set enqeue info in respective entry                       */
    /* -------------------------------------------------------------------------- */

    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_pc_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_pc_dec[i] = instr0_pc;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_pc_dec[i] = instr1_pc;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_instr_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_instr_dec[i] = instr0_instr;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_instr_dec[i] = instr1_instr;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_lrd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_lrd_dec[i] = instr0_lrd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_lrd_dec[i] = instr1_lrd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_prd_dec[i] = instr0_prd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_prd_dec[i] = instr1_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_old_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_old_prd_dec[i] = instr0_old_prd;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_old_prd_dec[i] = instr1_old_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            enq_need_to_wb_dec[i] = 'b0;
            if (instr0_enq_valid & (enqueue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                enq_need_to_wb_dec[i] = instr0_need_to_wb;
            end
            if (instr1_enq_valid & ((enqueue_ptr[`ROB_SIZE_LOG-1:0] + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                enq_need_to_wb_dec[i] = instr1_need_to_wb;
            end
        end
    end


    /* ---------------------------- write back logic ---------------------------- */


    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            wb_set_complete_dec[i] = 'b0;
            if (intwb0_instr_valid & (intwb0_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_complete_dec[i] = 1'b1;
            end
            if (sq2rob_cmpl_valid & (sq2rob_cmpl_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_complete_dec[i] = 1'b1;
            end
            // if (intb_writeback1_valid & (intb_writeback1_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
            //     wb_set_complete_dec[i] = 1'b1;
            // end
        end
    end

    //for now only l/s could trigger skip
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            wb_set_skip_dec[i] = 'b0;
            if (sq2rob_cmpl_valid & sq2rob_cmpl_mmio & (sq2rob_cmpl_robid[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                wb_set_skip_dec[i] = 1'b1;
            end
        end
    end


    /* ------------------------------ dequeue logic ----------------------------- */
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            commit_vld_dec[i] = 'b0;
            if (~is_idle || flush_valid) begin
                commit_vld_dec = 'b0;
            end else if (entry_ready_to_commit_dec[i] & (dequeue_ptr[`ROB_SIZE_LOG-1:0] == i[`ROB_SIZE_LOG-1:0])) begin
                commit_vld_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        deq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (commit_vld_dec[i]) begin
                deq_num = deq_num + 1;
            end
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            dequeue_ptr <= 0;
        end else begin
            dequeue_ptr <= dequeue_ptr + deq_num;
        end
    end

    /* -------------------------- output commit signal -------------------------- */
    assign commit0_valid      = commit_vld_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_pc         = entry_pc_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_instr      = entry_instr_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_lrd        = entry_lrd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_prd        = entry_prd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_old_prd    = entry_old_prd_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    assign commit0_robid      = dequeue_ptr;
    assign commit0_need_to_wb = entry_need_to_wb_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];
    //debug
    assign commit0_skip       = entry_skip_dec[dequeue_ptr[`ROB_SIZE_LOG-1:0]];



    //
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_counter <= 'b0;
        end else begin
            rob_counter <= rob_counter + enq_num[`ROB_SIZE_LOG-1:0] - deq_num[`ROB_SIZE_LOG-1:0];
        end
    end

    /* ------------------------------- flush logic ------------------------------ */
    localparam IDLE = 2'b00;
    localparam ROLLBACK = 2'b01;
    localparam WALK = 2'b10;

    wire is_idle;
    wire is_rollback;
    wire is_walk;

    assign is_idle     = (current_state == IDLE);
    assign is_rollback = (current_state == ROLLBACK);
    assign is_walk     = (current_state == WALK);

    reg [1:0] current_state;
    reg [1:0] next_state;
    assign rob_state = current_state;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            current_state <= 0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (flush_valid) begin
                    next_state = ROLLBACK;
                end else begin
                    next_state = IDLE;
                end
            end
            ROLLBACK: begin
                if (flush_valid) begin
                    next_state = ROLLBACK;
                end else begin
                    next_state = WALK;
                end
            end
            WALK: begin
                if (flush_valid) begin
                    next_state = ROLLBACK;
                end else if (entry_valid_dec[walking_ptr+1] == 0) begin
                    next_state = IDLE;
                end else begin
                    next_state = WALK;
                end
            end
            default: begin

            end
        endcase
    end

    reg [`ROB_SIZE_LOG:0] flush_robid_latch;  // 7bit:contain flag

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flush_robid_latch <= 'b0;
        end else if (flush_valid) begin
            flush_robid_latch <= flush_robid;
        end
    end


    always @(*) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (is_rollback) begin
                if (enqueue_ptr[`ROB_SIZE_LOG-1:0] > flush_robid_latch[`ROB_SIZE_LOG-1:0]) begin
                    flush_dec[i] = (i[`ROB_SIZE_LOG-1:0] > flush_robid_latch[`ROB_SIZE_LOG-1:0]) & (i[`ROB_SIZE_LOG-1:0] < enqueue_ptr[`ROB_SIZE_LOG-1:0]);
                end else begin
                    flush_dec[i] = (i[`ROB_SIZE_LOG-1:0] > flush_robid_latch[`ROB_SIZE_LOG-1:0]) | (i[`ROB_SIZE_LOG-1:0] < enqueue_ptr[`ROB_SIZE_LOG-1:0]);
                end
            end
        end
    end

    /* ------------------------------- walk logic ------------------------------- */

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_ptr <= 'b0;
        end else if (is_rollback) begin
            walking_ptr <= dequeue_ptr;
        end else if (is_walk) begin
            walking_ptr <= walking_ptr + 'd2;
        end
    end

    assign rob_walk0_valid     = entry_valid_dec[walking_ptr[`ROB_SIZE_LOG-1:0]] & entry_need_to_wb_dec[walking_ptr[`ROB_SIZE_LOG-1:0]] & is_walk;
    assign rob_walk0_lrd       = entry_lrd_dec[walking_ptr[`ROB_SIZE_LOG-1:0]];
    assign rob_walk0_prd       = entry_prd_dec[walking_ptr[`ROB_SIZE_LOG-1:0]];
    assign rob_walk0_complete  = entry_complete_dec[walking_ptr[`ROB_SIZE_LOG-1:0]];

    assign rob_walk1_valid     = entry_valid_dec[walking_ptr[`ROB_SIZE_LOG-1:0]+'b1] & entry_need_to_wb_dec[walking_ptr[`ROB_SIZE_LOG-1:0]+'b1] & is_walk;
    assign rob_walk1_lrd       = entry_lrd_dec[walking_ptr[`ROB_SIZE_LOG-1:0]+'b1];
    assign rob_walk1_prd       = entry_prd_dec[walking_ptr[`ROB_SIZE_LOG-1:0]+'b1];
    assign rob_walk1_complete  = entry_complete_dec[walking_ptr[`ROB_SIZE_LOG-1:0]+'b1];


    /* ----------------------------- internal signal ---------------------------- */

    assign instr0_actually_enq = instr0_enq_valid;
    assign instr1_actually_enq = instr1_enq_valid;

    genvar i;
    generate
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin : rob_entity
            robentry u_robentry (
                .clock                (clock),                         //i
                .reset_n              (reset_n),                       //i
                .enq_valid            (enq_valid_dec[i]),              //i//wren signal to write in entry data
                .enq_pc               (enq_pc_dec[i]),                 //i
                .enq_instr            (enq_instr_dec[i]),              //i
                .enq_lrd              (enq_lrd_dec[i]),                //i
                .enq_prd              (enq_prd_dec[i]),                //i
                .enq_old_prd          (enq_old_prd_dec[i]),            //i
                .enq_need_to_wb       (enq_need_to_wb_dec[i]),         //i
                // .enq_skip         ('b0                    ),//i
                .wb_set_complete      (wb_set_complete_dec[i]),        //i
                .wb_set_skip          (wb_set_skip_dec[i]),            //i
                .entry_ready_to_commit(entry_ready_to_commit_dec[i]),  //output//indicate entry ready to be commit, next cycle,commit_vld_dec=1,then invalid this entry
                .entry_valid          (entry_valid_dec[i]),            //output
                .entry_complete       (entry_complete_dec[i]),         //output
                .entry_pc             (entry_pc_dec[i]),               //output
                .entry_instr          (entry_instr_dec[i]),            //output
                .entry_lrd            (entry_lrd_dec[i]),              //output
                .entry_prd            (entry_prd_dec[i]),              //output
                .entry_old_prd        (entry_old_prd_dec[i]),          //output
                .entry_need_to_wb     (entry_need_to_wb_dec[i]),       //output
                .entry_skip           (entry_skip_dec[i]),             //output
                .commit_vld           (commit_vld_dec[i]),             //i
                .flush_vld            (flush_dec[i])                   //i
            );
        end
    endgenerate


    /* -------------------------------- pmu logic ------------------------------- */
    // wire test_begin_of_program;
    // assign test_begin_of_program = (commit0_instr == 32'h00000413) && commit0_valid;
    // always @(posedge clock) begin
    //     if (test_begin_of_program) begin
    //         $display("adsfsadf = %b", test_begin_of_program);
    //     end
    // end



    assign end_of_program = (commit0_instr == 32'h0005006b) && commit0_valid;

    reg [31:0] rob_pmu_flush_times_cnt;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_pmu_flush_times_cnt <= 'b0;
        end else if (flush_valid) begin
            rob_pmu_flush_times_cnt <= rob_pmu_flush_times_cnt + 1;
        end
    end

endmodule
