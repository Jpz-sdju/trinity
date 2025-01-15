`define PIPE_BEFORE_RENAME(out, in, clear)\
pipereg_2 u_pipereg_1(\
    .clock                   (clock                   ),\
    .reset_n                 (reset_n                 ),\
    .redirect_flush          (clear          ),\
    .ready                   (in``_ready                   ),\
    .lrs1                     (in``_lrs1                     ),\
    .lrs2                     (in``_lrs2                     ),\
    .lrd                      (in``_lrd                      ),\
    .imm                     (in``_imm                     ),\
    .src1_is_reg             (in``_src1_is_reg             ),\
    .src2_is_reg             (in``_src2_is_reg             ),\
    .need_to_wb              (in``_need_to_wb              ),\
    .cx_type                 (in``_cx_type                 ),\
    .is_unsigned             (in``_is_unsigned             ),\
    .alu_type                (in``_alu_type                ),\
    .is_word                 (in``_is_word                 ),\
    .is_load                 (in``_is_load                 ),\
    .is_imm                  (in``_is_imm                  ),\
    .is_store                (in``_is_store                ),\
    .ls_size                 (in``_ls_size                 ),\
    .muldiv_type             (in``_muldiv_type             ),\
    .instr_valid             (in``_valid             ),\
    .pc                      (in``_pc                      ),\
    .instr                   (in                   ),\
    .prs1                    ('b0),\
    .prs2                    ('b0),\
    .prd                     ('b0),\
    .old_prd                 ('b0),\
    .ls_address              ('b0),\
    .alu_result              ('b0),\
    .bju_result              ('b0),\
    .muldiv_result           ('b0),\
    .opload_read_data_wb     ('b0),\
    .out_ready                (out``_ready),\
    .out_lrs1                (out``_lrs1),\
    .out_lrs2                (out``_lrs2),\
    .out_lrd                 (out``_lrd),\
    .out_imm                 (out``_imm),\
    .out_src1_is_reg         (out``_src1_is_reg),\
    .out_src2_is_reg         (out``_src2_is_reg),\
    .out_need_to_wb          (out``_need_to_wb),\
    .out_cx_type             (out``_cx_type),\
    .out_is_unsigned         (out``_is_unsigned),\
    .out_alu_type            (out``_alu_type),\
    .out_is_word             (out``_is_word),\
    .out_is_load             (out``_is_load),\
    .out_is_imm              (out``_is_imm),\
    .out_is_store            (out``_is_store),\
    .out_ls_size             (out``_ls_size),\
    .out_muldiv_type         (out``_muldiv_type),\
    .out_instr_valid         (out``_valid         ),\
    .out_pc                  (out``_pc                  ),\
    .out_instr               (out               ),\
    .out_prs1                (),\
    .out_prs2                (),\
    .out_prd                 (),\
    .out_old_prd             (),\
    .out_ls_address          (),\
    .out_alu_result          (),\
    .out_bju_result          (),\
    .out_muldiv_result       (),\
    .out_opload_read_data_wb ()\
);

`define PIPE_BEFORE_WB(out, in, clear)\
pipereg_2 u_pipereg_2(\
    .clock                   (clock),\
    .reset_n                 (reset_n),\
    .ready                   (in``_ready),\
    .lrs1                    (in``_lrs1),\
    .lrs2                    (in``_lrs2),\
    .lrd                     (in``_lrd),\
    .imm                     (in``_imm),\
    .src1_is_reg             (in``_src1_is_reg),\
    .src2_is_reg             (in``_src2_is_reg),\
    .need_to_wb              (in``_need_to_wb),\
    .cx_type                 (in``_cx_type),\
    .is_unsigned             (in``_is_unsigned),\
    .alu_type                (in``_alu_type),\
    .is_word                 (in``_is_word),\
    .is_load                 (in``_is_load),\
    .is_imm                  (in``_is_imm),\
    .is_store                (in``_is_store),\
    .ls_size                 (in``_ls_size),\
    .muldiv_type             (in``_muldiv_type),\
    .instr_valid             (in``_valid             ),\
    .pc                      (in``_pc                      ),\
    .instr                   (in                   ),\
    .prs1                    (in``_prs1                    ),\
    .prs2                    (in``_prs2                    ),\
    .prd                     (in``_prd                     ),\
    .old_prd                 (in``_old_prd                 ),\
    .ls_address              ('b0),\
    .alu_result              ('b0),\
    .bju_result              ('b0),\
    .muldiv_result           ('b0),\
    .opload_read_data_wb     ('b0),\
    .redirect_flush          (clear          ),\
    .out_ready                (out``_ready),\
    .out_lrs1                 (out``_lrs1                 ),\
    .out_lrs2                 (out``_lrs2                 ),\
    .out_lrd                  (out``_lrd                  ),\
    .out_imm                 (out``_imm                 ),\
    .out_src1_is_reg         (out``_src1_is_reg         ),\
    .out_src2_is_reg         (out``_src2_is_reg         ),\
    .out_need_to_wb          (out``_need_to_wb          ),\
    .out_cx_type             (out``_cx_type             ),\
    .out_is_unsigned         (out``_is_unsigned         ),\
    .out_alu_type            (out``_alu_type            ),\
    .out_is_word             (out``_is_word             ),\
    .out_is_load             (out``_is_load             ),\
    .out_is_imm              (out``_is_imm              ),\
    .out_is_store            (out``_is_store            ),\
    .out_ls_size             (out``_ls_size             ),\
    .out_muldiv_type         (out``_muldiv_type         ),\
    .out_instr_valid         (out``_valid         ),\
    .out_pc                  (out``_pc                  ),\
    .out_instr               (out               ),\
    .out_prs1                (out``_prs1                ),\
    .out_prs2                (out``_prs2                ),\
    .out_prd                 (out``_prd                 ),\
    .out_old_prd             (out``_old_prd             ),\
    .out_ls_address          (),\
    .out_alu_result          (),\
    .out_bju_result          (),\
    .out_muldiv_result       (),\
    .out_opload_read_data_wb ()\
);




`define BACK_UP(out, in, clear, pause)\
pipereg_2 u_pipereg_2(\
    .clock                   (clock                   ),\
    .reset_n                 (reset_n                 ),\
    .stall                   (pause                   ),\
    .lrs1                     (in``_lrs1                     ),\
    .lrs2                     (in``_lrs2                     ),\
    .lrd                      (in``_lrd                      ),\
    .imm                     (in``_imm                     ),\
    .src1_is_reg             (in``_src1_is_reg             ),\
    .src2_is_reg             (in``_src2_is_reg             ),\
    .need_to_wb              (in``_need_to_wb              ),\
    .cx_type                 (in``_cx_type                 ),\
    .is_unsigned             (in``_is_unsigned             ),\
    .alu_type                (in``_alu_type                ),\
    .is_word                 (in``_is_word                 ),\
    .is_load                 (in``_is_load                 ),\
    .is_imm                  (in``_is_imm                  ),\
    .is_store                (in``_is_store                ),\
    .ls_size                 (in``_ls_size                 ),\
    .muldiv_type             (in``_muldiv_type             ),\
    .instr_valid             (in``_valid             ),\
    .pc                      (in``_pc                      ),\
    .instr                   (in                   ),\
    .prs1                    (in``_prs1                    ),\
    .prs2                    (in``_prs2                    ),\
    .prd                     (in``_prd                     ),\
    .old_prd                 (in``_old_prd                 ),\
    .ls_address              (in``_ls_address              ),\
    .alu_result              (in``_alu_result              ),\
    .bju_result              (in``_bju_result              ),\
    .muldiv_result           (in``_muldiv_result           ),\
    .opload_read_data_wb     (in``_opload_read_data_wb     ),\
    .redirect_flush          (clear          ),\
    .out_lrs1                 (in``_lrs1                 ),\
    .out_lrs2                 (in``_lrs2                 ),\
    .out_lrd                  (in``_lrd                  ),\
    .out_imm                 (in``_imm                 ),\
    .out_src1_is_reg         (in``_src1_is_reg         ),\
    .out_src2_is_reg         (in``_src2_is_reg         ),\
    .out_need_to_wb          (in``_need_to_wb          ),\
    .out_cx_type             (in``_cx_type             ),\
    .out_is_unsigned         (in``_is_unsigned         ),\
    .out_alu_type            (in``_alu_type            ),\
    .out_is_word             (in``_is_word             ),\
    .out_is_load             (in``_is_load             ),\
    .out_is_imm              (in``_is_imm              ),\
    .out_is_store            (in``_is_store            ),\
    .out_ls_size             (in``_ls_size             ),\
    .out_muldiv_type         (in``_muldiv_type         ),\
    .out_instr_valid         (in``_valid         ),\
    .out_pc                  (in``_pc                  ),\
    .out_instr               (in               ),\
    .out_prs1                (in``_prs1                ),\
    .out_prs2                (in``_prs2                ),\
    .out_prd                 (in``_prd                 ),\
    .out_old_prd             (in``_old_prd             ),\
    .out_ls_address          (in``_ls_address          ),\
    .out_alu_result          (in``_alu_result          ),\
    .out_bju_result          (in``_bju_result          ),\
    .out_muldiv_result       (in``_muldiv_result       ),\
    .out_opload_read_data_wb (in``_opload_read_data_wb )\
);
