module bht_btb(
    input clk,
    input reset_n,
    input [63:0] pc,//rd_addr
    input pc_handshake,//rd_en
    input [63:0] wr_addr,
    input wr_en,
    input [32:0] bht_wr_data,
    input [32:0] btb_wr_data,
    //output wr_done,
    output [32:0] bht_rd_data,
    output [32:0] btb_rd_data,
    output btbtag_hit

);

wire rd_en;
assign rd_en = pc_handshake;

// control logic
wire [2:0] rd_cntr_addr;
wire [7:0] rd_set_addr;
assign rd_cntr_addr = pc[5:3];
assign rd_set_addr = pc[13:6];

wire [2:0] wr_cntr_addr;
wire [7:0] wr_set_addr;
assign wr_cntr_addr = wr_addr[5:3];
assign wr_set_addr = wr_addr[13:6];

//BTB control logic 

reg [127:0] bhtram [0:32]; //BHT (1+16*2-1): vld+16 saturate counter per entry
reg [127:0] btb_tagram [16:0]; //BTB tagram (1+16-1):for debug convenient ,take pc[15:0] as tag
reg [127:0] btb_dataram [0:32]; //BTB dataram (1+32-1): vld+pc[31:0],take pc[31:0] as target address, dont take out pc[1:0] for debug convenient

wire [32:0] bhtram_out;
wire [16:0] btb_tagram_out;
wire [32:0] btb_dataram_out;

//BHT logic
always @(posedge clk or negedge reset_n) begin
    if(~reset_n)begin
        bhtram <= 0;
    end else if (rd_en && wr_en)begin
        bhtram_out <= bht_wr_data;
        bhtram[wr_set_addr] <= bht_wr_data;        
    end else if (rd_en && ~wr_en) begin
        bhtram_out <= bhtram[rd_set_addr];
    end else if (~rd_en && wr_en) begin
        bhtram[wr_set_addr] <= bht_wr_data;
    end
end

//BTB tag logic
always @(posedge clk or negedge reset_n) begin
    if(~reset_n)begin
        btb_tagram <= 0;
    end else if (rd_en && wr_en)begin
        btb_tagram_out <= {1'd1,wr_addr[15:0]};
        btb_tagram[wr_set_addr] <= {1'd1,wr_addr[15:0]};
    end else if (rd_en && ~wr_en) begin
        btb_tagram_out <= btb_tagram[rd_set_addr];
    end else if (~rd_en && wr_en) begin
        btb_tagram[wr_set_addr] <= {1'd1,wr_addr[15:0]};
    end
end

//BTB data logic
always @(posedge clk or negedge reset_n) begin
    if(~reset_n)begin
        btb_dataram <= 0;
    end else if (rd_en && wr_en)begin
        btb_dataram_out <= btb_wr_data;
        btb_dataram[wr_set_addr] <= btb_wr_data;
    end else if (rd_en && ~wr_en) begin
        btb_dataram_out <= btb_dataram[rd_set_addr];
    end else if (~rd_en && wr_en) begin
        btb_dataram[wr_set_addr] <= btb_wr_data;
    end
end

assign btbtag_hit = (pc == btb_tagram_out);
assign bht_rd_data = btbtag_hit ? bhtram_out:32'd0;
assign btb_rd_data = btbtag_hit ? btb_dataram_out:32'd0;



endmodule