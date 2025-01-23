module dcache_arb (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset_n signal

    // LSU Channel Inputs and Outputs : from lsu
    input  wire        lsu2arb_tbus_index_valid,    // Valid signal for lsu2arb_tbus_index
    input  wire [63:0] lsu2arb_tbus_index,          // 64-bit input for lsu2arb_tbus_index (Channel 1)
    output reg         lsu2arb_tbus_index_ready,    // Ready signal for LSU channel
    output reg  [63:0] lsu2arb_tbus_read_data,      // Output burst read data for LSU channel
    output reg         lsu2arb_tbus_operation_done,

    //SQ bus channel : from SQ
    input  reg                       sq2arb_tbus_index_valid,
    output reg                       sq2arb_tbus_index_ready,
    input  reg  [     `RESULT_RANGE] sq2arb_tbus_index,
    input  reg  [              63:0] sq2arb_tbus_write_data,
    input  reg  [              63:0] sq2arb_tbus_write_mask,
    output reg  [              63:0] sq2arb_tbus_read_data,
    output reg                       sq2arb_tbus_operation_done,
    input  wire [`TBUS_OPTYPE_RANGE] sq2arb_tbus_operation_type,


    // dcache Control Inputs and Outputs
    output reg                       tbus_index_valid,
    input  wire                      tbus_index_ready,      // Indicates if dcache is ready for new operation
    output reg  [              63:0] tbus_index,           // 64-bit selected index to be sent to dcache
    output reg  [              63:0] tbus_write_mask,      // Output write mask for opstore channel
    output reg  [              63:0] tbus_write_data,      // Output write data for opstore channel
    input  wire [              63:0] tbus_read_data,       // 512-bit data output for lw channel read
    output reg  [`TBUS_OPTYPE_RANGE] tbus_operation_type,
    input  wire                      tbus_operation_done

    //add redirect wire
    //input wire redirect_valid

);

    // State Encoding

    localparam IDLE = 2'b00;
    localparam SQ = 2'b01;
    localparam LSU = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // Arbiter Logic
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) current_state <= IDLE;
        else current_state <= next_state;
    end
    reg ddr_chip_enable_level;

    always @(*) begin
        case (current_state)
            IDLE: begin
                ddr_chip_enable_level       = 0;
                sq2arb_tbus_operation_done  = 0;
                lsu2arb_tbus_operation_done = 0;
                lsu2arb_tbus_index_ready    = 0;
                sq2arb_tbus_index_ready     = 0;

                if (sq2arb_tbus_index_valid && tbus_index_ready) next_state = SQ;
                else if (lsu2arb_tbus_index_valid && tbus_index_ready) next_state = LSU;
            end

            SQ: begin
                ddr_chip_enable_level      = 1'b1;
                tbus_index                 = sq2arb_tbus_index;
                tbus_write_data            = sq2arb_tbus_write_data;
                tbus_write_mask            = sq2arb_tbus_write_mask;
                sq2arb_tbus_operation_done = tbus_operation_done;
                sq2arb_tbus_index_ready    = tbus_index_ready;
                if (sq2arb_tbus_operation_type == `TBUS_WRITE) begin
                    tbus_operation_type = `TBUS_WRITE;
                end else begin
                    tbus_operation_type = `TBUS_READ;
                end

                if (tbus_operation_done) begin
                    sq2arb_tbus_read_data = tbus_read_data;
                    //sq2arb_tbus_index_ready = 1'b1;
                    next_state            = IDLE;
                end
            end

            LSU: begin
                ddr_chip_enable_level       = 1'b1;
                tbus_index                  = lsu2arb_tbus_index;
                tbus_operation_type         = 'b0;
                lsu2arb_tbus_operation_done = tbus_operation_done;
                lsu2arb_tbus_index_ready    = tbus_index_ready;

                if (tbus_operation_done) begin
                    lsu2arb_tbus_read_data = tbus_read_data;
                    //lsu2arb_tbus_index_ready = 1'b0;
                    next_state             = IDLE;
                end
            end
            default: begin
                // Default values
                ddr_chip_enable_level    = 1'b0;
                next_state               = current_state;
                tbus_index               = 64'b0;
                tbus_operation_type      = 'b0;
                tbus_write_mask          = 512'b0;
                tbus_write_data          = 512'b0;

                lsu2arb_tbus_index_ready = 1'b0;
                lsu2arb_tbus_read_data   = 512'b0;

                sq2arb_tbus_index_ready  = 1'b0;
                sq2arb_tbus_read_data    = 512'b0;
            end
        endcase
    end


    //make chip_enable a pulse
    reg ddr_chip_enable_latch;
    always @(posedge clock or negedge reset_n) begin
        if (~reset_n) begin
            ddr_chip_enable_latch <= 0;
        end else begin
            ddr_chip_enable_latch <= ddr_chip_enable_level;
        end
    end

    assign tbus_index_valid = ddr_chip_enable_level & ~ddr_chip_enable_latch;
endmodule
