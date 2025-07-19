
// dcache_tagarray Module
module cache_tagarray #(parameter DATA_WIDTH = 38,  // Width of data
                       parameter ADDR_WIDTH = 9   // Width of address bus (512 sets => 9 bits)
                      ) (
    input wire clock,                                 // Clock signal
    input wire reset_n,                             // Active low reset
    input wire we,                                  // Write enable
    input wire ce,                                  // Chip enable
    input wire [ADDR_WIDTH-1:0] waddr,              // Write address input
    input wire [ADDR_WIDTH-1:0] raddr,              // Read address input
    input wire [DATA_WIDTH-1:0] din,                // Data input
    input wire [DATA_WIDTH-1:0] wmask,              // Write mask
    output wire [DATA_WIDTH-1:0] dout               // Data output
);

    // Instantiate a single SRAM for the dcache_tagarray
    sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) sram_inst_2ways (
        .clock(clock),
        .reset_n(reset_n),  
        .ce(ce),
        .we(we),
        .waddr(waddr),
        .raddr(raddr),
        .din(din),
        .wmask(wmask),
        .dout(dout)
    );

endmodule