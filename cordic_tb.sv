`timescale 1ns/1ps

module cordic_tb;
    // 1. Parameters and Port-matching Signals
    localparam BITS = 16;
    localparam STAGES = 16;
    localparam CLK_PERIOD = 10; 

    logic clk = 0;
    logic reset = 1;
    logic theta_wr_en = 0;
    logic [31:0] theta_din;
    logic theta_full;
    logic sin_rd_en = 0;
    logic [BITS-1:0] sin_dout;
    logic sin_empty;
    logic cos_rd_en = 0;
    logic [BITS-1:0] cos_dout;
    logic cos_empty;

    // 2. Simulation Tracking Queues
    real expected_sin[$];
    real expected_cos[$];
    real input_degrees[$];
    
    // 3. Instantiate Unit Under Test (UUT)
    // Wildcard (.*) works because signal names match port names exactly
    cordic #(.BITS(BITS), .STAGES(STAGES)) uut (.*);

    // 4. Clock Generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // 5. Input Feeding Block
    initial begin
        // Declarations at the TOP of the block
        int fd_in, status, degree, wrapped_deg;
        real rad;

        fd_in = $fopen("degrees.txt", "r");
        if (!fd_in) begin 
            $display("ERROR: Could not open degrees.txt"); 
            $finish; 
        end

        repeat(10) @(posedge clk);
        reset = 0;

        while (!$feof(fd_in)) begin
            status = $fscanf(fd_in, "%d\n", degree);
            if (status == 1) begin
                // Normalize degree to [-180, 180] for 16-bit register safety
                wrapped_deg = degree;
                while (wrapped_deg > 180)  wrapped_deg -= 360;
                while (wrapped_deg < -180) wrapped_deg += 360;

                rad = (real'(wrapped_deg) * 3.1415926535) / 180.0;
                
                // Store Golden values for comparison
                expected_sin.push_back($sin((real'(degree) * 3.1415926535) / 180.0));
                expected_cos.push_back($cos((real'(degree) * 3.1415926535) / 180.0));
                input_degrees.push_back(real'(degree));

                // Wait if FIFO is full
                while (theta_full) @(posedge clk);
                
                @(posedge clk);
                theta_din = $rtoi(rad * 16384.0); // Q2.14
                theta_wr_en = 1;
                
                @(posedge clk);
                theta_wr_en = 0;
            end
        end
        $fclose(fd_in);
    end

    // 6. Output Monitoring Block
    initial begin
        // Declarations at the TOP of the block
        int fd_out;
        int output_count = 0;
        real g_sin, g_cos, deg_orig, hw_sin, hw_cos;

        fd_out = $fopen("results.txt", "w");
        wait(!reset);

        forever begin
            @(posedge clk);
            // Check if results are ready in both output FIFOs
            if (!sin_empty && !cos_empty) begin
                sin_rd_en = 1; 
                cos_rd_en = 1;
                
                @(posedge clk);
                sin_rd_en = 0;
                cos_rd_en = 0;

                if (expected_sin.size() > 0) begin
                    g_sin    = expected_sin.pop_front();
                    g_cos    = expected_cos.pop_front();
                    deg_orig = input_degrees.pop_front();
                    
                    // Convert fixed-point hardware output back to real
                    hw_sin = real'($signed(sin_dout)) / 16384.0;
                    hw_cos = real'($signed(cos_dout)) / 16384.0;

                    $display("DEG: %4.0f | SIN: %7.4f (Gold: %7.4f) | COS: %7.4f (Gold: %7.4f)", 
                             deg_orig, hw_sin, g_sin, hw_cos, g_cos);
                             
                    $fwrite(fd_out, "Deg: %f, SIN: %f, COS: %f\n", deg_orig, hw_sin, hw_cos);
                    output_count++;
                end
            end
            
            // Exit condition: Stop when we reach 721 samples (-360 to 360)
            if (output_count >= 721) begin
                $display("Simulation Finished. Data saved to results.txt");
                $fclose(fd_out);
                $stop;
            end
        end
    end
endmodule