
module hazardchecker (
    // Instruction 0 Inputs
    input  [4:0] instr0_lrs1,
    input        instr0_lrs1_valid,
    input  [4:0] instr0_lrs2,
    input        instr0_lrs2_valid,
    input  [4:0] instr0_lrd,
    input        instr0_lrd_valid,
    
    // Instruction 1 Inputs
    input  [4:0] instr1_lrs1,
    input        instr1_lrs1_valid,
    input  [4:0] instr1_lrs2,
    input        instr1_lrs2_valid,
    input  [4:0] instr1_lrd,
    input        instr1_lrd_valid,
    
    // Hazard Outputs
    output       raw_hazard_rs1,
    output       raw_hazard_rs2,
    output       waw_hazard
);

// RAW Hazard Detection for rs1
// A RAW hazard occurs if Instruction 1's rs1 reads a register that Instruction 0 writes to.
assign raw_hazard_rs1 = instr0_lrd_valid && instr1_lrs1_valid && 
                        (instr0_lrd == instr1_lrs1) && (instr0_lrd != 5'd0);

// RAW Hazard Detection for rs2
// A RAW hazard occurs if Instruction 1's rs2 reads a register that Instruction 0 writes to.
assign raw_hazard_rs2 = instr0_lrd_valid && instr1_lrs2_valid && 
                        (instr0_lrd == instr1_lrs2) && (instr0_lrd != 5'd0);

// WAW Hazard Detection
// A WAW hazard occurs if both Instruction 0 and Instruction 1 write to the same register.
assign waw_hazard = instr0_lrd_valid && instr1_lrd_valid &&
                   (instr0_lrd == instr1_lrd) && (instr0_lrd != 5'd0);

endmodule
