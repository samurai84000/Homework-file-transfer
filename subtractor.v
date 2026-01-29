module subtractor #(
    parameter DATA_INPUT = 8
)(
    input  logic                   clk,
    input  logic                   reset,
    input  logic [DATA_INPUT-1:0]  new_frame_data,
    input  logic [DATA_INPUT-1:0]  old_frame_data,
    input  logic                   ready,
    output logic                   frame_difference,
    output logic                   valid_data
);

    typedef enum logic [0:0] {IDLE, RUNNING} state_t;
    state_t curr_state, next_state;

    // Internal variable for calculation
    logic [DATA_INPUT-1:0] diff_result;

    // --- Process 1: Sequential Logic (State Register) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    // --- Process 2: Combinational Logic (Next State & Outputs) ---
    always_comb begin
        // Default assignments to prevent latches
        next_state = curr_state;
        valid_data = 1'b0;
        frame_difference = 1'b0;
        diff_result = '0;

        case (curr_state)
            IDLE: begin
                if (ready) begin
                    // Calculate absolute difference [cite: 8, 9]
                    if (old_frame_data >= new_frame_data)
                        diff_result = old_frame_data - new_frame_data;
                    else
                        diff_result = new_frame_data - old_frame_data;

                    // Apply Threshold (50) to detect motion 
                    frame_difference = (diff_result >= 50) ? 1'b1 : 1'b0;
                    valid_data = 1'b1;
                    next_state = RUNNING;
                end
            end

            RUNNING: begin
                if (ready) begin
                    // Continue processing while ready [cite: 132]
                    if (old_frame_data >= new_frame_data)
                        diff_result = old_frame_data - new_frame_data;
                    else
                        diff_result = new_frame_data - old_frame_data;

                    frame_difference = (diff_result >= 50) ? 1'b1 : 1'b0;
                    valid_data = 1'b1;
                    next_state = RUNNING; 
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
