`include "defines.sv"
module busytable (
    input                    clock,
    input                    reset_n,
    // read
    input      [`PREG_RANGE] read_addr0,
    input      [`PREG_RANGE] read_addr1,
    input      [`PREG_RANGE] read_addr2,
    input      [`PREG_RANGE] read_addr3,
    output reg               busy_out0,
    output reg               busy_out1,
    output reg               busy_out2,
    output reg               busy_out3,

    // allocate
    input               alloc_en0,
    input [`PREG_RANGE] alloc_addr0,
    input               alloc_en1,
    input [`PREG_RANGE] alloc_addr1,

    // free
    input               free_en0,
    input [`PREG_RANGE] free_addr0,
    input               free_en1,
    input [`PREG_RANGE] free_addr1,

    /* ------------------------------- walk logic ------------------------------- */
    input wire [        1:0] rob_state,
    input wire               rob_walk0_valid,
    input wire [`LREG_RANGE] rob_walk0_lrd,
    input wire [`PREG_RANGE] rob_walk0_prd,
    input wire               rob_walk1_valid,
    input wire [`LREG_RANGE] rob_walk1_lrd,
    input wire [`PREG_RANGE] rob_walk1_prd
);

    wire is_idle;
    wire is_ovwr;
    wire is_walking;
    assign is_idle    = (rob_state == `ROB_STATE_IDLE);
    assign is_ovwr    = (rob_state == `ROB_STATE_OVERWRITE_RAT);
    assign is_walking = (rob_state == `ROB_STATE_WALKING);

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
        if (!reset_n | is_ovwr) begin
            for (i = 0; i < `PREG_SIZE; i = i + 1) begin
                busy_table[i] <= 1'b0;  //means all ready
            end
        end else begin

            if (alloc_en0) begin
                busy_table[alloc_addr0] <= 1'b1;
            end
            if (alloc_en1) begin
                busy_table[alloc_addr1] <= 1'b1;
            end

            if (free_en0) begin
                busy_table[free_addr0] <= 1'b0;
            end
            if (free_en1) begin
                busy_table[free_addr1] <= 1'b0;
            end

            if (rob_walk0_valid) begin
                busy_table[rob_walk0_prd] <= 1'b0;
            end

            if (rob_walk1_valid) begin
                busy_table[rob_walk1_prd] <= 1'b0;
            end
        end
    end


    always @(*) begin
        if (free_en0 & (free_addr0 == read_addr0)) begin
            busy_out0 = 'b0;  //bypass logic
        end else if (free_en1 & (free_addr1 == read_addr0)) begin
            busy_out0 = 'b0;  //bypass logic
        end else begin
            busy_out0 = busy_table[read_addr0];
        end
    end
    always @(*) begin
        if (free_en0 & (free_addr0 == read_addr1)) begin
            busy_out1 = 'b0;  //bypass logic
        end else if (free_en1 & (free_addr1 == read_addr1)) begin
            busy_out1 = 'b0;  //bypass logic
        end else begin
            busy_out1 = busy_table[read_addr1];
        end
    end
    always @(*) begin
        if (free_en0 & (free_addr0 == read_addr2)) begin
            busy_out2 = 'b0;  //bypass logic
        end else if (free_en1 & (free_addr1 == read_addr2)) begin
            busy_out2 = 'b0;  //bypass logic
        end else begin
            busy_out2 = busy_table[read_addr2];
        end
    end
    always @(*) begin
        if (free_en0 & (free_addr0 == read_addr3)) begin
            busy_out3 = 'b0;  //bypass logic
        end else if (free_en1 & (free_addr1 == read_addr3)) begin
            busy_out3 = 'b0;  //bypass logic
        end else begin
            busy_out3 = busy_table[read_addr3];
        end
    end

endmodule
