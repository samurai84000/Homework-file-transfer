module matmul_top
#(
    parameter DATA_WIDTH    = 32,
    parameter MAT_DIM_WIDTH = 3,
    parameter MAT_DIM_SIZE  = 2 ** MAT_DIM_WIDTH,
    parameter ADDR_WIDTH    = MAT_DIM_WIDTH * 2,
    parameter MAT_SIZE      = 2 ** ADDR_WIDTH
)
(
    input  logic clk,
    input  logic rst,
    input  logic start,

    // Write interface for initial loading of X/Y matrices
    input  logic [ MAT_DIM_SIZE-1 : 0 ] mat_x_we,
    input  logic [ MAT_DIM_SIZE-1 : 0 ] mat_y_we,
    input  logic [ DATA_WIDTH-1 : 0 ]     mat_x_w_data,
    input  logic [ DATA_WIDTH-1 : 0 ]     mat_y_w_data,
    input  logic [ MAT_DIM_WIDTH-1 : 0 ] mat_x_w_addr,
    input  logic [ MAT_DIM_WIDTH-1 : 0 ] mat_y_w_addr,

    // Read interface for the Result (Z) matrix
    input  logic [ ADDR_WIDTH-1 : 0 ]    res_r_addr,
    output logic [ DATA_WIDTH-1 : 0 ]    res_r_data,
    output logic                         calculation_done
);

    /* Interconnect Signals */
    logic [ MAT_DIM_WIDTH-1 : 0 ] row_read_req_addr;
    logic [ MAT_DIM_WIDTH-1 : 0 ] col_read_req_addr;
    logic [ MAT_DIM_SIZE-1 : 0 ][ DATA_WIDTH-1 : 0 ] row_bus, col_bus;

    logic                        res_internal_we;
    logic [ ADDR_WIDTH-1 : 0 ]   res_internal_w_addr;
    logic [ DATA_WIDTH-1 : 0 ]   res_internal_w_data;

    /* Result Matrix (Z) - Flat BRAM */
    bram #(
        .BRAM_ADDR_WIDTH( ADDR_WIDTH ),
        .BRAM_DATA_WIDTH( DATA_WIDTH )
    ) result_mem_inst (
        .clock   ( clk ),
        .rd_addr ( res_r_addr ),
        .wr_addr ( res_internal_w_addr ),
        .wr_en   ( res_internal_we ),
        .din     ( res_internal_w_data ),
        .dout    ( res_r_data )
    );

    /* Input Matrices (X and Y) - Banked BRAMs */
    bram_block #(
        .BRAM_ADDR_WIDTH ( MAT_DIM_WIDTH ),
        .BANK_DATA_WIDTH ( DATA_WIDTH ),
        .BANK_CNT        ( MAT_DIM_SIZE ),
        .BRAM_DATA_WIDTH ( DATA_WIDTH * MAT_DIM_SIZE )
    )
    matrix_x_inst (
        .clock   ( clk ),
        .rd_addr ( row_read_req_addr ),
        .wr_addr ( mat_x_w_addr ),
        .wr_en   ( mat_x_we ),
        .din     ( mat_x_w_data ),
        .dout    ( row_bus )
    ),
    matrix_y_inst (
        .clock   ( clk ),
        .rd_addr ( col_read_req_addr ),
        .wr_addr ( mat_y_w_addr ),
        .wr_en   ( mat_y_we ),
        .din     ( mat_y_w_data ),
        .dout    ( col_bus )
    );

    /* Matrix Multiplication Engine */
    matmul #(
        .DATA_BIT_WIDTH   ( DATA_WIDTH ),
        .DIM_INDEX_WIDTH  ( MAT_DIM_WIDTH ),
        .DIM_SIZE         ( MAT_DIM_SIZE ),
        .TOTAL_ADDR_WIDTH ( ADDR_WIDTH ),
        .TOTAL_MAT_SIZE   ( MAT_SIZE )
    ) engine_inst (
        .clk            ( clk ),
        .rst_n          ( rst ),
        .start_cmd      ( start ),
        .row_data_in    ( row_bus ),
        .col_data_in    ( col_bus ),
        .next_row_req   ( row_read_req_addr ),
        .next_col_req   ( col_read_req_addr ),
        .res_write_en   ( res_internal_we ),
        .res_write_addr ( res_internal_w_addr ),
        .res_write_data ( res_internal_w_data ),
        .exec_done      ( calculation_done )
    );

endmodule
