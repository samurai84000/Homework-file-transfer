module cordic_stage #(
    parameter integer STAGE = 0,
    parameter integer BITS = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic signed [BITS-1:0] x_in,
    input  logic signed [BITS-1:0] y_in,
    input  logic signed [BITS-1:0] z_in,
    input  logic signed [BITS-1:0] angle_lut,
    input  logic v_in,
    output logic signed [BITS-1:0] x_out,
    output logic signed [BITS-1:0] y_out,
    output logic signed [BITS-1:0] z_out,
    output logic v_out
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_out <= 0; y_out <= 0; z_out <= 0; v_out <= 0;
        end else begin
            v_out <= v_in;
            if (!z_in[BITS-1]) begin // z >= 0
                x_out <= x_in - (y_in >>> STAGE);
                y_out <= y_in + (x_in >>> STAGE);
                z_out <= z_in - angle_lut;
            end else begin // z < 0
                x_out <= x_in + (y_in >>> STAGE);
                y_out <= y_in - (x_in >>> STAGE);
                z_out <= z_in + angle_lut;
            end
        end
    end
endmodule