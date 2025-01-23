`include "defines.sv"
module tb_top (
    input  wire [3:0] a,
    output wire [3:0] b,

    input wire clock,
    input wire reset_n
);
    assign b[3:0] = a + 4'b1;
    initial begin
        $display("heell");
        // $finish;
    end
    /* verilator lint_off UNDRIVEN */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off PINMISSING */
find_last1 
#(
    .WIDTH (8 )
)
u_find_last1(
    .data_in  (data_in  ),
    .data_out (data_out )
);

    /* verilator lint_off PINMISSING */
    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off UNDRIVEN */
endmodule
