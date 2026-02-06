`timescale 1ns/1ps

module top_level_tb;

    localparam WIDTH  = 720;
    localparam HEIGHT = 720;
    localparam HEADER_SIZE = 54;

    logic clk;
    logic rst;
    
    // Inputs to Top Level
    logic        in_wr_en;
    logic [23:0] in_din;
    logic        in_full;
    
    // Outputs from Top Level
    logic        out_rd_en;
    logic [7:0]  out_dout;
    logic        out_empty;

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate Top Level
    top_level dut (
        .clk(clk),
        .rst(rst),
        .in_wr_en(in_wr_en),
        .in_din(in_din),
        .in_full(in_full),
        .out_rd_en(out_rd_en),
        .out_dout(out_dout),
        .out_empty(out_empty)
    );

    byte header [HEADER_SIZE];
    
    // --- Stimulus: Feeding the Input FIFO ---
    initial begin
        int fd_in;
        in_wr_en = 0;
        in_din = 0;
        rst = 1;
        #20 rst = 0;

        fd_in = $fopen("tracks_720_720.bmp", "rb");
        if (fd_in == 0) begin
            $display("Error: Could not open input file.");
            $finish;
        end

        // Read BMP Header [cite: 33]
        void'($fread(header, fd_in));

        for (int i = 0; i < WIDTH * HEIGHT; i++) begin
            logic [7:0] r, g, b;
            void'($fscanf(fd_in, "%c%c%c", b, g, r));
            
            // Wait for FIFO room
            while (in_full) @(posedge clk);
            
            in_din = {r, g, b};
            in_wr_en = 1;
            @(posedge clk);
            in_wr_en = 0;
        end
        $fclose(fd_in);
        $display("Input: All pixels sent to FIFO 1.");
    end

    // --- Monitor: Reading from the Output FIFO ---
    initial begin
        int fd_out;
        byte out_pixel;
        out_rd_en = 0; // Single procedural driver for this signal

        wait(!rst);
        
        fd_out = $fopen("output_sobel.bmp", "wb");
        
        // Write standard BMP header to output 
        for (int i = 0; i < HEADER_SIZE; i++) $fwrite(fd_out, "%c", header[i]);

        for (int j = 0; j < WIDTH * HEIGHT; j++) begin
            // Wait until FIFO 3 has data [cite: 40]
            while (out_empty) @(posedge clk);
            
            // Pulse read enable for exactly one clock cycle
            out_rd_en = 1;
            @(posedge clk);
            out_pixel = out_dout;
            out_rd_en = 0;
            
            // Output grayscale as RGB for BMP compatibility
            $fwrite(fd_out, "%c%c%c", out_pixel, out_pixel, out_pixel);
            
            if (j % 50000 == 0) $display("Output: Collected %d pixels...", j);
        end

        $fclose(fd_out);
        $display("Success: output_sobel.bmp has been generated.");
        $finish;
    end

endmodule
