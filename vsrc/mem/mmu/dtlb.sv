`include "defines.sv"
module dtlb (
    input wire                ls_vaddr_valid,
    input wire [`VADDR_RANGE] ls_vaddr,


    output wire [`PADDR_RANGE] ls_paddr




);

    assign ls_paddr = ls_vaddr;

endmodule
