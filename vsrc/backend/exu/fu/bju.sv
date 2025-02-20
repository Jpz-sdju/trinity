`include "defines.sv"
module bju #(
    parameter BHTBTB_INDEX_WIDTH = 9  // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
) (
    input wire clock,   //only for pmu logic
    input wire reset_n, //only for pmu logic

    input wire [    `SRC_RANGE] src1,
    input wire [    `SRC_RANGE] src2,
    input wire [    `SRC_RANGE] imm,
    input wire                  predict_taken,
    input wire [          31:0] predict_target,
    input wire [     `PC_RANGE] pc,
    input wire [`CX_TYPE_RANGE] cx_type,
    input wire                  valid,
    input wire                  is_unsigned,

    output reg [`RESULT_RANGE] dest,
    output reg                 redirect_valid,
    output reg [    `PC_RANGE] redirect_target,

    //BHT Write Interface
    output reg                          bjusb_bht_write_enable,          // Write enable signal
    output reg [BHTBTB_INDEX_WIDTH-1:0] bjusb_bht_write_index,           // Set index for write operation
    output reg [                   1:0] bjusb_bht_write_counter_select,  // Counter select (0 to 3) within the set
    output reg                          bjusb_bht_write_inc,             // Increment signal for the counter
    output reg                          bjusb_bht_write_dec,             // Decrement signal for the counter
    output reg                          bjusb_bht_valid_in,              // Valid signal for the write operation

    //BTB Write Interface
    output reg         bjusb_btb_ce,            // Chip enable
    output reg         bjusb_btb_we,            // Write enable
    output reg [128:0] bjusb_btb_wmask,
    output reg [  8:0] bjusb_btb_write_index,   // Write address (9 bits for 512 sets)
    output reg [128:0] bjusb_btb_din,           // Data input (1 valid bit + 4 targets * 32 bits)
    output reg [ 31:0] bju_pmu_situation1_cnt_btype,  //b-type
    output reg [ 31:0] bju_pmu_situation2_cnt_btype,
    output reg [ 31:0] bju_pmu_situation3_cnt_btype,
    output reg [ 31:0] bju_pmu_situation4_cnt_btype,
    output reg [ 31:0] bju_pmu_situation5_cnt_btype,
    output reg [ 31:0] bju_pmu_situation1_cnt_jtype, //j-type
    output reg [ 31:0] bju_pmu_situation2_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation3_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation4_cnt_jtype,
    output reg [ 31:0] bju_pmu_situation5_cnt_jtype

);
    /* --------------------- bju calculation logic (bjucal) --------------------- */
    /*
    0 = JAL
    1 = JALR
    2 = BEQ
    3 = BNE
    4 = BLT
    5 = BGE
*/
    wire is_jal = cx_type[0];
    wire is_jalr = cx_type[1];
    wire is_beq = cx_type[2] & ~is_unsigned;
    wire is_bne = cx_type[3] & ~is_unsigned;
    wire is_blt = cx_type[4] & ~is_unsigned;
    wire is_bge = cx_type[5] & ~is_unsigned;
    wire is_bltu = cx_type[4] & is_unsigned;
    wire is_bgeu = cx_type[5] & is_unsigned;

    wire equal = (src1 == src2);
    wire not_equal = ~equal;
    reg  less_than;
    wire greater_equal = ~equal & ~less_than | equal;
    wire less_than_u = src1 < src2;
    wire greater_equal_u = ~equal & ~less_than_u | equal;
    always @(*) begin
        case ({
            src1[`SRC_LENGTH-1], src2[`SRC_LENGTH-1]
        })
            2'b00: less_than = src1[`SRC_LENGTH-2:0] < src2[`SRC_LENGTH-2:0];
            2'b01: less_than = 1'b0;
            2'b10: less_than = 1'b1;
            2'b11: less_than = src1[`SRC_LENGTH-2:0] < src2[`SRC_LENGTH-2:0];
        endcase
    end

    wire                 br_taken = is_beq & equal | is_bne & not_equal | is_blt & less_than | is_bge & greater_equal | is_bltu & less_than_u | is_bgeu & greater_equal_u;

    wire [    `PC_RANGE] br_jal_target = pc + imm;
    wire [    `PC_RANGE] jalr_target = src1 + imm;

    wire                 bjucal_redirect_valid;
    wire [    `PC_RANGE] bjucal_redirect_target;
    wire [`RESULT_RANGE] bjucal_dest;


    assign bjucal_redirect_valid  = (is_jal | is_jalr | br_taken) & valid;
    assign bjucal_redirect_target = is_jalr ? jalr_target : br_jal_target;
    assign bjucal_dest            = (pc + 'h4);
    assign dest                   = bjucal_dest;

    /* ----------------------------bju scoreboard logic (bjusb) ---------------------------- */
    wire bjusb_bju_taken_bpu_taken_right;  //bju_pmu_situation1
    wire bjusb_bju_taken_bpu_taken_butaddrwrong;  //bju_pmu_situation2
    wire bjusb_bju_taken_bpu_nottaken_wrong;  //bju_pmu_situation3
    wire bjusb_bju_nottaken_bpu_taken_wrong;  //bju_pmu_situation4
    wire bjusb_bju_nottaken_bpu_nottaken_right;  //bju_pmu_situation5

    assign bjusb_bju_taken_bpu_taken_right        = valid && (bjucal_redirect_valid && predict_taken) && (bjucal_redirect_target[31:0] == predict_target);

    assign bjusb_bju_taken_bpu_taken_butaddrwrong = valid && (bjucal_redirect_valid && predict_taken && (bjucal_redirect_target[31:0] != predict_target));
    assign bjusb_bju_taken_bpu_nottaken_wrong     = valid && (bjucal_redirect_valid && ~predict_taken);

    assign bjusb_bju_nottaken_bpu_taken_wrong     = valid && (~bjucal_redirect_valid && predict_taken);
    assign bjusb_bju_nottaken_bpu_nottaken_right  = valid && (~bjucal_redirect_valid && ~predict_taken);


    reg [128:0] btb_wmask;
    reg [128:0] btb_din;
    always @(*) begin
        btb_wmask = 'b0;
        btb_din   = 'b0;
        if (pc[3:2] == 2'b00) begin
            btb_wmask = {1'b1, 32'd0, 32'd0, 32'd0, {32{1'b1}}};
            btb_din   = {1'b1, 32'd0, 32'd0, 32'd0, bjucal_redirect_target[31:0]};
        end else if (pc[3:2] == 2'b01) begin
            btb_wmask = {1'b1, 32'd0, 32'd0, {32{1'b1}}, 32'd0};
            btb_din   = {1'b1, 32'd0, 32'd0, bjucal_redirect_target[31:0], 32'd0};
        end else if (pc[3:2] == 2'b10) begin
            btb_wmask = {1'b1, 32'd0, {32{1'b1}}, 32'd0, 32'd0};
            btb_din   = {1'b1, 32'd0, bjucal_redirect_target[31:0], 32'd0, 32'd0};
        end else if (pc[3:2] == 2'b11) begin
            btb_wmask = {1'b1, {32{1'b1}}, 32'd0, 32'd0, 32'd0};
            btb_din   = {1'b1, bjucal_redirect_target[31:0], 32'd0, 32'd0, 32'd0};
        end
    end

    always @(*) begin
        //bjusb2bht write interface
        bjusb_bht_write_enable         = 'b0;
        bjusb_bht_write_index          = 'b0;  //12-4+1=9bit used as set addr for 512set bht      
        bjusb_bht_write_counter_select = 'b0;  //pc[1:0] represent 4B = 1 instr, so pc[3:2] is for select 4 instr           
        bjusb_bht_write_inc            = 'b0;
        bjusb_bht_write_dec            = 'b0;
        bjusb_bht_valid_in             = 'b0;
        //redirect signals
        redirect_valid                 = 'b0;
        redirect_target                = 'b0;
        //bjusb_btb_ write interface
        bjusb_btb_ce                   = 'b0;  //useless , ce tie 1 at btb                   
        bjusb_btb_we                   = 'b0;
        bjusb_btb_wmask                = 'b0;
        bjusb_btb_write_index          = 'b0;
        bjusb_btb_din                  = 'b0;
        if (bjusb_bju_taken_bpu_taken_right) begin
            //predict jump right: enhance bht
            bjusb_bht_write_enable         = 1'b1;
            bjusb_bht_write_index          = pc[12:4];  //12-4+1=9bit used as set addr for 512set bht      
            bjusb_bht_write_counter_select = pc[3:2];  //pc[1:0] represent 4B = 1 instr, so pc[3:2] is for select 4 instr           
            bjusb_bht_write_inc            = 1'b1;
            bjusb_bht_write_dec            = 1'b0;
            bjusb_bht_valid_in             = 1'b1;
        end else if (bjusb_bju_taken_bpu_nottaken_wrong || bjusb_bju_taken_bpu_taken_butaddrwrong) begin
            //predict notjump wrong : enhance bht
            bjusb_bht_write_enable         = 1'b1;
            bjusb_bht_write_index          = pc[12:4];
            bjusb_bht_write_counter_select = pc[3:2];
            bjusb_bht_write_inc            = 1'b1;
            bjusb_bht_write_dec            = 1'b0;
            bjusb_bht_valid_in             = 1'b1;
            //send bjucal result as redirect
            redirect_valid                 = bjucal_redirect_valid;
            redirect_target                = bjucal_redirect_target;
            //write bjucal_redirect_target to btb
            bjusb_btb_ce                   = 1'b1;
            bjusb_btb_we                   = 1'b1;
            bjusb_btb_wmask                = btb_wmask;
            bjusb_btb_write_index          = pc[12:4];
            bjusb_btb_din                  = btb_din;
        end else if (bjusb_bju_nottaken_bpu_taken_wrong) begin
            //predict jump wrong : decrease bht
            bjusb_bht_write_enable         = 1'b1;
            bjusb_bht_write_index          = pc[12:4];
            bjusb_bht_write_counter_select = pc[3:2];
            bjusb_bht_write_inc            = 1'b0;
            bjusb_bht_write_dec            = 1'b1;
            bjusb_bht_valid_in             = 1'b1;
            //send pc+4 as redirect
            redirect_valid                 = 1'b1;
            redirect_target                = pc + 'd4;
            //
            // bjusb_btb_ce                   = 1'b1;
            // bjusb_btb_we                   = 1'b1;
            // bjusb_btb_wmask                = btb_wmask;
            // bjusb_btb_write_index          = pc[12:4];
            // bjusb_btb_din                  = btb_din;
        end else if (bjusb_bju_nottaken_bpu_nottaken_right) begin
            //predict not jump right, decrease bht
            bjusb_bht_write_enable         = 1'b1;
            bjusb_bht_write_index          = pc[12:4];
            bjusb_bht_write_counter_select = pc[3:2];
            bjusb_bht_write_inc            = 1'b0;
            bjusb_bht_write_dec            = 1'b1;
            bjusb_bht_valid_in             = 1'b1;
            //
            // bjusb_btb_ce                   = 1'b1;
            // bjusb_btb_we                   = 1'b1;
            // bjusb_btb_wmask                = btb_wmask;
            // bjusb_btb_write_index          = pc[12:4];
            // bjusb_btb_din                  = btb_din;
        end
    end

    /* -------------------------------- pmu logic ------------------------------- */

    wire j_type = (is_jal || is_jalr);
    wire b_type = ~j_type;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            bju_pmu_situation1_cnt_btype <= 'b0;
            bju_pmu_situation2_cnt_btype <= 'b0;
            bju_pmu_situation3_cnt_btype <= 'b0;
            bju_pmu_situation4_cnt_btype <= 'b0;
            bju_pmu_situation5_cnt_btype <= 'b0;
        end else if (b_type) begin
            if (bjusb_bju_taken_bpu_taken_right) begin
                bju_pmu_situation1_cnt_btype <= bju_pmu_situation1_cnt_btype + 1;
            end else if (bjusb_bju_taken_bpu_taken_butaddrwrong) begin
                bju_pmu_situation2_cnt_btype <= bju_pmu_situation2_cnt_btype + 1;
            end else if (bjusb_bju_taken_bpu_nottaken_wrong) begin
                bju_pmu_situation3_cnt_btype <= bju_pmu_situation3_cnt_btype + 1;
            end else if (bjusb_bju_nottaken_bpu_taken_wrong) begin
                bju_pmu_situation4_cnt_btype <= bju_pmu_situation4_cnt_btype + 1;
            end else if (bjusb_bju_nottaken_bpu_nottaken_right) begin
                bju_pmu_situation5_cnt_btype <= bju_pmu_situation5_cnt_btype + 1;
            end
        end
    end

        always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            bju_pmu_situation1_cnt_jtype <= 'b0;
            bju_pmu_situation2_cnt_jtype <= 'b0;
            bju_pmu_situation3_cnt_jtype <= 'b0;
            bju_pmu_situation4_cnt_jtype <= 'b0;
            bju_pmu_situation5_cnt_jtype <= 'b0;
        end else if (j_type) begin
            if (bjusb_bju_taken_bpu_taken_right) begin
                bju_pmu_situation1_cnt_jtype <= bju_pmu_situation1_cnt_jtype + 1;
            end else if (bjusb_bju_taken_bpu_taken_butaddrwrong) begin
                bju_pmu_situation2_cnt_jtype <= bju_pmu_situation2_cnt_jtype + 1;
            end else if (bjusb_bju_taken_bpu_nottaken_wrong) begin
                bju_pmu_situation3_cnt_jtype <= bju_pmu_situation3_cnt_jtype + 1;
            end else if (bjusb_bju_nottaken_bpu_taken_wrong) begin
                bju_pmu_situation4_cnt_jtype <= bju_pmu_situation4_cnt_jtype + 1;
            end else if (bjusb_bju_nottaken_bpu_nottaken_right) begin
                bju_pmu_situation5_cnt_jtype <= bju_pmu_situation5_cnt_jtype + 1;
            end
        end
    end



endmodule
