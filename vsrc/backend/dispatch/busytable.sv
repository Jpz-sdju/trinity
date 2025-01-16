`include "defines.sv"
module busytable #(
    parameter ENTRY_COUNT = 64
) (
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
    input [`PREG_RANGE] alloc_addr0,
    input               alloc_en0,
    input [`PREG_RANGE] alloc_addr1,
    input               alloc_en1,

    // free
    input [`PREG_RANGE] free_addr0,
    input               free_en0,
    input [`PREG_RANGE] free_addr1,
    input               free_en1
);


    reg [ENTRY_COUNT-1:0] busy_table;

    always @(negedge reset_n or posedge clock) begin
        integer i;
        if (!reset_n) begin
            for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
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
        end
    end


    always @(*) begin
        busy_out0 = busy_table[read_addr0];
        busy_out1 = busy_table[read_addr1];
        busy_out2 = busy_table[read_addr2];
        busy_out3 = busy_table[read_addr3];
    end

endmodule
