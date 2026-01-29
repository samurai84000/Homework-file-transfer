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
    state_t state;

    // We use a temporary logic variable for the math result
    logic [DATA_INPUT-1:0] diff_result;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            frame_difference <= 1'b0;
            valid_data       <= 1'b0;
        end else begin
            // Default: valid is low unless we process data
            valid_data <= 1'b0;

            case (state)
                IDLE: begin
                    if (ready) begin
                        // Do math
                        if (old_frame_data >= new_frame_data)
                            diff_result = old_frame_data - new_frame_data;
                        else
                            diff_result = new_frame_data - old_frame_data;

                        // Set outputs
                        frame_difference <= (diff_result >= 50) ? 1'b1 : 1'b0;
                        valid_data       <= 1'b1;
                        state            <= RUNNING;
                    end
                end

                RUNNING: begin
                    if (ready) begin
                        if (old_frame_data >= new_frame_data)
                            diff_result = old_frame_data - new_frame_data;
                        else
                            diff_result = new_frame_data - old_frame_data;

                        frame_difference <= (diff_result >= 50) ? 1'b1 : 1'b0;
                        valid_data       <= 1'b1;
                        // Stay in RUNNING
                    end else begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule