module matmul
#(
    parameter DATA_BIT_WIDTH  = 32,
    parameter DIM_INDEX_WIDTH = 3,
    parameter DIM_SIZE        = 2**DIM_INDEX_WIDTH,
    parameter TOTAL_ADDR_WIDTH = DIM_INDEX_WIDTH*2,
    parameter TOTAL_MAT_SIZE   = 2**TOTAL_ADDR_WIDTH
)
(
    input  logic clk,
    input  logic rst_n,
    input  logic start_cmd,
    input  logic [ DIM_SIZE-1 : 0 ] [ DATA_BIT_WIDTH-1 : 0 ] row_data_in,
    input  logic [ DIM_SIZE-1 : 0 ] [ DATA_BIT_WIDTH-1 : 0 ] col_data_in,
    
    output logic [ DIM_INDEX_WIDTH-1 : 0 ] next_row_req,
    output logic [ DIM_INDEX_WIDTH-1 : 0 ] next_col_req,
    output logic                           res_write_en,
    output logic [ TOTAL_ADDR_WIDTH-1 : 0 ] res_write_addr,
    output logic [ DATA_BIT_WIDTH-1 : 0 ]   res_write_data,
    output logic                           exec_done
);

    typedef enum logic [ 1:0 ] { STATE_IDLE, STATE_RUNNING } engine_state_t;
    engine_state_t curr_state, next_state;

    // --- Stage 0: Address Generation ---
    logic [ DIM_INDEX_WIDTH : 0 ] row_cnt, col_cnt;
    logic [ DIM_INDEX_WIDTH : 0 ] row_cnt_next, col_cnt_next;
    
    // --- Stage 1: Multiplication Pipeline ---
    logic [ DIM_SIZE-1 : 0 ] [ DATA_BIT_WIDTH-1 : 0 ] mult_results;
    logic [ TOTAL_ADDR_WIDTH-1 : 0 ] addr_s1;
    logic valid_s1, last_s1;

    // --- Stage 2: Accumulation Pipeline ---
    logic [ DATA_BIT_WIDTH-1 : 0 ] sum_s2;
    logic [ TOTAL_ADDR_WIDTH-1 : 0 ] addr_s2;
    logic valid_s2, last_s2;

    assign next_row_req = row_cnt[ DIM_INDEX_WIDTH-1 : 0 ]; [cite: 14]
    assign next_col_req = col_cnt[ DIM_INDEX_WIDTH-1 : 0 ]; 

    // Address Generation Logic
    always_comb begin
        next_state   = curr_state;
        row_cnt_next = row_cnt;
        col_cnt_next = col_cnt;

        case (curr_state)
            STATE_IDLE: begin
                if (start_cmd) next_state = STATE_RUNNING;
                row_cnt_next = 0;
                col_cnt_next = 0;
            end
            STATE_RUNNING: begin
                col_cnt_next = col_cnt + 1; [cite: 23]
                if (col_cnt_next == DIM_SIZE) begin [cite: 24]
                    col_cnt_next = 0;
                    row_cnt_next = row_cnt + 1; [cite: 24]
                end
                if (row_cnt_next == DIM_SIZE) next_state = STATE_IDLE; [cite: 25, 26]
            end
        endcase
    end

    // Sequential Pipeline Logic
    always_ff @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            curr_state     <= STATE_IDLE;
            row_cnt        <= 0;
            col_cnt        <= 0;
            valid_s1       <= 0;
            valid_s2       <= 0;
            res_write_en   <= 0;
            exec_done      <= 0;
        end else begin
            curr_state <= next_state;
            row_cnt    <= row_cnt_next;
            col_cnt    <= col_cnt_next;

            // --- STAGE 1: Multiply ---
            valid_s1 <= (curr_state == STATE_RUNNING);
            addr_s1  <= (row_cnt * DIM_SIZE) + col_cnt; // Calculate flat address 
            last_s1  <= (row_cnt_next == DIM_SIZE);

            for (int k = 0; k < DIM_SIZE; k++) begin
                mult_results[k] <= row_data_in[k] * col_data_in[k]; 
            end

            // --- STAGE 2: Sum ---
            valid_s2 <= valid_s1;
            addr_s2  <= addr_s1;
            last_s2  <= last_s1;
            
            automatic logic [DATA_BIT_WIDTH-1:0] temp_sum = 0;
            for (int k = 0; k < DIM_SIZE; k++) begin
                temp_sum += mult_results[k]; 
            end
            sum_s2 <= temp_sum;

            // --- Output Assignment (Aligned with Stage 2) ---
            res_write_en   <= valid_s2;
            res_write_addr <= addr_s2;
            res_write_data <= sum_s2;
            exec_done      <= last_s2 && valid_s2;
        end
    end

endmodule
