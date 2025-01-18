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

    reg [`PREG_SIZE-1:0] busy_table;

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

            if(rob_walk0_valid) begin
                busy_table[rob_walk0_prd] <= 1'b0;
            end

            if(rob_walk1_valid) begin
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
