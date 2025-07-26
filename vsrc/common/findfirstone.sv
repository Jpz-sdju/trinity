module findfirstone #(
    parameter WIDTH = 8,
    parameter WIDTH_LOG = 3
) (
    input      [    WIDTH-1:0] in_vector,  // Input vector
    output reg [    WIDTH-1:0] onehot,     // One-hot output indicating the position of the first '1'
    output reg [WIDTH_LOG-1:0] enc,
    output reg                 valid       // Valid flag to indicate if a '1' is found
);

    integer i;

    always @(*) begin
        onehot = 'b0;  // Default one-hot output
        enc    = 'b0;
        valid  = 'b0;  // Default valid flag
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (in_vector[i]) begin
                onehot[i] = 1;  // Set the one-hot bit corresponding to the position
                enc       = i;
                valid     = 1;
                break;  // Exit the loop after finding the first '1'
            end
        end
    end

endmodule
