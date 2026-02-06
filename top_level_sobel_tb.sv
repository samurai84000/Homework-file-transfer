`timescale 1ns/1ps

module top_level_tb;

    // Parameters matches image size
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

    // Image Buffers
    byte header [HEADER_SIZE];
    
    // --- Task: Send Pixels ---
    initial begin
        int fd_in;
        in_wr_en = 0;
        in_din = 0;
        rst = 1;
        #20 rst = 0;

        // Open input BMP
        fd_in = $fopen("tracks_720_720.bmp", "rb");
        if (fd_in == 0) begin
            $display("Error: Could not open input file.");
            $finish;
        end

        // Read and ignore header for now
        void'($fread(header, fd_in));

        // Send pixel data
        for (int i = 0; i < WIDTH * HEIGHT; i++) begin
            logic [7:0] r, g, b;
            
            // BMP pixels are stored B, G, R
            void'($fscanf(fd_in, "%c%c%c", b, g, r));
            
            wait(!in_full);
            @(posedge clk);
            in_din = {r, g, b};
            in_wr_en = 1;
            @(posedge clk);
            in_wr_en = 0;
        end
        $fclose(fd_in);
        $display("Finished sending all pixels.");
    end

    // --- Task: Receive and Save Pixels ---
    initial begin
        int fd_out;
        byte out_pixel;
        out_rd_en = 0;

        wait(!rst);
        
        fd_out = $fopen("output_sobel.bmp", "wb");
        
        // Write the same header back (Note: In a real test, you'd modify 
        // the header to reflect 8-bit grayscale vs 24-bit RGB)
        for (int i = 0; i < HEADER_SIZE; i++) $fwrite(fd_out, "%c", header[i]);

        // Collect pixels
        for (int j = 0; j < WIDTH * HEIGHT; j++) begin
            wait(!out_empty);
            @(posedge clk);
            out_rd_en = 1;
            @(posedge clk);
            out_pixel = out_dout;
            out_rd_en = 0;
            
            // Write grayscale value to R, G, and B to create a BMP-viewable file
            $fwrite(fd_out, "%c%c%c", out_pixel, out_pixel, out_pixel);
            
            if (j % 10000 == 0) $display("Processed %d pixels...", j);
        end

        $fclose(fd_out);
        $display("Image Processing Complete. File saved as output_sobel.bmp");
        $finish;
    end

endmodule
