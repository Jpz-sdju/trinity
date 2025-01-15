module regfile64 (
    input wire clock,
    input wire reset_n,
    input wire [4:0] rs1,               // Read register 1 address
    input wire [4:0] rs2,               // Read register 2 address
    input wire [4:0] rd,                // Write register address
    input wire [63:0] rd_write_data,          // Data to be written to rd
    input wire rd_write,               // Write enable signal for rd
    output reg [63:0] rs1_read_data,      // Data from rs1 register
    output reg [63:0] rs2_read_data       // Data from rs2 register
);

    reg [63:0] registers [31:0];        // 32 registers, 64 bits each

    // Reset all registers to 0 (optional)
    integer i;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end else if (rd_write && rd != 5'b0) begin
            // Write to rd only if rd is not zero (x0 is always 0 in RISC-V)
            registers[rd] <= rd_write_data;
        end
    end

    // Combinational read logic with forwarding
    always @(*) begin
        // Forward rd_write_data if rd_write is active and addresses match
        if (rd_write && rd == rs1 && rd != 5'b0) begin
            rs1_read_data = rd_write_data;
        end else begin
            rs1_read_data = registers[rs1];
        end
    end
    // Combinational read logic with forwarding
    always @(*) begin
        // Forward rd_write_data if rd_write is active and addresses match
        if (rd_write && rd == rs2 && rd != 5'b0) begin
            rs2_read_data = rd_write_data;
        end else begin
            rs2_read_data = registers[rs2];
        end
    end

    DifftestArchIntRegState u_DifftestArchIntRegState(
        .clock       (clock       ),
        .enable      (1'b1      ),
        .io_value_0  (registers[0]  ),
        .io_value_1  (registers[1]  ),
        .io_value_2  (registers[2]  ),
        .io_value_3  (registers[3]  ),
        .io_value_4  (registers[4]  ),
        .io_value_5  (registers[5]  ),
        .io_value_6  (registers[6]  ),
        .io_value_7  (registers[7]  ),
        .io_value_8  (registers[8]  ),
        .io_value_9  (registers[9]  ),
        .io_value_10 (registers[10] ),
        .io_value_11 (registers[11] ),
        .io_value_12 (registers[12] ),
        .io_value_13 (registers[13] ),
        .io_value_14 (registers[14] ),
        .io_value_15 (registers[15] ),
        .io_value_16 (registers[16] ),
        .io_value_17 (registers[17] ),
        .io_value_18 (registers[18] ),
        .io_value_19 (registers[19] ),
        .io_value_20 (registers[20] ),
        .io_value_21 (registers[21] ),
        .io_value_22 (registers[22] ),
        .io_value_23 (registers[23] ),
        .io_value_24 (registers[24] ),
        .io_value_25 (registers[25] ),
        .io_value_26 (registers[26] ),
        .io_value_27 (registers[27] ),
        .io_value_28 (registers[28] ),
        .io_value_29 (registers[29] ),
        .io_value_30 (registers[30] ),
        .io_value_31 (registers[31] ),
        .io_coreid   ('b0   )
    );
    
endmodule
