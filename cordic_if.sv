`timescale 1ns/1ps
interface cordic_if(input logic clk, input logic reset);
    logic        theta_wr_en;
    logic [31:0] theta_din;
    logic        theta_full;
    logic        sin_rd_en;
    logic [15:0] sin_dout;
    logic        sin_empty;
    logic        cos_rd_en;
    logic [15:0] cos_dout;
    logic        cos_empty;
endinterface