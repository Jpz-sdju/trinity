`include "defines.sv"
module regfile64 (
    input wire clock,
    input wire reset_n,

    input wire               read0_en,
    input wire               read1_en,
    input wire [`PREG_RANGE] read0_idx,  // Read register 1 address
    input wire [`PREG_RANGE] read1_idx,  // Read register 2 address

    output reg [63:0] read0_data,  // Data from read0_idx register
    output reg [63:0] read1_data,  // Data from read1_idx register

    input wire               write0_en,   // Write enable signal for write0_idx
    input wire [`PREG_RANGE] write0_idx,  // Write register address
    input wire [       63:0] write0_data, // Data to be written to write0_idx

    input wire               write1_en,   // Write enable signal for write1_idx
    input wire [`PREG_RANGE] write1_idx,  // Write register address
    input wire [       63:0] write1_data  // Data to be written to write1_idx
);

    reg     [63:0] registers[63:0];  // 64 registers, 64 bits each

    // Reset all registers to 0 (optional)
    integer        i;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end else begin
            if (write0_en && write0_idx != `PREG_LENGTH'b0) begin
                // Write to write0_idx only if write0_idx is not zero (x0 is always 0 in RISC-V)
                registers[write0_idx] <= write0_data;
            end
            if (write1_en && write1_idx != `PREG_LENGTH'b0) begin
                // Write to write0_idx only if write0_idx is not zero (x0 is always 0 in RISC-V)
                registers[write1_idx] <= write1_data;
            end
        end
    end
    /* verilator lint_off LATCH */
    // Combinational read logic with forwarding
    always @(*) begin
        if (read0_en) begin
            // Forward write0_data if write0_en is active and addresses match
            if (write0_en && write0_idx == read0_idx && write0_idx != `PREG_LENGTH'b0) begin
                read0_data = write0_data;
            end else if (write1_en && write1_idx == read0_idx && write1_idx != `PREG_LENGTH'b0) begin
                read0_data = write1_data;
            end else begin
                read0_data = registers[read0_idx];
            end
        end
    end
    // Combinational read logic with forwarding
    always @(*) begin
        if (read1_en) begin
            // Forward write0_data if write0_en is active and addresses match
            if (write0_en && write0_idx == read1_idx && write0_idx != `PREG_LENGTH'b0) begin
                read1_data = write0_data;
            end else if (write1_en && write1_idx == read1_idx && write1_idx != `PREG_LENGTH'b0) begin
                read1_data = write1_data;
            end else begin
                read1_data = registers[read1_idx];
            end
        end
    end
    /* verilator lint_off LATCH */
    DifftestArchIntRegState u_DifftestArchIntRegState (
        .clock      (clock),
        .enable     (1'b1),
        .io_value_0 (registers[0]),
        .io_value_1 (registers[1]),
        .io_value_2 (registers[2]),
        .io_value_3 (registers[3]),
        .io_value_4 (registers[4]),
        .io_value_5 (registers[5]),
        .io_value_6 (registers[6]),
        .io_value_7 (registers[7]),
        .io_value_8 (registers[8]),
        .io_value_9 (registers[9]),
        .io_value_10(registers[10]),
        .io_value_11(registers[11]),
        .io_value_12(registers[12]),
        .io_value_13(registers[13]),
        .io_value_14(registers[14]),
        .io_value_15(registers[15]),
        .io_value_16(registers[16]),
        .io_value_17(registers[17]),
        .io_value_18(registers[18]),
        .io_value_19(registers[19]),
        .io_value_20(registers[20]),
        .io_value_21(registers[21]),
        .io_value_22(registers[22]),
        .io_value_23(registers[23]),
        .io_value_24(registers[24]),
        .io_value_25(registers[25]),
        .io_value_26(registers[26]),
        .io_value_27(registers[27]),
        .io_value_28(registers[28]),
        .io_value_29(registers[29]),
        .io_value_30(registers[30]),
        .io_value_31(registers[31]),
        .io_coreid  ('b0)
    );

endmodule
