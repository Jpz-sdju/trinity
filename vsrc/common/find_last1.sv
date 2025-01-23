module find_last1 #(
    parameter WIDTH = 8
) (
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

    always @(*) begin
        integer i;
        data_out = 'b0;
        if (~(|data_in)) begin
            /* ------------------------- cause shift at outside ------------------------- */
            data_out[WIDTH-1] = 1'b1;
        end else begin
            for (i = WIDTH - 1; i >= 0; i = i - 1) begin
                if (data_in[i]) begin
                    data_out[i] = 1'b1;
                    break;
                end
            end
        end
    end

endmodule
