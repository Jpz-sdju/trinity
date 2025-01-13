module lfsr_random #(parameter N = 8) (
    input clock,                  // Clock input
    input reset_n,                // Active-low reset input
    input [N-1:0] seed,           // Input seed for initialization
    output reg [N-1:0] random_num // Random number output
);
    // Internal LFSR register
    reg [N-1:0] lfsr;

    // Tap positions for feedback (adjustable based on N)
    wire feedback = lfsr[N-1] ^ lfsr[2] ^ lfsr[1] ^ lfsr[0]; // Example taps for 8-bit

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            // Initialize the LFSR to the provided seed value
            lfsr <= seed;
        end else begin
            // Shift and apply feedback
            lfsr <= {lfsr[N-2:0], feedback};
        end
    end

    // Assign the LFSR value to the output
    always @(posedge clock) begin
        random_num <= lfsr;
    end
endmodule
