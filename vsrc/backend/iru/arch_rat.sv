
module arch_rat (
    input wire clock,
    input wire reset_n,
    
    // Commit Write Port 0
    input wire               commit0_valid,
    input wire               commit0_need_to_wb,
    input wire [`LREG_RANGE] commit0_lrd,
    input wire [`PREG_RANGE] commit0_prd,
    
    // Commit Write Port 1
    input wire               commit1_valid,
    input wire               commit1_need_to_wb,
    input wire [`LREG_RANGE] commit1_lrd,
    input wire [`PREG_RANGE] commit1_prd,
    
    // Debug Output Signals (32 Total)
    output wire [`PREG_RANGE] debug_preg0,
    output wire [`PREG_RANGE] debug_preg1,
    output wire [`PREG_RANGE] debug_preg2,
    output wire [`PREG_RANGE] debug_preg3,
    output wire [`PREG_RANGE] debug_preg4,
    output wire [`PREG_RANGE] debug_preg5,
    output wire [`PREG_RANGE] debug_preg6,
    output wire [`PREG_RANGE] debug_preg7,
    output wire [`PREG_RANGE] debug_preg8,
    output wire [`PREG_RANGE] debug_preg9,
    output wire [`PREG_RANGE] debug_preg10,
    output wire [`PREG_RANGE] debug_preg11,
    output wire [`PREG_RANGE] debug_preg12,
    output wire [`PREG_RANGE] debug_preg13,
    output wire [`PREG_RANGE] debug_preg14,
    output wire [`PREG_RANGE] debug_preg15,
    output wire [`PREG_RANGE] debug_preg16,
    output wire [`PREG_RANGE] debug_preg17,
    output wire [`PREG_RANGE] debug_preg18,
    output wire [`PREG_RANGE] debug_preg19,
    output wire [`PREG_RANGE] debug_preg20,
    output wire [`PREG_RANGE] debug_preg21,
    output wire [`PREG_RANGE] debug_preg22,
    output wire [`PREG_RANGE] debug_preg23,
    output wire [`PREG_RANGE] debug_preg24,
    output wire [`PREG_RANGE] debug_preg25,
    output wire [`PREG_RANGE] debug_preg26,
    output wire [`PREG_RANGE] debug_preg27,
    output wire [`PREG_RANGE] debug_preg28,
    output wire [`PREG_RANGE] debug_preg29,
    output wire [`PREG_RANGE] debug_preg30,
    output wire [`PREG_RANGE] debug_preg31
);

    // Parameters
    localparam LOGICAL_REG_WIDTH    = 5;
    localparam PHYSICAL_REG_WIDTH   = 6;
    localparam NUM_LOGICAL_REGS     = 32;
    localparam NUM_PHYSICAL_REGS    = 64;
    
    // Arch_RAT Register Array: Maps Logical Registers to Physical Registers
    reg [PHYSICAL_REG_WIDTH-1:0] arch_rat [0:NUM_LOGICAL_REGS-1]; // [5:0] reg [0:31]
    
    // Initialize Arch_RAT
    integer i;
    always @(posedge clock or posedge reset_n) begin
        if (~reset_n) begin
            for (i = 0; i < NUM_LOGICAL_REGS; i = i + 1) begin
                arch_rat[i] <= i; // Initial mapping: Logical Reg i maps to Physical Reg i
            end
        end
        else begin
            // Commit Write Port 0
            if (commit0_valid && commit0_need_to_wb) begin
                arch_rat[commit0_lrd] <= commit0_prd;
            end
            // Commit Write Port 1
            if (commit1_valid && commit1_need_to_wb) begin
                arch_rat[commit1_lrd] <= commit1_prd;
            end
        end
    end
    
    // Assign Debug Outputs
    assign debug_preg0  = arch_rat[0];
    assign debug_preg1  = arch_rat[1];
    assign debug_preg2  = arch_rat[2];
    assign debug_preg3  = arch_rat[3];
    assign debug_preg4  = arch_rat[4];
    assign debug_preg5  = arch_rat[5];
    assign debug_preg6  = arch_rat[6];
    assign debug_preg7  = arch_rat[7];
    assign debug_preg8  = arch_rat[8];
    assign debug_preg9  = arch_rat[9];
    assign debug_preg10 = arch_rat[10];
    assign debug_preg11 = arch_rat[11];
    assign debug_preg12 = arch_rat[12];
    assign debug_preg13 = arch_rat[13];
    assign debug_preg14 = arch_rat[14];
    assign debug_preg15 = arch_rat[15];
    assign debug_preg16 = arch_rat[16];
    assign debug_preg17 = arch_rat[17];
    assign debug_preg18 = arch_rat[18];
    assign debug_preg19 = arch_rat[19];
    assign debug_preg20 = arch_rat[20];
    assign debug_preg21 = arch_rat[21];
    assign debug_preg22 = arch_rat[22];
    assign debug_preg23 = arch_rat[23];
    assign debug_preg24 = arch_rat[24];
    assign debug_preg25 = arch_rat[25];
    assign debug_preg26 = arch_rat[26];
    assign debug_preg27 = arch_rat[27];
    assign debug_preg28 = arch_rat[28];
    assign debug_preg29 = arch_rat[29];
    assign debug_preg30 = arch_rat[30];
    assign debug_preg31 = arch_rat[31];
    
endmodule
