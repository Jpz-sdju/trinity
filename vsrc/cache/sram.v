// sram Module Template in Verilog

module sram #(parameter DATA_WIDTH = 64,  // Width of data
              parameter ADDR_WIDTH = 9   // Width of address bus
             ) (
    input wire clock,                      // Clock signal
    input wire reset_n,                  // Active low reset
    input wire ce,                       // Chip enable
    input wire we,                       // Write enable
    input wire [ADDR_WIDTH-1:0] waddr,   // Write address input
    input wire [ADDR_WIDTH-1:0] raddr,   // Read address input
    input wire [DATA_WIDTH-1:0] din,     // Data input
    input wire [DATA_WIDTH-1:0] wmask,   // Write mask
    output reg [DATA_WIDTH-1:0] dout     // Data output
);

    // Declare the SRAM memory array
    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all memory to 0
            integer i;
            for (i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
                mem[i] <= 0;
            end
            dout <= 0;
        end else if (ce) begin
            if (we) begin
                // Write operation with write mask
                mem[waddr] <= (mem[waddr] & ~wmask) | (din & wmask);
            end
            // Read operation
            dout <= mem[raddr];
        end
    end

endmodule