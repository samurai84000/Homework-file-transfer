module subtractor #(
    parameter DATA_INPUT = 8
)(
    input  logic                   clk,
    input  logic                   reset,
    input  logic [DATA_INPUT-1:0]   new_frame_data,
    input  logic [DATA_INPUT-1:0]   old_frame_data,
    input  logic                   ready,
    output logic [DATA_INPUT-1:0]   frame_difference
);

typedef enum logic [1:0] {IDLE, RUNNING} state_t;
state_t curr_state, next_state;

logic [DATA_INPUT-1:0] C;


always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        curr_state       <= IDLE;
        frame_difference <= '0;
    end else begin
        curr_state       <= next_state;
        frame_difference <= C;
    end
end

always_comb begin
    C          = '0;
    next_state = curr_state;

    case (curr_state)
        IDLE: begin
            if (ready)
                next_state = RUNNING;
        end

        RUNNING: begin
            if (new_frame_data >= old_frame_data)
                C = new_frame_data - old_frame_data;
            else
                C = old_frame_data - new_frame_data;

            next_state = IDLE;
        end
    endcase
end

endmodule