module channel_arb (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset_n signal

    // PC Channel Inputs and Outputs : from icache
    input  wire         pc_index_valid,    // Valid signal for pc_index
    input  wire [ 63:0] pc_index,          // 64-bit input for pc_index (Channel 1)
    output reg          pc_index_ready,    // Ready signal for pc channel
    output reg  [511:0] pc_read_inst,      // Output burst read data for pc channel
    output wire         pc_operation_done,

    //ddr bus channel : from dcache
    input  reg                  dbus_index_valid,
    output wire                 dbus_index_ready,
    input  reg  [`RESULT_RANGE] dbus_index,
    input  reg  [   511:0] dbus_write_data,
    input  reg  [   511:0] dbus_write_mask,
    output wire [   511:0] dbus_read_data,
    output wire                 dbus_operation_done,
    input  wire [  `DBUS_RANGE] dbus_operation_type,


    // DDR Control Inputs and Outputs
    output reg          ddr_chip_enable,     // Enables chip for one cycle when a channel is selected
    output reg  [ 63:0] ddr_index,           // 64-bit selected index to be sent to DDR
    output reg          ddr_write_enable,    // Write enable signal (1 for write, 0 for read)
    output reg          ddr_burst_mode,      // Burst mode signal, 1 when pc_index is selected
    output reg  [511:0] ddr_write_mask,      // Output write mask for opstore channel
    output reg  [511:0] ddr_write_data,      // Output write data for opstore channel
    input  wire [511:0] ddr_read_data,       // 512-bit data output for lw channel read
    input  wire         ddr_operation_done,
    input  wire         ddr_ready           // Indicates if DDR is ready for new operation

    //add redirect wire
    //input wire redirect_valid

);
 
// State Encoding

    localparam  IDLE = 2'b00;
    localparam  DBUS = 2'b01;
    localparam  PC = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // Arbiter Logic
    always@(posedge clock or negedge reset_n) begin
        if (~reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    reg ddr_chip_enable_level;

    always@(*) begin
        case (current_state)
            IDLE: begin
                ddr_chip_enable_level = 0;
                dbus_operation_done =0;
                pc_operation_done =0;
                pc_index_ready = 0;
                dbus_index_ready = 0;

                if (dbus_index_valid && ddr_ready)
                    next_state = DBUS;
                else if (pc_index_valid && ddr_ready)
                    next_state = PC;
            end

            DBUS: begin
                ddr_chip_enable_level  = 1'b1;
                ddr_index        = dbus_index;
                ddr_write_data   = dbus_write_data;
                ddr_write_mask   = dbus_write_mask;
                dbus_operation_done = ddr_operation_done;
                dbus_index_ready = ddr_ready;
                if(dbus_operation_type == `DBUS_WRITE)begin
                    ddr_write_enable = 1'b1;                     
                end else begin
                    ddr_write_enable = 1'b0;                                         
                end

                if (ddr_operation_done) begin
                    dbus_read_data   = ddr_read_data;
                    //dbus_index_ready = 1'b1;
                    next_state       = IDLE;
                end
            end

            PC: begin
                ddr_chip_enable_level  = 1'b1;
                ddr_index        = pc_index;
                ddr_burst_mode   = 1'b1; // Assume burst mode for PC channel
                ddr_write_enable = 1'b0;
                pc_operation_done = ddr_operation_done;
                pc_index_ready = ddr_ready;

                if (ddr_operation_done) begin
                    pc_read_inst   = ddr_read_data;
                    //pc_index_ready = 1'b0;
                    next_state     = IDLE;
                end
            end
            default: begin
                // Default values
                next_state       = current_state;
                ddr_chip_enable_level  = 1'b0;
                ddr_index        = 64'b0;
                ddr_write_enable = 1'b0;
                ddr_burst_mode   = 1'b0;
                ddr_write_mask   = 512'b0;
                ddr_write_data   = 512'b0;
        
                pc_index_ready   = 1'b0;
                pc_read_inst     = 512'b0;
        
                dbus_index_ready = 1'b0;
                dbus_read_data   = 512'b0;
            end
        endcase
    end

//make chip_enable a pulse
reg ddr_chip_enable_latch;
always @(posedge clock or negedge reset_n) begin
    if(~reset_n)begin
        ddr_chip_enable_latch <= 0;
    end else begin
        ddr_chip_enable_latch <= ddr_chip_enable_level;
    end
end

assign ddr_chip_enable =  ddr_chip_enable_level & ~ddr_chip_enable_latch;

endmodule
