`include "defines.sv"
/* verilator lint_off UNOPTFLAT */
module storequeue (
    input wire clock,
    input wire reset_n,

    //enq from dispatch
    //NOTE:Why enq from dispathch?If enq from IQ(issue queue),ooo memory access could cause load does not hit store.
    input  wire                     dispatch2sq_enq_valid,
    output wire                     sq_can_alloc,
    input  wire                     dispatch2sq_enq_robidx_flag,
    input  wire [`ROB_SIZE_LOG-1:0] dispatch2sq_enq_robidx,
    //debug
    input  wire [        `PC_RANGE] dispatch2sq_enq_pc,

    /* -------------------------- writeback fill field -------------------------- */
    input wire                     writeback1_valid,
    input wire                     writeback1_mmio,
    input wire                     writeback1_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] writeback1_robidx,
    input wire [       `SRC_RANGE] writeback1_store_addr,
    input wire [       `SRC_RANGE] writeback1_store_data,
    input wire [       `SRC_RANGE] writeback1_store_mask,
    input wire [              3:0] writeback1_store_ls_size,
    /* --------------------------------- commit --------------------------------- */
    input wire                     commits0_valid,
    input wire                     commits0_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] commits0_robidx,

    input wire                     commits1_valid,
    input wire                     commits1_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] commits1_robidx,

    /* -------------------------- redirect flush logic -------------------------- */
    input wire                     flush_valid,
    input wire                     flush_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    /* ------------------------- sq to dcache port ------------------------ */
    output reg                  sq2arb_tbus_index_valid,
    input  wire                 sq2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] sq2arb_tbus_index,
    output reg  [   `SRC_RANGE] sq2arb_tbus_write_data,
    output reg  [         63:0] sq2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] sq2arb_tbus_read_data,
    output wire [`TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type,
    input  wire                      sq2arb_tbus_operation_done,

    output wire                         enq_sqidx_flag,
    output wire [  `STOREQUEUE_LOG-1:0] enq_sqidx,
    /* --------------------------- SQ forwarding  -------------------------- */
    input  wire                         ldu2sq_forward_req_valid,
    input  wire                         ldu2sq_forward_req_sqidx_flag,
    input  wire [`STOREQUEUE_DEPTH-1:0] ldu2sq_forward_req_sqmask,
    input  wire [           `SRC_RANGE] ldu2sq_forward_req_load_addr,
    input  wire [       `LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    output wire                         ldu2sq_forward_resp_valid,
    output wire [           `SRC_RANGE] ldu2sq_forward_resp_data,
    output wire [           `SRC_RANGE] ldu2sq_forward_resp_mask


);
    /* -------------------------------------------------------------------------- */
    /*                         store queue entries entity                         */
    /* -------------------------------------------------------------------------- */


    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_enq_valid_dec;
    //pc used to debug
    reg  [               `PC_RANGE] sq_entries_enq_pc_dec           [`STOREQUEUE_DEPTH-1:0];
    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_enq_robidx_flag_dec;
    reg  [       `ROB_SIZE_LOG-1:0] sq_entries_enq_robidx_dec       [`STOREQUEUE_DEPTH-1:0];

    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_wb_valid_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_wb_mmio_dec;
    //below sig could save
    // reg  [              `SRC_RANGE] sq_entries_wb_store_addr_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [              `SRC_RANGE] sq_entries_wb_store_data_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [              `SRC_RANGE] sq_entries_wb_store_mask_dec    [`STOREQUEUE_DEPTH-1:0];
    // reg  [                     3:0] sq_entries_wb_store_ls_size_dec [`STOREQUEUE_DEPTH-1:0];


    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_robidx_flag_dec;
    reg  [       `ROB_SIZE_LOG-1:0] sq_entries_robidx_dec           [`STOREQUEUE_DEPTH-1:0];

    // reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_commit_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] sq_entries_issuing_dec;
    reg  [   `STOREQUEUE_DEPTH-1:0] flush_dec;

    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_ready_to_go_dec;
    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_valid_dec;
    wire [   `STOREQUEUE_DEPTH-1:0] sq_entries_mmio_dec;

    wire [              `SRC_RANGE] sq_entries_deq_store_addr_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [              `SRC_RANGE] sq_entries_deq_store_data_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [              `SRC_RANGE] sq_entries_deq_store_mask_dec   [`STOREQUEUE_DEPTH-1:0];
    wire [                     3:0] sq_entries_deq_store_ls_size_dec[`STOREQUEUE_DEPTH-1:0];


    /* -------------------------------------------------------------------------- */
    /*                                  pointers                                  */
    /* -------------------------------------------------------------------------- */
    //sqidx
    reg                             enq_ptr_flag;
    reg  [  `STOREQUEUE_LOG -1 : 0] enq_ptr;
    reg                             deq_ptr_flag;
    reg  [  `STOREQUEUE_LOG -1 : 0] deq_ptr;

    reg  [`STOREQUEUE_DEPTH -1 : 0] enq_ptr_oh;
    reg  [`STOREQUEUE_DEPTH -1 : 0] enq_ptr_oh_next;
    reg  [`STOREQUEUE_DEPTH -1 : 0] deq_ptr_oh;
    reg  [`STOREQUEUE_DEPTH -1 : 0] deq_ptr_oh_next;

    /* -------------------------------------------------------------------------- */
    /*                                  enq logic                                 */
    /* -------------------------------------------------------------------------- */

    wire                            enq_has_avail_entry;
    wire                            enq_fire;
    assign enq_has_avail_entry = |(enq_ptr_oh & ~sq_entries_valid_dec);
    assign enq_fire            = enq_has_avail_entry & dispatch2sq_enq_valid;

    assign sq_can_alloc        = ~(~enq_has_avail_entry & dispatch2sq_enq_valid);
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enq_ptr_oh <= 'b1;
        end else begin
            enq_ptr_oh <= enq_ptr_oh_next;
        end
    end

    always @(*) begin
        integer i;
        enq_ptr = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (enq_ptr_oh[i]) begin
                enq_ptr = i;
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            enq_ptr_flag <= 'b0;
        end else if (sq_entries_enq_valid_dec[`STOREQUEUE_DEPTH-1]) begin
            enq_ptr_flag <= ~enq_ptr_flag;
        end
    end
    assign enq_sqidx_flag = enq_ptr_flag;
    assign enq_sqidx      = enq_ptr;

    always @(*) begin
        integer i;
        sq_entries_enq_valid_dec = 'b0;
        if (enq_fire) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                sq_entries_enq_valid_dec[i] = enq_ptr_oh[i];
            end
        end
    end

    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_robidx_flag_dec, dispatch2sq_enq_robidx_flag, `STOREQUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_robidx_dec, dispatch2sq_enq_robidx, `STOREQUEUE_DEPTH)
    `MACRO_ENQ_DEC(enq_ptr_oh, sq_entries_enq_pc_dec, dispatch2sq_enq_pc, `STOREQUEUE_DEPTH)

    io_enq_policy #(
        .QUEUE_SIZE(`STOREQUEUE_DEPTH)
    ) u_io_enq_policy (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (flush_valid),
        .enq_fire       (enq_fire),
        .valid_dec      (~sq_entries_valid_dec),
        .enq_ptr_oh     (enq_ptr_oh),
        .enq_ptr_oh_next(enq_ptr_oh_next),
        .enq_valid_oh   (sq_entries_enq_valid_dec),
        .deq_ptr_oh     (deq_ptr_oh)
    );


    /* -------------------------------------------------------------------------- */
    /*                           writeback fill logic                             */
    /* -------------------------------------------------------------------------- */



    always @(*) begin
        integer i;
        sq_entries_wb_valid_dec = 'b0;
        if (writeback1_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if ((writeback1_robidx_flag == sq_entries_robidx_flag_dec[i]) & (writeback1_robidx == sq_entries_robidx_dec[i])) begin
                    sq_entries_wb_valid_dec[i] = 1'b1;
                end
            end
        end
    end

    always @(*) begin
        integer i;
        sq_entries_wb_mmio_dec = 'b0;
        if (writeback1_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if ((writeback1_robidx_flag == sq_entries_robidx_flag_dec[i]) & (writeback1_robidx == sq_entries_robidx_dec[i])) begin
                    sq_entries_wb_mmio_dec[i] = writeback1_mmio;
                end
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                             commit wakeup logic                            */
    /* -------------------------------------------------------------------------- */
    reg  [`STOREQUEUE_DEPTH-1:0] commits0_dec;
    reg  [`STOREQUEUE_DEPTH-1:0] commits1_dec;
    wire [`STOREQUEUE_DEPTH-1:0] commits_dec;
    assign commits_dec = commits0_dec | commits1_dec;
    always @(*) begin
        integer i;
        commits0_dec = 'b0;
        if (commits0_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commits0_robidx_flag == sq_entries_robidx_flag_dec[i]) & (commits0_robidx == sq_entries_robidx_dec[i])) begin
                    commits0_dec[i] = 1'b1;
                end
            end
        end
    end
    always @(*) begin
        integer i;
        commits1_dec = 'b0;
        if (commits1_valid) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                if (sq_entries_valid_dec[i] & (commits1_robidx_flag == sq_entries_robidx_flag_dec[i]) & (commits1_robidx == sq_entries_robidx_dec[i])) begin
                    commits1_dec[i] = 1'b1;
                end
            end
        end
    end




    /* -------------------------------------------------------------------------- */
    /*                                 flush logic                                */
    /* -------------------------------------------------------------------------- */

    //when ready togo,cannot flush use robidx,cause idx compare would be lleagal
    always @(flush_valid or flush_robidx or flush_robidx_flag) begin
        integer i;
        flush_dec = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (flush_valid) begin
                if (flush_valid & sq_entries_valid_dec[i] & (~sq_entries_ready_to_go_dec[i]) & ((flush_robidx_flag ^ sq_entries_robidx_flag_dec[i]) ^ (flush_robidx < sq_entries_robidx_dec[i]))) begin
                    flush_dec[i] = 1'b1;
                end
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                  deq logic                                 */
    /* -------------------------------------------------------------------------- */
    wire                         deq_fire;
    wire                         deq_has_req;
    wire                         mmio_fake_fire;
    reg  [`STOREQUEUE_DEPTH-1:0] deq_ptr_mask;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            deq_ptr_oh <= 'b1;
        end else begin
            deq_ptr_oh <= deq_ptr_oh_next;
        end
    end
    assign deq_has_req    = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & ~sq_entries_mmio_dec));
    assign mmio_fake_fire = (|(deq_ptr_oh & sq_entries_valid_dec & sq_entries_ready_to_go_dec & sq_entries_mmio_dec));
    assign deq_fire       = deq_has_req & sq2arb_tbus_index_ready | mmio_fake_fire;


    always @(*) begin
        integer i;
        sq_entries_issuing_dec = 'b0;
        if (deq_fire) begin
            for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
                sq_entries_issuing_dec[i] = deq_ptr_oh[i];
            end
        end
    end

    always @(*) begin
        integer i;
        deq_ptr = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (deq_ptr_oh[i]) begin
                deq_ptr = i;
            end
        end
    end
    always @(*) begin
        integer i;
        deq_ptr_mask = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (deq_ptr_oh[i] == 1'b0) begin
                deq_ptr_mask[i] = 'b1;
            end else begin
                break;
            end
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            deq_ptr_flag <= 'b0;
        end else if (sq_entries_issuing_dec[`STOREQUEUE_DEPTH-1]) begin
            deq_ptr_flag <= ~deq_ptr_flag;
        end
    end

    io_deq_policy #(
        .QUEUE_SIZE(`STOREQUEUE_DEPTH)
    ) u_io_deq_policy (
        .clock          (clock),
        .reset_n        (reset_n),
        .flush          (flush_valid),
        .enq_fire       (enq_fire),
        .deq_fire       (deq_fire),
        .valid_dec      (sq_entries_valid_dec),
        .enq_ptr_oh     (enq_ptr_oh),
        .enq_valid_oh   (sq_entries_enq_valid_dec),
        .deq_ptr_oh     (deq_ptr_oh),
        .deq_ptr_oh_next(deq_ptr_oh_next),
        .deq_valid_oh   (sq_entries_issuing_dec)
    );



    /* -------------------------------------------------------------------------- */
    /*                                 dcache arb                                 */
    /* -------------------------------------------------------------------------- */

    assign sq2arb_tbus_operation_type = `TBUS_WRITE;

    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_index, sq_entries_deq_store_addr_dec, `STOREQUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_data, sq_entries_deq_store_data_dec, `STOREQUEUE_DEPTH)
    `MACRO_DEQ_DEC(deq_ptr_oh, sq2arb_tbus_write_mask, sq_entries_deq_store_mask_dec, `STOREQUEUE_DEPTH)

    assign sq2arb_tbus_index_valid = deq_has_req;



    /* -------------------------------------------------------------------------- */
    /*                                  forwading                                 */
    /* -------------------------------------------------------------------------- */
    // jpz note:below cite from Kunminghu Core.
    // "Compare deqPtr (deqPtr) and forward.sqIdx, we have two cases:
    // (1) if they have the same flag, we need to check range(tail, sqIdx)
    // (2) if they have different flags, we need to check range(tail, VirtualLoadQueueSize) and range(0, sqIdx)""
    wire                         same_flag;
    wire [`STOREQUEUE_DEPTH-1:0] cmp_sqmask;
    assign same_flag  = ldu2sq_forward_req_sqidx_flag == deq_ptr_flag;
    assign cmp_sqmask = same_flag ? ldu2sq_forward_req_sqmask ^ deq_ptr_mask : ldu2sq_forward_req_sqmask | ~deq_ptr_mask;
    //we can use cam to checkout addr hit
    reg  [`STOREQUEUE_DEPTH-1:0] cmp_addr_hit;
    wire [           `SRC_RANGE] cmp_addr_mask;
    assign cmp_addr_mask = ldu2sq_forward_req_load_size[0] ? {64{1'b1}} : ldu2sq_forward_req_load_size[1] ? {{63{1'b1}}, 1'b0} : ldu2sq_forward_req_load_size[2] ? {{62{1'b1}}, 2'b0} : {{61{1'b1}}, 3'b0};

    always @(*) begin
        integer i;
        cmp_addr_hit = 'b0;
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin
            if (cmp_sqmask[i] & sq_entries_valid_dec[i] & ldu2sq_forward_req_valid) begin
                if ((sq_entries_deq_store_addr_dec[i] & cmp_addr_mask) == (ldu2sq_forward_req_load_addr & cmp_addr_mask)) begin
                    cmp_addr_hit[i] = 1'b1;
                end
            end
        end
    end






    genvar i;
    generate
        for (i = 0; i < `STOREQUEUE_DEPTH; i = i + 1) begin : sq_entity
            sq_entry u_sq_entry (
                .clock                  (clock),
                .reset_n                (reset_n),
                .enq_valid              (sq_entries_enq_valid_dec[i]),
                .enq_robidx_flag        (sq_entries_enq_robidx_flag_dec[i]),
                .enq_robidx             (sq_entries_enq_robidx_dec[i]),
                .enq_pc                 (sq_entries_enq_pc_dec[i]),
                /* -------------------------- writeback fill field -------------------------- */
                .writeback_valid        (sq_entries_wb_valid_dec[i]),
                .writeback_mmio         (sq_entries_wb_mmio_dec[i]),
                .writeback_store_addr   (writeback1_store_addr),
                .writeback_store_data   (writeback1_store_data),
                .writeback_store_mask   (writeback1_store_mask),
                .writeback_store_ls_size(writeback1_store_ls_size),
                .robidx_flag            (sq_entries_robidx_flag_dec[i]),
                .robidx                 (sq_entries_robidx_dec[i]),
                .commit                 (commits_dec[i]),
                .issuing                (sq_entries_issuing_dec[i]),
                .flush                  (flush_dec[i]),
                .valid                  (sq_entries_valid_dec[i]),
                .mmio                   (sq_entries_mmio_dec[i]),
                .ready_to_go            (sq_entries_ready_to_go_dec[i]),
                .deq_store_addr         (sq_entries_deq_store_addr_dec[i]),
                .deq_store_data         (sq_entries_deq_store_data_dec[i]),
                .deq_store_mask         (sq_entries_deq_store_mask_dec[i]),
                .deq_store_ls_size      (sq_entries_deq_store_ls_size_dec[i])
            );
        end
    endgenerate

    /* verilator lint_off UNOPTFLAT */
endmodule
