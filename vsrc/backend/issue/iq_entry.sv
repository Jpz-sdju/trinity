module iq_entry (
    input  wire                      clock,
    input  wire                      reset_n,
    input  wire                      enq_valid,
    input  wire [         `PC_RANGE] enq_pc,
    input  wire [              31:0] enq_instr,
    output wire                      enq_ready,
    input  wire [       `LREG_RANGE] enq_lrs1,
    input  wire [       `LREG_RANGE] enq_lrs2,
    input  wire [       `LREG_RANGE] enq_lrd,
    input  wire [              63:0] enq_imm,
    input  wire                      enq_src1_is_reg,
    input  wire                      enq_src2_is_reg,
    input  wire                      enq_need_to_wb,
    input  wire [    `CX_TYPE_RANGE] enq_cx_type,
    input  wire                      enq_is_unsigned,
    input  wire [   `ALU_TYPE_RANGE] enq_alu_type,
    input  wire [`MULDIV_TYPE_RANGE] enq_muldiv_type,
    input  wire                      enq_is_word,
    input  wire                      enq_is_imm,
    input  wire                      enq_is_load,
    input  wire                      enq_is_store,
    input  wire [               3:0] enq_ls_size,

    input wire [`PREG_RANGE] enq_prs1,
    input wire [`PREG_RANGE] enq_prs2,
    input wire [`PREG_RANGE] enq_prd,
    input wire [`PREG_RANGE] enq_old_prd,

    input wire                     enq_robidx_flag,
    input wire [`ROB_SIZE_LOG-1:0] enq_robidx,

    /* -------------------------------- src state ------------------------------- */
    input wire enq_src1_state,
    input wire enq_src2_state,

    /* ------------------------------- ready to go ------------------------------ */
    output wire ready_to_go,

    /* ------------------------------- write back ------------------------------- */
    input wire writeback0_wakeup_src1,
    input wire writeback0_wakeup_src2,
    input wire writeback1_wakeup_src1,
    input wire writeback1_wakeup_src2,

    /* ---------------------------------- issue --------------------------------- */
    input wire issue

);
    // Internal queue storage
    reg                      queue_valid;
    reg [         `PC_RANGE] queue_pc;
    reg [              31:0] queue_instr;
    reg [       `PREG_RANGE] queue_prs1;
    reg [       `PREG_RANGE] queue_prs2;
    reg                      queue_src1_is_reg;
    reg                      queue_src2_is_reg;
    reg                      queue_src1_state;
    reg                      queue_src2_state;

    reg [       `PREG_RANGE] queue_prd;
    reg [       `PREG_RANGE] queue_old_prd;
    reg [        `SRC_RANGE] queue_imm;

    reg                      queue_need_to_wb;
    reg [    `CX_TYPE_RANGE] queue_cx_type;
    reg                      queue_is_unsigned;
    reg [   `ALU_TYPE_RANGE] queue_alu_type;
    reg [`MULDIV_TYPE_RANGE] queue_muldiv_type;
    reg                      queue_is_word;
    reg                      queue_is_imm;
    reg                      queue_is_load;
    reg                      queue_is_store;
    reg [               3:0] queue_ls_size;

    reg                      queue_robidx_flag;
    reg [ `ROB_SIZE_LOG-1:0] queue_robidx;

    reg                      queue_ready_to_go;


    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_valid <= 1'b0;
        end else begin
            queue_valid <= enq_valid;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_pc <= 'b0;
        end else begin
            queue_pc <= enq_pc;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_instr <= 'b0;
        end else begin
            queue_instr <= enq_instr;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_prs1 <= 'b0;
        end else begin
            queue_prs1 <= enq_prs1;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_prs2 <= 'b0;
        end else begin
            queue_prs2 <= enq_prs2;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src1_is_reg <= 1'b0;
        end else begin
            queue_src1_is_reg <= enq_src1_is_reg;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src2_is_reg <= 1'b0;
        end else begin
            queue_src2_is_reg <= enq_src2_is_reg;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src1_state <= 1'b0;
        end else begin
            queue_src1_state <= enq_src1_state;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_src2_state <= 1'b0;
        end else begin
            queue_src2_state <= enq_src2_state;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_prd <= 'b0;
        end else begin
            queue_prd <= enq_prd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_old_prd <= 'b0;
        end else begin
            queue_old_prd <= enq_old_prd;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_imm <= 'b0;
        end else begin
            queue_imm <= enq_imm;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_need_to_wb <= 1'b0;
        end else begin
            queue_need_to_wb <= enq_need_to_wb;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_cx_type <= 'b0;
        end else begin
            queue_cx_type <= enq_cx_type;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_is_unsigned <= 1'b0;
        end else begin
            queue_is_unsigned <= enq_is_unsigned;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_alu_type <= 'b0;
        end else begin
            queue_alu_type <= enq_alu_type;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_muldiv_type <= 'b0;
        end else begin
            queue_muldiv_type <= enq_muldiv_type;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_is_word <= 1'b0;
        end else begin
            queue_is_word <= enq_is_word;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_is_imm <= 1'b0;
        end else begin
            queue_is_imm <= enq_is_imm;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_is_load <= 1'b0;
        end else begin
            queue_is_load <= enq_is_load;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_is_store <= 1'b0;
        end else begin
            queue_is_store <= enq_is_store;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_ls_size <= 'b0;
        end else begin
            queue_ls_size <= enq_ls_size;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_robidx_flag <= 1'b0;
        end else begin
            queue_robidx_flag <= enq_robidx_flag;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_robidx <= 'b0;
        end else begin
            queue_robidx <= enq_robidx;
        end
    end

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            queue_ready_to_go <= 1'b0;
        end else begin
            queue_ready_to_go <= issue;
        end
    end

endmodule
