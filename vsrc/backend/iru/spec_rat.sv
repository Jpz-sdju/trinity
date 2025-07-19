module spec_rat #(
    parameter DATA_WIDTH = 124
) (
    input wire       clock,
    input wire       reset_n,
    // Write Port 0 
    input wire       rn2specrat_instr0_lrd_wren,
    input wire [4:0] rn2specrat_instr0_lrd_wraddr,
    input wire [5:0] rn2specrat_instr0_lrd_wrdata,

    // Write Port 1 
    input wire       rn2specrat_instr1_lrd_wren,
    input wire [4:0] rn2specrat_instr1_lrd_wraddr,
    input wire [5:0] rn2specrat_instr1_lrd_wrdata,

    // Read Ports for Instruction     
    input wire       rn2specrat_instr0_lrs1_rden,
    input wire       rn2specrat_instr0_lrs2_rden,
    input wire       rn2specrat_instr0_lrd_rden,
    input wire [4:0] rn2specrat_instr0_lrs1,
    input wire [4:0] rn2specrat_instr0_lrs2,
    input wire [4:0] rn2specrat_instr0_lrd,
    input wire       rn2specrat_instr1_lrs1_rden,
    input wire       rn2specrat_instr1_lrs2_rden,
    input wire       rn2specrat_instr1_lrd_rden,
    input wire [4:0] rn2specrat_instr1_lrs1,
    input wire [4:0] rn2specrat_instr1_lrs2,
    input wire [4:0] rn2specrat_instr1_lrd,

    // Read Data Outputs for Instruction
    output wire [5:0] specrat2rn_instr0prs1,
    output wire [5:0] specrat2rn_instr0prs2,
    output wire [5:0] specrat2rn_instr0prd,
    output wire [5:0] specrat2rn_instr1prs1,
    output wire [5:0] specrat2rn_instr1prs2,
    output wire [5:0] specrat2rn_instr1prd,

    /* ------------------------------- commit port ------------------------------ */
    input wire       commit0_valid,
    input wire       commit0_need_to_wb,
    input wire [4:0] commit0_lrd,
    input wire [5:0] commit0_prd,
    input wire       commit1_valid,
    input wire       commit1_need_to_wb,
    input wire [4:0] commit1_lrd,
    input wire [5:0] commit1_prd,

    /* ------------------------------- walk_logic ------------------------------- */
    input wire [1:0] rob_state,
    input wire       rob_walk0_valid,
    input wire       rob_walk1_valid,
    input wire [5:0] rob_walk0_prd,
    input wire [5:0] rob_walk1_prd,
    input wire [4:0] rob_walk0_lrd,
    input wire [4:0] rob_walk1_lrd,

    /* --------------------- arch_rat : 32 arch regfile content -------------------- */
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
    wire is_idle;
    wire is_rollback;
    wire is_walk;

    assign is_idle     = (rob_state == `ROB_STATE_IDLE);
    assign is_rollback = (rob_state == `ROB_STATE_ROLLBACK);
    assign is_walk     = (rob_state == `ROB_STATE_WALK);

    //hit situation
    wire rename_lrd_hit;
    wire walk_lrd_hit;
    assign rename_lrd_hit = rn2specrat_instr0_lrd_wren && rn2specrat_instr1_lrd_wren && (rn2specrat_instr0_lrd_wraddr == rn2specrat_instr1_lrd_wraddr);
    assign walk_lrd_hit   = rob_walk0_valid && rob_walk1_valid && (rob_walk0_lrd == rob_walk1_lrd);

    // Parameters
    localparam LOGICAL_REG_WIDTH = 5;
    localparam PHYSICAL_REG_WIDTH = 6;
    localparam NUM_LOGICAL_REGS = 32;
    localparam NUM_PHYSICAL_REGS = 64;

    // Speculative RAT Register Array: Maps Logical Registers to Physical Registers
    reg     [PHYSICAL_REG_WIDTH-1:0] spec_rat[NUM_LOGICAL_REGS-1:0];  // [5:0] reg [31:0]

    // Initialize Speculative RAT
    integer                          i;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            for (i = 0; i < NUM_LOGICAL_REGS; i = i + 1) begin
                spec_rat[i] <= i;  // Initial mapping: Logical Reg i maps to Physical Reg i
            end
        end else begin
            if (is_rollback) begin
                spec_rat <= arch_rat_content;
            end else if (is_walk) begin
                if (rob_walk0_valid && ~walk_lrd_hit) begin
                    spec_rat[rob_walk0_lrd] <= rob_walk0_prd;  //prd is new physical reg number fetched from freelist, use it to upate arch_rat 
                end
                if (rob_walk1_valid) begin
                    spec_rat[rob_walk1_lrd] <= rob_walk1_prd;
                end
            end else begin  // (is_idle)
                // Write Port 0
                if (rn2specrat_instr0_lrd_wren && ~rename_lrd_hit) begin
                    spec_rat[rn2specrat_instr0_lrd_wraddr] <= rn2specrat_instr0_lrd_wrdata;
                end
                // Write Port 1
                if (rn2specrat_instr1_lrd_wren) begin
                    spec_rat[rn2specrat_instr1_lrd_wraddr] <= rn2specrat_instr1_lrd_wrdata;
                end
            end
        end
    end

    // Bypass Logic
    // For each read port, check if the read address matches any write address.
    // If a match is found and the write enable is active, bypass the write data.
    // Priority: Write Port 1 has higher priority than Write Port 0.

    // Instruction 0 Source 1 (prs1)
    wire [5:0] bypass_instr0_prs1;
    //wire       bypass_instr0_prs1_sel_wr1;
    //wire       bypass_instr0_prs1_sel_wr0;
    //assign bypass_instr0_prs1_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr0_lrs1 == rn2specrat_instr1_lrd_wraddr);
    //assign bypass_instr0_prs1_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr0_lrs1 == rn2specrat_instr0_lrd_wraddr) && !bypass_instr0_prs1_sel_wr1;
    //assign bypass_instr0_prs1         = bypass_instr0_prs1_sel_wr1 ? rn2specrat_instr1_lrd_wrdata : (bypass_instr0_prs1_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr0_lrs1]);
    assign bypass_instr0_prs1         = spec_rat[rn2specrat_instr0_lrs1];

    // Instruction 0 Source 2 (prs2)
    wire [5:0] bypass_instr0_prs2;
    //wire       bypass_instr0_prs2_sel_wr1;
    //wire       bypass_instr0_prs2_sel_wr0;
    //assign bypass_instr0_prs2_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr0_lrs2 == rn2specrat_instr1_lrd_wraddr);
    //assign bypass_instr0_prs2_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr0_lrs2 == rn2specrat_instr0_lrd_wraddr) && !bypass_instr0_prs2_sel_wr1;
    //assign bypass_instr0_prs2         = bypass_instr0_prs2_sel_wr1 ? rn2specrat_instr1_lrd_wrdata : (bypass_instr0_prs2_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr0_lrs2]);
    assign bypass_instr0_prs2         = spec_rat[rn2specrat_instr0_lrs2];

    // Instruction 0 Destination (prd)
    wire [5:0] bypass_instr0_prd;
    //wire       bypass_instr0_prd_sel_wr1;
    //wire       bypass_instr0_prd_sel_wr0;
    //assign bypass_instr0_prd_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr0_lrd == rn2specrat_instr1_lrd_wraddr);
    //assign bypass_instr0_prd_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr0_lrd == rn2specrat_instr0_lrd_wraddr) && !bypass_instr0_prd_sel_wr1;
    //assign bypass_instr0_prd         = bypass_instr0_prd_sel_wr1 ? rn2specrat_instr1_lrd_wrdata : (bypass_instr0_prd_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr0_lrd]);
    assign bypass_instr0_prd         = spec_rat[rn2specrat_instr0_lrd];

    // Instruction 1 Source 1 (prs1)
    wire [5:0] bypass_instr1_prs1;
    //wire       bypass_instr1_prs1_sel_wr1;
    wire       bypass_instr1_prs1_sel_wr0;
    //assign bypass_instr1_prs1_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr1_lrs1 == rn2specrat_instr1_lrd_wraddr);
    //assign bypass_instr1_prs1_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrs1 == rn2specrat_instr0_lrd_wraddr) && !bypass_instr1_prs1_sel_wr1;
    assign bypass_instr1_prs1_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrs1 == rn2specrat_instr0_lrd_wraddr);
    assign bypass_instr1_prs1         = (bypass_instr1_prs1_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr1_lrs1]);

    // Instruction 1 Source 2 (prs2)
    wire [5:0] bypass_instr1_prs2;
    //wire       bypass_instr1_prs2_sel_wr1;
    wire       bypass_instr1_prs2_sel_wr0;

    //assign bypass_instr1_prs2_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr1_lrs2 == rn2specrat_instr1_lrd_wraddr);
    //assign bypass_instr1_prs2_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrs2 == rn2specrat_instr0_lrd_wraddr) && !bypass_instr1_prs2_sel_wr1;
    assign bypass_instr1_prs2_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrs2 == rn2specrat_instr0_lrd_wraddr) ;

    //assign bypass_instr1_prs2         = bypass_instr1_prs2_sel_wr1 ? rn2specrat_instr1_lrd_wrdata : (bypass_instr1_prs2_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr1_lrs2]);
    assign bypass_instr1_prs2         = (bypass_instr1_prs2_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr1_lrs2]);

    // Instruction 1 Destination (prd)
    wire [5:0] bypass_instr1_prd;
    //wire       bypass_instr1_prd_sel_wr1;
    wire       bypass_instr1_prd_sel_wr0;

    //assign bypass_instr1_prd_sel_wr1 = rn2specrat_instr1_lrd_wren && (rn2specrat_instr1_lrd == rn2specrat_instr1_lrd_wraddr);

    //assign bypass_instr1_prd_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrd == rn2specrat_instr0_lrd_wraddr) && !bypass_instr1_prd_sel_wr1;
    assign bypass_instr1_prd_sel_wr0 = rn2specrat_instr0_lrd_wren && (rn2specrat_instr1_lrd == rn2specrat_instr0_lrd_wraddr) ;

    assign bypass_instr1_prd         =  bypass_instr1_prd_sel_wr0 ? rn2specrat_instr0_lrd_wrdata : spec_rat[rn2specrat_instr1_lrd];

    // Read Result
    assign specrat2rn_instr0prs1     = rn2specrat_instr0_lrs1_rden ? bypass_instr0_prs1 : 6'd0;
    assign specrat2rn_instr0prs2     = rn2specrat_instr0_lrs2_rden ? bypass_instr0_prs2 : 6'd0;
    assign specrat2rn_instr0prd      = rn2specrat_instr0_lrd_rden ? bypass_instr0_prd : 6'd0;
    assign specrat2rn_instr1prs1     = rn2specrat_instr1_lrs1_rden ? bypass_instr1_prs1 : 6'd0;
    assign specrat2rn_instr1prs2     = rn2specrat_instr1_lrs2_rden ? bypass_instr1_prs2 : 6'd0;
    assign specrat2rn_instr1prd      = rn2specrat_instr1_lrd_rden ? bypass_instr1_prd : 6'd0;


    /* -------------------------------- arch_rat -------------------------------- */

    arch_rat u_arch_rat (
        .clock             (clock),
        .reset_n           (reset_n),
        .commit0_valid     (commit0_valid),
        .commit0_need_to_wb(commit0_need_to_wb),
        .commit0_lrd       (commit0_lrd),
        .commit0_prd       (commit0_prd),
        .commit1_valid     (),
        .commit1_need_to_wb(),
        .commit1_lrd       (),
        .commit1_prd       (),
        .debug_preg0       (debug_preg0),
        .debug_preg1       (debug_preg1),
        .debug_preg2       (debug_preg2),
        .debug_preg3       (debug_preg3),
        .debug_preg4       (debug_preg4),
        .debug_preg5       (debug_preg5),
        .debug_preg6       (debug_preg6),
        .debug_preg7       (debug_preg7),
        .debug_preg8       (debug_preg8),
        .debug_preg9       (debug_preg9),
        .debug_preg10      (debug_preg10),
        .debug_preg11      (debug_preg11),
        .debug_preg12      (debug_preg12),
        .debug_preg13      (debug_preg13),
        .debug_preg14      (debug_preg14),
        .debug_preg15      (debug_preg15),
        .debug_preg16      (debug_preg16),
        .debug_preg17      (debug_preg17),
        .debug_preg18      (debug_preg18),
        .debug_preg19      (debug_preg19),
        .debug_preg20      (debug_preg20),
        .debug_preg21      (debug_preg21),
        .debug_preg22      (debug_preg22),
        .debug_preg23      (debug_preg23),
        .debug_preg24      (debug_preg24),
        .debug_preg25      (debug_preg25),
        .debug_preg26      (debug_preg26),
        .debug_preg27      (debug_preg27),
        .debug_preg28      (debug_preg28),
        .debug_preg29      (debug_preg29),
        .debug_preg30      (debug_preg30),
        .debug_preg31      (debug_preg31)
    );

    wire [`PREG_RANGE] arch_rat_content[31:0];
    assign arch_rat_content = {
        debug_preg31,//31
        debug_preg30,
        debug_preg29,
        debug_preg28,
        debug_preg27,
        debug_preg26,
        debug_preg25,
        debug_preg24,
        debug_preg23,
        debug_preg22,
        debug_preg21,
        debug_preg20,
        debug_preg19,
        debug_preg18,
        debug_preg17,
        debug_preg16,
        debug_preg15,
        debug_preg14,
        debug_preg13,
        debug_preg12,
        debug_preg11,
        debug_preg10,
        debug_preg9,
        debug_preg8,
        debug_preg7,
        debug_preg6,
        debug_preg5,
        debug_preg4,
        debug_preg3,
        debug_preg2,
        debug_preg1,
        debug_preg0 //0
    };

endmodule
