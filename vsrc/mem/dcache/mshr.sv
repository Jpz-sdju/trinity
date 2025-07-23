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


);

endmodule
