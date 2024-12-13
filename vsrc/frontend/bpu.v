module bpu (
    input clock,
    input reset_n,
    input [63:0] pc,//rd_addr
    input pc_handshake,//rd_en
    input [63:0] wr_addr,
    input wr_en,
    input [31:0] bht_wr_data,//16 saturate counter
    input [31:0] btb_wr_data,//predict target
    output [63:0] base_pc,
    output [63:0] trigger_pc,
    output [63:0] predict_target,
    output predict_valid

);

    wire [31:0] bht_rd_data;//16 saturate cnt
    wire [31:0] btb_rd_data;//predict target
    wire btbtag_hit;
    wire [63:0] bhtbtb2dec_pc;

    wire pc_handshake_mod; // only predict aligned pc for now
    assign pc_handshake_mod = pc[2]? 1'd0:1'd1;
    
bhtbtb u_bhtbtb(
    .clock         (clock         ),
    .reset_n       (reset_n       ),
    .pc            (pc            ),
    .pc_handshake  (pc_handshake_mod  ),
    .wr_addr       (wr_addr       ),
    .wr_en         (wr_en         ),
    .bht_wr_data   (bht_wr_data   ),
    .btb_wr_data   (btb_wr_data   ),
    .bht_rd_data   (bht_rd_data   ),
    .btb_rd_data   (btb_rd_data   ),
    .bhtbtb2dec_pc (bhtbtb2dec_pc ),
    .btbtag_hit    (btbtag_hit    )
);

wire predict_valid_premod;

bhtbtb_decoder u_bhtbtb_decoder(
    .bht_rd_data    (bht_rd_data    ),
    .btb_rd_data    (btb_rd_data    ),
    .btbtag_hit     (btbtag_hit     ),
    .bhtbtb2dec_pc  (bhtbtb2dec_pc  ),
    .base_pc        (base_pc        ),
    .trigger_pc     (trigger_pc     ),
    .predict_target (predict_target ),
    .predict_valid  (predict_valid_premod  )
);

assign predict_valid = predict_target[2]? 1'd0:1'd1;//only send out aligend predict_target for now



endmodule