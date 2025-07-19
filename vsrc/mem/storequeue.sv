`include "defines.sv"
module storequeue (
    input wire clock,
    input wire reset_n,

    //enq from dispatch
    //NOTE:Why enq from dispathch?If enq from IQ(issue queue),ooo memory access could cause load does not hit store.
    input  wire                   disp2sq_valid,
    output wire                   sq_can_alloc,
    input  wire [`ROB_SIZE_LOG:0] disp2sq_robid,
    //debug
    input  wire [      `PC_RANGE] disp2sq_pc,

    /* -------------------------- complete fill field -------------------------- */
    input wire                   st_agu0_cmpl_valid,
    input wire [ `SQ_SIZE_LOG:0] st_agu0_cmpl_sqid,
    input wire                   st_agu0_cmpl_mmio,
    input wire [     `SRC_RANGE] st_agu0_cmpl_addr,
    input wire [     `SRC_RANGE] st_agu0_cmpl_mask,
    input wire [            3:0] st_agu0_cmpl_size,
    // input wire [`ROB_SIZE_LOG:0] memwb_robid,
    input wire                   st_dgu0_cmpl_valid,
    input wire [ `SQ_SIZE_LOG:0] st_dgu0_cmpl_sqid,
    input wire [     `SRC_RANGE] st_dgu0_cmpl_data,
    /* --------------------------------- commit --------------------------------- */
    input wire                   commit0_valid,
    input wire [`ROB_SIZE_LOG:0] commit0_robid,

    input wire                   commit1_valid,
    input wire [`ROB_SIZE_LOG:0] commit1_robid,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                   flush_valid,
    input wire [`ROB_SIZE_LOG:0] flush_robid,
    input wire [ `SQ_SIZE_LOG:0] flush_sqid,


    /* ------------------------- sq to dcache port ------------------------ */
    output reg                  sq2arb_tbus_index_valid,
    input  wire                 sq2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] sq2arb_tbus_index,
    output reg  [   `SRC_RANGE] sq2arb_tbus_write_data,
    output reg  [         63:0] sq2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] sq2arb_tbus_read_data,
    output wire [`TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type,
    input  wire                      sq2arb_tbus_operation_done,

    output wire [      `SQ_SIZE_LOG:0] sq2disp_sqid,
    /* --------------------------- SQ forwarding  -------------------------- */
    input  wire                        ldu2sq_forward_req_valid,
    input  wire [      `SQ_SIZE_LOG:0] ldu2sq_forward_req_sqid,
    input  wire [`STOREQUEUE_SIZE-1:0] ldu2sq_forward_req_sqmask,
    input  wire [          `SRC_RANGE] ldu2sq_forward_req_load_addr,
    input  wire [      `LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    output reg                         ldu2sq_forward_resp_valid,
    output reg  [          `SRC_RANGE] ldu2sq_forward_resp_data,
    output reg  [          `SRC_RANGE] ldu2sq_forward_resp_mask


);
    /* -------------------------------------------------------------------------- */
    /*                         store queue entries entity                         */
    /* -------------------------------------------------------------------------- */


    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_enq_valid_dec;
    //pc used to debug
    reg  [              `PC_RANGE] sq_entries_enq_pc_dec           [`STOREQUEUE_SIZE-1:0];
    reg  [        `ROB_SIZE_LOG:0] sq_entries_enq_robid_dec        [`STOREQUEUE_SIZE-1:0];


    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_agu_cmpl_valid_dec;
    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_agu_cmpl_mmio_dec;
    reg  [             `SRC_RANGE] sq_entries_agu_cmpl_addr_dec    [`STOREQUEUE_SIZE-1:0];

    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_dgu_cmpl_valid_dec;
    reg  [             `SRC_RANGE] sq_entries_dgu_cmpl_data_dec    [`STOREQUEUE_SIZE-1:0];
    reg  [             `SRC_RANGE] sq_entries_dgu_cmpl_mask_dec    [`STOREQUEUE_SIZE-1:0];
    reg  [                    3:0] sq_entries_dgu_cmpl_size_dec    [`STOREQUEUE_SIZE-1:0];


    reg  [        `ROB_SIZE_LOG:0] sq_entries_robid_dec            [`STOREQUEUE_SIZE-1:0];

    // reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_commit_dec;
    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_issuing_dec;
    reg  [   `STOREQUEUE_SIZE-1:0] sq_entries_complete_dec;
    reg  [   `STOREQUEUE_SIZE-1:0] flush_dec;

    wire [   `STOREQUEUE_SIZE-1:0] sq_entries_ready_to_go_dec;
    wire [   `STOREQUEUE_SIZE-1:0] sq_entries_valid_dec;
    wire [   `STOREQUEUE_SIZE-1:0] sq_entries_mmio_dec;

    wire [             `SRC_RANGE] sq_entries_deq_store_addr_dec   [`STOREQUEUE_SIZE-1:0];
    wire [             `SRC_RANGE] sq_entries_deq_store_data_dec   [`STOREQUEUE_SIZE-1:0];
    wire [             `SRC_RANGE] sq_entries_deq_store_mask_dec   [`STOREQUEUE_SIZE-1:0];
    wire [                    3:0] sq_entries_deq_store_ls_size_dec[`STOREQUEUE_SIZE-1:0];


    /* -------------------------------------------------------------------------- */
    /*                                  pointers                                  */
    /* -------------------------------------------------------------------------- */
    wire [       `SQ_SIZE_LOG : 0] enq_ptr;
    wire [`STOREQUEUE_SIZE -1 : 0] enq_ptr_oh;

    wire [       `SQ_SIZE_LOG : 0] deq_ptr;
    reg  [`STOREQUEUE_SIZE -1 : 0] deq_ptr_oh;

    /* -------------------------------------------------------------------------- */
    /*                                  enq logic                                 */
    /* -------------------------------------------------------------------------- */

    wire                           enq_has_avail_entry;
    wire                           enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~sq_entries_valid_dec);
    assign enq_fire            = enq_has_avail_entry & disp2sq_valid;

    assign sq_can_alloc        = ~(~enq_has_avail_entry & disp2sq_valid);

    assign sq2disp_sqid        = enq_ptr;

    always @(*) begin
        integer i;
        sq_entries_enq_valid_dec = 'b0;
        if (enq_fire) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                sq_entries_enq_valid_dec[i] = enq_ptr_oh[i];
            end
        end
    end

    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_robid_dec, disp2sq_robid, `STOREQUEUE_SIZE)
    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_pc_dec, disp2sq_pc, `STOREQUEUE_SIZE)

    inorder_enq_policy #(
        .QUEUE_SIZE    (`STOREQUEUE_SIZE),
        .QUEUE_SIZE_LOG(`SQ_SIZE_LOG)
    ) u_inorder_enq_policy (
        .clock      (clock),
        .reset_n    (reset_n),
        .flush_valid(flush_valid),
        .flush_sqid (flush_sqid),
        .enq_fire   (enq_fire),
        .enq_ptr    (enq_ptr),
        .enq_ptr_oh (enq_ptr_oh)
    );



    /* -------------------------------------------------------------------------- */
    /*                           complete fill logic                             */
    /* -------------------------------------------------------------------------- */

    always @(*) begin
        integer i;
        sq_entries_agu_cmpl_valid_dec = 'b0;
        sq_entries_agu_cmpl_mmio_dec  = 'b0;
        sq_entries_agu_cmpl_addr_dec  = 'b0;
        if (st_agu0_cmpl_valid) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if ((st_agu0_cmpl_sqid == i)) begin
                    sq_entries_agu_cmpl_valid_dec[i] = 1'b1;
                    sq_entries_agu_cmpl_mmio_dec[i]  = st_agu0_cmpl_mmio;
                    sq_entries_agu_cmpl_addr_dec[i]  = st_agu0_cmpl_addr;
                end
            end
        end
    end



    always @(*) begin
        integer i;
        sq_entries_dgu_cmpl_data_dec = 'b0;
        sq_entries_dgu_cmpl_mask_dec = 'b0;
        sq_entries_dgu_cmpl_size_dec = 'b0;
        if (st_dgu0_cmpl_valid) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if ((st_dgu0_cmpl_sqid == i)) begin
                    sq_entries_dgu_cmpl_data_dec[i] = st_dgu0_cmpl_data;
                    sq_entries_dgu_cmpl_mask_dec[i] = st_agu0_cmpl_mask;
                    sq_entries_dgu_cmpl_size_dec[i] = st_agu0_cmpl_size;
                end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                             commit wakeup logic                            */
    /* -------------------------------------------------------------------------- */
    reg  [`STOREQUEUE_SIZE-1:0] commit0_dec;
    reg  [`STOREQUEUE_SIZE-1:0] commit1_dec;
    wire [`STOREQUEUE_SIZE-1:0] commits_dec;
    assign commits_dec = commit0_dec | commit1_dec;
    always @(*) begin
        integer i;
        commit0_dec = 'b0;
        if (commit0_valid) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commit0_robid == sq_entries_robid_dec[i])) begin
                    commit0_dec[i] = 1'b1;
                end
            end
        end
    end
    always @(*) begin
        integer i;
        commit1_dec = 'b0;
        if (commit1_valid) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commit1_robid == sq_entries_robid_dec[i])) begin
                    commit1_dec[i] = 1'b1;
                end
            end
        end
    end




    /* -------------------------------------------------------------------------- */
    /*                                 flush logic                                */
    /* -------------------------------------------------------------------------- */

    //when ready togo,cannot flush use robidx,cause idx compare would be lleagal
    always @(flush_valid or flush_sqid) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
            if (flush_valid) begin
                if (enq_ptr[`SQ_SIZE_LOG-1:0] >= flush_sqid[`SQ_SIZE_LOG-1:0]) begin
                    flush_dec[i] = (i[`SQ_SIZE_LOG-1:0] >= flush_sqid[`SQ_SIZE_LOG-1:0]) & (i[`SQ_SIZE_LOG-1:0] < enq_ptr[`SQ_SIZE_LOG-1:0]);
                end else begin
                    flush_dec[i] = (i[`SQ_SIZE_LOG-1:0] >= flush_sqid[`SQ_SIZE_LOG-1:0]) | (i[`SQ_SIZE_LOG-1:0] < enq_ptr[`SQ_SIZE_LOG-1:0]);
                end
                // if (flush_valid & sq_entries_valid_dec[i] & (~sq_entries_ready_to_go_dec[i]) & ((flush_sqid[`ROB_SIZE_LOG] ^ sq_entries_robid_dec[i][`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] <= sq_entries_robid_dec[i][`ROB_SIZE_LOG-1:0]))) begin
                //     flush_dec[i] = 1'b1;
                // end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                  deq logic                                 */
    /* -------------------------------------------------------------------------- */
    wire                        deq_fire;
    wire                        deq_has_req;
    wire                        mmio_fake_fire;
    reg  [`STOREQUEUE_SIZE-1:0] deq_ptr_mask;

    assign deq_has_req    = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & ~sq_entries_mmio_dec));
    assign mmio_fake_fire = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & sq_entries_mmio_dec));
    assign deq_fire       = deq_has_req & sq2arb_tbus_index_ready | mmio_fake_fire;


    always @(*) begin
        integer i;
        sq_entries_issuing_dec = 'b0;
        if (deq_fire) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                sq_entries_issuing_dec[i] = deq_ptr_oh[i];
            end
        end
    end


    always @(*) begin
        integer i;
        deq_ptr_mask = 'b0;
        for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
            if (deq_ptr_oh[i] == 1'b0) begin
                deq_ptr_mask[i] = 'b1;
            end else begin
                break;
            end
        end
    end


    inorder_deq_policy #(
        .QUEUE_SIZE    (`STOREQUEUE_SIZE),
        .QUEUE_SIZE_LOG(`SQ_SIZE_LOG)
    ) u_inorder_deq_policy (
        .clock     (clock),
        .reset_n   (reset_n),
        .deq_fire  (deq_fire),
        .deq_ptr_oh(deq_ptr_oh),
        .deq_ptr   (deq_ptr)
    );


    /* -------------------------------------------------------------------------- */
    /*                                 dcache arb                                 */
    /* -------------------------------------------------------------------------- */

    assign sq2arb_tbus_operation_type = `TBUS_WRITE;

    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_index, sq_entries_deq_store_addr_dec, `STOREQUEUE_SIZE)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_data, sq_entries_deq_store_data_dec, `STOREQUEUE_SIZE)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_mask, sq_entries_deq_store_mask_dec, `STOREQUEUE_SIZE)

    assign sq2arb_tbus_index_valid = deq_has_req;



    /* -------------------------------------------------------------------------- */
    /*                                  forwarding                                */
    /* -------------------------------------------------------------------------- */
    // jpz note:below cite from Kunminghu Core.
    // "Compare deqPtr (deqPtr) and forward.sqIdx, we have two cases:
    // (1) if they have the same flag, we need to check range(tail, sqIdx)
    // (2) if they have different flags, we need to check range(tail, VirtualLoadQueueSize) and range(0, sqIdx)""
    wire                        same_flag;
    wire [`STOREQUEUE_SIZE-1:0] cmp_sqmask;
    assign same_flag  = ldu2sq_forward_req_sqid[`SQ_SIZE_LOG] == deq_ptr[`SQ_SIZE_LOG];
    assign cmp_sqmask = same_flag ? ldu2sq_forward_req_sqmask ^ deq_ptr_mask : ldu2sq_forward_req_sqmask | ~deq_ptr_mask;
    //we can use cam to checkout addr hit
    reg  [`STOREQUEUE_SIZE-1:0] cmp_addr_hit;
    wire [          `SRC_RANGE] cmp_addr_mask;
    assign cmp_addr_mask = ldu2sq_forward_req_load_size[0] ? {64{1'b1}} : ldu2sq_forward_req_load_size[1] ? {{63{1'b1}}, 1'b0} : ldu2sq_forward_req_load_size[2] ? {{62{1'b1}}, 2'b0} : {{61{1'b1}}, 3'b0};

    always @(*) begin
        integer i;
        cmp_addr_hit = 'b0;
        for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
            if (cmp_sqmask[i] & sq_entries_valid_dec[i] & sq_entries_complete_dec[i] & ldu2sq_forward_req_valid) begin
                if ((sq_entries_deq_store_addr_dec[i] & cmp_addr_mask) == (ldu2sq_forward_req_load_addr & cmp_addr_mask)) begin
                    cmp_addr_hit[i] = 1'b1;
                end
            end
        end
    end

    wire [63:0] load_1b_mask;
    wire [63:0] load_1h_mask;
    wire [63:0] load_1w_mask;
    wire [63:0] load_2w_mask;

    assign load_1b_mask = {56'b0, {8{1'b1}}};
    assign load_1h_mask = {48'b0, {16{1'b1}}};
    assign load_1w_mask = {32'b0, {32{1'b1}}};
    assign load_2w_mask = {64{1'b1}};
    // reg 

    wire [`STOREQUEUE_SIZE-1:0] different_flag_upper_cmp_addr_hit;
    wire [`STOREQUEUE_SIZE-1:0] different_flag_lower_cmp_addr_hit;
    assign different_flag_upper_cmp_addr_hit = cmp_addr_hit & (~deq_ptr_mask);
    assign different_flag_lower_cmp_addr_hit = cmp_addr_hit & ldu2sq_forward_req_sqmask;



    //size is ont hot,means 1b,1h,1w,1d.
    always @(*) begin
        ldu2sq_forward_resp_valid = 'b0;

        case (ldu2sq_forward_req_load_size)
            4'b0001: begin
                ldu2sq_forward_resp_valid = &forwarding_valid_mask[7:0];
            end
            4'b0010: begin
                ldu2sq_forward_resp_valid = &forwarding_valid_mask[15:0];
            end
            4'b0100: begin
                ldu2sq_forward_resp_valid = &forwarding_valid_mask[31:0];
            end
            4'b1000: begin
                ldu2sq_forward_resp_valid = &forwarding_valid_mask[63:0];
            end
            default: ;
        endcase
    end
    reg [`SRC_RANGE] forwarding_valid_mask;


    always @(*) begin
        integer i;
        ldu2sq_forward_resp_data = 'b0;
        forwarding_valid_mask    = 'b0;
        if (same_flag) begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if (cmp_addr_hit[i]) begin
                    ldu2sq_forward_resp_data = ldu2sq_forward_resp_data & (~sq_entries_deq_store_mask_dec[i]) | (sq_entries_deq_store_data_dec[i] & sq_entries_deq_store_mask_dec[i]);
                    forwarding_valid_mask    = forwarding_valid_mask | sq_entries_deq_store_mask_dec[i];
                end
            end
        end else begin
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if (different_flag_upper_cmp_addr_hit[i]) begin
                    ldu2sq_forward_resp_data = ldu2sq_forward_resp_data & (~sq_entries_deq_store_mask_dec[i]) | (sq_entries_deq_store_data_dec[i] & sq_entries_deq_store_mask_dec[i]);
                    forwarding_valid_mask    = forwarding_valid_mask | sq_entries_deq_store_mask_dec[i];
                end
            end
            for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin
                if (different_flag_lower_cmp_addr_hit[i]) begin
                    ldu2sq_forward_resp_data = ldu2sq_forward_resp_data & (~sq_entries_deq_store_mask_dec[i]) | (sq_entries_deq_store_data_dec[i] & sq_entries_deq_store_mask_dec[i]);
                    forwarding_valid_mask    = forwarding_valid_mask | sq_entries_deq_store_mask_dec[i];
                end
            end
        end
    end





    genvar i;
    generate
        for (i = 0; i < `STOREQUEUE_SIZE; i = i + 1) begin : sq_entity
            sq_entry u_sq_entry (
                .clock            (clock),
                .reset_n          (reset_n),
                .enq_valid        (sq_entries_enq_valid_dec[i]),
                .enq_robid        (sq_entries_enq_robid_dec[i]),
                .enq_pc           (sq_entries_enq_pc_dec[i]),
                /* -------------------------- writeback fill field -------------------------- */
                .agu_cmpl_valid   (sq_entries_agu_cmpl_valid_dec[i]),
                .agu_cmpl_mmio    (sq_entries_agu_cmpl_mmio_dec[i]),
                .agu_cmpl_addr    (sq_entries_agu_cmpl_addr_dec[i]),
                .dgu_cmpl_valid   (sq_entries_dgu_cmpl_valid_dec[i]),
                .dgu_cmpl_data    (sq_entries_dgu_cmpl_data_dec[i]),
                .dgu_cmpl_mask    (sq_entries_dgu_cmpl_mask_dec[i]),
                .dgu_cmpl_size    (sq_entries_dgu_cmpl_size_dec[i]),
                .robid            (sq_entries_robid_dec[i]),
                .commit           (commits_dec[i]),
                .complete         (sq_entries_complete_dec[i]),
                .issuing          (sq_entries_issuing_dec[i]),
                .flush            (flush_dec[i]),
                .valid            (sq_entries_valid_dec[i]),
                .mmio             (sq_entries_mmio_dec[i]),
                .ready_to_go      (sq_entries_ready_to_go_dec[i]),
                .deq_store_addr   (sq_entries_deq_store_addr_dec[i]),
                .deq_store_data   (sq_entries_deq_store_data_dec[i]),
                .deq_store_mask   (sq_entries_deq_store_mask_dec[i]),
                .deq_store_ls_size(sq_entries_deq_store_ls_size_dec[i])
            );


        end
    endgenerate

endmodule
