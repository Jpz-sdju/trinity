`include "defines.sv"
module memblock (
    input  wire                     clock,
    input  wire                     reset_n,
    input  wire                     instr_valid,
    output wire                     instr_ready,
    input  wire [      `PREG_RANGE] prd,
    input  wire                     is_load,
    input  wire                     is_store,
    input  wire                     is_unsigned,
    input  wire [       `SRC_RANGE] imm,
    input  wire [       `SRC_RANGE] src1,
    input  wire [       `SRC_RANGE] src2,
    input  wire [   `LS_SIZE_RANGE] ls_size,
    input  wire                     robidx_flag,
    input  wire [`ROB_SIZE_LOG-1:0] robidx,

    //trinity bus channel
    output reg                  tbus_index_valid,
    input  wire                 tbus_index_ready,
    output reg  [`RESULT_RANGE] tbus_index,
    output reg  [   `SRC_RANGE] tbus_write_data,
    output reg  [         63:0] tbus_write_mask,

    input  wire [     `RESULT_RANGE] tbus_read_data,
    input  wire                      tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] tbus_operation_type,

    /* --------------------------- output to writeback -------------------------- */
    output wire               out_instr_valid,
    output wire               out_need_to_wb,
    output wire [`PREG_RANGE] out_prd,
    output wire               out_mmio,

    output wire                     out_robidx_flag,
    output wire [`ROB_SIZE_LOG-1:0] out_robidx,
    //read data to wb stage
    output wire [    `RESULT_RANGE] opload_read_data_wb,
    //mem stall
    output wire                     mem_stall,
    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                     flush_valid,
    input  wire                     flush_robidx_flag,
    input  wire [`ROB_SIZE_LOG-1:0] flush_robidx,

    /* --------------------------- memblock to dcache --------------------------- */
    output wire memblock2dcache_flush


);


    //redirect flush logic 
    wire need_flush;
    wire flush_this_beat;
    wire flush_outstanding;
    assign flush_this_beat       = instr_valid & flush_valid & ((flush_robidx_flag ^ robidx_flag) ^ (flush_robidx < robidx));
    assign flush_outstanding     = (~is_idle) & flush_valid & ((flush_robidx_flag ^ out_robidx_flag) ^ (flush_robidx < out_robidx));
    assign need_flush            = flush_this_beat | flush_outstanding;

    assign memblock2dcache_flush = need_flush;

    wire [`RESULT_RANGE] ls_address;
    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );

    localparam IDLE = 2'b00;
    localparam PENDING = 2'b01;
    localparam OUTSTANDING = 2'b10;
    localparam TEMP = 2'b11;
    reg  [1:0] ls_state;
    wire       is_idle = ls_state == IDLE;
    wire       is_pending = ls_state == PENDING;
    wire       is_outstanding = ls_state == OUTSTANDING;
    wire       is_temp = ls_state == TEMP;
    /*
    0 = B
    1 = HALF WORD
    2 = WORD
    3 = DOUBLE WORD
*/
    wire       size_1b = ls_size[0];
    wire       size_1h = ls_size[1];
    wire       size_1w = ls_size[2];
    wire       size_2w = ls_size[3];


    wire       req_fire;
    wire       req_pending;


    assign req_fire    = tbus_index_valid & tbus_index_ready;
    assign req_pending = tbus_index_valid & ~tbus_index_ready;


    /* -------------------------------------------------------------------------- */
    /*                            tbus signal generate                            */
    /* -------------------------------------------------------------------------- */

    wire [63:0] write_1b_mask = {56'b0, {8{1'b1}}};
    wire [63:0] write_1h_mask = {48'b0, {16{1'b1}}};
    wire [63:0] write_1w_mask = {32'b0, {32{1'b1}}};
    wire [63:0] write_2w_mask = {64{1'b1}};

    wire [ 2:0] shift_size = ls_address[2:0];

    wire [63:0] opstore_write_mask_qual;
    assign opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;

    wire [`RESULT_RANGE] opstore_write_data_qual = src2 << (shift_size * 8);
    reg  [`RESULT_RANGE] opload_read_data_wb_raw;

    always @(*) begin
        if (tbus_operation_done) begin
            case ({
                size_1b, size_1h, size_1w, size_2w, is_unsigned
            })

                5'b10001: begin
                    opload_read_data_wb_raw = (tbus_read_data >> ((ls_address[2:0]) * 8));
                    opload_read_data_wb     = {56'h0, opload_read_data_wb_raw[7:0]};
                end
                5'b01001: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:1]) * 16);
                    opload_read_data_wb     = {48'h0, opload_read_data_wb_raw[15:0]};
                end
                5'b00101: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2]) * 32);
                    opload_read_data_wb     = {32'h0, opload_read_data_wb_raw[31:0]};
                end
                5'b00010: opload_read_data_wb = tbus_read_data;
                5'b10000: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:0]) * 8);
                    opload_read_data_wb     = {{56{opload_read_data_wb_raw[7]}}, opload_read_data_wb_raw[7:0]};
                end
                5'b01000: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2:1]) * 16);
                    opload_read_data_wb     = {{48{opload_read_data_wb_raw[15]}}, opload_read_data_wb_raw[15:0]};
                end
                5'b00100: begin
                    opload_read_data_wb_raw = tbus_read_data >> ((ls_address[2]) * 32);
                    opload_read_data_wb     = {{32{opload_read_data_wb_raw[31]}}, opload_read_data_wb_raw[31:0]};
                end
                default:  ;
            endcase
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                             bus request region                             */
    /* -------------------------------------------------------------------------- */
    wire mmio_valid;
    assign mmio_valid = (is_load | is_store) & instr_valid & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);

    always @(*) begin
        tbus_index_valid    = 'b0;
        tbus_index          = 'b0;
        tbus_write_data     = 'b0;
        tbus_write_mask     = 'b0;
        tbus_operation_type = 'b0;
        if (is_load & instr_valid) begin
            if ((~is_outstanding) & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_operation_type = `TBUS_READ;
            end
        end else if (is_store & instr_valid) begin
            if (~is_outstanding & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_write_mask     = opstore_write_mask_qual;
                tbus_write_data     = opstore_write_data_qual;
                tbus_operation_type = `TBUS_WRITE;
            end
        end else begin

        end
    end

    /* -------------------------------------------------------------------------- */
    /*                                     FSM                                    */
    /* -------------------------------------------------------------------------- */
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | need_flush) begin
            ls_state <= IDLE;
        end else begin
            case (ls_state)
                IDLE: begin
                    if (req_pending) begin
                        ls_state <= PENDING;
                    end else if (req_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end
                PENDING: begin
                    if (req_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end
                OUTSTANDING: begin
                    if (tbus_operation_done) begin
                        ls_state <= IDLE;
                    end
                end

                default: ;
            endcase
        end
    end

    assign mem_stall = req_fire | ~is_idle;
    /* -------------------------------------------------------------------------- */
    /*                                 output logic                               */
    /* -------------------------------------------------------------------------- */

    reg                     outstanding_need_to_wb;
    reg [      `PREG_RANGE] outstanding_prd;
    reg                     outstanding_robidx_flag;
    reg [`ROB_SIZE_LOG-1:0] outstanding_robidx;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_need_to_wb <= 'b0;
        end else if (req_fire | mmio_valid) begin
            outstanding_need_to_wb <= instr_valid & is_load;
        end else if (tbus_operation_done | is_idle) begin
            outstanding_need_to_wb <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_prd <= 'b0;
        end else if (req_fire | mmio_valid) begin
            outstanding_prd <= prd;
        end else if (tbus_operation_done | is_idle) begin
            outstanding_prd <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_robidx_flag <= 'b0;
        end else if (req_fire | mmio_valid) begin
            outstanding_robidx_flag <= robidx_flag;
        end else if (tbus_operation_done | is_idle) begin
            outstanding_robidx_flag <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            outstanding_robidx <= 'b0;
        end else if (req_fire | mmio_valid) begin
            outstanding_robidx <= robidx;
        end else if (tbus_operation_done | is_idle) begin
            outstanding_robidx <= 'b0;
        end
    end

    reg out_mmio_valid;

    `MACRO_DFF_NONEN(out_mmio_valid, mmio_valid, 1)

    //when flush instr older than you,could not high out valid!
    assign out_instr_valid = is_outstanding & (tbus_operation_done) & ~need_flush | out_mmio_valid;
    assign out_need_to_wb  = outstanding_need_to_wb;

    assign out_prd         = outstanding_prd;
    assign out_mmio        = out_mmio_valid;

    assign out_robidx_flag = outstanding_robidx_flag;
    assign out_robidx      = outstanding_robidx;

    assign instr_ready     = ~mem_stall;
endmodule
