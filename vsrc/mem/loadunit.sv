`include "defines.sv"
module loadunit (
    input  wire                   clock,
    input  wire                   reset_n,
    input  wire                   instr_valid,
    input  wire [      `PC_RANGE] pc,
    output wire                   instr_ready,
    input  wire [    `PREG_RANGE] prd,
    input  wire                   is_load,
    input  wire                   is_unsigned,
    input  wire [     `SRC_RANGE] imm,
    input  wire [     `SRC_RANGE] src1,
    input  wire [     `SRC_RANGE] src2,
    input  wire [ `LS_SIZE_RANGE] ls_size,
    input  wire [`ROB_SIZE_LOG:0] robid,
    input  wire [ `SQ_SIZE_LOG:0] sqid,

    //trinity bus channel
    output reg                  load2arb_tbus_index_valid,
    input  wire                 load2arb_tbus_index_ready,
    output reg  [`RESULT_RANGE] load2arb_tbus_index,
    output reg  [   `SRC_RANGE] load2arb_tbus_write_data,
    output reg  [         63:0] load2arb_tbus_write_mask,

    input  wire [     `RESULT_RANGE] load2arb_tbus_read_data,
    input  wire                      load2arb_tbus_operation_done,
    output wire [`TBUS_OPTYPE_RANGE] load2arb_tbus_operation_type,

    /* -------------------------- redirect flush logic -------------------------- */
    input  wire                   flush_valid,
    input  wire [`ROB_SIZE_LOG:0] flush_robid,
    /* --------------------------- mem_top to dcache --------------------------- */
    //it can be used to flush dcache arb.
    output wire                   load2arb_flush_valid,
    /* --------------------------- output to writeback -------------------------- */
    output wire                   ldu_out_instr_valid,
    output wire [    `PREG_RANGE] ldu_out_prd,
    output wire [`ROB_SIZE_LOG:0] ldu_out_robid,
    output wire [  `RESULT_RANGE] ldu_out_load_data,
    output wire [      `PC_RANGE] ldu_out_pc,

    /* --------------------------- SQ forwarding query -------------------------- */
    output wire                        ldu2sq_forward_req_valid,
    output wire [     `ROB_SIZE_LOG:0] ldu2sq_forward_req_sqid,
    output wire [          `SRC_RANGE] ldu2sq_forward_req_load_addr,
    output wire [      `LS_SIZE_RANGE] ldu2sq_forward_req_load_size,
    input  wire                        ldu2sq_forward_resp_valid,
    input  wire [          `SRC_RANGE] ldu2sq_forward_resp_data,
    input  wire [          `SRC_RANGE] ldu2sq_forward_resp_mask

);
    localparam IDLE = 2'b00;
    localparam TAKEIN = 2'b01;
    localparam PENDING = 2'b10;
    localparam OUTSTANDING = 2'b11;
    reg  [1:0] ls_state;
    wire       is_idle;
    wire       is_pending;
    wire       is_outstanding;
    wire       is_takenin;

    assign is_idle        = ls_state == IDLE;
    assign is_takenin     = ls_state == TAKEIN;
    assign is_pending     = ls_state == PENDING;
    assign is_outstanding = ls_state == OUTSTANDING;
    assign instr_ready    = is_idle;

    /* -------------------------------------------------------------------------- */
    /*                            stage : info generate                           */
    /* -------------------------------------------------------------------------- */

    wire [  `RESULT_RANGE] ls_address;
    reg  [  `RESULT_RANGE] ls_address_latch;


    reg                    instr_valid_latch;
    reg                    need_to_wb_latch;
    reg  [    `PREG_RANGE] prd_latch;
    reg  [      `PC_RANGE] pc_latch;
    reg  [`ROB_SIZE_LOG:0] robid_latch;
    reg  [ `SQ_SIZE_LOG:0] sqid_latch;
    reg  [ `LS_SIZE_RANGE] ls_size_latch;
    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ls_address_latch <= 'b0;
        end else if (instr_valid & instr_ready) begin
            ls_address_latch <= ls_address;
        end
    end


    wire req_fire;
    assign req_fire = instr_valid & instr_ready;

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n | need_flush) begin
            instr_valid_latch <= 'b0;
        end else if (req_fire ) begin
            instr_valid_latch <= 1'b1;
        end else if (load2arb_tbus_operation_done) begin
            instr_valid_latch <= 1'b0;
        end
    end


    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            need_to_wb_latch <= 'b0;
        end else if (req_fire) begin
            need_to_wb_latch <= instr_valid & is_load;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            prd_latch <= 'b0;
        end else if (req_fire) begin
            prd_latch <= prd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            robid_latch <= 'b0;
        end else if (req_fire) begin
            robid_latch <= robid;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            pc_latch <= 'b0;
        end else if (req_fire) begin
            pc_latch <= pc;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            sqid_latch <= 'b0;
        end else if (req_fire) begin
            sqid_latch <= sqid;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ls_size_latch <= 'b0;
        end else if (req_fire) begin
            ls_size_latch <= ls_size;
        end
    end



    /*
    0 = B
    1 = HALF WORD
    2 = WORD
    3 = DOUBLE WORD
*/
    reg size_1b_latch;
    reg size_1h_latch;
    reg size_1w_latch;
    reg size_2w_latch;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            size_1b_latch <= 'b0;
            size_1h_latch <= 'b0;
            size_1w_latch <= 'b0;
            size_2w_latch <= 'b0;
        end else if (req_fire) begin
            size_1b_latch <= ls_size[0];
            size_1h_latch <= ls_size[1];
            size_1w_latch <= ls_size[2];
            size_2w_latch <= ls_size[3];
        end
    end

    reg is_unsigned_latch;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            is_unsigned_latch <= 'b0;
        end else if (req_fire) begin
            is_unsigned_latch <= is_unsigned;
        end
    end

    /* -------------------------------------------------------------------------- */
    /*                         stage : SQ forwarding query                        */
    /* -------------------------------------------------------------------------- */

    assign ldu2sq_forward_req_valid     = instr_valid_latch;
    assign ldu2sq_forward_req_sqid      = sqid_latch;
    assign ldu2sq_forward_req_load_addr = ls_address_latch;
    assign ldu2sq_forward_req_load_size = ls_size_latch;




    /* -------------------------------------------------------------------------- */
    /*                      stage: load tbus request generate                     */
    /* -------------------------------------------------------------------------- */

    wire tbus_fire;
    wire tbus_pending;
    assign tbus_fire    = load2arb_tbus_index_valid & load2arb_tbus_index_ready;
    assign tbus_pending = load2arb_tbus_index_valid & ~load2arb_tbus_index_ready;


    always @(*) begin
        load2arb_tbus_index_valid    = 'b0;
        load2arb_tbus_index          = 'b0;
        load2arb_tbus_write_data     = 'b0;
        load2arb_tbus_write_mask     = 'b0;
        load2arb_tbus_operation_type = 'b0;
        if (instr_valid_latch & ~ldu2sq_forward_resp_valid) begin
            if ((~is_outstanding)) begin
                load2arb_tbus_index_valid    = 1'b1;
                load2arb_tbus_index          = ls_address_latch[`RESULT_WIDTH-1:0];
                load2arb_tbus_operation_type = `TBUS_READ;
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
                    if (req_fire ) begin
                        ls_state <= TAKEIN;
                    end
                end
                TAKEIN: begin
                    if (tbus_pending) begin
                        ls_state <= PENDING;
                    end else if (tbus_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end
                PENDING: begin
                    if (tbus_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end
                OUTSTANDING: begin
                    if (load2arb_tbus_operation_done) begin
                        ls_state <= IDLE;
                    end
                end

                default: ;
            endcase
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                result check                                */
    /* -------------------------------------------------------------------------- */
    reg [`RESULT_RANGE] opload_read_data_wb_raw;
    reg [`RESULT_RANGE] opload_read_data_wb;

    always @(*) begin
        if (load2arb_tbus_operation_done) begin
            case ({
                size_1b_latch, size_1h_latch, size_1w_latch, size_2w_latch, is_unsigned_latch
            })

                5'b10001: begin
                    opload_read_data_wb_raw = (load2arb_tbus_read_data >> ((ls_address_latch[2:0]) * 8));
                    opload_read_data_wb     = {56'h0, opload_read_data_wb_raw[7:0]};
                end
                5'b01001: begin
                    opload_read_data_wb_raw = load2arb_tbus_read_data >> ((ls_address_latch[2:1]) * 16);
                    opload_read_data_wb     = {48'h0, opload_read_data_wb_raw[15:0]};
                end
                5'b00101: begin
                    opload_read_data_wb_raw = load2arb_tbus_read_data >> ((ls_address_latch[2]) * 32);
                    opload_read_data_wb     = {32'h0, opload_read_data_wb_raw[31:0]};
                end
                5'b00010: opload_read_data_wb = load2arb_tbus_read_data;
                5'b10000: begin
                    opload_read_data_wb_raw = load2arb_tbus_read_data >> ((ls_address_latch[2:0]) * 8);
                    opload_read_data_wb     = {{56{opload_read_data_wb_raw[7]}}, opload_read_data_wb_raw[7:0]};
                end
                5'b01000: begin
                    opload_read_data_wb_raw = load2arb_tbus_read_data >> ((ls_address_latch[2:1]) * 16);
                    opload_read_data_wb     = {{48{opload_read_data_wb_raw[15]}}, opload_read_data_wb_raw[15:0]};
                end
                5'b00100: begin
                    opload_read_data_wb_raw = load2arb_tbus_read_data >> ((ls_address_latch[2]) * 32);
                    opload_read_data_wb     = {{32{opload_read_data_wb_raw[31]}}, opload_read_data_wb_raw[31:0]};
                end
                default:  ;
            endcase
        end
    end


    /* -------------------------------------------------------------------------- */
    /*                                output logic                                */
    /* -------------------------------------------------------------------------- */
    assign ldu_out_instr_valid = load2arb_tbus_operation_done & instr_valid_latch | ldu2sq_forward_resp_valid;
    assign ldu_out_prd         = prd_latch;
    assign ldu_out_robid       = robid_latch;
    assign ldu_out_load_data   = ldu2sq_forward_resp_valid ? ldu2sq_forward_resp_data : opload_read_data_wb;
    assign ldu_out_pc          = pc_latch;

    /* -------------------------------------------------------------------------- */
    /*                                 flush logic                                */
    /* -------------------------------------------------------------------------- */
    wire need_flush;
    wire flush_outstanding;
    assign flush_outstanding    = (~is_idle) & flush_valid & ((flush_robid[`ROB_SIZE_LOG] ^ ldu_out_robid[`ROB_SIZE_LOG]) ^ (flush_robid[`ROB_SIZE_LOG-1:0] < ldu_out_robid[`ROB_SIZE_LOG-1:0]));
    assign need_flush           = flush_outstanding;

    //ONLY WHEN IS OUTSTANDING, LOAD COULD FLUSH DCACHE AND ARB
    assign load2arb_flush_valid = need_flush;

endmodule
