module pc_ctrl (
    input wire clk,                          // Clock signal
    input wire reset,                        // Reset signal
    input wire [47:0] interrupt_addr,        // 48-bit interrupt address
    input wire interrupt_valid,              // 1-bit interrupt valid signal
    output reg [18:0] pcctrl2ddr_index       // Lower 19 bits of the PC
);

    reg [47:0] boot_addr;                    // Internal 48-bit boot address, default 0
    reg [31:0] pc;                           // 32-bit Program Counter

    // Initialize boot_addr to 0 (can be set to other values later if needed)
    initial begin
        boot_addr = 48'b0;                   // Default boot address is 0
    end

    // Select the appropriate address based on interrupt_valid
    wire [47:0] addr_select = interrupt_valid ? interrupt_addr : boot_addr;

    // PC is set to bits [34:3] of the selected address (either boot_addr or interrupt_addr)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;                     // Reset PC to 0 on reset
        end else begin
            pc <= addr_select[34:3];         // Assign bits [34:3] of the selected address to PC
        end
    end

    // Output the lower 19 bits of the PC as pcctrl2ddr_index
    always @(pc) begin
        pcctrl2ddr_index = pc[18:0];
    end

endmodule
