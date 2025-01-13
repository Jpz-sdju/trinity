module instr_aligner (
    input  wire        pc_operation_done,
    input  wire [63:0] fetch_instr,         // 512-bit cache line input (16 instructions)
    input  wire [63:0] pc,                  // 63-bit Program Counter  
    output reg  [63:0] aligned_instr,       // Output cache line after processing
    output reg  [ 1:0] aligned_instr_valid // indicate instr valid
);
    always @* begin
        aligned_instr       = 'b0;
        aligned_instr_valid = 'b0;
        if (pc_operation_done) begin
            if (pc[2] == 1'b1) begin
                // Shift cache line to discard the lowest 32 bits (shift by 32 bits)
                aligned_instr       = {32'b0, fetch_instr[63:32]};
                aligned_instr_valid = {1'b0, 1'b1};
            end else begin
                aligned_instr       = fetch_instr;
                aligned_instr_valid = {1'b1, 1'b1};
            end
        end
    end
endmodule
