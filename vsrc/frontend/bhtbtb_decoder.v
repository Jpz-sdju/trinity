module bhtbtb_decoder (
    input [31:0] bht_rd_data,//16 saturate cnt
    input [31:0] btb_rd_data,//predict target
    input btbtag_hit,
    input [63:0] bhtbtb2dec_pc,
    output [63:0] trigger_pc,
    output [63:0] predict_target,
    output predict_valid

);
    wire [3:0] first_taken_index;
    wire [63:0] trigger_pc;
    integer i; // Loop variable
    always @(*) begin
        first_taken_index = 4'b1111;      //only for debug
        trigger_pc = 64'b0;               // Default to 0
        predict_valid = 0;                  // Default: no branch taken found
        predict_target = 0;
        if(btbtag_hit)begin 
        //if(btbtag_hit && (predict_target[2]==0))begin
            for (i = 0; i < 16; i = i + 1) begin
                // Extract 2 bits for the current counter
                if (bht_rd_data[i*2 +: 2] >= 2'b10) begin       // Check for `10` or `11`
                    first_taken_index = i[3:0];                 // Record the index
                    trigger_pc = bhtbtb2dec_pc + (i * 4);       // Calculate PC
                    predict_valid = 1;                            // Indicate a valid branch
                    predict_target = {32'd0,btb_rd_data};
                    break;                                      // Stop checking further
                end
            end
        end
    end

    
endmodule