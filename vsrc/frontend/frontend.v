module frontend (
    input wire clock,
    input wire reset_n,

    // PC control inputs
    input wire             redirect_valid,
    input wire [`PC_RANGE] redirect_target,

    output wire                               pc_index_valid,
    input  wire                               pc_index_ready,
    input  wire                               pc_operation_done,
    input  wire [`ICACHE_FETCHWIDTH128_RANGE] pc_read_inst,
    output wire [                       63:0] pc_index,

    // Instruction buffer inputs
    input wire ibuffer_instr_ready,  //fifo_read_en，signal from backend to enable fifo read 128bit instrs

    // ibuffer outputs
    output wire        ibuffer_instr_valid,
    output wire [31:0] ibuffer_inst_out,
    output wire [63:0] ibuffer_pc_out,
    output wire        ibuffer_predicttaken_out,
    output wire [31:0] ibuffer_predicttarget_out,



    // BHT Write Interface
    input wire       commit0_bht_write_enable,
    input wire [8:0] commit0_bht_write_index,
    input wire [1:0] commit0_bht_write_counter_select,
    input wire       commit0_bht_write_inc,
    input wire       commit0_bht_write_dec,
    input wire       commit0_bht_valid_in,

    // BTB Write Interface
    input wire         commit0_btb_ce,
    input wire         commit0_btb_we,
    input wire [128:0] commit0_btb_wmask,
    input wire [  8:0] commit0_btb_write_index,
    input wire [128:0] commit0_btb_din,
    input wire         end_of_program

);
    wire backend_stall = ~ibuffer_instr_ready;
    wire fifo_empty;  //for debug

    // Instance of the ifu module
    ifu_top u_ifu_top (
        .clock                    (clock),
        .reset_n                  (reset_n),
        .boot_addr                (64'h80000000),
        .interrupt_valid          (1'd0),
        .interrupt_addr           (64'd0),
        .redirect_valid           (redirect_valid),
        .redirect_target          (redirect_target),
        .pc_index_valid           (pc_index_valid),
        .pc_index_ready           (pc_index_ready),
        .pc_operation_done        (pc_operation_done),
        .pc_read_inst             (pc_read_inst),
        .ibuffer_instr_ready      (ibuffer_instr_ready),
        .ibuffer_instr_valid      (ibuffer_instr_valid),
        .ibuffer_inst_out         (ibuffer_inst_out),
        .ibuffer_pc_out           (ibuffer_pc_out),
        .pc_index                 (pc_index),
        .ibuffer_predicttaken_out (ibuffer_predicttaken_out),
        .ibuffer_predicttarget_out(ibuffer_predicttarget_out),
        .fifo_empty               (fifo_empty),
        .backend_stall            (backend_stall),
        //intwb bht btb signal
        .bht_write_enable         (commit0_bht_write_enable),
        .bht_write_index          (commit0_bht_write_index),
        .bht_write_counter_select (commit0_bht_write_counter_select),
        .bht_write_inc            (commit0_bht_write_inc),
        .bht_write_dec            (commit0_bht_write_dec),
        .bht_valid_in             (commit0_bht_valid_in),
        .btb_ce                   (commit0_btb_ce),
        .btb_we                   (commit0_btb_we),
        .btb_wmask                (commit0_btb_wmask),
        .btb_write_index          (commit0_btb_write_index),
        .btb_din                  (commit0_btb_din),
        .end_of_program           (end_of_program)

    );

endmodule
