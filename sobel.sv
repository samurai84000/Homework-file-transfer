module Sobel(
    input  logic clk,
    input  logic rst,
    input  logic [7:0] pixel_in,
    output logic [7:0] sobel_pixel
);

    typedef enum logic [1:0] {init, reading, sobel_process} states;
    states curr_state, next_state;

    // Internal Registers (The Memory)
    logic [7:0] prev_pixel_row [0:719];
    logic [7:0] curr_pixel_row [0:719];
    logic [9:0] counter;      // Column counter (0-719)
    logic [9:0] row_counter;  // Row counter (0-539)
    logic [1:0] counter_looparound;
    logic [7:0] w [0:2][0:2]; 

    // Combinational "Next-Value" signals
    logic [9:0] next_counter;
    logic [9:0] next_row_counter;
    logic [1:0] next_counter_looparound;
    logic [7:0] next_w [0:2][0:2];
    
    // Sobel Math Wires
    logic signed [10:0] Gx, Gy;
    logic [10:0] abs_Gx, abs_Gy, sum_G;
    logic is_border;

    // --- SEQUENTIAL BLOCK: Clocking Registers ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_state         <= init;
            counter            <= 0;
            row_counter        <= 0;
            counter_looparound <= 0;
            // Clear window registers
            for (int i=0; i<3; i++) for (int j=0; j<3; j++) w[i][j] <= 8'h00;
        end else begin
            curr_state         <= next_state;
            counter            <= next_counter;
            row_counter        <= next_row_counter;
            counter_looparound <= next_counter_looparound;
            
            // Apply window updates
            for (int i=0; i<3; i++) for (int j=0; j<3; j++) w[i][j] <= next_w[i][j];

            // Buffer writes (Must be in FF to infer RAM correctly)
            if (curr_state == reading) begin
                if (counter_looparound == 0) prev_pixel_row[counter] <= pixel_in;
                else curr_pixel_row[counter] <= pixel_in;
            end else if (curr_state == sobel_process) begin
                prev_pixel_row[counter] <= curr_pixel_row[counter];
                curr_pixel_row[counter] <= pixel_in;
            end
        end
    end

    // --- SINGLE COMBINATIONAL BLOCK: All Logic, Math, and Border Handling ---
    always_comb begin
        // 1. Default Assignments (Prevents Latches)
        next_state = curr_state;
        next_counter = counter;
        next_row_counter = row_counter;
        next_counter_looparound = counter_looparound;
        for (int i=0; i<3; i++) for (int j=0; j<3; j++) next_w[i][j] = w[i][j];

        // 2. State Machine and Counter Logic
        case (curr_state)
            init: begin
                next_state = reading;
                next_counter = 0;
                next_row_counter = 0;
                next_counter_looparound = 0;
            end

            reading: begin
                if (counter < 719) begin
                    next_counter = counter + 1;
                end else begin
                    next_counter = 0;
                    next_row_counter = row_counter + 1;
                    if (counter_looparound == 1) begin
                        next_state = sobel_process;
                        next_row_counter = 2; // We are starting the 3rd row (index 2)
                    end else begin
                        next_counter_looparound = counter_looparound + 1;
                    end
                end
            end

            sobel_process: begin
                // Update next window state (Shift left + inject new column)
                for (int i = 0; i < 3; i++) begin
                    next_w[i][0] = w[i][1];
                    next_w[i][1] = w[i][2];
                end
                next_w[0][2] = prev_pixel_row[counter];
                next_w[1][2] = curr_pixel_row[counter];
                next_w[2][2] = pixel_in;

                // Handle Counter Wrap-around
                if (counter == 719) begin
                    next_counter = 0;
                    if (row_counter < 539) next_row_counter = row_counter + 1;
                end else begin
                    next_counter = counter + 1;
                end
            end
        endcase

        // 3. Parallel Sobel Math
        // Gx = [-1 0 1, -2 0 2, -1 0 1]
        Gx = (w[0][2] + (w[1][2] << 1) + w[2][2]) - (w[0][0] + (w[1][0] << 1) + w[2][0]);
        // Gy = [1 2 1, 0 0 0, -1 -2 -1]
        Gy = (w[0][0] + (w[0][1] << 1) + w[0][2]) - (w[2][0] + (w[2][1] << 1) + w[2][2]);

        abs_Gx = (Gx < 0) ? -Gx : Gx;
        abs_Gy = (Gy < 0) ? -Gy : Gy;
        sum_G = abs_Gx + abs_Gy;

        // 4. Border Check and Final Output Assignment
        // Border occurs at Col 0, Col 719, Row 0, or Row 539
        is_border = (counter == 0) || (counter == 719) || (row_counter == 0) || (row_counter == 539);

        if (curr_state == sobel_process) begin
            if (is_border)
                sobel_pixel = 8'h00; // Black border
            else
                sobel_pixel = (sum_G > 255) ? 8'hFF : sum_G[7:0]; // Math + Saturation
        end else begin
            sobel_pixel = 8'h00; // Black while buffering
        end
    end

endmodule
