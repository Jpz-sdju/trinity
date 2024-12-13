module ibuffer (
    input wire clock,
    input wire reset_n,
    input wire pc_index_ready,                  // Signal indicating readiness from `pc_index`
    input wire pc_operation_done,
    input wire [511:0] pc_read_inst,        // 512-bit input data from arbiter (16 instructions, 32 bits each)
    input wire fifo_read_en,                    // External read enable signal for FIFO
    input wire clear_ibuffer,                   // Clear signal for ibuffer
    input wire can_fetch_inst,
    input wire [47:0] pc,
    input wire cut_first_32_bit,

    output wire ibuffer_instr_valid,
    output wire [31:0]  ibuffer_inst_out,
    output wire [47:0]  ibuffer_pc_out,
    output reg fetch_inst,                      // Output pulse when FIFO count decreases from 4 to 3
    output wire fifo_empty,                      // Signal indicating if the FIFO is empty

    input wire mem_stall
);
//predict logic
// Registers for counter and range tracking
reg [63:0] pc_counter;         // Simple counter starting from 0
reg within_range;              // Indicates if the counter is within the range
reg [63:0] range_count;        // Stores the calculated range count
assign predict_valid_level = within_range; // Output signal for valid range

// Counter logic
always @(posedge clock or negedge reset_n) begin
    if (!reset_n || clear_ibuffer) begin
        pc_counter <= 64'b0;
        within_range <= 1'b0;
        range_count <= 64'b0;  // Reset range count
    end else begin
        if (pc_operation_done) begin
            // Calculate range_count when pc_operation_done pulse is high
            range_count <= (trigger_pc - base_pc) >> 2;
            pc_counter <= 64'b0; // Reset counter to start from 0
        end

        // Increment the counter only if it is within range_count
        if (pc_counter < range_count) begin
            pc_counter <= pc_counter + 1;
        end

        // Check if counter is within the valid range
        within_range <= (pc_counter < range_count);
    end
end







//
    wire [(32+48-1):0] fifo_inst_addr_out;           // 32-bit output data from the FIFO
    assign ibuffer_inst_out = fifo_inst_addr_out[(32+48-1):48];
    assign ibuffer_pc_out = fifo_inst_addr_out[47:0];

    reg [31:0] inst_cut [0:15];
    reg [47:0] pc_cut [0:15];
    integer i;

    always @(*) begin
        for (i = 0; i < 16; i = i + 1) begin
            inst_cut[i] = pc_read_inst[(i * 32) + 31 -: 32];
            pc_cut[i] = pc+(i*4);
        end
    end


    // Internal signals
    reg [(32+48-1):0] inst_buffer [0:15];              // Buffer to store 16 instructions (32-bit each)
    reg pc_index_ready_prev;                    // To detect rising edge of pc_index_ready
    reg write_enable;                           // Enable writing to FIFO
    wire fifo_full;                             // Full signal from FIFO
    wire [5:0] fifo_count;                      // Count of entries in the FIFO
    reg [5:0] fifo_count_prev;                  // Previous FIFO count to detect transition from 4 to 3
    
    // Instantiate the 32x24 FIFO with clear functionality
    fifo_depth24 fifo_inst (
        .clock(clock),
        .reset_n(reset_n),
        .data_in(inst_buffer[write_index]),     // 32-bit input to FIFO
        .write_en(write_enable),
        .read_en(fifo_read_en),
        .clear_ibuffer(clear_ibuffer),          // Pass clear signal to FIFO
        .data_out(fifo_inst_addr_out),
        .empty(fifo_empty),
        .full(fifo_full),
        .count(fifo_count),
        .data_valid(ibuffer_instr_valid),
        .stall(mem_stall)
    );

    reg [3:0] write_index;                      // Index for loading instructions into FIFO

    // Detect rising edge of pc_index_ready
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc_index_ready_prev <= 1'b0;
        end else begin
            pc_index_ready_prev <= pc_index_ready;
        end
    end

    // Store 16 instructions into inst_buffer when pc_index_ready rises from 0 to 1
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            write_index <= 4'b0;
            write_enable <= 1'b0;
            fetch_inst <= 1'b0;
            fifo_count_prev <= 6'b0;
        end else begin
            // Detect rising edge of pc_index_ready
            // if (pc_index_ready && !pc_index_ready_prev) begin
            if (pc_operation_done) begin
                // Split pc_read_inst into 16 instructions and load them into inst_buffer
                inst_buffer[0]  <= {inst_cut[0 ] , (pc_cut[0 ])};
                inst_buffer[1]  <= {inst_cut[1 ] , (pc_cut[1 ])};
                inst_buffer[2]  <= {inst_cut[2 ] , (pc_cut[2 ])};
                inst_buffer[3]  <= {inst_cut[3 ] , (pc_cut[3 ])};
                inst_buffer[4]  <= {inst_cut[4 ] , (pc_cut[4 ])};
                inst_buffer[5]  <= {inst_cut[5 ] , (pc_cut[5 ])};
                inst_buffer[6]  <= {inst_cut[6 ] , (pc_cut[6 ])};
                inst_buffer[7]  <= {inst_cut[7 ] , (pc_cut[7 ])};
                inst_buffer[8]  <= {inst_cut[8 ] , (pc_cut[8 ])};
                inst_buffer[9]  <= {inst_cut[9 ] , (pc_cut[9 ])};
                inst_buffer[10] <= {inst_cut[10] , (pc_cut[10])};
                inst_buffer[11] <= {inst_cut[11] , (pc_cut[11])};
                inst_buffer[12] <= {inst_cut[12] , (pc_cut[12])};
                inst_buffer[13] <= {inst_cut[13] , (pc_cut[13])};
                inst_buffer[14] <= {inst_cut[14] , (pc_cut[14])};
                inst_buffer[15] <= {inst_cut[15] , (pc_cut[15])};

                write_index <= 4'b0;             // Reset write_index
                write_enable <= 1'b1;            // Start writing to FIFO
            end

            // Write instructions from inst_buffer to FIFO
            if (write_enable && !fifo_full) begin
                write_index <= write_index + 1;
                if ((cut_first_32_bit == 1) && write_index == 4'd14) begin
                    write_enable <= 1'b0;        // Stop writing after 16 instructions
                end
                if ((cut_first_32_bit == 0) && write_index == 4'd15) begin
                    write_enable <= 1'b0;        // Stop writing after 16 instructions
                end
            end

            // Update fifo_count_prev to detect transition from 4 to 3
            fifo_count_prev <= fifo_count;

            // Generate fetch_inst pulse when FIFO count decreases from 4 to 3
            if(can_fetch_inst)begin
                fetch_inst <= ((fifo_count_prev == 6'd4 && fifo_count == 6'd3)||fifo_empty) ? 1'b1 : 1'b0;
            end
        end
    end

endmodule
