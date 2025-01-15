`include "defines.sv"
module core_top #(
) (
    input wire clock,
    input wire reset_n,

    // DDR Control Inputs and Outputs
    output wire         ddr_chip_enable,     // Enables chip for one cycle when a channel is selected
    output wire [ 63:0] ddr_index,           // 19-bit selected index to be sent to DDR
    output wire         ddr_write_enable,    // Write enable signal (1 for write, 0 for read)
    output wire         ddr_burst_mode,      // Burst mode signal, 1 when pc_index is selected
    output wire [511:0] ddr_write_mask,      // Output write mask for opstore channel
    output wire [511:0] ddr_write_data,      // Output write data for opstore channel
    input  wire [511:0] ddr_read_data,       // 64-bit data output for lw channel read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready,           // Indicates if DDR is ready for new operation
    output reg          flop_commit_valid
);


    wire                               chip_enable = 1'b1;

    //redirect
    wire                               redirect_valid;
    wire [                  `PC_RANGE] redirect_target;
    //mem stall
    wire                               mem_stall;
    // PC Channel Inputs and Outputs
    wire                               pc_index_valid;  // Valid signal for pc_index
    wire [                       63:0] pc_index;  // 64-bit input for pc_index (Channel 1)
    wire                               pc_index_ready;  // Ready signal for pc channel
    wire [`ICACHE_FETCHWIDTH128_RANGE] pc_read_inst;  // Output burst read data for pc channel
    wire                               pc_operation_done;
    //trinity bus channel:lsu to dcache
    wire                               tbus_index_valid;
    wire                               tbus_index_ready;
    wire [              `RESULT_RANGE] tbus_index;
    wire [                 `SRC_RANGE] tbus_write_data;
    wire [                       63:0] tbus_write_mask;

    wire [              `RESULT_RANGE] tbus_read_data;
    wire                               tbus_operation_done;
    wire [         `TBUS_OPTYPE_RANGE] tbus_operation_type;


    reg                                dcache2arb_dbus_index_valid;
    wire                               dcache2arb_dbus_index_ready;
    reg  [              `RESULT_RANGE] dcache2arb_dbus_index;
    reg  [                 `SRC_RANGE] dcache2arb_dbus_write_data;
    reg  [                 `SRC_RANGE] dcache2arb_dbus_write_mask;
    wire [        `CACHELINE512_RANGE] dcache2arb_dbus_read_data;
    wire                               dcache2arb_dbus_operation_done;
    wire [         `TBUS_OPTYPE_RANGE] dcache2arb_dbus_operation_type;
    wire                               dcache2arb_dbus_burst_mode;


    reg                                icache2arb_dbus_index_valid;
    wire                               icache2arb_dbus_index_ready;
    reg  [              `RESULT_RANGE] icache2arb_dbus_index;
    reg  [                 `SRC_RANGE] icache2arb_dbus_write_data;
    reg  [                 `SRC_RANGE] icache2arb_dbus_write_mask;
    wire [        `CACHELINE512_RANGE] icache2arb_dbus_read_data;
    wire                               icache2arb_dbus_operation_done;
    wire [         `TBUS_OPTYPE_RANGE] icache2arb_dbus_operation_type;
    wire                               icache2arb_dbus_burst_mode;



    dcache u_dcache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (redirect_valid),
        //tbus channel from backend lsu (mem.v)
        .tbus_index_valid              (tbus_index_valid),
        .tbus_index_ready              (tbus_index_ready),
        .tbus_index                    (tbus_index),
        .tbus_write_data               (tbus_write_data),
        .tbus_write_mask               (tbus_write_mask),
        .tbus_read_data                (tbus_read_data),
        .tbus_operation_done           (tbus_operation_done),
        .tbus_operation_type           (tbus_operation_type),
        // dcache channel for lsu operation
        .dcache2arb_dbus_index_valid   (dcache2arb_dbus_index_valid),
        .dcache2arb_dbus_index_ready   (dcache2arb_dbus_index_ready),
        .dcache2arb_dbus_index         (dcache2arb_dbus_index),
        .dcache2arb_dbus_write_data    (dcache2arb_dbus_write_data),
        .dcache2arb_dbus_write_mask    (dcache2arb_dbus_write_mask),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type)
    );

    icache u_icache (
        .clock                         (clock),
        .reset_n                       (reset_n),
        .flush                         (redirect_valid),
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
        .icache2arb_dbus_write_mask    (icache2arb_dbus_write_mask),
        .icache2arb_dbus_read_data     (icache2arb_dbus_read_data),
        .icache2arb_dbus_operation_done(icache2arb_dbus_operation_done),
        .icache2arb_dbus_operation_type()
    );

    frontend u_frontend (
        .clock              (clock),
        .reset_n            (reset_n),
        .redirect_valid     (redirect_valid),
        .redirect_target    (redirect_target),
        .pc_index_valid     (pc_index_valid),
        .pc_index_ready     (pc_index_ready),
        .pc_operation_done  (pc_operation_done),
        .pc_read_inst       (pc_read_inst),
        .pc_index           (pc_index),
        .fifo_read_en       (~mem_stall),           //when mem stall,ibuf can not to read instr anymore!
        //to backend
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .mem_stall(mem_stall)

    );


    backend u_backend (
        .clock              (clock),
        .reset_n            (reset_n),
        .ibuffer_instr_valid(ibuffer_instr_valid),
        .ibuffer_inst_out   (ibuffer_inst_out),
        .ibuffer_pc_out     (ibuffer_pc_out),
        .redirect_valid     (redirect_valid),
        .redirect_target    (redirect_target),
        .mem_stall          (mem_stall),
        .tbus_index_valid   (tbus_index_valid),
        .tbus_index_ready   (tbus_index_ready),
        .tbus_index         (tbus_index),
        .tbus_write_data    (tbus_write_data),
        .tbus_write_mask    (tbus_write_mask),
        .tbus_read_data     (tbus_read_data),
        .tbus_operation_done(tbus_operation_done),
        .tbus_operation_type(tbus_operation_type),
        .flop_commit_valid  (flop_commit_valid)
    );



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
        .dcache2arb_dbus_write_mask    (dcache2arb_dbus_write_mask),
        .dcache2arb_dbus_read_data     (dcache2arb_dbus_read_data),
        .dcache2arb_dbus_operation_done(dcache2arb_dbus_operation_done),
        .dcache2arb_dbus_operation_type(dcache2arb_dbus_operation_type),
        //ddr channel
        .ddr_chip_enable               (ddr_chip_enable),
        .ddr_index                     (ddr_index),
        .ddr_write_enable              (ddr_write_enable),
        .ddr_burst_mode                (ddr_burst_mode),
        .ddr_write_mask                (ddr_write_mask),
        .ddr_write_data                (ddr_write_data),
        .ddr_read_data                 (ddr_read_data),
        .ddr_operation_done            (ddr_operation_done),
        .ddr_ready                     (ddr_ready)
        //.redirect_valid     (redirect_valid)
    );



endmodule
