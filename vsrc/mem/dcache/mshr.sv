`include "defines.sv"
module mshr (
    input wire                   clock,            // Clock signal
    input wire                   reset_n,          // Active low reset
    input wire                   allocate0_valid,
    input wire [   `PADDR_RANGE] allocate0_paddr,
    input wire [`ROB_SIZE_LOG:0] allocate0_robid,


    input wire                   allocate1_valid,
    input wire [   `PADDR_RANGE] allocate1_paddr,
    input wire [`ROB_SIZE_LOG:0] allocate1_robid,

    // input wire                allocate2_valid,
    // input wire [`PADDR_RANGE] allocate2_paddr,


    output wire                     dmshr2arb_valid,
    input  wire                     dmshr2arb_ready,
    output wire [     `PADDR_RANGE] dmshr2arb_paddr,
    output wire [`MSHR_NUM_LOG-1:0] dmshr2arb_mshrid,
    input  wire                     dmshr2arb_operation_done,
    input  wire [`MSHR_NUM_LOG-1:0] dmshr2arb_operation_done_mshrid,
    input  wire [            511:0] dmshr2arb_read_data

);



    wire [    `MSHR_NUM-1:0] rpt_valid_vec;
    wire [  `ROB_SIZE_LOG:0] rpt_robid_vec             [0:`MSHR_NUM-1];
    wire [     `PADDR_RANGE] rpt_paddr_vec             [0:`MSHR_NUM-1];
    wire [            511:0] rpt_refilldata_vec        [0:`MSHR_NUM-1];
    wire [`MSHR_NUM_LOG-1:0] rpt_mshrid_vec            [0:`MSHR_NUM-1];
    wire [    `MSHR_NUM-1:0] rpt_rdy2refill_vec;

    wire [    `MSHR_NUM-1:0] refill_grant_vec;
    wire                     refill_grant_valid;




    wire [    `MSHR_NUM-1:0] mshr_avail_vec;
    wire [    `MSHR_NUM-1:0] mshr_avail_vec_except_ff0;
    wire                     ff0_valid;
    wire [    `MSHR_NUM-1:0] ff0_oh;
    wire                     ff0_enc;
    wire                     ff1_valid;
    wire [    `MSHR_NUM-1:0] ff1_oh;
    wire                     ff1_enc;


    wire [    `MSHR_NUM-1:0] chi_arb_req_valid_vec;
    wire [    `MSHR_NUM-1:0] chi_arb_req_ready_vec;
    wire                     chi_arb_is_valid;

    reg  [    `MSHR_NUM-1:0] arb_resp_valid_vec;
    reg  [            511:0] arb_resp_data_vec         [0:`MSHR_NUM-1];

    assign mshr_avail_vec            = ~rpt_valid_vec;
    assign mshr_avail_vec_except_ff0 = mshr_avail_vec & ~ff0_oh;


    findfirstone #(
        .WIDTH    (`MSHR_NUM),
        .WIDTH_LOG(`MSHR_NUM_LOG)
    ) allocate_ff0 (
        .in_vector(mshr_avail_vec),
        .onehot   (ff0_oh),
        .enc      (),
        .valid    (ff0_valid)
    );

    findfirstone #(
        .WIDTH    (`MSHR_NUM),
        .WIDTH_LOG(`MSHR_NUM_LOG)
    ) allocate_ff1 (
        .in_vector(mshr_avail_vec_except_ff0),
        .onehot   (ff1_oh),
        .enc      (),
        .valid    (ff1_valid)
    );

    reg [  `MSHR_NUM-1:0] mshr_install_valid_vec;
    reg [   `PADDR_RANGE] mshr_install_paddr_vec [0:`MSHR_NUM-1];
    reg [`ROB_SIZE_LOG:0] mshr_install_robid_vec [0:`MSHR_NUM-1];

    always @(*) begin
        integer i;
        for (i = 0; i < `MSHR_NUM; i = i + i) begin
            mshr_install_valid_vec[i] = ff0_oh[i] | ff1_oh[i];
            mshr_install_paddr_vec[i] = {`PADDR_LENGTH{ff0_oh[i]}} & allocate0_paddr | {`PADDR_LENGTH{ff1_oh[i]}} & allocate1_paddr;
            mshr_install_robid_vec[i] = {(`ROB_SIZE_LOG + 1) {ff0_oh[i]}} & allocate0_robid | {(`ROB_SIZE_LOG + 1) {ff1_oh[i]}} & allocate1_robid;
        end
    end


    /* ---------------------- All MSHR arb to access L2/MEM --------------------- */

    findfirstone #(
        .WIDTH    (`MSHR_NUM),
        .WIDTH_LOG(`MSHR_NUM_LOG)
    ) chi_arb (
        .in_vector(chi_arb_req_valid_vec),
        .onehot   (chi_arb_req_ready_vec),
        .enc      (),
        .valid    (chi_arb_is_valid)
    );



    always @(*) begin
        integer i;
        arb_resp_valid_vec = 'b0;
        arb_resp_data_vec  = 'b0;
        for (i = 0; i < `MSHR_NUM; i = i + 1) begin
            if (i == dmshr2arb_mshrid && dmshr2arb_operation_done) begin
                arb_resp_valid_vec[i] = 'b1;
                arb_resp_data_vec[i]  = dmshr2arb_read_data;
            end
        end
    end


    /* ---------------------- All MSHR arb to Refill Dcache --------------------- */

    findfirstone #(
        .WIDTH    (`MSHR_NUM),
        .WIDTH_LOG(`MSHR_NUM_LOG)
    ) chi_arb (
        .in_vector(rpt_rdy2refill_vec),
        .onehot   (refill_grant_vec),
        .enc      (),
        .valid    (chi_arb_is_valid)
    );


    genvar i;
    generate
        for (i = 0; i < `MSHR_NUM; i = i + 1) begin
            mshr_entry #(
                .MSHR_ID(i)
            ) u_mshr_entry (
                .clock               (clock),
                .reset_n             (reset_n),
                .install_valid       (mshr_install_valid_vec[i]),
                .install_paddr       (mshr_install_paddr_vec[i]),
                .install_robid       (mshr_install_robid_vec[i]),
                .merge_valid         (),
                .merge_robid         (),
                .rpt_entry_valid     (rpt_valid_vec[i]),
                .rpt_entry_robid     (rpt_robid_vec[i]),
                .rpt_entry_paddr     (rpt_paddr_vec[i]),
                .rpt_entry_refilldata(rpt_refilldata_vec[i]),
                .rpt_entry_mshrid    (rpt_mshrid_vec[i]),
                .rpt_entry_rdy2refill(rpt_rdy2refill_vec[i]),
                .chi_arb_req_valid   (chi_arb_req_valid_vec[i]),
                .chi_arb_req_ready   (chi_arb_req_ready_vec[i]),
                .chi_arb_resp_valid  (arb_resp_valid_vec[i]),
                .chi_arb_resp_data   (arb_resp_data_vec[i]),
                .win_refill_arb      (refill_grant_vec[i] & refill_grant_valid)
            );
        end
    endgenerate




endmodule
