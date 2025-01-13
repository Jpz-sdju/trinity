module ibuffer (
    input wire        clock,
    input wire        reset_n,
    input wire        pc_index_ready,       // Signal indicating readiness from `pc_index`
    input wire        pc_operation_done,
    input wire [63:0] aligned_instr,        // 64-bit input data from arbiter (two instructions, 32 bits each)
    input wire [ 1:0] aligned_instr_valid,  // 2-bit validity indicator (11 or 01)
    input wire        fifo_read_en,         // External read enable signal for FIFO
    input wire        clear_ibuffer,        // Clear signal for ibuffer
    input wire [63:0] pc,

    output wire        ibuffer_instr_valid,
    output wire [31:0] ibuffer_inst_out,
    output wire [47:0] ibuffer_pc_out,
    output reg         fetch_inst,           // Output pulse when FIFO count decreases from 4 to 3
    output wire        fifo_empty,           // Signal indicating if the FIFO is empty

    input wire mem_stall
);
    wire [(32+64-1):0] fifo_inst_addr_out;  // Output data from the FIFO
    assign ibuffer_inst_out = fifo_inst_addr_out[(32+64-1):64];
    assign ibuffer_pc_out   = fifo_inst_addr_out[47:0];

    // Internal buffers for splitting instructions
    reg [31:0] inst_cut[0:1];
    reg [63:0] pc_cut  [0:1];

    // Splitting instructions and calculating PCs
    always @(*) begin
        inst_cut[0] = aligned_instr[31:0];
        inst_cut[1] = aligned_instr[63:32];
        pc_cut[0]   = pc;
        pc_cut[1]   = pc + 4;
    end

    // FIFO signals
    reg  [(32+64-1):0] inst_buffer   [0:1];  // Buffer for up to 2 instructions, 32bit instr+64bit addr
    wire               fifo_full;  // Full signal from FIFO
    wire [        5:0] fifo_count;  // Count of entries in the FIFO
    reg  [        5:0] fifo_count_prev;  // Previous FIFO count to detect transition from 4 to 3
    reg  [        1:0] valid_counter;  // Counter for valid instructions
    reg  [        0:0] write_index;  // Index for writing to FIFO
    // Instantiate the FIFO
    fifo_depth24 fifo_inst (
        .clock        (clock),
        .reset_n      (reset_n),
        .data_in      (inst_buffer[write_index]),  // Input to FIFO
        .write_en     (valid_counter > 0),         // Write enable based on counter
        .read_en      (fifo_read_en),
        .clear_ibuffer(clear_ibuffer),             // Pass clear signal to FIFO
        .data_out     (fifo_inst_addr_out),
        .empty        (fifo_empty),
        .full         (fifo_full),
        .count        (fifo_count),
        .data_valid   (ibuffer_instr_valid),
        .stall        (mem_stall)
    );

    // Control logic for writing instructions to FIFO
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            fetch_inst      <= 1'b1;
            fifo_count_prev <= 6'b0;
        end else begin
            // Generate inst_buffer  based on aligned_instr_valid
            if (aligned_instr_valid[0]) begin
                inst_buffer[0] <= {inst_cut[0], pc_cut[0][63:0]};
            end

            if (aligned_instr_valid[1]) begin
                inst_buffer[1] <= {inst_cut[1], pc_cut[1][63:0]};
            end

            // Update fifo_count_prev to detect transition from 4 to 3
            fifo_count_prev <= fifo_count;

            // Generate fetch_inst pulse when FIFO count decreases from 4 to 3
            fetch_inst      <= ((fifo_count_prev == 6'd4 && fifo_count == 6'd3) || fifo_empty) ? 1'b1 : 1'b0;
        end
    end
    // Control logic for writing instructions to FIFO
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            valid_counter <= 2'b0;
        end else begin
            // Initialize valid_counter based on aligned_instr_valid
            if (aligned_instr_valid != 2'b00) begin
                valid_counter <= aligned_instr_valid[0] + aligned_instr_valid[1];
            end  // Write instructions to FIFO and decrement counter
            else if (valid_counter > 0 && !fifo_full) begin
                valid_counter <= valid_counter - 1;
            end
        end
    end
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n || clear_ibuffer) begin
            write_index <= 'b0;
        end else begin
            if(valid_counter >0 & ~fifo_full) begin
                write_index <= write_index + 1'b1;
            end else if(valid_counter == 0) begin
                write_index <= 'b0;
            end
        end
    end
endmodule
