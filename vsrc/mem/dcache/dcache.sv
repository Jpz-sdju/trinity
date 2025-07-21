`include "defines.sv"
module dcache #(
    parameter DATA_WIDTH = 64,  // Width of DATARAM
    parameter TAGARRAY_DATA_WIDTH = 44,  // Width of TAGRAM
    parameter TAGARRAY_ADDR_WIDTH = 6,  // Width of TAGRAM
    parameter ADDR_WIDTH = 9,  // Width of address bus
    parameter TAG_ARRAY_IDX_HIGH = 11,
    parameter TAG_ARRAY_IDX_LOW = 6
) (
    /* verilator lint_off UNOPTFLAT */
    input wire clock,    // Clock signal
    input wire reset_n,  // Active low reset
    input wire flush,


    input  wire                ldu0_l1_req_valid,
    output wire                ldu0_l1_req_ready,
    input  wire [`VADDR_RANGE] ldu0_l1_req_vaddr,

    input  wire                ldu1_l1_req_valid,
    output wire                ldu1_l1_req_ready,
    input  wire [`VADDR_RANGE] ldu1_l1_req_vaddr,

    input wire                     ldu0_l2_tlbresp_valid,
    input wire [`TBUS_INDEX_RANGE] ldu0_l2_tlbresp_paddr,

    input wire                     ldu1_l2_tlbresp_valid,
    input wire [`TBUS_INDEX_RANGE] ldu1_l2_tlbresp_paddr,





    //trinity bus channel as input
    output reg                       tbus_index_ready,
    input  reg                       tbus_index_valid,
    input  reg  [ `TBUS_INDEX_RANGE] tbus_index,
    output reg  [  `TBUS_DATA_RANGE] tbus_read_data,
    output reg                       tbus_operation_done,
    input  wire [`TBUS_OPTYPE_RANGE] tbus_operation_type,
    input  reg  [  `TBUS_DATA_RANGE] tbus_write_data,
    input  reg  [  `TBUS_DATA_RANGE] tbus_write_mask,


    //trinity bus channel as output
    output wire                       dcache2arb_dbus_index_valid,
    input  wire                       dcache2arb_dbus_index_ready,
    input  wire [`CACHELINE512_RANGE] dcache2arb_dbus_read_data,
    input  wire                       dcache2arb_dbus_operation_done,
    output reg  [  `DBUS_INDEX_RANGE] dcache2arb_dbus_index,
    output reg  [`CACHELINE512_RANGE] dcache2arb_dbus_write_data,
    output reg  [ `DBUS_OPTYPE_RANGE] dcache2arb_dbus_operation_type

);
    wire                      tbus_fire;
    wire [     `TAGRAM_RANGE] tagarray_dout;
    wire [    DATA_WIDTH-1:0] dataarray_dout_banks                                                [0:7];
    wire                      in_idle;
    wire                      in_lookup;
    wire                      in_writecache;
    wire [               2:0] bankaddr_latch;
    wire                      tbus_is_write;
    wire                      tbus_is_read;
    wire [               7:0] seed;
    wire [               7:0] random_num;
    wire [              18:0] tagarray_dout_waycontent_s1                                         [0:1];
    wire [               1:0] tagarray_dout_wayvalid_s1;
    wire [               1:0] tagarray_dout_waydirty_s1;
    wire                      tagarray_dout_wayisfull_s1;
    wire [     `TAGRAM_RANGE] tagarray_dout_or;
    wire [               1:0] lookup_hitway_oh_or;
    wire                      lookup_hitway_dec_or;
    wire [               1:0] random_way_s1;
    wire [               1:0] victimway_oh_s1;
    wire [               1:0] ff_way_s1;
    wire                      victimway_isdirty_s1;
    wire                      tagarray_full_have_clean;
    wire [`CACHE_WAY_NUM-1:0] tagarray_full_clean_way_oh;
    wire [ `TAGRAM_TAG_RANGE] victimway_pa_s1;
    wire [       `ADDR_RANGE] victimway_fulladdr_s1;
    wire [       `ADDR_RANGE] victimway_fulladdr_or;
    wire                      lu_hit_s1;
    wire                      lu_miss_s1;
    wire                      lu_miss_full_vicdirty;
    wire                      lu_miss_full_vicclean;
    wire                      lu_miss_notfull;
    wire                      read_hit_s1;
    wire                      write_hit_s1;
    wire [     `RESULT_RANGE] masked_ddr_readdata_or;
    wire [              16:0] debug_ls_addr_latch_tag;
    wire [              18:0] debug_tagarray_din_lo;
    wire [              18:0] debug_tagarray_din_hi;
    wire [              16:0] debug_tagarray_tagin_lo;
    wire [              16:0] debug_tagarray_tagin_hi;
    wire [    DATA_WIDTH-1:0] dataarray_din_banks_allone                                          [0:7];
    wire [    DATA_WIDTH-1:0] dataarray_din_banks_allzero                                         [0:7];
    wire                      dcache2arb_fire;
    wire [              63:0] miss_read_align_addr;


    //internal signals


    reg                       dcache2arb_dbus_index_valid_internal;
    reg                       tagarray_we;
    reg                       tagarray_ce;
    reg  [    ADDR_WIDTH-1:0] tagarray_raddr;
    reg  [    ADDR_WIDTH-1:0] tagarray_waddr;
    reg  [     TAG_WIDTH-1:0] tagarray_din;
    reg  [     TAG_WIDTH-1:0] tagarray_wmask;
    reg                       dataarray_we;
    reg  [               1:0] dataarray_ce_way;
    reg  [               7:0] dataarray_ce_bank;
    reg  [    ADDR_WIDTH-1:0] dataarray_writesetaddr;
    reg  [    ADDR_WIDTH-1:0] dataarray_readsetaddr;
    reg  [    DATA_WIDTH-1:0] dataarray_din_banks                                                 [0:7];
    reg  [    DATA_WIDTH-1:0] dataarray_wmask_banks                                               [0:7];
    reg  [     `RESULT_RANGE] tbus_read_data_s2;
    // State register
    reg  [               2:0] state;
    reg  [               2:0] next_state;
    reg  [              63:0] ls_addr_latch;
    reg  [               7:0] bankaddr_onehot_latch;
    reg  [        `SRC_RANGE] write_data_latch;
    reg  [        `SRC_RANGE] write_mask_latch;
    reg  [               1:0] operation_type_latch;
    reg  [    DATA_WIDTH-1:0] write_data_8banks                                                   [0:7];
    reg  [    DATA_WIDTH-1:0] write_mask_8banks                                                   [0:7];
    reg  [     `TAGRAM_RANGE] tagarray_dout_latch;
    reg                       lookup_hit_s1;
    reg  [               1:0] lookup_hitway_onehot_s1;
    reg                       lookup_hitway_dec_s1;
    reg  [               1:0] lookup_hitway_oh_latch;
    reg                       lookup_hitway_dec_latch;
    reg  [       `ADDR_RANGE] victimway_fulladdr_latch;
    reg  [     `TAGRAM_RANGE] tagarray_din_writecache_s1;
    reg  [               7:0] dataarray_ce_bank_q;  //regnext the ce bank to select data array out
    // reg [512-1:0] dataarray_dout_banks_dirty512;
    reg  [             511:0] dataarray_dout_banks_dirty512;
    reg  [     `RESULT_RANGE] ddr_512_readdata_sx                                                 [0:7];
    reg  [     `RESULT_RANGE] masked_ddr_readdata_sx;
    reg  [     `RESULT_RANGE] masked_ddr_readdata_latch;
    reg  [     `RESULT_RANGE] merged_512_write_data                                               [0:7];
    reg  [     `TAGRAM_RANGE] tagarray_din_refillread_sx;
    reg  [     `TAGRAM_RANGE] tagarray_din_refillwrite_sx;
    reg                       dcache2arb_inprocess;


    // Define states using parameters
    localparam IDLE = 3'b000;
    localparam LOOKUP = 3'b001;
    localparam WRITE_CACHE = 3'b010;
    localparam READ_CACHE = 3'b011;
    localparam WRITE_DDR = 3'b100;
    localparam READ_DDR = 3'b101;
    localparam REFILL_READ = 3'b110;
    localparam REFILL_WRITE = 3'b111;




    wire                           tagarray_rd_en_port0;
    wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_rd_idx_port0;
    wire [    `DCACHE_WAY_NUM-1:0] tagarray_rd_way_port0;
    wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data_port0;

    wire                           tagarray_rd_en_port1;
    wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_rd_idx_port1;
    wire [    `DCACHE_WAY_NUM-1:0] tagarray_rd_way_port1;
    wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data_port1;

    wire                           tagarray_rd_en_port2;
    wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_rd_idx_port2;
    wire [    `DCACHE_WAY_NUM-1:0] tagarray_rd_way_port2;
    wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_rd_data_port2;


    wire                           tagarray_wr_en;
    wire [TAGARRAY_ADDR_WIDTH-1:0] tagarray_wr_idx;
    wire [    `DCACHE_WAY_NUM-1:0] tagarray_wr_way;
    wire [TAGARRAY_DATA_WIDTH-1:0] tagarray_wr_data;


    /* -------------------------------------------------------------------------- */
    /*                                   Stage1                                   */
    /* -------------------------------------------------------------------------- */

    dcache_loadpipe_l1 #(
        .TAG_ARRAY_IDX_HIGH(TAG_ARRAY_IDX_HIGH),
        .TAG_ARRAY_IDX_LOW (TAG_ARRAY_IDX_LOW)
    ) u_dcache_loadpipe0_l1 (
        .clock            (clock),
        .reset_n          (reset_n),
        .flush            (flush),
        .fromldu_req_valid(ldu0_l1_req_valid),
        .fromldu_req_ready(ldu0_l1_req_ready),
        .fromldu_req_vaddr(ldu0_l1_req_vaddr),
        .tagarray_rd_en   (tagarray_rd_en_port0),
        .tagarray_rd_idx  (tagarray_rd_idx_port0)
    );


    dcache_loadpipe_l1 #(
        .TAG_ARRAY_IDX_HIGH(TAG_ARRAY_IDX_HIGH),
        .TAG_ARRAY_IDX_LOW (TAG_ARRAY_IDX_LOW)
    ) u_dcache_loadpipe1_l1 (
        .clock            (clock),
        .reset_n          (reset_n),
        .flush            (flush),
        .fromldu_req_valid(ldu1_l1_req_valid),
        .fromldu_req_ready(ldu1_l1_req_ready),
        .fromldu_req_vaddr(ldu1_l1_req_vaddr),
        .tagarray_rd_en   (tagarray_rd_en_port1),
        .tagarray_rd_idx  (tagarray_rd_idx_port1)
    );




    /* -------------------------------------------------------------------------- */
    /*                               STAGE 2:look up                              */
    /* -------------------------------------------------------------------------- */







    assign tbus_fire                   = tbus_index_valid & tbus_index_ready;
    assign dcache2arb_dbus_index_valid = dcache2arb_dbus_index_valid_internal & ~flush;



    assign in_idle                     = (state == IDLE);
    assign in_lookup                   = (state == LOOKUP);
    assign in_writecache               = (state == WRITE_CACHE);

    /* -------------------------------------------------------------------------- */
    /*                   IDLE : Stage0                                            */
    /* -------------------------------------------------------------------------- */
    /* ----------------------------------- latch input ----------------------------------- */
    //latch 64bit tbus addr
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ls_addr_latch <= 'b0;
        end else if (in_idle & tbus_index_valid) begin
            ls_addr_latch <= tbus_index;
        end
    end

    //decode bankaddr base on latched tbus addr
    assign bankaddr_latch = ls_addr_latch[5:3];
    always @(*) begin
        integer i;
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            bankaddr_onehot_latch[i] = (bankaddr_latch == i);
        end
    end

    //latch 64bit tbus data
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            write_data_latch <= 'b0;
        end else if (in_idle & tbus_index_valid) begin
            write_data_latch <= tbus_write_data;
        end
    end

    //latch 64bit tbus wmask
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            write_mask_latch <= 'b0;
        end else if (in_idle & tbus_index_valid) begin
            write_mask_latch <= tbus_write_mask;
        end
    end

    //latch tbus operation_type
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            operation_type_latch <= 'b0;
        end else if (in_idle & tbus_index_valid) begin
            operation_type_latch <= tbus_operation_type;
        end
    end

    //decode opreation type
    assign tbus_is_write = (operation_type_latch == `TBUS_WRITE);
    assign tbus_is_read  = (operation_type_latch == `TBUS_READ);

    //extend latched tbus write data to 2D array for writing dataarray
    always @(*) begin
        integer i;
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            if (bankaddr_onehot_latch[i]) begin
                write_data_8banks[i] = write_data_latch;
            end else begin
                write_data_8banks[i] = 0;
            end
        end

    end
    //extend latched tbus wmask to 2D array for writing dataarray

    always @(*) begin
        integer i;
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            if (bankaddr_onehot_latch[i]) begin
                write_mask_8banks[i] = write_mask_latch;
            end else begin
                write_mask_8banks[i] = 0;
            end
        end

    end

    /* ------------------------------- lfsr random ------------------------------ */
    assign seed = 8'hFF;

    lfsr_random u_lfsr_random (
        .clock     (clock),
        .reset_n   (reset_n),
        .seed      (seed),
        .random_num(random_num)
    );

    /* -------------------------------------------------------------------------- */
    /*            LOOKUP : Stage1 , get tagarray dout, check miss / hit , generate tag/data array access logic           */
    /* -------------------------------------------------------------------------- */

    /* -------------------------- decode tagarray dout (s1)-------------------------- */



    assign tagarray_dout_waycontent_s1[0] = tagarray_dout[18:0];  //way0 is [18:0]
    assign tagarray_dout_waycontent_s1[1] = tagarray_dout[37:19];  //way1 is [37:19] 
    assign tagarray_dout_wayvalid_s1      = {tagarray_dout_waycontent_s1[1][`TAGRAM_VALID_RANGE], tagarray_dout_waycontent_s1[0][`TAGRAM_VALID_RANGE]};
    assign tagarray_dout_waydirty_s1      = {tagarray_dout_waycontent_s1[1][`TAGRAM_DIRTY_RANGE], tagarray_dout_waycontent_s1[0][`TAGRAM_DIRTY_RANGE]};
    assign tagarray_dout_wayisfull_s1     = &tagarray_dout_wayvalid_s1;

    //latch tagarray_dout in state lookup
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            tagarray_dout_latch <= 0;
        end else if (in_idle) begin
            tagarray_dout_latch <= 'b0;
        end else if ((state == LOOKUP) && (next_state != LOOKUP)) begin
            tagarray_dout_latch <= tagarray_dout;
        end
    end
    assign tagarray_dout_or = tagarray_dout_latch | tagarray_dout;



    /* ------------------------- lookup logic (s1)------------------------- */

    always @(*) begin
        integer i;
        lookup_hit_s1           = 0;
        lookup_hitway_onehot_s1 = 0;
        for (i = 0; i < `TAGRAM_WAYNUM; i = i + 1) begin
            if ((tagarray_dout_waycontent_s1[i][`TAGRAM_TAG_RANGE] == ls_addr_latch[31:15]) && tagarray_dout_waycontent_s1[i][`TAGRAM_VALID_RANGE]) begin
                lookup_hit_s1              = 1'b1;
                lookup_hitway_onehot_s1[i] = 1'b1;
                lookup_hitway_dec_s1       = i;
                break;
            end else begin
                lookup_hit_s1              = 1'b0;
                lookup_hitway_onehot_s1[i] = 1'b0;
                lookup_hitway_dec_s1       = 0;
            end
        end
    end

    //latch victimway_fulladdr in state lookup
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            lookup_hitway_oh_latch  <= 0;
            lookup_hitway_dec_latch <= 0;
        end else if (in_idle) begin
            lookup_hitway_oh_latch  <= 0;
            lookup_hitway_dec_latch <= 0;
        end else if ((state == LOOKUP) && (next_state != LOOKUP)) begin
            lookup_hitway_oh_latch  <= lookup_hitway_onehot_s1;
            lookup_hitway_dec_latch <= lookup_hitway_dec_s1;
        end
    end
    assign lookup_hitway_oh_or     = lookup_hitway_oh_latch | lookup_hitway_onehot_s1;
    assign lookup_hitway_dec_or    = lookup_hitway_dec_latch | lookup_hitway_dec_s1;




    /* ------------------------------------ cal victim way (s1)----------------------------------- */
    assign debug_ls_addr_latch_tag = ls_addr_latch[31:15];
    assign miss_read_align_addr    = {ls_addr_latch[63:6], 6'b0};
    assign debug_tagarray_din_lo   = tagarray_din[18:0];
    assign debug_tagarray_din_hi   = tagarray_din[37:19];
    assign debug_tagarray_tagin_lo = debug_tagarray_din_lo[16:0];
    assign debug_tagarray_tagin_hi = debug_tagarray_din_hi[16:0];

    findfirstone u_findfirstone_nonvalid (
        .in_vector(~tagarray_dout_wayvalid_s1),
        .onehot   (ff_way_s1),
        .enc      (),
        .valid    ()
    );

    assign tagarray_full_have_clean = tagarray_dout_wayisfull_s1 && ((&tagarray_dout_waydirty_s1) == 'b0);

    findfirstone u_findfirstone_clean (
        .in_vector(~tagarray_dout_waydirty_s1),
        .onehot   (tagarray_full_clean_way_oh),
        .enc      (),
        .valid    ()
    );


    assign random_way_s1         = {random_num[0], ~random_num[0]};  //random_num[0] itself is decimal num 
    //  assign victimway_oh_s1 = tagarray_dout_wayisfull_s1 ? random_way_s1 : ff_way_s1;
    assign victimway_oh_s1       = tagarray_dout_wayisfull_s1 && (tagarray_dout_waydirty_s1 == 2'b11) ? random_way_s1 : tagarray_full_have_clean ? tagarray_full_clean_way_oh : ff_way_s1;

    assign victimway_isdirty_s1  = |(tagarray_dout_waydirty_s1 & tagarray_dout_wayvalid_s1 & victimway_oh_s1);

    /* -------------------------- calculate victim addr (s1)------------------------- */
    assign victimway_pa_s1       = tagarray_dout_waycontent_s1[random_num[0]][`TAGRAM_TAG_RANGE];
    assign victimway_fulladdr_s1 = {32'd0, victimway_pa_s1, ls_addr_latch[14:6], 6'd0};  //64=32+17+9+6
    //latch victimway_fulladdr in state lookup
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            victimway_fulladdr_latch <= 0;
        end else if (in_idle) begin
            victimway_fulladdr_latch <= 0;
        end else if ((state == LOOKUP) && (next_state != LOOKUP)) begin
            victimway_fulladdr_latch <= victimway_fulladdr_s1;
        end
    end
    assign victimway_fulladdr_or = victimway_fulladdr_latch | victimway_fulladdr_s1;

    /* ------------------------------ lookup result ----------------------------- */

    assign lu_hit_s1             = lookup_hit_s1;
    assign lu_miss_s1            = ~lookup_hit_s1;
    assign lu_miss_notfull       = lu_miss_s1 && ~tagarray_dout_wayisfull_s1;
    assign lu_miss_full_vicdirty = lu_miss_s1 && tagarray_dout_wayisfull_s1 && victimway_isdirty_s1;
    assign lu_miss_full_vicclean = lu_miss_s1 && tagarray_dout_wayisfull_s1 && ~victimway_isdirty_s1;

    assign read_hit_s1           = tbus_is_read && lu_hit_s1;
    assign write_hit_s1          = tbus_is_write && lu_hit_s1;

    /* -------------- prepare tagarray input for state WRITE_CACHE -------------- */
    always @(*) begin
        tagarray_din_writecache_s1 = 'b0;
        if (lookup_hitway_dec_or == 1'b0) begin  //hit way0
            tagarray_din_writecache_s1 = {tagarray_dout_or[37:19], tagarray_dout_or[18], 1'b1, tagarray_dout_or[16:0]};  // set way0 dirty to 1
        end else begin
            tagarray_din_writecache_s1 = {tagarray_dout_or[37], 1'b1, tagarray_dout_or[35:19], tagarray_dout_or[18:0]};  // set way1 dirty to 1            
        end
    end



    /* -------------------------------------------------------------------------- */
    /*                    Stage2 : when state == WRITE_CACHE or READ_CACHE                  */
    /* -------------------------------------------------------------------------- */
    /* -------- when state = WRITE_CACHE , write tagarray and data array -------- */


    /* --------------------------- when state == READ_CACHE, get dataarray bank dout --------------------------- */

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            dataarray_ce_bank_q <= 'b0;
        end else begin
            dataarray_ce_bank_q <= dataarray_ce_bank;
        end

    end

    always @(*) begin
        integer i;
        tbus_read_data_s2 = 'b0;
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            if (dataarray_ce_bank_q[i]) begin
                tbus_read_data_s2 = dataarray_dout_banks[i];
            end
        end
    end
    // //collect dirty 512 cacheline
    // always @(*) begin
    //     integer i;
    //     dataarray_dout_banks_dirty512 = 'b0;
    //     for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
    //             dataarray_dout_banks_dirty512[((i+1)*64-1):i*64] = dataarray_dout_banks[i];
    //     end
    // end
    // Collect dirty 512 cacheline

    always @(*) begin
        dataarray_dout_banks_dirty512 = 'b0;
        for (integer i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            dataarray_dout_banks_dirty512[i*64+:64] = dataarray_dout_banks[i];
        end
    end
    /* -------------------------------------------------------------------------- */
    /*      Stage sx : when (state == READ_DDR) and opreation_done     */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- get ddr 512bit cacheline data -------------------------- */
    genvar i;
    generate
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin : gen_ddr_readdata
            always @(*) begin
                ddr_512_readdata_sx[i] = 0;
                if ((state == READ_DDR) && dcache2arb_dbus_operation_done) begin
                    ddr_512_readdata_sx[i] = dcache2arb_dbus_read_data[(i+1)*64-1 : i*64];
                end else begin
                    ddr_512_readdata_sx[i] = 0;
                end
            end
        end
    endgenerate
    /* -------- when opload, extract target 64 bit from ddr 512 bit data -------- */
    always @(*) begin
        integer i;
        masked_ddr_readdata_sx = 0;
        if ((state == READ_DDR) && dcache2arb_dbus_operation_done) begin
            for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
                if (bankaddr_onehot_latch[i]) begin
                    masked_ddr_readdata_sx = ddr_512_readdata_sx[i];
                    break;
                end
            end
        end
    end

    //latch 64bit tbus wmask
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            masked_ddr_readdata_latch <= 0;
        end else if (in_idle) begin
            masked_ddr_readdata_latch <= 0;
        end else begin
            masked_ddr_readdata_latch <= masked_ddr_readdata_sx;
        end
    end
    assign masked_ddr_readdata_or = masked_ddr_readdata_latch | masked_ddr_readdata_sx;




    /* ------------------------ when opstore , merge data ----------------------- */
    always @(*) begin
        integer i;
        for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
            merged_512_write_data[i] = 'b0;
        end
        if ((state == READ_DDR) && dcache2arb_dbus_operation_done) begin
            for (i = 0; i < `DATARAM_BANKNUM; i = i + 1) begin
                if (~bankaddr_onehot_latch[i]) begin
                    merged_512_write_data[i] = ddr_512_readdata_sx[i];
                end else begin
                    merged_512_write_data[i] = (write_data_8banks[i] & write_mask_8banks[i]) | (ddr_512_readdata_sx[i] & ~write_mask_8banks[i]);
                end
            end
        end
    end


    /* --------------------------- state = REFILL_READ -------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            tagarray_din_refillread_sx <= 0;
        end else begin
            //if (lookup_hitway_dec_or == 1'b0) begin  //hit way0
            if (victimway_oh_s1 == 2'b01) begin  //hit way0
                tagarray_din_refillread_sx <= {tagarray_dout_or[37:19], 1'b1, 1'b0, ls_addr_latch[31:15]};  // set way0 dirty to 0
            end else if (victimway_oh_s1 == 2'b10) begin
                tagarray_din_refillread_sx <= {1'b1, 1'b0, ls_addr_latch[31:15], tagarray_dout_or[18:0]};  // set way1 dirty to 0            
            end
        end
    end

    //REFILL_WRITE tag din
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            tagarray_din_refillwrite_sx <= 0;
        end else begin
            if (victimway_oh_s1 == 2'b01) begin  //hit way0
                tagarray_din_refillwrite_sx <= {tagarray_dout_or[37:19], 1'b1, 1'b1, ls_addr_latch[31:15]};  // set way0 dirty to 1
            end else if (victimway_oh_s1 == 2'b10) begin
                tagarray_din_refillwrite_sx <= {1'b1, 1'b1, ls_addr_latch[31:15], tagarray_dout_or[18:0]};  // set way1 dirty to 1            
            end
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                            tagarray / dataarray                            */
    /* -------------------------------------------------------------------------- */



    dcache_tagarray #(
        .DATA_WIDTH(TAGARRAY_DATA_WIDTH),
        .ADDR_WIDTH(TAGARRAY_ADDR_WIDTH)
    ) u_dcache_tagarray (
        .clock            (clock),
        .reset_n          (reset_n),
        .readport0_rd_en  (tagarray_rd_en_port0),
        .readport0_rd_way (tagarray_rd_way_port0),
        .readport0_rd_idx (tagarray_rd_idx_port0),
        .readport0_rd_data(readport0_rd_data),
        .readport1_rd_en  (tagarray_rd_en_port0),
        .readport1_rd_way (tagarray_rd_way_port0),
        .readport1_rd_idx (tagarray_rd_idx_port0),
        .readport1_rd_data(readport1_rd_data),
        .readport2_rd_en  (tagarray_rd_en_port0),
        .readport2_rd_way (tagarray_rd_way_port0),
        .readport2_rd_idx (tagarray_rd_idx_port0),
        .readport2_rd_data(readport2_rd_data),
        .writeport_wr_en  (tagarray_wr_en),
        .writeport_wr_way (tagarray_wr_way),
        .writeport_wr_idx (tagarray_wr_idx),
        .writeport_wr_data(tagarray_wr_data)
    );


    cache_dataarray u_dcache_dataarray (
        .clock       (clock),
        .reset_n     (reset_n),
        .we          (dataarray_we),
        .ce_way      (dataarray_ce_way),
        .ce_bank     (dataarray_ce_bank),
        .writesetaddr(dataarray_writesetaddr),
        .readsetaddr (dataarray_readsetaddr),
        .din_banks   (dataarray_din_banks),
        .wmask_banks (dataarray_wmask_banks),
        .dout_banks  (dataarray_dout_banks)     //output
    );


    /* -------------------------------------------------------------------------- */
    /*                                     FSM                                    */
    /* -------------------------------------------------------------------------- */

    // State transition logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n | flush) state <= IDLE;  // Reset to IDLE state
        else if (flush) begin
            state <= IDLE;
        end else state <= next_state;
    end
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (tbus_fire & ~dcache2arb_inprocess) next_state = LOOKUP;
                else next_state = IDLE;
            end
            LOOKUP: begin
                if (write_hit_s1) begin
                    next_state = WRITE_CACHE;
                end else if (read_hit_s1 || lu_miss_full_vicdirty) begin
                    next_state = READ_CACHE;
                end else begin  //lu_miss_full_vicclean / lu_miss_notfull
                    next_state = READ_DDR;
                end
            end
            WRITE_CACHE: begin
                next_state = IDLE;
            end
            READ_CACHE: begin
                if (read_hit_s1) begin
                    next_state = IDLE;
                end else if (lu_miss_full_vicdirty) begin
                    next_state = WRITE_DDR;
                end
            end
            WRITE_DDR: begin
                if (dcache2arb_dbus_operation_done) begin
                    next_state = READ_DDR;
                end
            end
            READ_DDR: begin
                if (dcache2arb_dbus_operation_done && tbus_is_read) begin
                    next_state = REFILL_READ;
                end else if (dcache2arb_dbus_operation_done && tbus_is_write) begin
                    next_state = REFILL_WRITE;
                end
            end
            REFILL_READ: begin
                next_state = IDLE;
            end
            REFILL_WRITE: begin
                next_state = IDLE;
            end
            default: next_state = state;
        endcase
    end
    // end



    /* --------------------------- set tagarray input --------------------------- */
    //set tagarray chip_enable / writeenable



    always @(*) begin
        if (next_state == LOOKUP) begin
            tagarray_ce    = 1'b1;
            tagarray_we    = 1'b0;
            tagarray_raddr = tbus_index[14:6];
            tagarray_waddr = 0;
            tagarray_din   = 0;
            tagarray_wmask = 0;
        end else if (next_state == WRITE_CACHE) begin
            tagarray_ce    = 1'b1;
            tagarray_we    = 1'b1;
            tagarray_raddr = 0;
            tagarray_waddr = ls_addr_latch[14:6];
            tagarray_din   = tagarray_din_writecache_s1;
            tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
        end else if (next_state == REFILL_READ) begin
            tagarray_ce    = 1'b1;
            tagarray_we    = 1'b1;
            tagarray_raddr = 0;
            tagarray_waddr = ls_addr_latch[14:6];
            tagarray_din   = tagarray_din_refillread_sx;
            tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
        end else if (next_state == REFILL_WRITE) begin
            tagarray_ce    = 1'b1;
            tagarray_we    = 1'b1;
            tagarray_raddr = 0;
            tagarray_waddr = ls_addr_latch[14:6];
            tagarray_din   = tagarray_din_refillwrite_sx;
            tagarray_wmask = {`TAGRAM_LENGTH{1'b1}};
        end else begin
            tagarray_ce    = 1'b0;
            tagarray_we    = 1'b0;
            tagarray_raddr = 0;
            tagarray_waddr = 0;
            tagarray_din   = 0;
            tagarray_wmask = 0;
        end
    end

    /* --------------------------- set dataarray input -------------------------- */



    assign dataarray_din_banks_allone  = {{64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}, {64'hffff_ffff_ffff_ffff}};
    assign dataarray_din_banks_allzero = {{64'h0}, {64'h0}, {64'h0}, {64'h0}, {64'h0}, {64'h0}, {64'h0}, {64'h0}};

    always @(*) begin
        if (~reset_n) begin
            dataarray_we           = 0;
            dataarray_ce_way       = 0;
            dataarray_ce_bank      = 0;
            dataarray_din_banks    = dataarray_din_banks_allzero;
            dataarray_writesetaddr = 0;
            dataarray_readsetaddr  = 0;
            dataarray_wmask_banks  = dataarray_din_banks_allzero;
        end else if (next_state == WRITE_CACHE) begin  //write dataarray
            dataarray_we           = 1;
            dataarray_ce_way       = lookup_hitway_onehot_s1;
            dataarray_ce_bank      = bankaddr_onehot_latch;
            dataarray_din_banks    = write_data_8banks;
            dataarray_writesetaddr = ls_addr_latch[14:6];
            dataarray_readsetaddr  = 0;
            dataarray_wmask_banks  = write_mask_8banks;
        end else if (next_state == READ_CACHE) begin  //read dataarray
            if (read_hit_s1) begin
                dataarray_we           = 0;
                dataarray_ce_way       = lookup_hitway_onehot_s1;
                dataarray_ce_bank      = bankaddr_onehot_latch;
                dataarray_din_banks    = dataarray_din_banks_allzero;
                dataarray_writesetaddr = 0;
                dataarray_readsetaddr  = ls_addr_latch[14:6];
                dataarray_wmask_banks  = dataarray_din_banks_allzero;
            end else begin  // lu_miss_full_vicdirty
                dataarray_we           = 0;
                dataarray_ce_way       = victimway_oh_s1;
                dataarray_ce_bank      = 8'hff;
                dataarray_din_banks    = dataarray_din_banks_allzero;
                dataarray_writesetaddr = 0;
                dataarray_readsetaddr  = ls_addr_latch[14:6];
                dataarray_wmask_banks  = dataarray_din_banks_allzero;
            end

        end else if (next_state == REFILL_READ) begin  //write 512 ddr read data
            dataarray_we           = 1;
            dataarray_ce_way       = victimway_oh_s1;
            dataarray_ce_bank      = 8'hff;
            dataarray_din_banks    = ddr_512_readdata_sx;
            dataarray_writesetaddr = ls_addr_latch[14:6];
            dataarray_readsetaddr  = 0;
            dataarray_wmask_banks  = dataarray_din_banks_allone;
        end else if (next_state == REFILL_WRITE) begin  //write 512 merged data
            dataarray_we           = 1;
            dataarray_ce_way       = victimway_oh_s1;
            dataarray_ce_bank      = 8'hff;
            dataarray_din_banks    = merged_512_write_data;
            dataarray_writesetaddr = ls_addr_latch[14:6];
            dataarray_readsetaddr  = 0;
            dataarray_wmask_banks  = dataarray_din_banks_allone;
        end else begin
            dataarray_we           = 0;
            dataarray_ce_way       = 0;
            dataarray_ce_bank      = 0;
            dataarray_din_banks    = dataarray_din_banks_allzero;
            dataarray_writesetaddr = 0;
            dataarray_readsetaddr  = 0;
            dataarray_wmask_banks  = dataarray_din_banks_allzero;
        end
    end

    /* ----------------------- trinity bus to backend/pc_ctrl ----------------------- */
    always @(*) begin
        if (state == IDLE && ~dcache2arb_inprocess) begin
            tbus_operation_done = 1'b0;
            tbus_read_data      = 0;
            tbus_index_ready    = 1;
        end else if (state == WRITE_CACHE) begin
            tbus_operation_done = 1'b1;
            tbus_read_data      = 0;
            tbus_index_ready    = 0;
        end else if (state == READ_CACHE && next_state == IDLE) begin
            tbus_operation_done = 1'b1;
            tbus_read_data      = tbus_read_data_s2;
            tbus_index_ready    = 0;
        end else if (state == REFILL_READ && next_state == IDLE) begin
            tbus_operation_done = 1'b1;
            tbus_read_data      = masked_ddr_readdata_or;
            tbus_index_ready    = 0;
        end else if (state == REFILL_WRITE && next_state == IDLE) begin
            tbus_operation_done = 1'b1;
            tbus_read_data      = 'b0;
            tbus_index_ready    = 0;
        end else begin
            tbus_operation_done = 'b0;
            tbus_read_data      = 0;
            tbus_index_ready    = 0;
        end
    end



    /* ------------------------------- set ddr bus ------------------------------ */
    assign dcache2arb_fire = dcache2arb_dbus_index_valid_internal & dcache2arb_dbus_index_ready;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            dcache2arb_inprocess <= 'b0;
        end else if (dcache2arb_fire) begin
            dcache2arb_inprocess <= 1'b1;
        end else if (dcache2arb_dbus_operation_done) begin
            dcache2arb_inprocess <= 'b0;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            dcache2arb_dbus_index_valid_internal <= 0;
            dcache2arb_dbus_index                <= 0;
            dcache2arb_dbus_write_data           <= 0;
            dcache2arb_dbus_operation_type       <= 0;
        end else if (flush) begin
            dcache2arb_dbus_index_valid_internal <= 0;
            dcache2arb_dbus_index                <= 0;
            dcache2arb_dbus_write_data           <= 0;
            dcache2arb_dbus_operation_type       <= 0;
        end else if (state == READ_CACHE && next_state == WRITE_DDR) begin  //write back dirty data to ddr
            dcache2arb_dbus_index_valid_internal <= 1;
            dcache2arb_dbus_index                <= victimway_fulladdr_latch;
            //            dcache2arb_dbus_write_data     <= tbus_read_data_s2;  //64bit
            dcache2arb_dbus_write_data           <= dataarray_dout_banks_dirty512;  //512bit
            dcache2arb_dbus_operation_type       <= `TBUS_WRITE;
        end else if ((state == WRITE_DDR && dcache2arb_dbus_index_ready) || (state == READ_DDR && dcache2arb_dbus_index_ready)) begin  //write ddr/read ddr is fire
            dcache2arb_dbus_index_valid_internal <= 0;
        end else if ((state == WRITE_DDR) && (next_state == READ_DDR)) begin  //read cacheline from ddr
            dcache2arb_dbus_index_valid_internal <= 1;
            dcache2arb_dbus_index                <= miss_read_align_addr;
            dcache2arb_dbus_write_data           <= 0;
            dcache2arb_dbus_operation_type       <= `TBUS_READ;
        end else if (((state == LOOKUP) && (next_state == READ_DDR))) begin  //read cacheline from ddr 
            // 2nd condition means when state in READ_DDR,but ddr is busy,so have to wait till it finish
            dcache2arb_dbus_index_valid_internal <= 1;
            dcache2arb_dbus_index                <= miss_read_align_addr;
            dcache2arb_dbus_write_data           <= 0;
            dcache2arb_dbus_operation_type       <= `TBUS_READ;
        end
    end


    /* verilator lint_off UNOPTFLAT */
endmodule


