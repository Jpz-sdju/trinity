
//use SRAM to simulate DDR behavior
//DDR specification : 
//                  4MB storage 
//                  64bit per entry 
//                  burst_mode : read and write operation wait for 80 cycle and finish 512 bit transfer in 81th cyele
//                  non-burst_mode : read and write operation wait for 64 cycle and finish 64 bit transfer in 65th cyele

module simddr (
    input wire clk,                         // Clock signal
    input wire reset,                       // Reset signal
    input wire chip_enable,                 // Chip enable signal (1 to enable operations)
    input wire write_enable,                // Write enable signal (1 for write, 0 for read)
    input wire burst_mode,                  // Burst mode control (1 for 512-bit, 0 for 64-bit)
    input wire [18:0] address,              // Address input (19 bits to address 524,288 entries)
    input wire [511:0] l2_burst_write_data, // 512-bit data input for burst write operations
    input wire [63:0] access_write_data,    // 64-bit data input for single access write
    output reg [511:0] fetch_burst_read_data, // 512-bit data output for burst read operations
    output reg [63:0] access_read_data,     // 64-bit data output for single access read
    output reg ready                        // Ready signal, high when data is available (read) or written (write)
);

    reg [63:0] memory [0:524287];           // 64-bit DDR memory array (524,288 entries, each 64-bit)

    reg [7:0] cycle_counter;                // 8-bit counter for counting up to 80 cycles for burst or 64 cycles for single access
    reg operation_in_progress;              // Flag to indicate if a read or write operation is in progress

    // Initialize the memory with some test values (optional, can be replaced with actual data)
    integer i;
    initial begin
        for (i = 0; i < 524288; i = i + 1) begin
            memory[i] = 64'hA0A0_B0B0_C0C0_D0D0 + i;
        end
    end

    // State machine to handle both burst and single access read/write operations
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cycle_counter <= 8'b0;
            ready <= 1'b0;
            operation_in_progress <= 1'b0;
            fetch_burst_read_data <= 512'b0;
            access_read_data <= 64'b0;
        end else begin
            if (chip_enable && operation_in_progress) begin  // Operations only proceed when chip_enable is high
                if (burst_mode && cycle_counter == 8'd79) begin  // After 80 cycles in burst mode
                    cycle_counter <= 8'b0;        // Reset cycle counter
                    ready <= 1'b1;                // Signal that the operation is complete
                    operation_in_progress <= 1'b0;  // End the operation
                    
                    if (!write_enable) begin
                        // Read 512 bits (8 x 64-bit entries) from memory in one cycle for burst mode
                        fetch_burst_read_data[63:0]   <= memory[address];
                        fetch_burst_read_data[127:64] <= memory[address + 1];
                        fetch_burst_read_data[191:128] <= memory[address + 2];
                        fetch_burst_read_data[255:192] <= memory[address + 3];
                        fetch_burst_read_data[319:256] <= memory[address + 4];
                        fetch_burst_read_data[383:320] <= memory[address + 5];
                        fetch_burst_read_data[447:384] <= memory[address + 6];
                        fetch_burst_read_data[511:448] <= memory[address + 7];
                    end else if (write_enable) begin
                        // Write 512 bits (8 x 64-bit entries) to memory in one cycle for burst mode
                        memory[address]     <= l2_burst_write_data[63:0];
                        memory[address + 1] <= l2_burst_write_data[127:64];
                        memory[address + 2] <= l2_burst_write_data[191:128];
                        memory[address + 3] <= l2_burst_write_data[255:192];
                        memory[address + 4] <= l2_burst_write_data[319:256];
                        memory[address + 5] <= l2_burst_write_data[383:320];
                        memory[address + 6] <= l2_burst_write_data[447:384];
                        memory[address + 7] <= l2_burst_write_data[511:448];
                    end
                end else if (!burst_mode && cycle_counter == 8'd63) begin  // After 64 cycles for single access
                    cycle_counter <= 8'b0;        // Reset cycle counter
                    ready <= 1'b1;                // Signal that the operation is complete
                    operation_in_progress <= 1'b0;  // End the operation
                    
                    if (!write_enable) begin
                        // Single 64-bit read from memory for single access mode
                        access_read_data <= memory[address];
                    end else if (write_enable) begin
                        // Single 64-bit write to memory for single access mode
                        memory[address] <= access_write_data;
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1;  // Increment cycle counter for both modes
                    ready <= 1'b0;                       // Data not ready during the wait
                end
            end else if (chip_enable && !operation_in_progress && (!write_enable || write_enable)) begin
                // Start a new read or write operation if chip_enable is 1
                cycle_counter <= 8'b0;            // Reset cycle counter
                operation_in_progress <= 1'b1;    // Mark operation as in progress
                ready <= 1'b0;                    // Reset ready signal
            end
        end
    end

endmodule
