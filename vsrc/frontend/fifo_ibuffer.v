module fifo_ibuffer (
    input wire               clock,
    input wire               reset_n,
    input wire [(32+64-1):0] data_in,        // (32+64-1)-bit data input
    input wire               write_en,       // Write enable
    input wire               read_en,        // Read enable
    input wire               redirect_valid,  // Clear signal for ibuffer
    input wire               stall,          // Stall signal (new input)

    output reg  [(32+64-1):0] data_out,   // (32+64-1)-bit data output
    output wire               empty,      // FIFO empty flag
    output wire               full,       // FIFO full flag
    output reg  [        5:0] count,      // FIFO count
    output reg                data_valid  // Data valid signal
);

    localparam FIFO_DEPTH  = 48;
    localparam FIFO_DEPTH_LOG = 6;

    reg [(32+64-1):0] fifo                        [FIFO_DEPTH-1:0];  // FIFO storage ((32+64-1)x24)
    reg [        FIFO_DEPTH_LOG-1 :0] read_ptr;  // Read pointer
    reg [        FIFO_DEPTH_LOG-1 :0] write_ptr;  // Write pointer

    assign empty = (count == 6'd0);
    assign full  = (count == 6'd63);

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || redirect_valid) begin
            // Reset or clear the FIFO
            read_ptr   <= 6'b0;
            write_ptr  <= 6'b0;
            data_out   <= {(32 + 64) {1'b0}};
            data_valid <= 1'b0;  // Reset data valid signal
        end else begin
            // Write operation
            if (write_en && !full) begin
                fifo[write_ptr] <= data_in;
                write_ptr       <= (write_ptr + 1) % FIFO_DEPTH;
            end

            // Read operation
            if (stall) begin
                // When stall is high, freeze the data output and valid signal
                // Do not change data_out and data_valid
                data_out   <= data_out;
                data_valid <= data_valid;
            end else if (read_en && !empty) begin
                // If stall is low, perform read operation
                data_out   <= fifo[read_ptr];
                data_valid <= 1'b1;  // Set data valid signal when data is read
                read_ptr   <= (read_ptr + 1) % FIFO_DEPTH;
            end else begin
                // No read operation, reset data_valid
                data_valid <= 1'b0;  // Clear data valid signal
            end
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || redirect_valid) begin
            // Reset or clear the FIFO
            count      <= 6'b0;
        end else begin
            // Write operation
            if(write_en && !full & (read_en & empty | ~read_en))begin
                count <= count + 1'b1;
            end else if(~write_en & read_en & ~empty) begin
                count <= count - 1'b1;
            end
        end
    end
endmodule
