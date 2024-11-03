`include "defines.sv"
module decoder (
    input wire        clock,
    input wire        reset_n,
    input wire        fifo_empty,
    input wire [31:0] ibuffer_inst_out,
    input wire [47:0] ibuffer_pc_out,

    //to regfile read 
    output reg [ 4:0] rs1,
    output reg [ 4:0] rs2,
    input      [63:0] rs1_read_data,
    input      [63:0] rs2_read_data,

    output reg  [ 4:0] rd,
    output reg  [63:0] src1,
    output reg  [63:0] src2,
    output reg  [63:0] imm,
    output reg         src1_is_reg,
    output reg         src2_is_reg,
    output reg         need_to_wb,
    output reg  [ 5:0] cx_type,
    output reg         is_unsigned,
    output reg  [ 9:0] alu_type,
    output reg         is_word,
    output reg         is_imm,
    output reg         is_load,
    output reg         is_store,
    output reg  [ 3:0] ls_size,
    output reg  [12:0] muldiv_type,
    output wire [47:0] decoder_pc_out,
    output wire [47:0] decoder_inst_out

);
    assign decoder_pc_out   = ibuffer_pc_out;
    assign decoder_inst_out = ibuffer_inst_out;

    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    localparam OPCODE_LUI = 7'b0110111;
    localparam OPCODE_AUIPC = 7'b0010111;
    localparam OPCODE_JAL = 7'b1101111;
    localparam OPCODE_JALR = 7'b1100111;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;
    localparam OPCODE_ALU_ITYPE = 7'b0010011;
    localparam OPCODE_ALU_RTYPE = 7'b0110011;
    localparam OPCODE_FENCE = 7'b0001111;
    localparam OPCODE_ENV = 7'b1110011;
    localparam OPCODE_ALU_ITYPE_WORD = 7'b0011011;
    localparam OPCODE_ALU_RTYPE_WORD = 7'b0111011;

    reg [11:0] imm_itype;
    reg [11:0] imm_stype;
    reg [12:0] imm_btype;
    reg [19:0] imm_utype;
    reg [20:0] imm_jtype;
    reg [63:0] imm_itype_64_s;
    reg [63:0] imm_itype_64_u;
    reg [63:0] imm_stype_64;
    reg [63:0] imm_btype_64_s;
    reg [63:0] imm_btype_64_u;
    reg [63:0] imm_utype_64;
    reg [63:0] imm_jtype_64;


    always @(*) begin
        if (!fifo_empty) begin
            imm_itype        = ibuffer_inst_out[31:20];
            imm_stype        = {ibuffer_inst_out[31:25], ibuffer_inst_out[11:7]};

            imm_btype[11]    = ibuffer_inst_out[7];
            imm_btype[4:1]   = ibuffer_inst_out[11:8];
            imm_btype[10:5]  = ibuffer_inst_out[30:25];
            imm_btype[12]    = ibuffer_inst_out[31];
            imm_btype[0]     = 1'b0;

            imm_utype        = ibuffer_inst_out[31:12];

            imm_jtype[19:12] = ibuffer_inst_out[19:12];
            imm_jtype[11]    = ibuffer_inst_out[20];
            imm_jtype[10:1]  = ibuffer_inst_out[30:21];
            imm_jtype[20]    = ibuffer_inst_out[31];
            imm_jtype[0]     = 1'b0;

            imm_itype_64_s   = {{52{imm_itype[11]}}, imm_itype};
            imm_itype_64_u   = {52'd0, imm_itype};
            imm_stype_64     = {{52{imm_stype[11]}}, imm_stype};
            imm_btype_64_s   = {{51{imm_btype[12]}}, imm_btype};
            imm_btype_64_u   = {51'b0, imm_btype};
            imm_utype_64     = {{32{imm_utype[19]}}, imm_utype, 12'b0};
            imm_jtype_64     = {{43{imm_jtype[20]}}, imm_jtype};


            rs1              = ibuffer_inst_out[19:15];
            rs2              = ibuffer_inst_out[24:20];
            rd               = ibuffer_inst_out[11:7];
            src1             = 64'b0;
            src2             = 64'b0;
            src1_is_reg      = 1'b0;
            src2_is_reg      = 1'b0;
            need_to_wb       = 1'b0;
            cx_type          = 6'b0;
            is_unsigned      = 1'b0;
            alu_type         = 10'b0;
            is_word          = 1'b0;
            is_imm           = 1'b0;
            is_load          = 1'b0;
            is_store         = 1'b0;
            ls_size          = 4'b0;
            muldiv_type      = 12'b0;

            src1             = rs1_read_data;
            src2             = rs2_read_data;

            opcode           = ibuffer_inst_out[6:0];
            funct3           = ibuffer_inst_out[14:12];
            funct7           = ibuffer_inst_out[31:25];
            case (opcode)
                OPCODE_LUI: begin
                    imm        = imm_utype_64;
                    alu_type   = `IS_LUI;
                    need_to_wb = 1'b1;
                end
                OPCODE_AUIPC: begin
                    imm        = imm_utype_64;
                    alu_type   = `IS_AUIPC;
                    need_to_wb = 1'b1;
                end
                OPCODE_JAL: begin
                    imm        = imm_jtype_64;
                    cx_type    = `IS_JAL;
                    need_to_wb = 1'b1;
                end
                OPCODE_JALR: begin
                    imm        = imm_itype_64_s;
                    cx_type    = `IS_JALR;
                    need_to_wb = 1'b1;
                end
                OPCODE_BRANCH: begin
                    case (funct3)
                        3'b000: begin
                            imm     = imm_btype_64_s;
                            cx_type = `IS_BEQ;
                        end
                        3'b001: begin
                            imm     = imm_btype_64_s;
                            cx_type = `IS_BNE;
                        end
                        3'b100: begin
                            imm     = imm_btype_64_s;
                            cx_type = `IS_BLT;
                        end
                        3'b101: begin
                            imm     = imm_btype_64_s;
                            cx_type = `IS_BGE;
                        end
                        3'b110: begin
                            imm         = imm_btype_64_u;
                            cx_type     = `IS_BLT;
                            is_unsigned = 1'b1;
                        end
                        3'b111: begin
                            imm         = imm_btype_64_u;
                            cx_type     = `IS_BGE;
                            is_unsigned = 1'b1;
                        end
                        default: ;
                    endcase
                end
                OPCODE_LOAD: begin
                    is_load    = 1'b1;
                    need_to_wb = 1'b1;
                    case (funct3)
                        3'b000: begin
                            imm     = imm_itype_64_s;
                            ls_size = `IS_B;
                        end
                        3'b001: begin
                            imm     = imm_itype_64_s;
                            ls_size = `IS_H;
                        end
                        3'b010: begin
                            imm     = imm_itype_64_s;
                            ls_size = `IS_W;
                        end
                        3'b011: begin  // RV64I extension
                            imm     = imm_itype_64_s;
                            ls_size = `IS_D;
                        end
                        3'b100: begin
                            imm         = imm_itype_64_u;
                            ls_size     = `IS_B;
                            is_unsigned = 1'b1;
                        end
                        3'b101: begin
                            imm         = imm_itype_64_u;
                            ls_size     = `IS_H;
                            is_unsigned = 1'b1;
                        end
                        3'b110: begin  // RV64I extension
                            imm         = imm_itype_64_s;
                            is_unsigned = 1'b1;
                            ls_size     = `IS_W;
                        end
                        default: ;
                    endcase
                end
                OPCODE_STORE: begin
                    is_store = 1'b1;
                    imm      = imm_stype_64;
                    case (funct3)
                        3'b000: begin
                            ls_size = `IS_B;
                        end
                        3'b001: begin
                            ls_size = `IS_H;
                        end
                        3'b010: begin
                            ls_size = `IS_W;
                        end
                        3'b011: begin  // RV64I extension
                            ls_size = `IS_D;
                        end
                        default: ;
                    endcase
                end
                OPCODE_ALU_ITYPE: begin
                    imm        = imm_itype_64_s;
                    need_to_wb = 1'b1;
                    case ({
                        funct7, funct3
                    })
                        10'b??????000: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_ADD;
                        end
                        10'b??????010: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SLT;
                        end
                        10'b??????011: begin
                            is_imm      = 1'b1;
                            is_unsigned = 1'b1;
                            alu_type    = `IS_SLT;
                        end
                        10'b??????100: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_XOR;
                        end
                        10'b??????110: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_OR;
                        end
                        10'b??????111: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_AND;
                        end
                        10'b0000000001: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SLL;
                        end
                        10'b0000000101: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SRL;
                        end
                        10'b0100000101: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SRA;
                        end
                        default: ;
                    endcase
                end
                OPCODE_ALU_RTYPE: begin
                    need_to_wb = 1'b1;
                    case ({
                        funct7, funct3
                    })
                        10'b0000000000: begin
                            alu_type = `IS_ADD;
                        end
                        10'b0100000000: begin
                            alu_type = `IS_SUB;
                        end
                        10'b0000000001: begin
                            alu_type = `IS_SLL;
                        end
                        10'b0000000010: begin
                            alu_type = `IS_SLT;
                        end
                        10'b0000000011: begin
                            is_unsigned = 1'b1;
                            alu_type    = `IS_SLT;
                        end
                        10'b0000000100: begin
                            alu_type = `IS_XOR;
                        end
                        10'b0000000101: begin
                            alu_type = `IS_SRL;
                        end
                        10'b0100000101: begin
                            alu_type = `IS_SRA;
                        end
                        10'b0000000110: begin
                            alu_type = `IS_OR;
                        end
                        10'b0000000111: begin
                            alu_type = `IS_AND;
                        end
                        10'b0000001000: begin
                            muldiv_type = `IS_MUL;
                        end
                        10'b0000001001: begin
                            muldiv_type = `IS_MULH;
                        end
                        10'b0000001010: begin
                            muldiv_type = `IS_MULHSU;
                        end
                        10'b0000001011: begin
                            muldiv_type = `IS_MULHU;
                        end
                        10'b0000001100: begin
                            muldiv_type = `IS_DIV;
                        end
                        10'b0000001101: begin
                            muldiv_type = `IS_DIVU;
                        end
                        10'b0000001110: begin
                            muldiv_type = `IS_REM;
                        end
                        10'b0000001111: begin
                            muldiv_type = `IS_REMU;
                        end
                        default: ;
                    endcase
                end
                OPCODE_FENCE: begin
                    // Add your implementation here
                end
                OPCODE_ENV: begin
                    // Add your implementation here
                end
                OPCODE_ALU_ITYPE_WORD: begin
                    is_word    = 1'b1;
                    need_to_wb = 1'b1;
                    case ({
                        funct7, funct3
                    })
                        10'b??????000: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_ADD;
                        end
                        10'b0000000001: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SLL;
                        end
                        10'b0000000101: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SRL;
                        end
                        10'b0100000101: begin
                            is_imm   = 1'b1;
                            alu_type = `IS_SRA;
                        end
                        default: ;
                    endcase
                end
                OPCODE_ALU_RTYPE_WORD: begin
                    is_word    = 1'b1;
                    need_to_wb = 1'b1;
                    case ({
                        funct7, funct3
                    })
                        10'b0000000000: begin
                            alu_type = `IS_ADD;
                        end
                        10'b0100000000: begin
                            alu_type = `IS_SUB;
                        end
                        10'b0000000001: begin
                            alu_type = `IS_SLL;
                        end
                        10'b0000000101: begin
                            alu_type = `IS_SRL;
                        end
                        10'b0100000101: begin
                            alu_type = `IS_SRA;
                        end
                        10'b0000001000: begin
                            muldiv_type = `IS_MULW;
                        end
                        10'b0000001100: begin
                            muldiv_type = `IS_DIVW;
                        end
                        0000001101: muldiv_type = `IS_DIVUW;
                        0000001110: muldiv_type = `IS_REMW;
                        0000001111: muldiv_type = `IS_REMUW;
                        default: ;
                    endcase
                end
                default: ;
            endcase
        end
    end



endmodule