`include "defines.sv"

module rename_table #(
    
) (
    input wire rat_read_valid_0,
    input wire [`LREG_RANGE] rat_read_idx_lrs1_0,
    input wire [`LREG_RANGE] rat_read_idx_lrs2_0,
    input wire [`LREG_RANGE] rat_read_idx_lrd_0,
    
    input wire rat_read_valid_1,
    input wire [`LREG_RANGE] rat_read_idx_lrs1_1,
    input wire [`LREG_RANGE] rat_read_idx_lrs2_1,
    input wire [`LREG_RANGE] rat_read_idx_lrd_1,


    input wire [`PREG_RANGE] rat_read_data_prs1_0,
    input wire [`PREG_RANGE] rat_read_data_prs2_0,
    input wire [`PREG_RANGE] rat_read_data_prd_0,

    input wire [`PREG_RANGE] rat_read_data_prs1_1,
    input wire [`PREG_RANGE] rat_read_data_prs2_1,
    input wire [`PREG_RANGE] rat_read_data_prd_1,



);
     reg [5:0] rat [4:0];


endmodule