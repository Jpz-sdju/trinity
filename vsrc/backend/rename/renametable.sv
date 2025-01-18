`include "defines.sv"
module renametable (
    input wire clock,
    input wire reset_n,

    //read req from decode
    input wire       instr0_src1_is_reg,
    input wire [4:0] instr0_lrs1,
    input wire       instr0_src2_is_reg,
    input wire [4:0] instr0_lrs2,
    input wire       instr0_need_to_wb,
    input wire [4:0] instr0_lrd,


    input wire       instr1_src1_is_reg,
    input wire [4:0] instr1_lrs1,
    input wire       instr1_src2_is_reg,
    input wire [4:0] instr1_lrs2,
    input wire       instr1_need_to_wb,
    input wire [4:0] instr1_lrd,

    //read data to rename
    output wire [`PREG_RANGE] rat2rename_instr0_prs1,
    output wire [`PREG_RANGE] rat2rename_instr0_prs2,
    output wire [`PREG_RANGE] rat2rename_instr0_prd,

    output wire [`PREG_RANGE] rat2rename_instr1_prs1,
    output wire [`PREG_RANGE] rat2rename_instr1_prs2,
    output wire [`PREG_RANGE] rat2rename_instr1_prd,

    //write request from rename
    input wire               rename2rat_instr0_rename_valid,
    input wire [        4:0] rename2rat_instr0_rename_addr,
    input wire [`PREG_RANGE] rename2rat_instr0_rename_data,

    input wire               rename2rat_instr1_rename_valid,
    input wire [        4:0] rename2rat_instr1_rename_addr,
    input wire [`PREG_RANGE] rename2rat_instr1_rename_data,


    //arch rat write 
    input wire               commits0_valid,
    input wire               commits0_need_to_wb,
    input wire [`LREG_RANGE] commits0_lrd,
    input wire [`PREG_RANGE] commits0_prd,

    input wire               commits1_valid,
    input wire               commits1_need_to_wb,
    input wire [`LREG_RANGE] commits1_lrd,
    input wire [`PREG_RANGE] commits1_prd,

    //debug
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
    output wire [`PREG_RANGE] debug_preg31,
    /* ------------------------------- walk logic ------------------------------- */
    input  wire [        1:0] rob_state,
    input  wire               rob_walk0_valid,
    input  wire [`LREG_RANGE] rob_walk0_lrd,
    input  wire [`PREG_RANGE] rob_walk0_prd,
    input  wire               rob_walk1_valid,
    input  wire [`LREG_RANGE] rob_walk1_lrd,
    input  wire [`PREG_RANGE] rob_walk1_prd

);
    wire is_idle;
    wire is_ovwr;
    wire is_walking;
    assign is_idle    = (rob_state == `ROB_STATE_IDLE);
    assign is_ovwr    = (rob_state == `ROB_STATE_OVERWRITE_RAT);
    assign is_walking = (rob_state == `ROB_STATE_WALKING);

    reg  [`PREG_RANGE] renametables               [0:31];
    reg  [       31:0] renametables_wren_dec;
    reg  [`PREG_RANGE] renametables_wdata_dec     [0:31];


    wire               instr0_prs1_bypass_rename0;
    wire               instr0_prs1_bypass_rename1;
    wire               instr0_prs2_bypass_rename0;
    wire               instr0_prs2_bypass_rename1;
    wire               instr1_prs1_bypass_rename0;
    wire               instr1_prs1_bypass_rename1;
    wire               instr1_prs2_bypass_rename0;
    wire               instr1_prs2_bypass_rename1;

    wire               instr0_prd_bypass_rename0;
    wire               instr0_prd_bypass_rename1;
    wire               instr1_prd_bypass_rename0;
    wire               instr1_prd_bypass_rename1;

    wire [`PREG_RANGE] instr0_prs1_byp_res;
    wire [`PREG_RANGE] instr0_prs2_byp_res;
    wire [`PREG_RANGE] instr1_prs1_byp_res;
    wire [`PREG_RANGE] instr1_prs2_byp_res;

    wire [`PREG_RANGE] instr0_prd_byp_res;
    wire [`PREG_RANGE] instr1_prd_byp_res;

    wire               instr0_prs1_byp;
    wire               instr0_prs2_byp;
    wire               instr1_prs1_byp;
    wire               instr1_prs2_byp;

    wire               instr0_prd_byp;
    wire               instr1_prd_byp;

    assign instr0_prs1_bypass_rename0 = rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == instr0_lrs1);
    assign instr0_prs1_bypass_rename1 = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr0_lrs1);
    assign instr0_prs2_bypass_rename0 = rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == instr0_lrs2);
    assign instr0_prs2_bypass_rename1 = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr0_lrs2);

    assign instr1_prs1_bypass_rename0 = rename2rat_instr1_rename_valid & (rename2rat_instr0_rename_addr == instr1_lrs1);
    assign instr1_prs1_bypass_rename1 = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr1_lrs1);
    assign instr1_prs2_bypass_rename0 = rename2rat_instr1_rename_valid & (rename2rat_instr0_rename_addr == instr1_lrs2);
    assign instr1_prs2_bypass_rename1 = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr1_lrs2);

    //rd bypass
    assign instr0_prd_bypass_rename0  = rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == instr0_lrd);
    assign instr0_prd_bypass_rename1  = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr0_lrd);

    assign instr1_prd_bypass_rename0  = rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == instr1_lrd);
    assign instr1_prd_bypass_rename1  = rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == instr1_lrd);


    assign instr0_prs1_byp            = instr0_prs1_bypass_rename1 | instr0_prs1_bypass_rename0;
    assign instr0_prs2_byp            = instr0_prs2_bypass_rename1 | instr0_prs2_bypass_rename0;
    assign instr1_prs1_byp            = instr1_prs1_bypass_rename1 | instr1_prs1_bypass_rename0;
    assign instr1_prs2_byp            = instr1_prs2_bypass_rename1 | instr1_prs2_bypass_rename0;

    //rd bypass
    assign instr0_prd_byp             = instr0_prd_bypass_rename1 | instr0_prd_bypass_rename0;
    assign instr1_prd_byp             = instr1_prd_bypass_rename1 | instr1_prd_bypass_rename0;


    assign instr0_prs1_byp_res        = instr0_prs1_bypass_rename1 ? rename2rat_instr1_rename_data : instr0_prs1_bypass_rename0 ? rename2rat_instr0_rename_data : 'hB;
    assign instr0_prs2_byp_res        = instr0_prs2_bypass_rename1 ? rename2rat_instr1_rename_data : instr0_prs2_bypass_rename0 ? rename2rat_instr0_rename_data : 'hB;
    assign instr1_prs1_byp_res        = instr1_prs1_bypass_rename1 ? rename2rat_instr1_rename_data : instr1_prs1_bypass_rename0 ? rename2rat_instr1_rename_data : 'hB;
    assign instr1_prs2_byp_res        = instr1_prs2_bypass_rename1 ? rename2rat_instr1_rename_data : instr1_prs2_bypass_rename0 ? rename2rat_instr1_rename_data : 'hB;


    //rd bypass
    assign instr0_prd_byp_res         = instr0_prd_bypass_rename1 ? rename2rat_instr1_rename_data : instr0_prd_bypass_rename0 ? rename2rat_instr0_rename_data : 'hB;
    assign instr1_prd_byp_res         = instr1_prd_bypass_rename1 ? rename2rat_instr1_rename_data : instr1_prd_bypass_rename0 ? rename2rat_instr1_rename_data : 'hB;


    //read data to rename
    wire [`PREG_RANGE] instr0_rat_prs1_raw;
    wire [`PREG_RANGE] instr0_rat_prs2_raw;
    wire [`PREG_RANGE] instr0_rat_prd_raw;

    wire [`PREG_RANGE] instr1_rat_prs1_raw;
    wire [`PREG_RANGE] instr1_rat_prs2_raw;
    wire [`PREG_RANGE] instr1_rat_prd_raw;
    /* -------------------------------------------------------------------------- */
    /*                                 bypass logic                                 */
    /* -------------------------------------------------------------------------- */
    assign instr0_rat_prs1_raw    = instr0_src1_is_reg ? instr0_prs1_byp ? instr0_prs1_byp_res : renametables[instr0_lrs1] : 'b0;  //could gate?
    assign instr0_rat_prs2_raw    = instr0_src2_is_reg ? instr0_prs2_byp ? instr0_prs2_byp_res : renametables[instr0_lrs2] : 'b0;
    assign instr0_rat_prd_raw     = instr0_need_to_wb ? instr0_prd_byp ? instr0_prd_byp_res : renametables[instr0_lrd] : 'b0;

    assign instr1_rat_prs1_raw    = instr1_src1_is_reg ? instr1_prs1_byp ? instr1_prs1_byp_res : renametables[instr1_lrs1] : 'b0;  //could gate?
    assign instr1_rat_prs2_raw    = instr1_src2_is_reg ? instr1_prs2_byp ? instr1_prs2_byp_res : renametables[instr1_lrs2] : 'b0;
    assign instr1_rat_prd_raw     = instr1_need_to_wb ? instr1_prd_byp ? instr1_prd_byp_res : renametables[instr1_lrd] : 'b0;

    assign rat2rename_instr0_prs1 = instr0_rat_prs1_raw;
    assign rat2rename_instr0_prs2 = instr0_rat_prs2_raw;
    assign rat2rename_instr0_prd  = instr0_rat_prd_raw;

    assign rat2rename_instr1_prs1 = instr1_rat_prs1_raw;
    assign rat2rename_instr1_prs2 = instr1_rat_prs2_raw;
    assign rat2rename_instr1_prd  = instr1_rat_prd_raw;

    // `MACRO_DFF_NONEN(rat2rename_instr0_prs1, instr0_rat_prs1_raw, `PREG_LENGTH)
    // `MACRO_DFF_NONEN(rat2rename_instr0_prs2, instr0_rat_prs2_raw, `PREG_LENGTH)
    // `MACRO_DFF_NONEN(rat2rename_instr0_prd, instr0_rat_prd_raw, `PREG_LENGTH)

    // `MACRO_DFF_NONEN(rat2rename_instr1_prs1, instr1_rat_prs1_raw, `PREG_LENGTH)
    // `MACRO_DFF_NONEN(rat2rename_instr1_prs2, instr1_rat_prs2_raw, `PREG_LENGTH)
    // `MACRO_DFF_NONEN(rat2rename_instr1_prd, instr1_rat_prd_raw, `PREG_LENGTH)

    //conflict logic
    wire rename_lrd_hit;
    wire walk_lrd_hit;
    assign rename_lrd_hit = rename2rat_instr0_rename_valid & rename2rat_instr1_rename_valid & (rename2rat_instr0_rename_addr == rename2rat_instr1_rename_addr);
    assign walk_lrd_hit   = rob_walk0_valid & rob_walk1_valid & (rob_walk0_lrd == rob_walk1_lrd);

    //条件太长太难看，但是是for循环，怎么办？
    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wren_dec[i] = 'b0;
            if (is_walking) begin
                if (rob_walk0_valid & (rob_walk0_lrd == i[`LREG_RANGE]) | rob_walk1_valid & (rob_walk1_lrd == i[`LREG_RANGE])) begin
                    renametables_wren_dec[i] = 1'b1;
                end
            end else if (rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == i[4:0]) | rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == i[4:0])) begin
                renametables_wren_dec[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            renametables_wdata_dec[i] = 'b0;
            if (is_walking) begin
                if (rob_walk0_valid & rob_walk0_valid & (rob_walk0_lrd == i[`LREG_RANGE]) & ~walk_lrd_hit) begin
                    renametables_wdata_dec[i] = rob_walk0_prd;
                end else if (rob_walk1_valid & rob_walk1_valid & (rob_walk1_lrd == i[`LREG_RANGE])) begin
                    renametables_wdata_dec[i] = rob_walk1_prd;
                end
            end else if (rename2rat_instr0_rename_valid & (rename2rat_instr0_rename_addr == i[4:0]) & ~rename_lrd_hit) begin
                renametables_wdata_dec[i] = rename2rat_instr0_rename_data;
            end else if (rename2rat_instr1_rename_valid & (rename2rat_instr1_rename_addr == i[4:0])) begin
                renametables_wdata_dec[i] = rename2rat_instr1_rename_data;
            end
        end
    end

    //ugly sig
    wire [`PREG_RANGE] temp_sig[31:0];
    assign temp_sig = {
        debug_preg31,
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
        debug_preg0
    };
    always @(posedge clock or negedge reset_n) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            if (~reset_n) begin
                renametables[i] <= i[5:0];
            end else if (is_ovwr) begin
                renametables[i] <= temp_sig[i];
            end else if (renametables_wren_dec[i]) begin
                renametables[i] <= renametables_wdata_dec[i];
            end
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                  arch rat                                  */
    /* -------------------------------------------------------------------------- */
    archrenametable u_archrenametable (
        .clock              (clock),
        .reset_n            (reset_n),
        .commits0_valid     (commits0_valid),
        .commits0_need_to_wb(commits0_need_to_wb),
        .commits0_lrd       (commits0_lrd),
        .commits0_prd       (commits0_prd),
        .commits1_valid     (commits1_valid),
        .commits1_need_to_wb(commits1_need_to_wb),
        .commits1_lrd       (commits1_lrd),
        .commits1_prd       (commits1_prd),
        //debug
        .debug_preg0        (debug_preg0),
        .debug_preg1        (debug_preg1),
        .debug_preg2        (debug_preg2),
        .debug_preg3        (debug_preg3),
        .debug_preg4        (debug_preg4),
        .debug_preg5        (debug_preg5),
        .debug_preg6        (debug_preg6),
        .debug_preg7        (debug_preg7),
        .debug_preg8        (debug_preg8),
        .debug_preg9        (debug_preg9),
        .debug_preg10       (debug_preg10),
        .debug_preg11       (debug_preg11),
        .debug_preg12       (debug_preg12),
        .debug_preg13       (debug_preg13),
        .debug_preg14       (debug_preg14),
        .debug_preg15       (debug_preg15),
        .debug_preg16       (debug_preg16),
        .debug_preg17       (debug_preg17),
        .debug_preg18       (debug_preg18),
        .debug_preg19       (debug_preg19),
        .debug_preg20       (debug_preg20),
        .debug_preg21       (debug_preg21),
        .debug_preg22       (debug_preg22),
        .debug_preg23       (debug_preg23),
        .debug_preg24       (debug_preg24),
        .debug_preg25       (debug_preg25),
        .debug_preg26       (debug_preg26),
        .debug_preg27       (debug_preg27),
        .debug_preg28       (debug_preg28),
        .debug_preg29       (debug_preg29),
        .debug_preg30       (debug_preg30),
        .debug_preg31       (debug_preg31)
    );

endmodule
