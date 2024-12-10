module pc_ctrl (
    input wire clock,   // Clock signal
    input wire reset_n, // Active-low reset signal

    //boot and interrupt addr
    input wire [47:0] boot_addr,        // 48-bit boot address
    input wire        interrupt_valid,  // Interrupt valid signal
    input wire [47:0] interrupt_addr,   // 48-bit interrupt address

    //port with pju
    input wire        redirect_valid,
    input wire [47:0] redirect_target,

    //port with bpu
    input  wire [47:0] predict_target,
    input  wire predict_valid,

    //ports with ibuffer
    input  wire        fetch_inst,      // Fetch instruction signal, pulse signal for PC increment
    output reg         can_fetch_inst,  // Indicates if a new instruction can be fetched
    output reg         clear_ibuffer,
    output reg  [47:0] pc,              // 48-bit Program Counter  
    output reg         cancel_pc_fetch,

    //ports with channel_arb
    output reg         pc_index_valid,    // Valid signal for PC index
    output wire [18:0] pc_index,          // Selected bits [21:3] of the PC for DDR index
    input  wire        pc_index_ready,    // Signal indicating DDR operation is complete
    input  wire        pc_operation_done

);
    // Output the selected bits [21:3] of the current PC as pc_index
    assign pc_index = pc[21:3];

    localparam BOOT_SETTING_0 = 4'd0;
    localparam RAISE_VALID_NORMAL_1 = 4'd1;
    localparam NORMAL_PROCESS_2 = 4'd2;
    localparam NORMAL_DONE_3 = 4'd3;
    localparam WASTED_NORMAL_PROCESS_4 = 4'd4;
    localparam WASTED_NORMAL_DONE_5 = 4'd5;
    localparam REDIRECT_PROCESS_6 = 4'd6;
    localparam REDIRECT_DONE_7 = 4'd7;
    localparam CAN_FETCH_INST_8 = 4'd8;
    localparam GET_FETCH_INST_9 = 4'd9;
    localparam SET_PC_10 = 4'd10;
    localparam RAISE_VALID_REDIRECT_11 = 4'd11;

    reg [3:0] current_state;
    reg [3:0] next_state;

    always @(posedge clock or negedge reset_n) begin
        if(~reset_n) begin
            current_state <= 4'd0;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case(current_state)
            BOOT_SETTING_0: begin
                pc = boot_addr;
                pc_index_valid = 1'b0;
                can_fetch_inst = 1'b0;
                clear_ibuffer  = 1'b0;
                    next_state = RAISE_VALID_NORMAL_1;                
            end
            RAISE_VALID_NORMAL_1:begin
                pc_index_valid = 1'b1;
                if( pc_index_ready) begin
                    next_state = NORMAL_PROCESS_2;
                end
            end
            NORMAL_PROCESS_2:begin
                pc_index_valid = 1'b0;
                if(redirect_valid_or && ~pc_operation_done)begin
                    next_state = WASTED_NORMAL_PROCESS_4;
                end else if(pc_operation_done) begin
                    next_state = NORMAL_DONE_3;
                end
            end
            NORMAL_DONE_3:begin
                    next_state= CAN_FETCH_INST_8;
            end
            
            WASTED_NORMAL_PROCESS_4:begin
                cancel_pc_fetch = 1'b1;        
                if(pc_operation_done)begin
                    next_state = WASTED_NORMAL_DONE_5;
                end            
            end
            WASTED_NORMAL_DONE_5:begin
                cancel_pc_fetch = 1'b0;      
                next_state = CAN_FETCH_INST_8;
            end

            CAN_FETCH_INST_8:begin
                can_fetch_inst = 1'b1;
                if(fetch_inst)begin
                    next_state = GET_FETCH_INST_9;
                end
            end
            GET_FETCH_INST_9:begin
                can_fetch_inst = 1'b0;
                next_state =  SET_PC_10;               
            end

            SET_PC_10:begin
                if(redirect_valid_or)begin
                    pc = redirect_target_or; 
                    next_state = RAISE_VALID_REDIRECT_11;     
                end else if (predict_valid_or) begin
                    pc = predict_target_or; // only take aligned predict_target for now
                    next_state = RAISE_VALID_NORMAL_1;
                end else begin
                    pc = had_unalign_redirect ? pc + 60 :(pc + 64);
                    next_state = RAISE_VALID_NORMAL_1;
                end
            end

            RAISE_VALID_REDIRECT_11:begin
                pc_index_valid = 1'b1;
                if(pc_index_ready)begin
                    next_state = REDIRECT_PROCESS_6;
                end
            end
            REDIRECT_PROCESS_6: begin
                pc_index_valid = 1'b0;
                if(pc_operation_done)begin
                    next_state = REDIRECT_DONE_7;
                end
            end
            REDIRECT_DONE_7: begin
                next_state = CAN_FETCH_INST_8;
            end

            default:begin
                
            end
        endcase
    end

    reg redirect_valid_latch;
    reg [47:0] redirect_target_latch;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            redirect_valid_latch <= 1'b0;
            redirect_target_latch <= 48'd0;
        end else if (redirect_valid) begin
            redirect_valid_latch <= 1'b1; 
            redirect_target_latch <= redirect_target;
        end else if (current_state == REDIRECT_DONE_7) begin
            redirect_valid_latch <= 1'b0;
            redirect_target_latch <= 48'd0;
        end
    end

    wire redirect_valid_or;
    assign redirect_valid_or = redirect_valid || redirect_valid_latch;
    wire [47:0] redirect_target_or;
    assign redirect_target_or = ({48{redirect_valid}} & redirect_target) | ({48{redirect_valid_latch}} & redirect_target_latch);

    reg had_unalign_redirect;
    always @(posedge clock or negedge reset_n ) begin
        if(~reset_n) begin
            had_unalign_redirect <= 'b0;
        end
        else begin
            if(redirect_valid & redirect_target[2] ) begin
                had_unalign_redirect <= 1'b1;
            end else if  (redirect_valid & ~redirect_target[2] ) begin
                had_unalign_redirect <= 1'b0;                
            end else if((current_state == NORMAL_DONE_3)) begin
                had_unalign_redirect <= 1'b0;
            end
        end
    end

    reg predict_valid_latch;
    reg [47:0] predict_target_latch;
    always @(posedge clock or negedge reset_n) begin
        if(~reset_n)begin
            predict_valid_latch <= 1'b0;
            predict_target_latch <= 48'd0;
        end else if (predict_valid) begin
            predict_valid_latch <= 1'b1; 
            predict_target_latch <= predict_target;
        end else if (current_state == NORMAL_DONE_3) begin
            predict_valid_latch <= 1'b0;
            predict_target_latch <= 48'd0;
        end
    end

    wire predict_valid_or;
    assign predict_valid_or = predict_valid || predict_valid_latch;
    wire [47:0] predict_target_or;
    assign predict_target_or = ({48{predict_valid}} & predict_target) | ({48{predict_valid_latch}} & predict_target_latch);



endmodule
