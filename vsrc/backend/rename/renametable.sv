`include "defines.sv"
module renametable (
    input wire clock,
    input wire reset_n,

    //read req from decode
    input wire       instr0_src1_is_reg,
    input wire [4:0] instr0_rs1,
    input wire       instr0_src2_is_reg,
    input wire [4:0] instr0_rs2,
    input wire       instr0_need_to_wb,
    input wire [4:0] instr0_rd,


    input wire       instr1_src1_is_reg,
    input wire [4:0] instr1_rs1,
    input wire       instr1_src2_is_reg,
    input wire [4:0] instr1_rs2,
    input wire       instr1_need_to_wb,
    input wire [4:0] instr1_rd,

    //read data to rename
    output wire [`PREG_RANGE] instr0_rat_prs1,
    output wire [`PREG_RANGE] instr0_rat_prs2,
    output wire [`PREG_RANGE] instr0_rat_prd,

    output wire [`PREG_RANGE] instr1_rat_prs1,
    output wire [`PREG_RANGE] instr1_rat_prs2,
    output wire [`PREG_RANGE] instr1_rat_prd,

    //write request from rename
    input wire       instr0_rat_rename_valid,
    input wire [4:0] instr0_rat_rename_addr,
    input wire [`PREG_RANGE] instr0_rat_rename_data,

    input wire       instr1_rat_rename_valid,
    input wire [4:0] instr1_rat_rename_addr,
    input wire [`PREG_RANGE] instr1_rat_rename_data

);

    reg [ `PREG_RANGE] renametables          [0:31];

    reg [31:0] renametables_wren_dec;
    reg [ `PREG_RANGE] renametables_wdata_dec[0:31];


    assign instr0_rat_prs1 = instr0_src1_is_reg ? renametables[instr0_rs1] : 'b0;  //could gate?
    assign instr0_rat_prs2 = instr0_src2_is_reg ? renametables[instr0_rs2] : 'b0;
    assign instr0_rat_prd  = instr0_need_to_wb ? renametables[instr0_rd] : 'b0;

    assign instr1_rat_prs1 = instr1_src1_is_reg ? renametables[instr1_rs1] : 'b0;  //could gate?
    assign instr1_rat_prs2 = instr1_src2_is_reg ? renametables[instr1_rs2] : 'b0;
    assign instr1_rat_prd  = instr1_need_to_wb ? renametables[instr1_rd] : 'b0;

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
endmodule
