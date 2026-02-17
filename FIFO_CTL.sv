module fifo_ctrl #(
    parameter FIFO_BUFFER_SIZE = 1024
)(
    input  logic       reset,
    input  logic       wr_clk,
    input  logic       wr_en,
    input  logic [7:0] din,
    input  logic       sof_in,
    input  logic       eof_in,
    output logic       full,    // Gated Full

    input  logic       rd_clk,
    input  logic       rd_en,
    output logic [7:0] dout,
    output logic       sof_out,
    output logic       eof_out,
    output logic       empty    // Gated Empty
);

    logic data_full, ctrl_full;
    logic data_empty, ctrl_empty;

    // 1. Data FIFO: 8-bit wide for datagram bytes [cite: 39]
    fifo #(
        .FIFO_DATA_WIDTH(8),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) data_fifo_inst (
        .reset(reset),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .din(din),
        .full(data_full),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .dout(dout),
        .empty(data_empty)
    );

    // 2. Control FIFO: 2-bit wide for {sof, eof} [cite: 39]
    fifo #(
        .FIFO_DATA_WIDTH(2),
        .FIFO_BUFFER_SIZE(FIFO_BUFFER_SIZE)
    ) ctrl_fifo_inst (
        .reset(reset),
        .wr_clk(wr_clk),
        .wr_en(wr_en),
        .din({sof_in, eof_in}),
        .full(ctrl_full),
        .rd_clk(rd_clk),
        .rd_en(rd_en),
        .dout({sof_out, eof_out}),
        .empty(ctrl_empty)
    );

    // Gated Logic: Combined status for the system
    // Full if either buffer is full to prevent overflow 
    assign full  = data_full | ctrl_full;
    
    // Empty if either buffer is empty to maintain sync [cite: 151]
    assign empty = data_empty | ctrl_empty;

endmodule	 