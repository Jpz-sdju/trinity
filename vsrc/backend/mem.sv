`include "defines.sv"
module mem (
    input  wire                  clock,
    input  wire                  reset_n,
    input  wire                  is_load,
    input  wire                  is_store,
    input  wire                  is_unsigned,
    input  wire [    `SRC_RANGE] imm,
    input  wire [    `SRC_RANGE] src1,
    input  wire [    `SRC_RANGE] src2,
    input  wire [`LS_SIZE_RANGE] ls_size,
    input  wire                  instr_valid,
    input  wire [     `PC_RANGE] pc,
    input  wire [  `INSTR_RANGE] instr,

    //trinity bus channel
    output reg                  tbus_index_valid,
    input  wire                 tbus_index_ready,
    output reg  [`RESULT_RANGE] tbus_index,
    output reg  [   `SRC_RANGE] tbus_write_data,
    output reg  [         63:0] tbus_write_mask,

    input  wire [ `RESULT_RANGE] tbus_read_data,
    input  wire                 tbus_operation_done,
    output wire [  `TBUS_RANGE] tbus_operation_type,

    // output valid, pc , inst
    output wire                 instr_valid_out,
    output wire [    `PC_RANGE] pc_out,
    output wire [ `INSTR_RANGE] instr_out,
    output wire [`RESULT_RANGE] ls_address,
    //read data to wb stage
    output wire [`RESULT_RANGE] opload_read_data_wb,
    //mem stall
    output wire                 mem_stall


);

    agu u_agu (
        .src1      (src1),
        .imm       (imm),
        .ls_address(ls_address)
    );



    assign instr_valid_out = instr_valid;
    assign pc_out          = pc;
    assign instr_out       = instr;


    localparam IDLE = 2'b00;
    localparam PENDING = 2'b01;
    localparam OUTSTANDING = 2'b10;
    localparam TEMP = 2'b11;
    reg  [1:0] ls_state;
    wire       ls_idle = ls_state == IDLE;
    wire       ls_pending = ls_state == PENDING;
    wire       ls_outstanding = ls_state == OUTSTANDING;
    wire       ls_temp = ls_state == TEMP;
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

    wire       ls_valid = is_load | is_store;


    wire       read_fire = tbus_index_valid & tbus_index_ready & (tbus_operation_type == `TBUS_READ);
    wire       read_pending = tbus_index_valid & ~tbus_index_ready & (tbus_operation_type == `TBUS_READ);


    wire       write_fire = tbus_index_valid & tbus_index_ready & (tbus_operation_type == `TBUS_WRITE);
    wire       write_pending = tbus_index_valid & ~tbus_index_ready & (tbus_operation_type == `TBUS_WRITE);

    reg        outstanding_load_q;
    reg        outstanding_store_q;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            outstanding_load_q <= 'b0;
        end else if(read_fire & ~tbus_operation_done) begin
            outstanding_load_q <= 'b1;
        end else if (tbus_operation_done) begin
            outstanding_load_q <= 'b0;
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            outstanding_store_q <= 'b0;
        end else if(write_fire & ~tbus_operation_done) begin
            outstanding_store_q <= 'b1;
        end else if (tbus_operation_done) begin
            outstanding_store_q <= 'b0;
        end
    end

    wire opload_operation_done;
    wire opstore_operation_done;

    assign opload_operation_done = outstanding_load_q & tbus_operation_done;
    assign opstore_operation_done = outstanding_store_q & tbus_operation_done;
    
    wire                 mmio_valid = (is_load | is_store) & ('h30000000 <= ls_address) & (ls_address <= 'h40700000);


    wire [         63:0] write_1b_mask = {56'b0, {8{1'b1}}};
    wire [         63:0] write_1h_mask = {48'b0, {16{1'b1}}};
    wire [         63:0] write_1w_mask = {32'b0, {32{1'b1}}};
    wire [         63:0] write_2w_mask = {64{1'b1}};

    wire [          2:0] shift_size = ls_address[2:0];

    wire [         63:0] opstore_write_mask_qual = size_1b ? write_1b_mask << (shift_size * 8) : size_1h ? write_1h_mask << (shift_size * 8) : size_1w ? write_1w_mask << (shift_size * 8) : write_2w_mask;

    wire [`RESULT_RANGE] opstore_write_data_qual = src2 << (shift_size * 8);
    reg  [`RESULT_RANGE] opload_read_data_wb_raw;

    always @(*) begin
        if (opload_operation_done) begin
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


    always @(*) begin
        tbus_index_valid    = 'b0;
        tbus_index          = 'b0;
        tbus_write_data     = 'b0;
        tbus_write_mask     = 'b0;
        tbus_operation_type = 'b0;

        if (is_load & instr_valid) begin
            if ((~ls_outstanding) & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_operation_type = `TBUS_READ;
            end
        end else if (is_store & instr_valid) begin
            if (~ls_outstanding & ~mmio_valid) begin
                tbus_index_valid    = 1'b1;
                tbus_index          = ls_address[`RESULT_WIDTH-1:0];
                tbus_write_mask     = opstore_write_mask_qual;
                tbus_write_data     = opstore_write_data_qual;
                tbus_operation_type = `TBUS_WRITE;
            end
        end else begin

        end

    end



    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ls_state <= IDLE;
        end else begin
            case (ls_state)
                IDLE: begin
                    if (read_pending | write_pending) begin
                        ls_state <= PENDING;
                    end else if (read_fire | write_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end

                PENDING: begin
                    if (read_fire | write_fire) begin
                        ls_state <= OUTSTANDING;
                    end
                end

                OUTSTANDING: begin
                    if (opload_operation_done | opstore_operation_done) begin
                        ls_state <= IDLE;
                    end
                end

                default: ;
            endcase

        end

    end

    assign mem_stall = (~ls_idle | tbus_index_valid) & ~((opload_operation_done | opstore_operation_done) & (ls_outstanding));

endmodule
