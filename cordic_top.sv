`timescale 1ns/1ps

module cordic #(
    parameter integer BITS = 16,
    parameter integer STAGES = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic theta_wr_en,
    input  logic [31:0] theta_din,
    output logic theta_full,
    input  logic sin_rd_en,
    output logic [BITS-1:0] sin_dout,
    output logic sin_empty,
    input  logic cos_rd_en,
    output logic [BITS-1:0] cos_dout,
    output logic cos_empty
);

    // Constants in Q2.14 format (fixed-point)
    localparam signed [31:0] PI      = 32'sd51472;  // PI * 2^14
    localparam signed [31:0] HALF_PI = 32'sd25736;  // PI/2 * 2^14
    localparam signed [15:0] K_INV   = 16'h26DD;    // 0.60725 * 2^14

    // CORDIC Rotation LUT (Angles in Q2.14)
    const logic signed [15:0] LUT [0:15] = '{
        16'h3243, 16'h1DAC, 16'h0FAD, 16'h07F5, 16'h03FE, 16'h01FF, 16'h00FF, 16'h007F, 
        16'h003F, 16'h001F, 16'h000F, 16'h0007, 16'h0003, 16'h0001, 16'h0000, 16'h0000
    };

    logic [31:0] theta_raw;
    logic theta_fifo_empty, theta_fifo_rd;
    assign theta_fifo_rd = !theta_fifo_empty;

    // Input FIFO
    fifo #(.FIFO_DATA_WIDTH(32), .FIFO_BUFFER_SIZE(16)) in_f (
        .reset(reset), .wr_clk(clk), .wr_en(theta_wr_en), .din(theta_din), .full(theta_full),
        .rd_clk(clk), .rd_en(theta_fifo_rd), .dout(theta_raw), .empty(theta_fifo_empty)
    );

    // Pipeline signals
    logic signed [BITS-1:0] x_p [0:STAGES], y_p [0:STAGES], z_p [0:STAGES];
    logic v_p [0:STAGES];

    // --- FIXED PRE-ROTATION LOGIC ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_p[0] <= 0; y_p[0] <= 0; z_p[0] <= 0; v_p[0] <= 0;
        end else if (theta_fifo_rd) begin
            v_p[0] <= 1;
            // Use full 32-bit signed comparisons and arithmetic
            if ($signed(theta_raw) > HALF_PI) begin
                x_p[0] <= -K_INV;
                y_p[0] <= 0;
                z_p[0] <= $signed(theta_raw) - PI; // Fixed: Removed 16-bit truncation
            end else if ($signed(theta_raw) < -HALF_PI) begin
                x_p[0] <= -K_INV;
                y_p[0] <= 0;
                z_p[0] <= $signed(theta_raw) + PI; // Fixed: Removed 16-bit truncation
            end else begin
                x_p[0] <= K_INV;
                y_p[0] <= 0;
                z_p[0] <= theta_raw[15:0];
            end
        end else begin
            v_p[0] <= 0;
        end
    end

    // Pipeline Stages
    genvar i;
    generate
        for (i = 0; i < STAGES; i++) begin : p
            cordic_stage #(.STAGE(i), .BITS(BITS)) s (
                .clk(clk), .reset(reset), .v_in(v_p[i]), .angle_lut(LUT[i]),
                .x_in(x_p[i]), .y_in(y_p[i]), .z_in(z_p[i]),
                .x_out(x_p[i+1]), .y_out(y_p[i+1]), .z_out(z_p[i+1]), .v_out(v_p[i+1])
            );
        end
    endgenerate

    // Output FIFOs
    fifo #(.FIFO_DATA_WIDTH(BITS), .FIFO_BUFFER_SIZE(16)) s_f (
        .reset(reset), .wr_clk(clk), .rd_clk(clk), .wr_en(v_p[STAGES]),
        .din(y_p[STAGES]), .rd_en(sin_rd_en), .dout(sin_dout), .empty(sin_empty), .full()
    );

    fifo #(.FIFO_DATA_WIDTH(BITS), .FIFO_BUFFER_SIZE(16)) c_f (
        .reset(reset), .wr_clk(clk), .rd_clk(clk), .wr_en(v_p[STAGES]),
        .din(x_p[STAGES]), .rd_en(cos_rd_en), .dout(cos_dout), .empty(cos_empty), .full()
    );

endmodule