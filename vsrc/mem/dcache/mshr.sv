`include "defines.sv"
module mshr (
    input wire                clock,            // Clock signal
    input wire                reset_n,          // Active low reset
    input wire                allocate0_valid,
    input wire [`PADDR_RANGE] allocate0_paddr,
    input wire                allocate1_valid,
    input wire [`PADDR_RANGE] allocate1_paddr,
    input wire                allocate2_valid,
    input wire [`PADDR_RANGE] allocate2_paddr,


    output wire dmshr2arb_valid,
    input wire dmshr2arb_ready,
    output wire [`PADDR_RANGE] dmshr2arb_paddr

);






    genvar i;
    generate
        for(i = 0; i < `MSHR_NUM; i = i + 1) begin : 
            mshr_entry 
            #(
                .MSHR_ID (i )
            )
            u_mshr_entry(
                .clock                (clock                ),
                .reset_n              (reset_n              ),
                .install_valid        (install_valid        ),
                .install_robid        (install_robid        ),
                .install_paddr        (install_paddr        ),
                .merge_valid          (merge_valid          ),
                .merge_robid          (merge_robid          ),
                .rpt_entry_valid      (rpt_entry_valid      ),
                .rpt_entry_robid      (rpt_entry_robid      ),
                .rpt_entry_paddr      (rpt_entry_paddr      ),
                .rpt_entry_rdy2refill (rpt_entry_rdy2refill ),
                .win_chi_arb          (win_chi_arb          ),
                .chi_arb_resp_valid   (chi_arb_resp_valid   ),
                .chi_arb_resp_data    (chi_arb_resp_data    ),
                .win_refill_arb       (win_refill_arb       )
            );
            
        end
    endgenerate
endmodule
