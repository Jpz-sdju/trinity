`include "defines.sv"

module rename #(

) (
    //we need to get srcType to determine raw hazard logic and 
    input wire [`LREG_RANGE] lrs1_0,
    input wire [`LREG_RANGE] lrs2_0,
    input wire [`LREG_RANGE] lrd_0,

    input wire src1_is_reg_0,
    input wire src2_is_reg_0,
    input wire need_to_wb_0,


    input wire [`LREG_RANGE] lrs1_1,
    input wire [`LREG_RANGE] lrs2_1,
    input wire [`LREG_RANGE] lrd_1,

    input wire src1_is_reg_1,
    input wire src2_is_reg_1,
    input wire need_to_wb_1,


    input wire [`PREG_RANGE] rat_read_data_prs1_0,
    input wire [`PREG_RANGE] rat_read_data_prs2_0,
    input wire [`PREG_RANGE] rat_read_data_prd_0,

    input wire [`PREG_RANGE] rat_read_data_prs1_1,
    input wire [`PREG_RANGE] rat_read_data_prs2_1,
    input wire [`PREG_RANGE] rat_read_data_prd_1,


    //alloc freelist preg num
    output wire freelist_alloc_valid_0,
    output wire freelist_alloc_valid_1,

    input wire [`PREG_RANGE] freelist_alloc_data_0,
    input wire [`PREG_RANGE] freelist_alloc_data_1,



);


//now we get all information 

    wire [`PREG_RANGE] new_prd_0;
    wire [`PREG_RANGE] new_prd_1;
    assign new_prd_0 = freelist_alloc_data_0;
    assign new_prd_1 = freelist_alloc_data_1;

    wire rs1_raw_hazard;
    wire rs2_raw_hazard;
    assign rs1_raw_hazard = (lrd_0  == lrs1_1 ) & (need_to_wb_0 & src1_is_reg_1) ; 
    assign rs2_raw_hazard = (lrd_0 == lrs2_1) &(need_to_wb_0 & src2_is_reg_1);

    wire waw_detect ;
    assign waw_detect = (lrd_0 == lrd1) & (need_to_wb_0 & need_to_wb_1);


    wire [`PREG_RANGE] prs1_muxed;
    wire [`PREG_RANGE] prs2_muxed;
    // wire [`PREG_RANGE] prd_muxed; //dont need this!!
    wire [`PREG_RANGE] old_prd_muxed; 
    

    //to qual issue 0 have rd?
    assign prs1_muxed = rs1_raw_hazard  ?  new_prd_0 : rat_read_data_prs1_1;
    assign prs2_muxed = rs2_raw_hazard  ?  new_prd_0 : rat_read_data_prs2_1;

    assign old_prd_muxed = waw_detect ? new_prd_0 : rat_read_data_prd_1;

    
    
endmodule