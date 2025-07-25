`include "defines.sv"
module mshr_entry#(
    parameter MSHR_ID = 0
) (
    input wire                clock,          // Clock signal
    input wire                reset_n,        // Active low reset
    input wire                install_valid,
    input wire [`PADDR_RANGE] install_paddr


);


    // Internal signals for MSHR entry
    wire [`PADDR_RANGE] mshr_paddr;
    wire mshr_valid;

    // Logic to handle MSHR entry operations
    assign mshr_paddr = install_paddr;
    assign mshr_valid = install_valid;

    // Output signals for the MSHR entry
    assign dmshr2arb_valid = mshr_valid;
    assign dmshr2arb_paddr = mshr_paddr;
endmodule
