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
    input [`PREG_RANGE] free_addr1
);


    reg [`PREG_SIZE-1:0] busy_table;

    always @(negedge reset_n or posedge clock) begin
        integer i;
        if (!reset_n) begin
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
