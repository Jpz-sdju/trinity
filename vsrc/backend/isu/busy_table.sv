`include "defines.sv"
module busy_table (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    // Read Port 0
    input  wire [`PREG_RANGE] disp2bt_instr0_rs1,          // Address for disp2bt_instr0_rs1_rddata
    input  wire               disp2bt_instr0_src1_is_reg,
    output reg                bt2disp_instr0_src1_busy,    // Data output for disp2bt_instr0_rs1_rddata

    // Read Port 1
    input  wire [`PREG_RANGE] disp2bt_instr0_rs2,          // Address for disp2bt_instr0_rs2_rddata
    input  wire               disp2bt_instr0_src2_is_reg,
    output reg                bt2disp_instr0_src2_busy,    // Data output for disp2bt_instr0_rs2_rddata

    // Read Port 2
    input  wire [`PREG_RANGE] disp2bt_instr1_rs1,          // Address for disp2bt_instr1_rs1_rddata
    input  wire               disp2bt_instr1_src1_is_reg,
    output reg                bt2disp_instr1_src1_busy,    // Data output for disp2bt_instr1_rs1_rddata

    // Read Port 3
    input  wire [`PREG_RANGE] disp2bt_instr1_rs2,          // Address for disp2bt_instr1_rs2_rddata
    input  wire               disp2bt_instr1_src2_is_reg,
    output reg                bt2disp_instr1_src2_busy,    // Data output for disp2bt_instr1_rs2_rddata

    // Write Port 0 - Allocate Instruction 0
    input wire               disp2bt_alloc_instr0_rd_en,  // Enable for disp2bt_alloc_instr0_rd
    input wire [`PREG_RANGE] disp2bt_alloc_instr0_rd,     // Address for disp2bt_alloc_instr0_rd

    // Write Port 1 - Allocate Instruction 1
    input wire               disp2bt_alloc_instr1_rd_en,  // Enable for disp2bt_alloc_instr1_rd
    input wire [`PREG_RANGE] disp2bt_alloc_instr1_rd,     // Address for disp2bt_alloc_instr1_rd

    // Write Port 2 - Free Instruction 0
    input wire               intwb02bt_free_instr0_rd_en,  // Enable for intwb02bt_free_instr0_rd
    input wire [`PREG_RANGE] intwb02bt_free_instr0_rd,     // Address for intwb02bt_free_instr0_rd

    // Write Port 3 - Free Instruction 1
    input wire               memwb2bt_free_instr0_rd_en,  // Enable for memwb2bt_free_instr0_rd
    input wire [`PREG_RANGE] memwb2bt_free_instr0_rd,     // Address for memwb2bt_free_instr0_rd

    /* ------------------------------- walk logic ------------------------------- */
    input                            flush_valid,
    input      [`INSTR_ID_WIDTH-1:0] flush_robid,         //TODO, use robid to kill young instr
    input wire [                1:0] rob_state,
    input wire                       rob_walk0_valid,
    input wire                       rob_walk0_complete,
    input wire [        `PREG_RANGE] rob_walk0_prd,
    input wire                       rob_walk1_valid,
    input wire [        `PREG_RANGE] rob_walk1_prd,
    input wire                       rob_walk1_complete

);
    wire is_idle;
    wire is_rollback;
    wire is_walking;
    assign is_idle     = (rob_state == `ROB_STATE_IDLE);
    assign is_rollback = (rob_state == `ROB_STATE_ROLLBACK);
    assign is_walking  = (rob_state == `ROB_STATE_WALK);

    reg  [`PREG_SIZE-1:0] busy_table;
    //debug
    wire                  debug_busy_table_0 = busy_table[0];
    wire                  debug_busy_table_1 = busy_table[1];
    wire                  debug_busy_table_2 = busy_table[2];
    wire                  debug_busy_table_3 = busy_table[3];
    wire                  debug_busy_table_4 = busy_table[4];
    wire                  debug_busy_table_5 = busy_table[5];
    wire                  debug_busy_table_6 = busy_table[6];
    wire                  debug_busy_table_7 = busy_table[7];
    wire                  debug_busy_table_8 = busy_table[8];
    wire                  debug_busy_table_9 = busy_table[9];
    wire                  debug_busy_table_10 = busy_table[10];
    wire                  debug_busy_table_11 = busy_table[11];
    wire                  debug_busy_table_12 = busy_table[12];
    wire                  debug_busy_table_13 = busy_table[13];
    wire                  debug_busy_table_14 = busy_table[14];
    wire                  debug_busy_table_15 = busy_table[15];
    wire                  debug_busy_table_16 = busy_table[16];
    wire                  debug_busy_table_17 = busy_table[17];
    wire                  debug_busy_table_18 = busy_table[18];
    wire                  debug_busy_table_19 = busy_table[19];
    wire                  debug_busy_table_20 = busy_table[20];
    wire                  debug_busy_table_21 = busy_table[21];
    wire                  debug_busy_table_22 = busy_table[22];
    wire                  debug_busy_table_23 = busy_table[23];
    wire                  debug_busy_table_24 = busy_table[24];
    wire                  debug_busy_table_25 = busy_table[25];
    wire                  debug_busy_table_26 = busy_table[26];
    wire                  debug_busy_table_27 = busy_table[27];
    wire                  debug_busy_table_28 = busy_table[28];
    wire                  debug_busy_table_29 = busy_table[29];
    wire                  debug_busy_table_30 = busy_table[30];
    wire                  debug_busy_table_31 = busy_table[31];
    wire                  debug_busy_table_32 = busy_table[32];
    wire                  debug_busy_table_33 = busy_table[33];
    wire                  debug_busy_table_34 = busy_table[34];
    wire                  debug_busy_table_35 = busy_table[35];
    wire                  debug_busy_table_36 = busy_table[36];
    wire                  debug_busy_table_37 = busy_table[37];
    wire                  debug_busy_table_38 = busy_table[38];
    wire                  debug_busy_table_39 = busy_table[39];
    wire                  debug_busy_table_40 = busy_table[40];
    wire                  debug_busy_table_41 = busy_table[41];
    wire                  debug_busy_table_42 = busy_table[42];
    wire                  debug_busy_table_43 = busy_table[43];
    wire                  debug_busy_table_44 = busy_table[44];
    wire                  debug_busy_table_45 = busy_table[45];
    wire                  debug_busy_table_46 = busy_table[46];
    wire                  debug_busy_table_47 = busy_table[47];
    wire                  debug_busy_table_48 = busy_table[48];
    wire                  debug_busy_table_49 = busy_table[49];
    wire                  debug_busy_table_50 = busy_table[50];
    wire                  debug_busy_table_51 = busy_table[51];
    wire                  debug_busy_table_52 = busy_table[52];
    wire                  debug_busy_table_53 = busy_table[53];
    wire                  debug_busy_table_54 = busy_table[54];
    wire                  debug_busy_table_55 = busy_table[55];
    wire                  debug_busy_table_56 = busy_table[56];
    wire                  debug_busy_table_57 = busy_table[57];
    wire                  debug_busy_table_58 = busy_table[58];
    wire                  debug_busy_table_59 = busy_table[59];
    wire                  debug_busy_table_60 = busy_table[60];
    wire                  debug_busy_table_61 = busy_table[61];
    wire                  debug_busy_table_62 = busy_table[62];
    wire                  debug_busy_table_63 = busy_table[63];


    //when overwrite ,clear all the busy
    always @(negedge reset_n or posedge clock) begin
        integer i;
        if (!reset_n | is_rollback) begin
            for (i = 0; i < `PREG_SIZE; i = i + 1) begin
                busy_table[i] <= 1'b0;  //means all ready
            end
        end else begin

            if (disp2bt_alloc_instr0_rd_en) begin
                busy_table[disp2bt_alloc_instr0_rd] <= 1'b1;
            end
            if (disp2bt_alloc_instr1_rd_en) begin
                busy_table[disp2bt_alloc_instr1_rd] <= 1'b1;
            end


            if (rob_walk0_valid & ~rob_walk0_complete) begin
                busy_table[rob_walk0_prd] <= 1'b1;
            end

            if (rob_walk1_valid & ~rob_walk1_complete) begin
                busy_table[rob_walk1_prd] <= 1'b1;
            end
            //TODO:could free at walk state,if free addr hit walk addr,how could this can taken??
            if (intwb02bt_free_instr0_rd_en) begin
                busy_table[intwb02bt_free_instr0_rd] <= 1'b0;
            end
            if (memwb2bt_free_instr0_rd_en) begin
                busy_table[memwb2bt_free_instr0_rd] <= 1'b0;
            end
        end
    end


    always @(*) begin
        if (intwb02bt_free_instr0_rd_en & (intwb02bt_free_instr0_rd == disp2bt_instr0_rs1)) begin
            bt2disp_instr0_src1_busy = 'b0;  //bypass logic
        end else if (memwb2bt_free_instr0_rd_en & (memwb2bt_free_instr0_rd == disp2bt_instr0_rs1)) begin
            bt2disp_instr0_src1_busy = 'b0;  //bypass logic
        end else begin
            bt2disp_instr0_src1_busy = busy_table[disp2bt_instr0_rs1] & disp2bt_instr0_src1_is_reg;
        end
    end
    always @(*) begin
        if (intwb02bt_free_instr0_rd_en & (intwb02bt_free_instr0_rd == disp2bt_instr0_rs2)) begin
            bt2disp_instr0_src2_busy = 'b0;  //bypass logic
        end else if (memwb2bt_free_instr0_rd_en & (memwb2bt_free_instr0_rd == disp2bt_instr0_rs2)) begin
            bt2disp_instr0_src2_busy = 'b0;  //bypass logic
        end else begin
            bt2disp_instr0_src2_busy = busy_table[disp2bt_instr0_rs2] & disp2bt_instr0_src2_is_reg;
        end
    end
    always @(*) begin
        if (intwb02bt_free_instr0_rd_en & (intwb02bt_free_instr0_rd == disp2bt_instr1_rs1)) begin
            bt2disp_instr1_src1_busy = 'b0;  //bypass logic
        end else if (memwb2bt_free_instr0_rd_en & (memwb2bt_free_instr0_rd == disp2bt_instr1_rs1)) begin
            bt2disp_instr1_src1_busy = 'b0;  //bypass logic
        end else begin
            bt2disp_instr1_src1_busy = busy_table[disp2bt_instr1_rs1] & disp2bt_instr1_src1_is_reg;
        end
    end
    always @(*) begin
        if (intwb02bt_free_instr0_rd_en & (intwb02bt_free_instr0_rd == disp2bt_instr1_rs2)) begin
            bt2disp_instr1_src2_busy = 'b0;  //bypass logic
        end else if (memwb2bt_free_instr0_rd_en & (memwb2bt_free_instr0_rd == disp2bt_instr1_rs2)) begin
            bt2disp_instr1_src2_busy = 'b0;  //bypass logic
        end else begin
            bt2disp_instr1_src2_busy = busy_table[disp2bt_instr1_rs2] & disp2bt_instr1_src2_is_reg;
        end
    end


endmodule
