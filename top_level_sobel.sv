module top_level (
    input  logic        clk,
    input  logic        rst,
    
    // External Interface (Connects to Testbench)
    input  logic        in_wr_en,
    input  logic [23:0] in_din,     // RGB Input
    output logic        in_full,
    
    input  logic        out_rd_en,   // Added for TB compatibility
    output logic [7:0]  out_dout,    // Sobel Output
    output logic        out_empty    // Added for TB compatibility
);

    // --- Intermediate Signals ---
    
    // FIFO 1 (Input) to Grayscale
    logic [23:0] fifo1_to_gs_data;
    logic        gs_rd_en; [cite: 50]
    logic        fifo1_empty;
    
    // Grayscale to FIFO 2 (Intermediate)
    logic [7:0]  gs_to_fifo2_data; [cite: 51]
    logic        gs_wr_en; [cite: 52]
    logic        fifo2_full;
    
    // FIFO 2 (Intermediate) to Sobel
    logic [7:0]  fifo2_to_sobel_data; [cite: 53]
    logic        sobel_rd_en; [cite: 54]
    logic        fifo2_empty;
    
    // Sobel to FIFO 3 (Output)
    logic [7:0]  sobel_to_fifo3_data; [cite: 55]
    logic        sobel_wr_en; [cite: 56]
    logic        fifo3_full;

    // --- 1. Input FIFO (RGB Data) ---
    fifo #(.FIFO_DATA_WIDTH(24), .FIFO_BUFFER_SIZE(1024)) input_fifo (
        .reset   (rst),
        .wr_clk  (clk),
        .wr_en   (in_wr_en),
        .din     (in_din),
        .full    (in_full),
        .rd_clk  (clk),
        .rd_en   (gs_rd_en),
        .dout    (fifo1_to_gs_data), [cite: 58]
        .empty   (fifo1_empty)
    ); [cite: 57]

    // --- 2. Grayscale Module ---
    grayscale gs_inst (
        .clock     (clk),
        .reset     (rst),
        .in_rd_en  (gs_rd_en),
        .in_empty  (fifo1_empty),
        .in_dout   (fifo1_to_gs_data),
        .out_wr_en (gs_wr_en),
        .out_full  (fifo2_full),
        .out_din   (gs_to_fifo2_data)
    ); [cite: 59, 60]

    // --- 3. Intermediate FIFO (Grayscale Data) ---
    fifo #(.FIFO_DATA_WIDTH(8), .FIFO_BUFFER_SIZE(1024)) inter_fifo (
        .reset   (rst),
        .wr_clk  (clk),
        .wr_en   (gs_wr_en),
        .din     (gs_to_fifo2_data),
        .full    (fifo2_full),
        .rd_clk  (clk), [cite: 61]
        .rd_en   (sobel_rd_en),
        .dout    (fifo2_to_sobel_data),
        .empty   (fifo2_empty)
    );

    // --- 4. Sobel Module ---
    Sobel sobel_inst (
        .clk        (clk),
        .rst        (rst),
        .in_rd_en   (sobel_rd_en),
        .in_empty   (fifo2_empty),
        .pixel_in   (fifo2_to_sobel_data),
        .out_wr_en  (sobel_wr_en),
        .out_full   (fifo3_full),        // Connected to Output FIFO status
        .sobel_pixel(sobel_to_fifo3_data) // Feeds into Output FIFO
    ); 

    // --- 5. Output FIFO ---
    fifo #(.FIFO_DATA_WIDTH(8), .FIFO_BUFFER_SIZE(1024)) output_fifo (
        .reset   (rst),
        .wr_clk  (clk),
        .wr_en   (sobel_wr_en),
        .din     (sobel_to_fifo3_data),
        .full    (fifo3_full),
        .rd_clk  (clk),
        .rd_en   (out_rd_en),           // Driven by TB
        .dout    (out_dout),            // Read by TB
        .empty   (out_empty)            // Monitored by TB
    );

endmodule
