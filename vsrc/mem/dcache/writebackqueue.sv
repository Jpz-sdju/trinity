
`include "defines.sv"
module writebackqueue #(

) (


    input wire clock,   // Clock signal
    input wire reset_n, // Active low reset

    output wire                     wbq2arb_valid,
    input  wire                     wbq2arb_ready,
    output wire [     `PADDR_RANGE] wbq2arb_paddr,
    output wire [            511:0] wbq2arb_data,
    output wire [`MSHR_NUM_LOG-1:0] wbq2arb_wbqid

);




endmodule
