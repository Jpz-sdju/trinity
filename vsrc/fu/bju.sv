`include "defines.sv"
module bju (
    input wire [    `SRC_RANGE] src1,
    input wire [    `SRC_RANGE] src2,
    input wire [`SRC_RANGE] offset,
    input wire [     `PC_RANGE] pc,
    input wire [`CX_TYPE_RANGE] cx_type,
    input wire valid,

    output wire [`RESULT_RANGE] dest,
    output wire redirect_valid,
    output wire [`PC_RANGE] redirect_target
);
    /*
    0 = JAL
    1 = JALR
    2 = BEQ
    3 = BNE
    4 = BLT
    5 = BGE
    6 = BLTU
    7 = BGEU
*/
    wire is_jal = cx_type[0]; 
    wire is_jalr = cx_type[1]; 
    wire is_beq = cx_type[2]; 
    wire is_bne = cx_type[3]; 
    wire is_blt = cx_type[4]; 
    wire is_bgt = cx_type[5]; 
    wire is_bltu = cx_type[6]; 
    wire is_bgeu = cx_type[7]; 

    wire equal = (src1 == src2);
    wire not_equal = ~equal;
    reg less_than ;
    wire greater_equal = ~equal & ~less_than;
    wire less_than_u = src1 < src2;
    wire greater_equal_u = ~eqaul & ~less_than_u;
    always @(*) begin
        case(src1[`SRC_WIDTH-1], src2[`SRC_WIDTH-1]) 
            2'b00: less_than = src1[`SRC_WIDTH-2:0 ] < src2[`SRC_WIDTH-2:0 ];
            2'b01: less_than = 1'b0;
            2'b10: less_than = 1'b1;
            2'b11: less_than = src1[`SRC_WIDTH-2:0 ] < src2[`SRC_WIDTH-2:0 ];
        endcase
    end

    wire br_taken = is_beq & equal | 
                    is_bne & not_equal |
                    is_blt & less_than |
                    is_bge & greater_equal |
                    is_bltu & less_than_u |
                    is_bgeu & greater_equal_u;

    wire [`PC_RANGE] br_jal_target = pc + offset;
    wire [`PC_RANGE] jalr_target = src1 + offset;


    assign redirect_valid = (is_jal | is_jalr | br_taken) & valid;
    assign redirect_target = is_jalr ? jalr_target : br_jal_target;
    assign dest = {16'b0, (pc + 48'h4)};
endmodule
