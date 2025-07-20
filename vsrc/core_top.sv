`include "defines.sv"
module core_top #(
    parameter BHTBTB_INDEX_WIDTH = 9  // Width of the set index (for SETS=512, BHTBTB_INDEX_WIDTH=9)
) (
    input wire clock,
    input wire reset_n,

    // DDR Control Inputs and Outputs
    output wire         ddr_chip_enable,     // Enables chip for one cycle when a channel is selected
    output wire [ 63:0] ddr_index,           // 19-bit selected index to be sent to DDR
    output wire         ddr_write_enable,    // Write enable signal (1 for write, 0 for read)
    output wire         ddr_burst_mode,      // Burst mode signal, 1 when pc_index is selected
    output wire [511:0] ddr_write_data,      // Output write data for opstore channel
    input  wire [511:0] ddr_read_data,       // 64-bit data output for lw channel read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready
);

    // ibuffer outputs
    wire                               ibuffer_instr_valid;
    wire                               ibuffer_instr_ready;
    wire [                       31:0] ibuffer_inst_out;
    wire [                       63:0] ibuffer_pc_out;
    wire                               ibuffer_predicttaken_out;
    wire [                       31:0] ibuffer_predicttarget_out;
    //bhtbtb write interface
    wire                               intwb_bht_write_enable;
    wire [     BHTBTB_INDEX_WIDTH-1:0] intwb_bht_write_index;
    wire [                        1:0] intwb_bht_write_counter_select;
    wire                               intwb_bht_write_inc;
    wire                               intwb_bht_write_dec;
    wire                               intwb_bht_valid_in;
    wire                               intwb_btb_ce;  // Chip enable
    wire                               intwb_btb_we;  // Write enable
    wire [                      128:0] intwb_btb_wmask;
    wire [                        8:0] intwb_btb_write_index;  // Write address (9 bits for 512 sets)
    wire [                      128:0] intwb_btb_din;  // Data input (1 valid bit + 4 targets * 32 bits)

    //redirect
    wire                               flush_valid;
    wire [                  `PC_RANGE] flush_target;

    // PC Channel Inputs and Outputs
    wire                               pc_index_valid;  // Valid signal for pc_index
    wire [                       63:0] pc_index;  // 64-bit input for pc_index (Channel 1)
    wire                               pc_index_ready;  // Ready signal for pc channel
    wire [`ICACHE_FETCHWIDTH128_RANGE] pc_read_inst;  // Output burst read data for pc channel
    wire                               pc_operation_done;



    /* ---------------------- dcache to arb to memory or l2 --------------------- */

    wire                               dcache2arb_dbus_index_valid;
    wire                               dcache2arb_dbus_index_ready;
    wire [              `RESULT_RANGE] dcache2arb_dbus_index;
    wire [        `CACHELINE512_RANGE] dcache2arb_dbus_write_data;
    wire [        `CACHELINE512_RANGE] dcache2arb_dbus_read_data;
    wire                               dcache2arb_dbus_operation_done;
    wire [         `TBUS_OPTYPE_RANGE] dcache2arb_dbus_operation_type;
    wire                               dcache2arb_dbus_burst_mode;

    reg                                icache2arb_dbus_index_valid;
    wire                               icache2arb_dbus_index_ready;
    reg  [              `RESULT_RANGE] icache2arb_dbus_index;
    reg  [        `CACHELINE512_RANGE] icache2arb_dbus_write_data;
    reg  [                 `SRC_RANGE] icache2arb_dbus_write_mask;
    wire [        `CACHELINE512_RANGE] icache2arb_dbus_read_data;
    wire                               icache2arb_dbus_operation_done;
    wire [         `TBUS_OPTYPE_RANGE] icache2arb_dbus_operation_type;
    wire                               icache2arb_dbus_burst_mode;

    wire                               end_of_program;

    /* -------------------------------------------------------------------------- */
    /*                             channel_arb / icache / dcache                  */
    /* -------------------------------------------------------------------------- */
    channel_arb u_channel_arb (
        .clock                         (clock),
        .reset_n                       (reset_n),
        //icache channel
        .icache2arb_dbus_index_valid   (icache2arb_dbus_index_valid),
        .icache2arb_dbus_index         (icache2arb_dbus_index),
        .icache2arb_dbus_index_ready   (icache2arb_dbus_index_ready),
        .icache2arb_dbus_read_data     (icache2arb_dbus_read_data),
        .icache2arb_dbus_operation_done(icache2arb_dbus_operation_done),
        //dcache channel
        .dcache2arb_dbus_index_valid   (dcache2arb_dbus_index_valid),
        .dcache2arb_dbus_index_ready   (dcache2arb_dbus_index_ready),
        .dcache2arb_dbus_index         (dcache2arb_dbus_index),
        .dcache2arb_dbus_write_data    (dcache2arb_dbus_write_data),
        //.dcache2arb_dbus_write_mask      (dcache2arb_dbus_write_mask     ),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type),
        //ddr channel
        .ddr_chip_enable               (ddr_chip_enable),
        .ddr_index                     (ddr_index),
        .ddr_write_enable              (ddr_write_enable),
        .ddr_burst_mode                (ddr_burst_mode),
        .ddr_write_data                (ddr_write_data),
        .ddr_read_data                 (ddr_read_data),
        .ddr_operation_done            (ddr_operation_done),
        .ddr_ready                     (ddr_ready)
    );


    icache u_icache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (flush_valid),
        //tbus channel from pc_ctrl
        .tbus_index_valid              (pc_index_valid),
        .tbus_index_ready              (pc_index_ready),
        .tbus_index                    (pc_index),
        .tbus_write_data               ('b0),
        .tbus_write_mask               ('b0),
        .tbus_read_data                (pc_read_inst),
        .tbus_operation_done           (pc_operation_done),
        .tbus_operation_type           (2'b00),
        //icache channel for reading inst from ddr
        .icache2arb_dbus_index_valid   (icache2arb_dbus_index_valid),
        .icache2arb_dbus_index_ready   (icache2arb_dbus_index_ready),
        .icache2arb_dbus_index         (icache2arb_dbus_index),
        .icache2arb_dbus_write_data    (icache2arb_dbus_write_data),
        .icache2arb_dbus_read_data     (icache2arb_dbus_read_data),
        .icache2arb_dbus_operation_done(icache2arb_dbus_operation_done),
        .icache2arb_dbus_operation_type()
    );

    /* -------------------------------------------------------------------------- */
    /*                                     frontend                               */
    /* -------------------------------------------------------------------------- */

    frontend u_frontend (
        .clock                         (clock),
        .reset_n                       (reset_n),
        //redirect
        .redirect_valid                (flush_valid),
        .redirect_target               (flush_target),
        //instr fetch from ddr
        .pc_index_valid                (pc_index_valid),
        .pc_index_ready                (pc_index_ready),
        .pc_operation_done             (pc_operation_done),
        .pc_read_inst                  (pc_read_inst),
        .pc_index                      (pc_index),
        //output to backend
        .ibuffer_instr_ready           (ibuffer_instr_ready),
        .ibuffer_instr_valid           (ibuffer_instr_valid),
        .ibuffer_inst_out              (ibuffer_inst_out),
        .ibuffer_pc_out                (ibuffer_pc_out),
        .ibuffer_predicttaken_out      (ibuffer_predicttaken_out),
        .ibuffer_predicttarget_out     (ibuffer_predicttarget_out),
        //bht btb signals
        .intwb_bht_write_enable        (intwb_bht_write_enable),
        .intwb_bht_write_index         (intwb_bht_write_index),
        .intwb_bht_write_counter_select(intwb_bht_write_counter_select),
        .intwb_bht_write_inc           (intwb_bht_write_inc),
        .intwb_bht_write_dec           (intwb_bht_write_dec),
        .intwb_bht_valid_in            (intwb_bht_valid_in),
        .intwb_btb_ce                  (intwb_btb_ce),
        .intwb_btb_we                  (intwb_btb_we),
        .intwb_btb_wmask               (intwb_btb_wmask),
        .intwb_btb_write_index         (intwb_btb_write_index),
        .intwb_btb_din                 (intwb_btb_din),
        .end_of_program                (end_of_program)
    );


    /* -------------------------------------------------------------------------- */
    /*                                   backend                                  */
    /* -------------------------------------------------------------------------- */

    backend u_backend (
        .clock                    (clock),
        .reset_n                  (reset_n),
        .ibuffer_instr_valid      (ibuffer_instr_valid),
        .ibuffer_instr_ready      (ibuffer_instr_ready),
        .ibuffer_predicttaken_out (ibuffer_predicttaken_out),
        .ibuffer_predicttarget_out(ibuffer_predicttarget_out),
        .ibuffer_inst_out         (ibuffer_inst_out),
        .ibuffer_pc_out           (ibuffer_pc_out),
        .flush_valid              (flush_valid),
        .flush_target             (flush_target),
        .tbus_index_valid         (tbus_index_valid),
        .tbus_index_ready         (tbus_index_ready),
        .tbus_index               (tbus_index),
        .tbus_write_data          (tbus_write_data),
        .tbus_write_mask          (tbus_write_mask),
        .tbus_read_data           (tbus_read_data),
        .tbus_operation_done      (tbus_operation_done),
        .tbus_operation_type      (tbus_operation_type),
        .arb2dcache_flush_valid   (arb2dcache_flush_valid),

        .intwb0_bht_write_enable        (intwb_bht_write_enable),
        .intwb0_bht_write_index         (intwb_bht_write_index),
        .intwb0_bht_write_counter_select(intwb_bht_write_counter_select),
        .intwb0_bht_write_inc           (intwb_bht_write_inc),
        .intwb0_bht_write_dec           (intwb_bht_write_dec),
        .intwb0_bht_valid_in            (intwb_bht_valid_in),
        .intwb0_btb_ce                  (intwb_btb_ce),
        .intwb0_btb_we                  (intwb_btb_we),
        .intwb0_btb_wmask               (intwb_btb_wmask),
        .intwb0_btb_write_index         (intwb_btb_write_index),
        .intwb0_btb_din                 (intwb_btb_din),
        .end_of_program                 (end_of_program),

        .dcache2arb_dbus_index_valid   (dcache2arb_dbus_index_valid),
        .dcache2arb_dbus_index_ready   (dcache2arb_dbus_index_ready),
        .dcache2arb_dbus_index         (dcache2arb_dbus_index),
        .dcache2arb_dbus_write_data    (dcache2arb_dbus_write_data),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type),
        .dcache2arb_dbus_burst_mode    (dcache2arb_dbus_burst_mode)
    );


endmodule
