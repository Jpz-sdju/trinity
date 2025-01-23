`include "defines.sv"
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */
module rob (
    input wire               clock,
    input wire               reset_n,
    //rob enq logic
    input wire               instr0_enq_valid,
    input wire               issuequeue2rob_instr0_can_accept,
    input wire [  `PC_RANGE] instr0_pc,
    input wire [       31:0] instr0,
    input wire [`LREG_RANGE] instr0_lrs1,
    input wire [`LREG_RANGE] instr0_lrs2,
    input wire [`LREG_RANGE] instr0_lrd,
    input wire [`PREG_RANGE] instr0_prd,
    input wire [`PREG_RANGE] instr0_old_prd,
    input wire               instr0_need_to_wb,

    input wire               instr1_enq_valid,
    input wire               issuequeue2rob_instr1_can_accept,
    input wire [  `PC_RANGE] instr1_pc,
    input wire [       31:0] instr1,
    input wire [`LREG_RANGE] instr1_lrs1,
    input wire [`LREG_RANGE] instr1_lrs2,
    input wire [`LREG_RANGE] instr1_lrd,
    input wire [`PREG_RANGE] instr1_prd,
    input wire [`PREG_RANGE] instr1_old_prd,
    input wire               instr1_need_to_wb,

    //counter(temp sig)
    output reg [`ROB_SIZE_LOG-1:0] counter,

    //robidx output put
    output reg                     enq_robidx_flag,
    output reg [`ROB_SIZE_LOG-1:0] enq_robidx,

    //write back port
    input wire                     writeback0_valid,
    input wire                     writeback0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback0_robidx,
    input wire                     writeback0_need_to_wb,

    input wire                     writeback1_valid,
    input wire                     writeback1_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback1_robidx,
    input wire                     writeback1_need_to_wb,
    input wire                     writeback1_mmio,

    input wire                     writeback2_valid,
    input wire                     writeback2_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback2_robidx,
    input wire                     writeback2_need_to_wb,

    //commit port
    output wire                     commits0_valid,
    output wire [        `PC_RANGE] commits0_pc,
    output wire [             31:0] commits0_instr,
    output wire [      `LREG_RANGE] commits0_lrd,
    output wire [      `PREG_RANGE] commits0_prd,
    output wire [      `PREG_RANGE] commits0_old_prd,
    // debug
    output wire [`ROB_SIZE_LOG-1:0] commits0_robidx,
    output wire                     commits0_need_to_wb,
    output wire                     commits0_skip,


    output wire                     commits1_valid,
    output wire [        `PC_RANGE] commits1_pc,
    output wire [             31:0] commits1_instr,
    output wire [      `LREG_RANGE] commits1_lrd,
    output wire [      `PREG_RANGE] commits1_prd,
    output wire [      `PREG_RANGE] commits1_old_prd,
    // debug
    output wire [`ROB_SIZE_LOG-1:0] commits1_robidx,
    output wire                     commits1_need_to_wb,
    output wire                     commits1_skip,

    //flush
    input wire                     flush_valid,
    input wire [             63:0] flush_target,
    input wire                     flush_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    /* ------------------------------- walk logic ------------------------------- */
    output reg  [        1:0] rob_state,
    output wire               rob_walk0_valid,
    output wire               rob_walk0_complete,
    output wire [`LREG_RANGE] rob_walk0_lrd,
    output wire [`PREG_RANGE] rob_walk0_prd,
    output wire               rob_walk1_valid,
    output wire [`LREG_RANGE] rob_walk1_lrd,
    output wire [`PREG_RANGE] rob_walk1_prd,
    output wire               rob_walk1_complete

);


    reg                      enq_flag;
    reg  [`ROB_SIZE_LOG-1:0] enq_idx;
    reg                      enq_flag_next;
    reg  [`ROB_SIZE_LOG-1:0] enq_idx_next;
    reg  [  `ROB_SIZE_LOG:0] enq_num;  //add one bit to adapt flag bit

    reg                      deq_flag;
    reg  [`ROB_SIZE_LOG-1:0] deq_idx;
    reg                      deq_flag_next;
    reg  [`ROB_SIZE_LOG-1:0] deq_idx_next;
    reg  [  `ROB_SIZE_LOG:0] deq_num;  //add one bit to adapt flag bit

    reg  [    `ROB_SIZE-1:0] rob_entries_enq_dec;
    reg  [        `PC_RANGE] rob_entries_enq_pc_dec                   [0:`ROB_SIZE-1];
    reg  [             31:0] rob_entries_enq_instr_dec                [0:`ROB_SIZE-1];
    reg  [      `LREG_RANGE] rob_entries_enq_lrd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] rob_entries_enq_prd_dec                  [0:`ROB_SIZE-1];
    reg  [      `PREG_RANGE] rob_entries_enq_old_prd_dec              [0:`ROB_SIZE-1];
    reg  [    `ROB_SIZE-1:0] rob_entries_enq_need_to_wb_dec;

    wire [    `ROB_SIZE-1:0] rob_entries_valid_dec;
    wire [    `ROB_SIZE-1:0] rob_entries_deq_dec;
    wire [        `PC_RANGE] rob_entries_deq_pc_dec                   [0:`ROB_SIZE-1];
    wire [             31:0] rob_entries_deq_instr_dec                [0:`ROB_SIZE-1];
    wire [      `LREG_RANGE] rob_entries_deq_lrd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] rob_entries_deq_prd_dec                  [0:`ROB_SIZE-1];
    wire [      `PREG_RANGE] rob_entries_deq_old_prd_dec              [0:`ROB_SIZE-1];
    wire [    `ROB_SIZE-1:0] rob_entries_deq_need_to_wb_dec;
    wire [    `ROB_SIZE-1:0] rob_entries_deq_skip_dec;
    wire [    `ROB_SIZE-1:0] rob_entries_deq_complete_dec;

    reg  [    `ROB_SIZE-1:0] flush_dec;
    reg  [    `ROB_SIZE-1:0] need_walk_dec;
    wire                     is_idle;
    wire                     is_ovwr;
    wire                     is_walking;
    assign is_idle    = (rob_state == `ROB_STATE_IDLE);
    assign is_ovwr    = (rob_state == `ROB_STATE_OVERWRITE_RAT);
    assign is_walking = (rob_state == `ROB_STATE_WALKING);
    //used to latch flush robidx and robidx flag to walk and flush
    reg                      flush_start_robidx_flag;
    reg  [`ROB_SIZE_LOG-1:0] flush_start_robidx;

    //IQ take this instr,we can let instr actually in
    wire                     instr0_actually_enq;
    wire                     instr1_actually_enq;

    assign instr0_actually_enq = instr0_enq_valid & issuequeue2rob_instr0_can_accept;
    assign instr1_actually_enq = instr1_enq_valid & issuequeue2rob_instr1_can_accept;

    /* -------------------------------------------------------------------------- */
    /*                        enq information to dec format                       */
    /* -------------------------------------------------------------------------- */
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_dec[i] = 'b0;
            if (instr0_actually_enq & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_dec[i] = 1'b1;
            end
            if (instr1_actually_enq & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_dec[i] = 1'b1;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_pc_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_pc_dec[i] = instr0_pc;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_pc_dec[i] = instr1_pc;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_instr_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_instr_dec[i] = instr0;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_instr_dec[i] = instr1;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_lrd_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_lrd_dec[i] = instr0_lrd;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_lrd_dec[i] = instr1_lrd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_prd_dec[i] = instr0_prd;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_prd_dec[i] = instr1_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_old_prd_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_old_prd_dec[i] = instr0_old_prd;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_old_prd_dec[i] = instr1_old_prd;
            end
        end
    end
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_enq_need_to_wb_dec[i] = 'b0;
            if (instr0_enq_valid & (enq_idx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_need_to_wb_dec[i] = instr0_need_to_wb;
            end
            if (instr1_enq_valid & ((enq_idx + 1) == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_enq_need_to_wb_dec[i] = instr1_need_to_wb;
            end
        end
    end
    /* -------------------------------------------------------------------------- */
    /*                                  enq logic                                 */
    /* -------------------------------------------------------------------------- */


    always @(*) begin
        integer i;
        enq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (rob_entries_enq_dec[i]) begin
                enq_num = enq_num + 1;
            end
        end
    end

    //when flush happen,enq ptr should point to next entry of FLUSH ROBIDX 
    always @(*) begin
        if (is_ovwr) begin
            {enq_flag_next, enq_idx_next} = {flush_start_robidx_flag, flush_start_robidx} + 'b1;
        end else begin
            {enq_flag_next, enq_idx_next} = {enq_flag, enq_idx} + enq_num;
        end
    end


    `MACRO_DFF_NONEN(enq_flag, enq_flag_next, 1)
    `MACRO_DFF_NONEN(enq_idx, enq_idx_next, `ROB_SIZE_LOG)


    //output for enq issue queue
    assign enq_robidx_flag = enq_flag;
    assign enq_robidx      = enq_idx;

    /* -------------------------------------------------------------------------- */
    /*                               writeback logic                              */
    /* -------------------------------------------------------------------------- */
    reg [`ROB_SIZE-1:0] rob_entries_writeback_dec;
    reg [`ROB_SIZE-1:0] rob_entries_writeback_skip_dec;
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_writeback_dec[i] = 'b0;
            if (writeback0_valid & (writeback0_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
            if (writeback1_valid & (writeback1_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
            if (writeback2_valid & (writeback2_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_dec[i] = 1'b1;
            end
        end
    end

    //for now only l/s could trigger skip
    always @(*) begin
        integer i;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_entries_writeback_skip_dec[i] = 'b0;
            if (writeback1_valid & writeback1_mmio & (writeback1_robidx == i[`ROB_SIZE_LOG-1:0])) begin
                rob_entries_writeback_skip_dec[i] = 1'b1;
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                commit logic (deq)                          */
    /* -------------------------------------------------------------------------- */
    reg [`ROB_SIZE-1:0] go_commit;  //max hot = 2,cause commit width is 2

    //jpz note:below is a very ugly logic!!
    always @(*) begin
        go_commit[`ROB_SIZE-1:0] = 'b0;
        if (~is_idle | flush_valid) begin
            go_commit[`ROB_SIZE-1:0] = 'b0;
        end else begin
            go_commit[deq_idx] = rob_entries_deq_dec[deq_idx];
            // go_commit[deq_idx+1]     = rob_entries_deq_dec[deq_idx+1] & go_commit[deq_idx];
        end
    end


    always @(*) begin
        integer i;
        deq_num = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (go_commit[i]) begin
                deq_num = deq_num + 1;
            end
        end
    end

    always @(*) begin
        {deq_flag_next, deq_idx_next} = {deq_flag, deq_idx} + deq_num;
    end


    `MACRO_DFF_NONEN(deq_flag, deq_flag_next, 1)
    `MACRO_DFF_NONEN(deq_idx, deq_idx_next, `ROB_SIZE_LOG)

    // assign commits0_valid      = rob_entries_deq_dec[deq_idx] ;
    assign commits0_valid      = go_commit[deq_idx];
    assign commits0_pc         = rob_entries_deq_pc_dec[deq_idx];
    assign commits0_instr      = rob_entries_deq_instr_dec[deq_idx];
    assign commits0_lrd        = rob_entries_deq_lrd_dec[deq_idx];
    assign commits0_prd        = rob_entries_deq_prd_dec[deq_idx];
    assign commits0_old_prd    = rob_entries_deq_old_prd_dec[deq_idx];
    //debug
    assign commits0_robidx     = deq_idx;
    assign commits0_need_to_wb = rob_entries_deq_need_to_wb_dec[deq_idx];
    assign commits0_skip       = rob_entries_deq_skip_dec[deq_idx];

    genvar i;
    generate
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin : rob_entity
            robentry u_robentry (
                .clock         (clock),
                .reset_n       (reset_n),
                .enq           (rob_entries_enq_dec[i]),
                .enq_pc        (rob_entries_enq_pc_dec[i]),
                .enq_instr     (rob_entries_enq_instr_dec[i]),
                .enq_lrd       (rob_entries_enq_lrd_dec[i]),
                .enq_prd       (rob_entries_enq_prd_dec[i]),
                .enq_old_prd   (rob_entries_enq_old_prd_dec[i]),
                .enq_need_to_wb(rob_entries_enq_need_to_wb_dec[i]),
                .enq_skip      ('b0),
                .writeback     (rob_entries_writeback_dec[i]),
                .writeback_skip(rob_entries_writeback_skip_dec[i]),
                .valid         (rob_entries_valid_dec[i]),
                .can_deq       (rob_entries_deq_dec[i]),
                .deq_complete  (rob_entries_deq_complete_dec[i]),
                .deq_pc        (rob_entries_deq_pc_dec[i]),
                .deq_instr     (rob_entries_deq_instr_dec[i]),
                .deq_lrd       (rob_entries_deq_lrd_dec[i]),
                .deq_prd       (rob_entries_deq_prd_dec[i]),
                .deq_old_prd   (rob_entries_deq_old_prd_dec[i]),
                .deq_need_to_wb(rob_entries_deq_need_to_wb_dec[i]),
                .deq_skip      (rob_entries_deq_skip_dec[i]),
                //commit,clear valid
                .commit        (go_commit[i]),
                //flush entry
                .flush         (flush_dec[i])
            );
        end
    endgenerate

    reg [`ROB_SIZE_LOG-1:0] counter_next;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            counter <= 'b0;
        end else begin
            counter <= counter_next;
        end
    end

    always @(*) begin
        counter_next = counter + enq_num[`ROB_SIZE_LOG-1:0] - deq_num[`ROB_SIZE_LOG-1:0];
    end


    /* -------------------------------------------------------------------------- */
    /*                                 walk logic                                 */
    /* -------------------------------------------------------------------------- */

    //only two hot at most for now
    reg [    `ROB_SIZE-1:0] walking_dec;
    //why not use walking_flag?cause unuse
    reg [`ROB_SIZE_LOG-1:0] walking_idx;

    /*At overwrite state,ARCH RAT should copy to SPEC RAT;
    and flushed entries in rob should be clear ;
    at same time ,calculate all need_walk_dec  */

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            rob_state <= 2'b0;
        end else begin
            case (rob_state)
                `ROB_STATE_IDLE: begin
                    if (flush_valid) begin
                        rob_state <= `ROB_STATE_OVERWRITE_RAT;
                    end
                end

                `ROB_STATE_OVERWRITE_RAT: begin
                    //means coming a older flush
                    if (flush_valid) begin
                        rob_state <= `ROB_STATE_OVERWRITE_RAT;
                    end else begin
                        rob_state <= `ROB_STATE_WALKING;

                    end
                end
                `ROB_STATE_WALKING: begin
                    //means coming a older flush
                    if (flush_valid) begin
                        rob_state <= `ROB_STATE_OVERWRITE_RAT;
                    end else if (rob_entries_valid_dec[walking_idx+1] == 'b0) begin
                        //means walk could finish
                        rob_state <= `ROB_STATE_IDLE;
                    end
                end
                default: ;
            endcase
        end
    end

    /* --------------------------- latch flush robidx --------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flush_start_robidx_flag <= 'b0;
        end else if (flush_valid) begin
            flush_start_robidx_flag <= flush_robidx_flag;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            flush_start_robidx <= 'b0;
        end else if (flush_valid) begin
            flush_start_robidx <= flush_robidx;
        end
    end


    //这里时序如果改成在flush的当拍形成flush_dec，第二拍直接刷会不会好一点？
    //It is imposible when redirect hit rob enq,casue dispatch can cover this!
    //When enq_idx > flushrobidx, enq_flag == flush_rob_flag, so use & to cover all entry need flush
    //On the contrary, enq_flag =/= flush_rob_flag; so use | to cover all entry need flush
    always @(*) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            if (is_ovwr) begin
                if (enq_idx > flush_start_robidx) begin
                    flush_dec[i] = (i[`ROB_SIZE_LOG-1:0] > flush_start_robidx) & (i[`ROB_SIZE_LOG-1:0] < enq_idx);
                end else begin
                    flush_dec[i] = (i[`ROB_SIZE_LOG-1:0] > flush_start_robidx) | (i[`ROB_SIZE_LOG-1:0] < enq_idx);
                end
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_idx <= 'b0;
        end else if (is_ovwr) begin
            walking_idx <= deq_idx;
        end else if (is_walking) begin
            walking_idx <= walking_idx + 'd2;
        end
    end


    assign rob_walk0_valid    = rob_entries_valid_dec[walking_idx] & rob_entries_deq_need_to_wb_dec[walking_idx] & is_walking;
    assign rob_walk0_lrd      = rob_entries_deq_lrd_dec[walking_idx];
    assign rob_walk0_prd      = rob_entries_deq_prd_dec[walking_idx];
    assign rob_walk0_complete = rob_entries_deq_complete_dec[walking_idx];

    assign rob_walk1_valid    = rob_entries_valid_dec[walking_idx+'b1] & rob_entries_deq_need_to_wb_dec[walking_idx+'b1] & is_walking;
    assign rob_walk1_lrd      = rob_entries_deq_lrd_dec[walking_idx+'b1];
    assign rob_walk1_prd      = rob_entries_deq_prd_dec[walking_idx+'b1];
    assign rob_walk1_complete = rob_entries_deq_complete_dec[walking_idx+'b1];


    // always @(posedge clock or negedge reset_n) begin
    //     integer i;
    //     for (i = 0; i < `ROB_SIZE; i = i + 1) begin
    //         if (~reset_n) begin
    //             need_walk_dec[i] <= 'b0;
    //             //when flush_robidx > deq_idx,set all entry from DEQ_IDX to FLUSH_ROBIDX bit to 1,including themselves
    //         end else if (is_ovwr) begin
    //             if (flush_robidx > deq_idx) begin
    //                 need_walk_dec[i] <= (i[`ROB_SIZE_LOG-1:0] <= flush_robidx) & (i[`ROB_SIZE_LOG-1:0] >= deq_idx);
    //             end else begin
    //                 need_walk_dec[i] <= (i[`ROB_SIZE_LOG-1:0] <= flush_robidx) | (i[`ROB_SIZE_LOG-1:0] >= deq_idx);
    //             end
    //         end
    //     end
    // end
    // always @(*) begin
    //     integer i;
    //     for (i = 0; i < `ROB_SIZE; i = i + 1) begin
    //         walking_dec[i] = 'b0;
    //         if (is_walking) begin
    //             walking_dec[walking_idx]   = need_walk_dec[walking_idx];
    //             walking_dec[walking_idx+1] = need_walk_dec[walking_idx+1];
    //         end
    //     end
    // end




endmodule
/* verilator lint_off UNDRIVEN */
/* verilator lint_off UNUSEDSIGNAL */

