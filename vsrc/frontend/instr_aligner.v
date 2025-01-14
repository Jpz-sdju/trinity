module instr_aligner (
    input  wire        pc_operation_done,
    input  wire [`ICACHE_FETCHWIDTH128_RANGE] fetch_instr,         // 128-bit cache line input (4 instructions)
    input  wire [63:0] pc,                  // 63-bit Program Counter  
    output reg  [`ICACHE_FETCHWIDTH128_RANGE] aligned_instr,       // Output cache line after processing
    output reg  [ 3:0] aligned_instr_valid // indicate instr valid
);
    always @* begin
        aligned_instr       = 'b0;
        aligned_instr_valid = 'b0;
        if (pc_operation_done) begin
            if (pc[3:2] == 2'b01) begin
                // Shift cache line to discard the lowest 32 bits (shift by 32 bits)
                aligned_instr       = {32'b0, fetch_instr[127:32]};
                aligned_instr_valid = {4'b0111};
            end else if (pc[3:2] == 2'b10) begin
                aligned_instr       = {64'b0, fetch_instr[127:64]};
                aligned_instr_valid = {4'b0011};
            end else if (pc[3:2] == 2'b11) begin
                aligned_instr       = {96'b0, fetch_instr[127:96]};
                aligned_instr_valid = {4'b0001};
            end else begin // (pc[3:2] == 2'b00), get all instr
                aligned_instr       = fetch_instr;
                aligned_instr_valid = {4'b1111};
            end
        end
    end
endmodule
