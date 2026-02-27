module matmul_llama_200mhz #(
    parameter INT_WIDTH   = 8,
    parameter GS          = 64
)(
    input  logic clock,
    input  logic reset,
    input  logic start,
    input  logic [15:0] n,
    input  logic signed [INT_WIDTH-1:0] w_q, x_q,
    input  logic [31:0] w_s, x_s, 
    output logic [31:0] row_final_out,
    output logic        row_done
);

    // --- STAGE 1: The "Slim" Integer MAC ---
    // Using your 22-bit idea to keep the carry-chain short
    logic signed [21:0] ival_22;
    logic [7:0]  gs_cnt;
    logic [15:0] total_cnt;
    logic        pulse_dequant;
    logic signed [21:0] ival_reg; // EXTRA PIPELINE REGISTER HERE

    always_ff @(posedge clock) begin
        if (reset) begin
            ival_22 <= '0; gs_cnt <= '0; total_cnt <= '0; pulse_dequant <= 1'b0;
        end else if (start && total_cnt < n) begin
            ival_22 <= (gs_cnt == 0) ? (w_q * x_q) : (ival_22 + (w_q * x_q));
            gs_cnt  <= gs_cnt + 1;
            total_cnt <= total_cnt + 1;
            
            if (gs_cnt == GS-1) begin
                pulse_dequant <= 1'b1;
                ival_reg      <= ival_22 + (w_q * x_q); // Freeze the sum
                gs_cnt        <= '0;
            end else pulse_dequant <= 1'b0;
        end else pulse_dequant <= 1'b0;
    end

    // --- STAGE 2: The Scaling "Breakers" ---
    // We add TWO stages of registers between the multipliers.
    // This allows the DSP blocks to use their internal "Output Registers".
    
    logic [31:0] s1_ws_xs;
    logic [31:0] s2_ws_xs; // Deep pipe
    logic [31:0] s3_final_prod;
    logic s1_v, s2_v, s3_v;

    always_ff @(posedge clock) begin
        s1_v    <= pulse_dequant;
        s1_ws_xs <= w_s * x_s;     // Multiplier 1

        s2_v    <= s1_v;
        s2_ws_xs <= s1_ws_xs;      // Routing Buffer (Critical for 200MHz)

        s3_v    <= s2_v;
        s3_final_prod <= s2_ws_xs * 32'(ival_reg); // Multiplier 2
    end

    // --- STAGE 3: Split Accumulator ---
    // 32-bit addition can be slow. We break it into two 16-bit chunks 
    // if needed, but at 32-bits, a single register often suffices.
    logic [31:0] f_accum;
    always_ff @(posedge clock) begin
        if (s3_v) f_accum <= f_accum + s3_final_prod;
        if (start && total_cnt == 0) f_accum <= '0;
    end

    // Shift the "Done" signal to match the new pipeline depth
    logic [5:0] done_pipe;
    always_ff @(posedge clock) begin
        done_pipe <= {done_pipe[4:0], (total_cnt == n && n > 0)};
        row_done  <= done_pipe[5];
        row_final_out <= f_accum;
    end

endmodule
