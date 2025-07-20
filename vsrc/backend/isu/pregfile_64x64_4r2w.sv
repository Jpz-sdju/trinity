`include "defines.sv"
module pregfile_64x64_4r2w (
    input  wire         clock,
    input  wire         reset_n,    // Active-low reset

    // Write port 0
    input  wire         wren0,        // Write enable for port 0
    input  wire [5:0]   waddr0,       // Write address for port 0
    input  wire [63:0]  wdata0,       // Write data for port 0

    // Write port 1
    input  wire         wren1,        // Write enable for port 1
    input  wire [5:0]   waddr1,       // Write address for port 1
    input  wire [63:0]  wdata1,       // Write data for port 1

    // Read port 0
    input  wire         rden0,        // Read enable for port 0
    input  wire [5:0]   raddr0,       // Read address for port 0
    output wire [63:0]  rdata0,       // Read data for port 0

    // Read port 1
    input  wire         rden1,        // Read enable for port 1
    input  wire [5:0]   raddr1,       // Read address for port 1
    output wire [63:0]  rdata1,       // Read data for port 1
    
    // Read port 2
    input  wire         rden2,        // Read enable for port 2
    input  wire [5:0]   raddr2,       // Read address for port 2
    output wire [63:0]  rdata2,       // Read data for port 2

    // Read port 3
    input  wire         rden3,        // Read enable for port 3
    input  wire [5:0]   raddr3,       // Read address for port 3
    output wire [63:0]  rdata3,       // Read data for port 3
    
    //debug signals (unchanged)
    input wire [`PREG_RANGE] debug_preg0,
    input wire [`PREG_RANGE] debug_preg1,
    input wire [`PREG_RANGE] debug_preg2,
    input wire [`PREG_RANGE] debug_preg3,
    input wire [`PREG_RANGE] debug_preg4,
    input wire [`PREG_RANGE] debug_preg5,
    input wire [`PREG_RANGE] debug_preg6,
    input wire [`PREG_RANGE] debug_preg7,
    input wire [`PREG_RANGE] debug_preg8,
    input wire [`PREG_RANGE] debug_preg9,
    input wire [`PREG_RANGE] debug_preg10,
    input wire [`PREG_RANGE] debug_preg11,
    input wire [`PREG_RANGE] debug_preg12,
    input wire [`PREG_RANGE] debug_preg13,
    input wire [`PREG_RANGE] debug_preg14,
    input wire [`PREG_RANGE] debug_preg15,
    input wire [`PREG_RANGE] debug_preg16,
    input wire [`PREG_RANGE] debug_preg17,
    input wire [`PREG_RANGE] debug_preg18,
    input wire [`PREG_RANGE] debug_preg19,
    input wire [`PREG_RANGE] debug_preg20,
    input wire [`PREG_RANGE] debug_preg21,
    input wire [`PREG_RANGE] debug_preg22,
    input wire [`PREG_RANGE] debug_preg23,
    input wire [`PREG_RANGE] debug_preg24,
    input wire [`PREG_RANGE] debug_preg25,
    input wire [`PREG_RANGE] debug_preg26,
    input wire [`PREG_RANGE] debug_preg27,
    input wire [`PREG_RANGE] debug_preg28,
    input wire [`PREG_RANGE] debug_preg29,
    input wire [`PREG_RANGE] debug_preg30,
    input wire [`PREG_RANGE] debug_preg31
);

    // 64 registers, each 64 bits wide
    reg [63:0] pregfile [63:0];
    
    integer i;

    //====================================================================
    // 1) WRITE LOGIC + RESET (SYNCHRONOUS)
    //====================================================================
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Asynchronously reset all registers to 0
            for (i = 0; i < 64; i = i + 1) begin
                pregfile[i] <= 64'b0;
            end
        end
        else begin
            if (wren0 && (waddr0 != 6'b0)) begin
                pregfile[waddr0] <= wdata0;
            end
            if (wren1 && (waddr1 != 6'b0)) begin
                pregfile[waddr1] <= wdata1;
            end
        end
    end

    //====================================================================
    // 2) RAW (UN-BYPASSED) READS (ASYNCHRONOUS)
    //====================================================================
    wire [63:0] raw_data0 = pregfile[raddr0];
    wire [63:0] raw_data1 = pregfile[raddr1];
    wire [63:0] raw_data2 = pregfile[raddr2];
    wire [63:0] raw_data3 = pregfile[raddr3];

    //====================================================================
    // 3) HAZARD BYPASS (FORWARDING) LOGIC
    //====================================================================
    wire [63:0] bypassed_data0 = (wren1 && (waddr1 == raddr0) && (waddr1 != 6'b0)) ? wdata1 :
                                 (wren0 && (waddr0 == raddr0) && (waddr0 != 6'b0)) ? wdata0 :
                                  raw_data0;

    wire [63:0] bypassed_data1 = (wren1 && (waddr1 == raddr1) && (waddr1 != 6'b0)) ? wdata1 :
                                 (wren0 && (waddr0 == raddr1) && (waddr0 != 6'b0)) ? wdata0 :
                                  raw_data1;

    // Bypass logic for read port 2
    wire [63:0] bypassed_data2 = (wren1 && (waddr1 == raddr2) && (waddr1 != 6'b0)) ? wdata1 :
                                 (wren0 && (waddr0 == raddr2) && (waddr0 != 6'b0)) ? wdata0 :
                                  raw_data2;

    // Bypass logic for read port 3
    wire [63:0] bypassed_data3 = (wren1 && (waddr1 == raddr3) && (waddr1 != 6'b0)) ? wdata1 :
                                 (wren0 && (waddr0 == raddr3) && (waddr0 != 6'b0)) ? wdata0 :
                                  raw_data3;

    //====================================================================
    // 4) READ ENABLE GATING
    //====================================================================
    assign rdata0 = rden0 ? bypassed_data0 : 64'b0;
    assign rdata1 = rden1 ? bypassed_data1 : 64'b0;
    assign rdata2 = rden2 ? bypassed_data2 : 64'b0;
    assign rdata3 = rden3 ? bypassed_data3 : 64'b0;

    /* verilator lint_off LATCH */
    DifftestArchIntRegState u_DifftestArchIntRegState (
        .clock      (clock),
        .enable     (1'b1),
        .io_value_0 (pregfile[debug_preg0]),//debug_preg0: physical reg number of arch reg 0
        .io_value_1 (pregfile[debug_preg1]),
        .io_value_2 (pregfile[debug_preg2]),
        .io_value_3 (pregfile[debug_preg3]),
        .io_value_4 (pregfile[debug_preg4]),
        .io_value_5 (pregfile[debug_preg5]),
        .io_value_6 (pregfile[debug_preg6]),
        .io_value_7 (pregfile[debug_preg7]),
        .io_value_8 (pregfile[debug_preg8]),
        .io_value_9 (pregfile[debug_preg9]),
        .io_value_10(pregfile[debug_preg10]),
        .io_value_11(pregfile[debug_preg11]),
        .io_value_12(pregfile[debug_preg12]),
        .io_value_13(pregfile[debug_preg13]),
        .io_value_14(pregfile[debug_preg14]),
        .io_value_15(pregfile[debug_preg15]),
        .io_value_16(pregfile[debug_preg16]),
        .io_value_17(pregfile[debug_preg17]),
        .io_value_18(pregfile[debug_preg18]),
        .io_value_19(pregfile[debug_preg19]),
        .io_value_20(pregfile[debug_preg20]),
        .io_value_21(pregfile[debug_preg21]),
        .io_value_22(pregfile[debug_preg22]),
        .io_value_23(pregfile[debug_preg23]),
        .io_value_24(pregfile[debug_preg24]),
        .io_value_25(pregfile[debug_preg25]),
        .io_value_26(pregfile[debug_preg26]),
        .io_value_27(pregfile[debug_preg27]),
        .io_value_28(pregfile[debug_preg28]),
        .io_value_29(pregfile[debug_preg29]),
        .io_value_30(pregfile[debug_preg30]),
        .io_value_31(pregfile[debug_preg31]),
        .io_coreid  ('b0)
    );

endmodule
