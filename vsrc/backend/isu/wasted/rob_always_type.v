
module rob #(
    parameter DATA_WIDTH   = 124, // 64 pc + 32 instr + 5 lrs1 + 5 lrs2 + 5 lrd + 6 prd + 6 old_prd + 1 rd_valid = 124 bits
    parameter DEPTH        = 64,  // Queue depth set to 64
    parameter STATUS_WIDTH = 1 ,   // Status bitwidth set to 1: "complete" or "ready to commit"
    parameter DEPTH_LOG    = 6,
    parameter ADDR_WIDTH  = $clog2(DEPTH), // 6 bit
    parameter INDEX_WIDTH = $clog2(DEPTH) + 1  // 6 bit + 1 bit flaf

)(
    input  clock,
    input  reset_n,  // Active-low reset

    // Write Port 0
    input                  disp2rob_instr0_valid,
    input [DATA_WIDTH-1:0] disp2rob_instr0_entrydata,

    // Write Port 1
    input                  disp2rob_instr1_valid,
    input [DATA_WIDTH-1:0] disp2rob_instr1_entrydata,

    // Status Write Port 0
    input                       complete_wren0,
    input [ADDR_WIDTH-1:0]      complete_wraddr0,
    input [STATUS_WIDTH-1:0]    complete_wrdata0,

    // Status Write Port 1
    input                       complete_wren1,
    input [ADDR_WIDTH-1:0]      complete_wraddr1,
    input [STATUS_WIDTH-1:0]    complete_wrdata1,

    // Commit Port :

    output wire         rob2fl_commit_valid0,       // Indicates that commit_data is valid this cycle
    output wire  [5:0]  rob2fl_commit_old_prd,        
    
    output wire               rob2specrat_commit0_valid      ,
    output wire               rob2specrat_commit0_need_to_wb ,
    output wire [`LREG_RANGE] rob2specrat_commit0_lrd        ,
    output wire [`PREG_RANGE] rob2specrat_commit0_prd        ,

    output wire               rob2specrat_commit1_valid      ,
    output wire               rob2specrat_commit1_need_to_wb ,
    output wire [`LREG_RANGE] rob2specrat_commit1_lrd        ,
    output wire [`PREG_RANGE] rob2specrat_commit1_prd        ,


    // // Status Flags
    // output full,
    // output empty,

    //rob2 
    output wire [INDEX_WIDTH-1:0] rob2disp_instr_cnt, //7 bit
    output wire [INDEX_WIDTH-1:0] rob2disp_instr_id, //7 bit

    //flush signal
    input wire                          flush_valid,
    input wire [63:0]                   flush_target,
    input wire [`INSTR_ID_WIDTH-1:0]    flush_id, 
    //walk signal
    output wire is_idle,
    output wire is_rollback,
    output wire is_walk,
    output wire walking_valid0,
    output wire walking_valid1,
    output wire [5:0] walking_prd0,
    output wire [5:0] walking_prd1,
    output wire walking_complete0,
    output wire walking_complete1,
    output wire [4:0] walking_lrd0,
    output wire [4:0] walking_lrd1,
    output wire [5:0] walking_old_prd0,
    output wire [5:0] walking_old_prd1

);

    // Queue storage arrays
    reg [DATA_WIDTH-1:0]   cqentry_data   [0:DEPTH-1];
    reg                    cqentry_valid  [0:DEPTH-1];
    reg [INDEX_WIDTH-1:0]  cqentry_index  [0:DEPTH-1];
    reg [STATUS_WIDTH-1:0] cqentry_complete [0:DEPTH-1];

    // Pointers and counters
    reg [ADDR_WIDTH-1:0]     enqueue_ptr  ;  // points to the next location to write
    reg [ADDR_WIDTH-1:0]     dequeue_ptr  ;  // points to the next location to commit (read out)
    //reg [$clog2(DEPTH):0]  wr_count      = 0;  // total number of entries written
    //reg [$clog2(DEPTH):0]  rd_count      = 0;  // total number of entries removed via commit
    reg [INDEX_WIDTH-1:0]    instr_id ;  // increments for each new entry

    // // Status flags
    // assign full  = ((wr_count - rd_count) >= DEPTH);
    // assign empty = (wr_count == rd_count);
    reg [INDEX_WIDTH-1:0] instr_avail_cnt;//represent available instr number in rob
    assign rob2disp_instr_cnt = instr_avail_cnt;// what to do in flush, can be send with flush signal from intblock
    assign rob2disp_instr_id  = instr_id;
    //--------------------------------------------------------------------------
    // Write Logic
    //--------------------------------------------------------------------------
    integer i;
    integer write_count;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            enqueue_ptr   <= 0;
            //wr_count      <= 0;
            instr_id <= 0;
            instr_avail_cnt <= 0;
            // Reset all queue entries
            for (i = 0; i < DEPTH; i = i + 1) begin
                cqentry_data[i]   <= {DATA_WIDTH{1'b0}};
                cqentry_valid[i]  <= 1'b0;
                cqentry_index[i]  <= {INDEX_WIDTH{1'b0}};
                cqentry_complete[i] <= {STATUS_WIDTH{1'b0}};
            end
//        end else if (current_state == IDLE && next_state == ROLLBACK)begin // when flush_valid, ROLLBACK enqueue_ptr to flush_id
        end else if (is_rollback)begin // to align with other unit rollback action timing
                enqueue_ptr   <= (flush_id[5:0]+1) % DEPTH; // rollback enqueue ptr
                instr_id      <= flush_id + 1;       // rollback instr_id
                cqentry_valid <= cqentry_valid & ~cqentry_needflush_valid;   // rollback valid vector 
        end else if(is_walk)begin
            
        end else begin // is_idle
            // Count how many writes are requested in this cycle
            write_count = disp2rob_instr0_valid + disp2rob_instr1_valid;
            if (write_count == 1 && disp2rob_instr0_valid && !full) begin
                cqentry_data[enqueue_ptr]   <= disp2rob_instr0_entrydata;
                cqentry_valid[enqueue_ptr]  <= 1'b1;
                cqentry_index[enqueue_ptr]  <= instr_id;
                cqentry_complete[enqueue_ptr] <= {STATUS_WIDTH{1'b0}}; // status defaults to 0

                enqueue_ptr   <= (enqueue_ptr + 1) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt + 1 ;
                //wr_count      <= wr_count + 1;
                instr_id <= instr_id + 1;
            end else if (write_count == 2 && disp2rob_instr1_valid && !full) begin
                cqentry_data[enqueue_ptr]   <= disp2rob_instr0_entrydata;
                cqentry_valid[enqueue_ptr]  <= 1'b1;
                cqentry_index[enqueue_ptr]  <= instr_id;
                cqentry_complete[enqueue_ptr] <= {STATUS_WIDTH{1'b0}}; // status defaults to 0

                cqentry_data[enqueue_ptr+1]   <= disp2rob_instr1_entrydata;
                cqentry_valid[enqueue_ptr+1]  <= 1'b1;
                cqentry_index[enqueue_ptr+1]  <= instr_id+1;
                cqentry_complete[enqueue_ptr+1] <= {STATUS_WIDTH{1'b0}};

                enqueue_ptr   <= (enqueue_ptr + 2) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt + 2 ;
                //wr_count      <= wr_count + 2;
                instr_id <= instr_id + 2;
            end
    //--------------------------------------------------------------------------
    // Complete Write Logic
    //--------------------------------------------------------------------------
            // Complete Write Port 0
            if (complete_wren0 && (complete_wraddr0 < DEPTH)) begin
                cqentry_complete[complete_wraddr0] <= complete_wrdata0;
            end

            // Complete Write Port 1
            if (complete_wren1 && (complete_wraddr1 < DEPTH)) begin
                cqentry_complete[complete_wraddr1] <= complete_wrdata1;
            end

        end
    end

    // //--------------------------------------------------------------------------
    // // Complete Write Logic
    // //--------------------------------------------------------------------------
    // always @(posedge clock or negedge reset_n) begin
    //     if (!reset_n) begin
    //         for (i = 0; i < DEPTH; i = i + 1) begin
    //             cqentry_complete[i] <= {STATUS_WIDTH{1'b0}};
    //         end
    //     end
    //     else begin
    //         // Complete Write Port 0
    //         if (complete_wren0 && (complete_wraddr0 < DEPTH)) begin
    //             cqentry_complete[complete_wraddr0] <= complete_wrdata0;
    //         end

    //         // Complete Write Port 1
    //         if (complete_wren1 && (complete_wraddr1 < DEPTH)) begin
    //             cqentry_complete[complete_wraddr1] <= complete_wrdata1;
    //         end
    //     end
    // end

    //--------------------------------------------------------------------------
    // Commit Logic 
    //--------------------------------------------------------------------------
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            dequeue_ptr  <= 0;
            //rd_count     <= 0;
            commit_valid <= 0;
            commit_data  <= {DATA_WIDTH{1'b0}};
        end
        else begin
            commit_valid <= 0;

            if (cqentry_valid[dequeue_ptr] && cqentry_complete[dequeue_ptr] && cqentry_data[dequeue_ptr][117]) begin//117:instr_need_to_wb
                commit_valid   <= 1'b1;
                commit_data    <= cqentry_data[dequeue_ptr];

                // "Remove" from the queue
                cqentry_valid[dequeue_ptr] <= 1'b0; // Invalidate
                dequeue_ptr                <= (dequeue_ptr + 1) % DEPTH;
                instr_avail_cnt <= instr_avail_cnt - 1 ;
                //rd_count                  <= rd_count + 1;
            end
        end
    end

    assign rob2fl_commit_valid0 = commit_valid && commit_data[0]; //need_to_wb
    assign rob2fl_commit_old_prd = commit_data[6:1];

    assign rob2specrat_commit0_valid      = commit_valid;
    assign rob2specrat_commit0_need_to_wb = commit_data[0];
    assign rob2specrat_commit0_lrd        = commit_data[17:13];
    assign rob2specrat_commit0_prd        = commit_data[12:7];


/* ---------------------------- flush walk logic ---------------------------- */
localparam IDLE = 2'b00;
localparam ROLLBACK = 2'b01;
localparam WALK = 2'b10;

assign is_idle = current_state == IDLE;
assign is_rollback = current_state == ROLLBACK;
assign is_walk = current_state == WALK;

reg [1:0] current_state;
reg [1:0] next_state;

always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        current_state <= 0;
    end else begin
        current_state <= next_state;
    end
end

always @(*) begin
    case (current_state)
        IDLE:
            if(flush_valid)begin
                next_state = ROLLBACK;        
            end else begin
                next_state = IDLE;
            end
        ROLLBACK:
            next_state = WALK;
        WALK:
            if(cqentry_valid[walking_ptr+1] == 0)begin
                next_state = IDLE;
            end else begin
                next_state = WALK;
            end
        default: 
    endcase
end

//roll back cqentry_valid vector logic
//prepare before rollback cycle
reg  cqentry_needflush_valid  [0:DEPTH-1];
always @(*) begin
    for(i = 0; i<DEPTH;i=i+1)begin
        if(current_state == IDLE && next_state == ROLLBACK)begin
            if(enqueue_ptr > flush_id[5:0])begin
                cqentry_needflush_valid[i] = (i[DEPTH_LOG-1:0] > flush_id[5:0]) & (i[DEPTH_LOG-1:0] < enqueue_ptr);
            end else begin
                cqentry_needflush_valid[i] = (i[DEPTH_LOG-1:0] > flush_id[5:0]) | (i[DEPTH_LOG-1:0] < enqueue_ptr);
            end
        end
    end
end


//walk logic
    reg [ADDR_WIDTH-1:0]  walking_ptr ;  // points to the next location to commit (read out)
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            walking_ptr <= 0;
        end else if (is_rollback) begin // happen in first cycle of walking
            walking_ptr <= dequeue_ptr;
        end else if (is_walk) begin // begin to walk in second cycle of walking
            walking_ptr <= walking_ptr + 'd2;
        end
    end
//check if 2 instr now is walking pass is valid or not
assign walking_valid0 = cqentry_valid[walking_ptr] && cqentry_data[walking_ptr][0] && is_walk;//instr_need_to_wb
assign walking_valid1 = cqentry_valid[walking_ptr+1] && cqentry_data[walking_ptr+1][0] && is_walk;
assign walking_prd0 =  cqentry_data[walking_ptr][12 : 7];//prd
assign walking_prd1 =  cqentry_data[walking_ptr+1][12 : 7];
assign walking_complete0 = cqentry_complete[walking_ptr];
assign walking_complete0 = cqentry_complete[walking_ptr+1];
assign walking_lrd0 = cqentry_data[walking_ptr][17 : 13];//lrd
assign walking_lrd1 = cqentry_data[walking_ptr+1][17 : 13];
assign walking_old_prd0  = cqentry_data[walking_ptr][6:1];
assign walking_old_prd1  = cqentry_data[walking_ptr+1][6:1];

//   disp2rob_wrdata0 =   
//   { 
//   instr0_pc           ,//[123:60]
//   instr0              ,//[59:28]
//   instr0_lrs1         ,//[27:23]
//   instr0_lrs2         ,//[22:18]
//   instr0_lrd          ,//[17:13]
//   instr0_prd          ,//[12:7]
//   instr0_old_prd      ,//[6:1]
//   instr0_need_to_wb    //[0]
//   };





endmodule
