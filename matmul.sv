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
    input  logic rst, // Changed to match matmul_top [cite: 33]
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

    typedef enum logic [1:0] { STATE_IDLE, STATE_RUNNING } engine_state_t;
    engine_state_t curr_state, next_state;

    // --- Stage 0: Address Generation ---
    logic [DIM_INDEX_WIDTH:0] row_cnt, col_cnt;
    logic [DIM_INDEX_WIDTH:0] row_cnt_next, col_cnt_next;
    
    // --- Stage 1: Multiplication Pipeline ---
    logic [DIM_SIZE-1:0][DATA_BIT_WIDTH-1:0] mult_results;
    logic [TOTAL_ADDR_WIDTH-1:0] addr_s1;
    logic valid_s1, last_s1;

    // --- Stage 2: Accumulation Pipeline ---
    logic [DATA_BIT_WIDTH-1:0] sum_wire; // Combinational sum of mult_results
    logic [TOTAL_ADDR_WIDTH-1:0] addr_s2;
    logic valid_s2, last_s2;

    assign next_row_req = row_cnt[DIM_INDEX_WIDTH-1:0];
    assign next_col_req = col_cnt[DIM_INDEX_WIDTH-1:0];

    // Combinational Adder Tree (Stage 2 input)
    always_comb begin
        sum_wire = '0;
        for (int k = 0; k < DIM_SIZE; k++) begin
            sum_wire = sum_wire + mult_results[k];
        end
    end

    // FSM and Counter Logic
    always_comb begin
        next_state   = curr_state;
        row_cnt_next = row_cnt;
        col_cnt_next = col_cnt;

        case (curr_state)
            STATE_IDLE: begin
                if (start_cmd) next_state = STATE_RUNNING;
                row_cnt_next = '0;
                col_cnt_next = '0;
            end
            STATE_RUNNING: begin
                col_cnt_next = col_cnt + 1'b1;
                if (col_cnt_next == DIM_SIZE) begin
                    col_cnt_next = '0;
                    row_cnt_next = row_cnt + 1'b1;
                end
                if (row_cnt_next == DIM_SIZE) next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Sequential Pipeline Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state     <= STATE_IDLE;
            row_cnt        <= '0;
            col_cnt        <= '0;
            valid_s1       <= 1'b0;
            valid_s2       <= 1'b0;
            res_write_en   <= 1'b0;
            res_write_data <= '0;
            res_write_addr <= '0;
            exec_done      <= 1'b0;
        end else begin
            curr_state <= next_state;
            row_cnt    <= row_cnt_next;
            col_cnt    <= col_cnt_next;

            // --- STAGE 1: Multiply ---
            valid_s1 <= (curr_state == STATE_RUNNING);
            // Proper flattening: row * DIM_SIZE + col
            addr_s1  <= (row_cnt[DIM_INDEX_WIDTH-1:0] << DIM_INDEX_WIDTH) | col_cnt[DIM_INDEX_WIDTH-1:0];
            last_s1  <= (row_cnt_next == DIM_SIZE);

            for (int k = 0; k < DIM_SIZE; k++) begin
                mult_results[k] <= row_data_in[k] * col_data_in[k];
            end

            // --- STAGE 2: Register the Sum ---
            valid_s2       <= valid_s1;
            addr_s2        <= addr_s1;
            last_s2        <= last_s1;
            res_write_data <= sum_wire;

            // --- Output Assignment ---
            res_write_en   <= valid_s2;
            res_write_addr <= addr_s2;
            exec_done      <= last_s2 && valid_s2;
        end
    end
endmodule
