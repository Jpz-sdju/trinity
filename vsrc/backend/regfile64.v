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
    input wire [       63:0] write1_data, // Data to be written to write1_idx

    //debug
    input wire [`PREG_RANGE] debug_preg0,
    input wire [`PREG_RANGE] debug_preg1,
    input wire [`PREG_RANGE] debug_preg2,
    input wire [`PREG_RANGE] debug_preg3,
    input wire [`PREG_RANGE] debug_preg4,
    input wire [`PREG_RANGE] debug_preg5,
    input wire [`PREG_RANGE] debug_preg6,
    input wire [`PREG_RANGE] debug_preg7,
    input wire [`PREG_RANGE] debug_preg8,
    input wire [`PREG_RANGE] debug_preg9,
    input wire [`PREG_RANGE] debug_preg10,
    input wire [`PREG_RANGE] debug_preg11,
    input wire [`PREG_RANGE] debug_preg12,
    input wire [`PREG_RANGE] debug_preg13,
    input wire [`PREG_RANGE] debug_preg14,
    input wire [`PREG_RANGE] debug_preg15,
    input wire [`PREG_RANGE] debug_preg16,
    input wire [`PREG_RANGE] debug_preg17,
    input wire [`PREG_RANGE] debug_preg18,
    input wire [`PREG_RANGE] debug_preg19,
    input wire [`PREG_RANGE] debug_preg20,
    input wire [`PREG_RANGE] debug_preg21,
    input wire [`PREG_RANGE] debug_preg22,
    input wire [`PREG_RANGE] debug_preg23,
    input wire [`PREG_RANGE] debug_preg24,
    input wire [`PREG_RANGE] debug_preg25,
    input wire [`PREG_RANGE] debug_preg26,
    input wire [`PREG_RANGE] debug_preg27,
    input wire [`PREG_RANGE] debug_preg28,
    input wire [`PREG_RANGE] debug_preg29,
    input wire [`PREG_RANGE] debug_preg30,
    input wire [`PREG_RANGE] debug_preg31
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
            if (write0_en && (write0_idx != `PREG_LENGTH'b0)) begin
                // Write to write0_idx only if write0_idx is not zero (x0 is always 0 in RISC-V)
                registers[write0_idx] <= write0_data;
            end
            if (write1_en && (write1_idx != `PREG_LENGTH'b0)) begin
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
            if (write0_en && (write0_idx == read0_idx) && (write0_idx != `PREG_LENGTH'b0)) begin
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
            if (write0_en && (write0_idx == read1_idx) && (write0_idx != `PREG_LENGTH'b0)) begin
                read1_data = write0_data;
            end else if (write1_en && (write1_idx == read1_idx) && (write1_idx != `PREG_LENGTH'b0)) begin
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
        .io_value_0 (registers[debug_preg0]),
        .io_value_1 (registers[debug_preg1]),
        .io_value_2 (registers[debug_preg2]),
        .io_value_3 (registers[debug_preg3]),
        .io_value_4 (registers[debug_preg4]),
        .io_value_5 (registers[debug_preg5]),
        .io_value_6 (registers[debug_preg6]),
        .io_value_7 (registers[debug_preg7]),
        .io_value_8 (registers[debug_preg8]),
        .io_value_9 (registers[debug_preg9]),
        .io_value_10(registers[debug_preg10]),
        .io_value_11(registers[debug_preg11]),
        .io_value_12(registers[debug_preg12]),
        .io_value_13(registers[debug_preg13]),
        .io_value_14(registers[debug_preg14]),
        .io_value_15(registers[debug_preg15]),
        .io_value_16(registers[debug_preg16]),
        .io_value_17(registers[debug_preg17]),
        .io_value_18(registers[debug_preg18]),
        .io_value_19(registers[debug_preg19]),
        .io_value_20(registers[debug_preg20]),
        .io_value_21(registers[debug_preg21]),
        .io_value_22(registers[debug_preg22]),
        .io_value_23(registers[debug_preg23]),
        .io_value_24(registers[debug_preg24]),
        .io_value_25(registers[debug_preg25]),
        .io_value_26(registers[debug_preg26]),
        .io_value_27(registers[debug_preg27]),
        .io_value_28(registers[debug_preg28]),
        .io_value_29(registers[debug_preg29]),
        .io_value_30(registers[debug_preg30]),
        .io_value_31(registers[debug_preg31]),
        .io_coreid  ('b0)
    );

endmodule
