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
    output wire [`PADDR_RANGE] dmshr2arb_paddr,

);






    genvar i;
    generate
        for(i = 0; i < `MSHR_NUM; i = i + 1) begin : 
            mshr_entry #(
                .MSHR_ID(i)
            )mshr_entry_inst (
                .clock(clock),
                .reset_n(reset_n),
                .allocate0_valid(allocate0_valid && (i == 0)),
                .allocate0_paddr(allocate0_paddr),
                .allocate1_valid(allocate1_valid && (i == 1)),
                .allocate1_paddr(allocate1_paddr),
                .allocate2_valid(allocate2_valid && (i == 2)),
                .allocate2_paddr(allocate2_paddr),
                .dmshr2arb_valid(dmshr2arb_valid && (i == 0)),
                .dmshr2arb_ready(dmshr2arb_ready),
                .dmshr2arb_paddr(dmshr2arb_paddr)
            );



            
        end
    endgenerate
endmodule
