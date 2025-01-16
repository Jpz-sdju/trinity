`include "defines.sv"
module renametable (
    input wire clock,
    input wire reset_n,

    //read req from decode
    input wire       instr0_src1_is_reg,
    input wire [4:0] instr0_lrs1,
    input wire       instr0_src2_is_reg,
    input wire [4:0] instr0_lrs2,
    input wire       instr0_need_to_wb,
    input wire [4:0] instr0_lrd,


    input wire       instr1_src1_is_reg,
    input wire [4:0] instr1_lrs1,
    input wire       instr1_src2_is_reg,
    input wire [4:0] instr1_lrs2,
    input wire       instr1_need_to_wb,
    input wire [4:0] instr1_lrd,

    //read data to rename
    output wire [`PREG_RANGE] instr0_rat_prs1,
    output wire [`PREG_RANGE] instr0_rat_prs2,
    output wire [`PREG_RANGE] instr0_rat_prd,

    output wire [`PREG_RANGE] instr1_rat_prs1,
    output wire [`PREG_RANGE] instr1_rat_prs2,
    output wire [`PREG_RANGE] instr1_rat_prd,

    //write request from rename
    input wire               instr0_rat_rename_valid,
    input wire [        4:0] instr0_rat_rename_addr,
    input wire [`PREG_RANGE] instr0_rat_rename_data,

    input wire               instr1_rat_rename_valid,
    input wire [        4:0] instr1_rat_rename_addr,
    input wire [`PREG_RANGE] instr1_rat_rename_data,


    //arch rat write 
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

    reg [`PREG_RANGE] renametables          [0:31];

    reg [       31:0] renametables_wren_dec;
    reg [`PREG_RANGE] renametables_wdata_dec[0:31];


    assign instr0_rat_prs1 = instr0_src1_is_reg ? renametables[instr0_lrs1] : 'b0;  //could gate?
    assign instr0_rat_prs2 = instr0_src2_is_reg ? renametables[instr0_lrs2] : 'b0;
    assign instr0_rat_prd  = instr0_need_to_wb ? renametables[instr0_lrd] : 'b0;

    assign instr1_rat_prs1 = instr1_src1_is_reg ? renametables[instr1_lrs1] : 'b0;  //could gate?
    assign instr1_rat_prs2 = instr1_src2_is_reg ? renametables[instr1_lrs2] : 'b0;
    assign instr1_rat_prd  = instr1_need_to_wb ? renametables[instr1_lrd] : 'b0;

    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wren_dec[i] = 'b0;
            if (instr0_rat_rename_valid & (instr0_rat_rename_addr == i[4:0]) | instr1_rat_rename_valid & (instr1_rat_rename_addr == i[4:0])) begin
                renametables_wren_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wdata_dec[i] = 'b0;
            if (instr0_rat_rename_valid & (instr0_rat_rename_addr == i[4:0])) begin
                renametables_wdata_dec[i] = instr0_rat_rename_data;
            end else if (instr1_rat_rename_valid & (instr1_rat_rename_addr == i[4:0])) begin
                renametables_wdata_dec[i] = instr1_rat_rename_data;
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


    /* -------------------------------------------------------------------------- */
    /*                                  arch rat                                  */
    /* -------------------------------------------------------------------------- */
    archrenametable u_archrenametable (
        .clock              (clock),
        .reset_n            (reset_n),
        .commits0_valid     (commits0_valid),
        .commits0_need_to_wb(commits0_need_to_wb),
        .commits0_lrd       (commits0_lrd),
        .commits0_prd       (commits0_prd),
        .commits1_valid     (commits1_valid),
        .commits1_need_to_wb(commits1_need_to_wb),
        .commits1_lrd       (commits1_lrd),
        .commits1_prd       (commits1_prd),
        //debug
        .debug_preg0        (debug_preg0),
        .debug_preg1        (debug_preg1),
        .debug_preg2        (debug_preg2),
        .debug_preg3        (debug_preg3),
        .debug_preg4        (debug_preg4),
        .debug_preg5        (debug_preg5),
        .debug_preg6        (debug_preg6),
        .debug_preg7        (debug_preg7),
        .debug_preg8        (debug_preg8),
        .debug_preg9        (debug_preg9),
        .debug_preg10       (debug_preg10),
        .debug_preg11       (debug_preg11),
        .debug_preg12       (debug_preg12),
        .debug_preg13       (debug_preg13),
        .debug_preg14       (debug_preg14),
        .debug_preg15       (debug_preg15),
        .debug_preg16       (debug_preg16),
        .debug_preg17       (debug_preg17),
        .debug_preg18       (debug_preg18),
        .debug_preg19       (debug_preg19),
        .debug_preg20       (debug_preg20),
        .debug_preg21       (debug_preg21),
        .debug_preg22       (debug_preg22),
        .debug_preg23       (debug_preg23),
        .debug_preg24       (debug_preg24),
        .debug_preg25       (debug_preg25),
        .debug_preg26       (debug_preg26),
        .debug_preg27       (debug_preg27),
        .debug_preg28       (debug_preg28),
        .debug_preg29       (debug_preg29),
        .debug_preg30       (debug_preg30),
        .debug_preg31       (debug_preg31)
    );

endmodule
