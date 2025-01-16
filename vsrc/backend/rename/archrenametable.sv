`include "defines.sv"
module archrenametable (
    input wire clock,
    input wire reset_n,

    input wire               commits0_valid,
    input wire               commits0_need_to_wb,
    input wire [`LREG_RANGE] commits0_lrd,
    input wire [`PREG_RANGE] commits0_prd,

    input wire               commits1_valid,
    input wire               commits1_need_to_wb,
    input wire [`LREG_RANGE] commits1_lrd,
    input wire [`PREG_RANGE] commits1_prd,

    //debug
    output wire [`PREG_RANGE] debug_preg0,
    output wire [`PREG_RANGE] debug_preg1,
    output wire [`PREG_RANGE] debug_preg2,
    output wire [`PREG_RANGE] debug_preg3,
    output wire [`PREG_RANGE] debug_preg4,
    output wire [`PREG_RANGE] debug_preg5,
    output wire [`PREG_RANGE] debug_preg6,
    output wire [`PREG_RANGE] debug_preg7,
    output wire [`PREG_RANGE] debug_preg8,
    output wire [`PREG_RANGE] debug_preg9,
    output wire [`PREG_RANGE] debug_preg10,
    output wire [`PREG_RANGE] debug_preg11,
    output wire [`PREG_RANGE] debug_preg12,
    output wire [`PREG_RANGE] debug_preg13,
    output wire [`PREG_RANGE] debug_preg14,
    output wire [`PREG_RANGE] debug_preg15,
    output wire [`PREG_RANGE] debug_preg16,
    output wire [`PREG_RANGE] debug_preg17,
    output wire [`PREG_RANGE] debug_preg18,
    output wire [`PREG_RANGE] debug_preg19,
    output wire [`PREG_RANGE] debug_preg20,
    output wire [`PREG_RANGE] debug_preg21,
    output wire [`PREG_RANGE] debug_preg22,
    output wire [`PREG_RANGE] debug_preg23,
    output wire [`PREG_RANGE] debug_preg24,
    output wire [`PREG_RANGE] debug_preg25,
    output wire [`PREG_RANGE] debug_preg26,
    output wire [`PREG_RANGE] debug_preg27,
    output wire [`PREG_RANGE] debug_preg28,
    output wire [`PREG_RANGE] debug_preg29,
    output wire [`PREG_RANGE] debug_preg30,
    output wire [`PREG_RANGE] debug_preg31

);

    reg  [`PREG_RANGE] renametables          [0:31];

    //wren and wrdata decode
    reg  [       31:0] renametables_wren_dec;
    reg  [`PREG_RANGE] renametables_wdata_dec[0:31];


    wire               commits0_rat_wren;
    wire               commits1_rat_wren;
    assign commits0_rat_wren = commits0_valid & commits0_need_to_wb;
    assign commits1_rat_wren = commits1_valid & commits1_need_to_wb;

    //write at same time , forbid older write data
    wire same_lrd = commits0_rat_wren & commits1_rat_wren & (commits0_lrd == commits1_lrd);

    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wren_dec[i] = 'b0;
            if (commits0_rat_wren & (commits0_lrd == i[4:0]) | commits1_rat_wren & (commits1_lrd == i[4:0])) begin
                renametables_wren_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wdata_dec[i] = 'b0;
            if (commits0_rat_wren & (commits0_lrd == i[4:0]) & (~same_lrd)) begin
                renametables_wdata_dec[i] = commits0_prd;
            end else if (commits1_rat_wren & (commits1_lrd == i[4:0])) begin
                renametables_wdata_dec[i] = commits1_prd;
            end
        end
    end



    always @(posedge clock or negedge reset_n) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            if (~reset_n) begin
                renametables[i] <= i[5:0];
            end else if (renametables_wren_dec[i]) begin
                renametables[i] <= renametables_wdata_dec[i];
            end
        end
    end


    //debug
    assign debug_preg0  = renametables[0];
    assign debug_preg1  = renametables[1];
    assign debug_preg2  = renametables[2];
    assign debug_preg3  = renametables[3];
    assign debug_preg4  = renametables[4];
    assign debug_preg5  = renametables[5];
    assign debug_preg6  = renametables[6];
    assign debug_preg7  = renametables[7];
    assign debug_preg8  = renametables[8];
    assign debug_preg9  = renametables[9];
    assign debug_preg10 = renametables[10];
    assign debug_preg11 = renametables[11];
    assign debug_preg12 = renametables[12];
    assign debug_preg13 = renametables[13];
    assign debug_preg14 = renametables[14];
    assign debug_preg15 = renametables[15];
    assign debug_preg16 = renametables[16];
    assign debug_preg17 = renametables[17];
    assign debug_preg18 = renametables[18];
    assign debug_preg19 = renametables[19];
    assign debug_preg20 = renametables[20];
    assign debug_preg21 = renametables[21];
    assign debug_preg22 = renametables[22];
    assign debug_preg23 = renametables[23];
    assign debug_preg24 = renametables[24];
    assign debug_preg25 = renametables[25];
    assign debug_preg26 = renametables[26];
    assign debug_preg27 = renametables[27];
    assign debug_preg28 = renametables[28];
    assign debug_preg29 = renametables[29];
    assign debug_preg30 = renametables[30];
    assign debug_preg31 = renametables[31];

endmodule
