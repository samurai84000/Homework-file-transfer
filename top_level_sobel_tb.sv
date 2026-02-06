`timescale 1ns/1ps

module top_level_tb;

    localparam WIDTH  = 720;
    localparam HEIGHT = 720;
    localparam HEADER_SIZE = 54;
    localparam BYTES_PER_PIXEL = 3;
    // Hardware only outputs pixels after the first 2 rows are buffered
    localparam EXPECTED_OUT_PIXELS = (HEIGHT - 2) * WIDTH; 

    logic clk;
    logic rst;
    logic in_wr_en, in_full;
    logic [23:0] in_din;
    logic out_rd_en, out_empty;
    logic [7:0] out_dout;

    initial clk = 0;
    always #5 clk = ~clk;

    top_level dut (
        .clk(clk), .rst(rst),
        .in_wr_en(in_wr_en), .in_din(in_din), .in_full(in_full),
        .out_rd_en(out_rd_en), .out_dout(out_dout), .out_empty(out_empty)
    );

    byte header [HEADER_SIZE];
    
    // --- Input Process (Stable Negedge Handshaking) ---
    initial begin
        int fd_in;
        in_wr_en = 0;
        rst = 1;
        #50 rst = 0;

        fd_in = $fopen("/home/tnj0921/Downloads/tracks_720_720.bmp", "rb");
        if (fd_in == 0) $finish;
        void'($fread(header, fd_in));

        for (int i = 0; i < WIDTH * HEIGHT; i++) begin
            logic [7:0] r, g, b;
            void'($fscanf(fd_in, "%c%c%c", b, g, r));
            
            @(negedge clk);
            while (in_full) @(negedge clk);
            
            in_din = {r, g, b};
            in_wr_en = 1;
            @(negedge clk);
            in_wr_en = 0;
        end
        $fclose(fd_in);
    end

    // --- Output Process (Fixed for Hangs and Duplication) ---
    initial begin : img_write_process
        int fd_out;
        int pixels_collected = 0;
        out_rd_en = 0;

        wait(!rst);
        fd_out = $fopen("output_sobel.bmp", "wb");
        for (int i = 0; i < HEADER_SIZE; i++) $fwrite(fd_out, "%c", header[i]);

        // Loop for exactly the number of pixels hardware provides
        while (pixels_collected < EXPECTED_OUT_PIXELS) begin
            @(negedge clk);
            out_rd_en = 0;

            if (!out_empty) begin
                // Write 8-bit output as 24-bit grayscale triplet [cite: 279]
                $fwrite(fd_out, "%c%c%c", out_dout, out_dout, out_dout);
                out_rd_en = 1;
                pixels_collected++;
                
                if (pixels_collected % 50000 == 0) 
                    $display("Collected %d pixels", pixels_collected);
            end
        end

        @(negedge clk) out_rd_en = 0;
        $fclose(fd_out);
        $display("Processing complete. Collected %d pixels.", pixels_collected);
        $finish;
    end

endmodule
