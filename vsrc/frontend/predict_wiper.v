module predict_wiper (
    input [511:0] selected_data,      // 16 32-bit instructions
    input [63:0] base_pc,          // Base program counter (64-bit)
    input [63:0] trigger_pc,       // Trigger program counter (64-bit)
    input predict_valid,           // Wipe enable signal
    output [511:0] predict_wiper_data     // Resultant instructions
);
    wire [3:0] trigger_index;      // Index of trigger instruction (0-15)
    wire [15:0] mask;              // 16-bit mask
    genvar i;

    // Calculate the trigger index
    assign trigger_index = (trigger_pc - base_pc) >> 2;

    // Generate mask: all 1's if predict_valid is 0; else 1's up to trigger_index
    assign mask = predict_valid ? (16'hFFFF << (16 - trigger_index)) : 16'hFFFF;

    // Apply mask to each instruction
    generate
        for (i = 0; i < 16; i = i + 1) begin : wipe_logic
            assign predict_wiper_data[i * 32 +: 32] = selected_data[i * 32 +: 32] & {32{mask[i]}};
        end
    endgenerate




endmodule
