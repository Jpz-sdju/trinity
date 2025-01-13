module SimTop (
    input  wire       reset,
    input  wire       clock,
    input  wire       difftest_logCtrl_begin,
    input  wire       difftest_logCtrl_end,
    output wire       difftest_uart_out_valid,
    output wire [7:0] difftest_uart_out_ch,
    input  wire       difftest_uart_in_valid,
    input  wire [7:0] difftest_uart_in_ch,

    input wire difftest_perfCtrl_clean,
    input wire difftest_perfCtrl_dump,

    output wire difftest_exit,
    output wire difftest_step

);
    assign difftest_step           = 1'b1;
    assign difftest_exit           = 1'b0;
    assign difftest_uart_out_ch    = 8'b0;
    assign difftest_uart_out_valid = 1'b0;



    // DDR Control Inputs and Outputs
    wire         ddr_chip_enable;  // Enables chip for one cycle when a channel is selected
    wire [ 63:0] ddr_index;  // 19-bit selected index to be sent to DDR
    wire         ddr_write_enable;  // Write enable signal (1 for write; 0 for read)
    wire         ddr_burst_mode;  // Burst mode signal; 1 when pc_index is selected
    wire [ 511:0] ddr_write_mask;  // Output write mask for opstore channel
    wire [ 511:0] ddr_write_data;  // Output write data for opstore channel
    wire [ 511:0] ddr_read_data;  // 64-bit data output for lw channel read
    wire         ddr_operation_done;
    wire         ddr_ready;  // Indicates if DDR is ready for new operation
    wire         flop_commit_valid;
    reg  [ 63:0] commit_valid_cnt;

    always @(posedge clock or negedge reset) begin
        if (reset) begin
            commit_valid_cnt <= 0;
        end else if (flop_commit_valid) begin
            commit_valid_cnt <= commit_valid_cnt + 1;
        end
    end

    core_top u_core_top (
        .clock                 (clock),
        .reset_n               (~reset),
        .ddr_chip_enable       (ddr_chip_enable),
        .ddr_index             (ddr_index),
        .ddr_write_enable      (ddr_write_enable),
        .ddr_burst_mode        (ddr_burst_mode),
        .ddr_write_mask(ddr_write_mask),
        .ddr_write_data(ddr_write_data),
        .ddr_read_data  (ddr_read_data),
        .ddr_operation_done    (ddr_operation_done),
        .ddr_ready             (ddr_ready),
        .flop_commit_valid     (flop_commit_valid)
    );




    simddr u_simddr (
        .clock             (clock),
        .reset_n           (~reset),
        .ddr_chip_enable   (ddr_chip_enable),
        .ddr_index         (ddr_index),
        .ddr_write_enable  (ddr_write_enable),
        .ddr_burst_mode    (ddr_burst_mode),
        .ddr_write_mask    (ddr_write_mask),
        .ddr_write_data    (ddr_write_data),
        .ddr_read_data     (ddr_read_data),
        .ddr_operation_done(ddr_operation_done),
        .ddr_ready         (ddr_ready)
    );


    reg [63:0] cycle_cnt;
    always @(posedge clock) begin
        if (reset) begin
            cycle_cnt <= 'b0;
        end else begin
            cycle_cnt <= cycle_cnt + 1'b1;
        end

    end
    DifftestTrapEvent u_DifftestTrapEvent (
        .clock      (clock),
        .enable     (1'b1),
        .io_hasTrap (1'b0),
        .io_cycleCnt(cycle_cnt),
        .io_instrCnt(commit_valid_cnt),
        .io_hasWFI  ('b0),
        .io_code    ('b0),
        .io_pc      ('b0),
        .io_coreid  ('b0)
    );


    DifftestArchEvent u_DifftestArchEvent (
        .clock                            (clock),
        .enable                           (1'b0),
        .io_valid                         ('b0),
        .io_interrupt                     ('b0),
        .io_exception                     ('b0),
        .io_exceptionPC                   ('b0),
        .io_exceptionInst                 ('b0),
        .io_hasNMI                        ('b0),
        .io_virtualInterruptIsHvictlInject('b0),
        .io_coreid                        (1'b0)
    );

    DifftestCSRState u_DifftestCSRState (
        .clock           (clock),
        .enable          (1'b1),
        .io_privilegeMode('b0),
        .io_mstatus      ('b0),
        .io_sstatus      ('b0),
        .io_mepc         ('b0),
        .io_sepc         ('b0),
        .io_mtval        ('b0),
        .io_stval        ('b0),
        .io_mtvec        ('b0),
        .io_stvec        ('b0),
        .io_mcause       ('b0),
        .io_scause       ('b0),
        .io_satp         ('b0),
        .io_mip          ('b0),
        .io_mie          ('b0),
        .io_mscratch     ('b0),
        .io_sscratch     ('b0),
        .io_mideleg      ('b0),
        .io_medeleg      ('b0),
        .io_coreid       ('b0)
    );



endmodule
