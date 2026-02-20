`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import cordic_pkg::*;

module cordic_tb_top;
    logic clk, reset;
    
    // UVM and Interface Setup
    cordic_if inf(clk, reset);

    // Instantiate Unit Under Test (UUT)
    cordic uut (
        .clk            (clk),
        .reset          (reset),
        .theta_wr_en    (inf.theta_wr_en),
        .theta_din      (inf.theta_din),
        .theta_full     (inf.theta_full),
        .sin_rd_en      (inf.sin_rd_en),
        .sin_dout       (inf.sin_dout),
        .sin_empty      (inf.sin_empty),
        .cos_rd_en      (inf.cos_rd_en),
        .cos_dout       (inf.cos_dout),
        .cos_empty      (inf.cos_empty)
    );

    // 1. Simulation Tracking Queues (From your template [cite: 5])
    real expected_sin[$];
    real expected_cos[$];
    real input_degrees[$];

    // 2. Clock and Reset Generation (From your template [cite: 3, 7])
    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin reset = 1; #50 reset = 0; end

    // 3. UVM Environment Launch
    initial begin
        uvm_resource_db#(virtual cordic_if)::set("ifs", "vif", inf);
        run_test("cordic_base_test");
    end

    // 4. Input Capture: Monitor Driver and store "Golden" values [cite: 14, 15]
    always @(posedge clk) begin : input_capture
        automatic real rad;
        automatic real degree;
        if (inf.theta_wr_en && !inf.theta_full) begin
            // Convert binary input (Q2.14) back to radians for golden calculation
            rad = real'($signed(inf.theta_din)) / 16384.0;
            degree = (rad * 180.0) / 3.1415926535;

            expected_sin.push_back($sin(rad));
            expected_cos.push_back($cos(rad));
            input_degrees.push_back(degree);
        end
    end

    // 5. Output Monitoring Block (Template-Style [cite: 18-27])
    initial begin : output_comparison
        int fd_out;
        int output_count = 0;
        real g_sin, g_cos, deg_orig, hw_sin, hw_cos;

        // Automatically read whenever data is available [cite: 21]
        assign inf.sin_rd_en = !inf.sin_empty;
        assign inf.cos_rd_en = !inf.cos_empty;

        fd_out = $fopen("results.txt", "w");
        wait(!reset);

        forever begin
            @(posedge clk);
            
            // Wait for both FIFOs to have valid data [cite: 21]
            if (!inf.sin_empty && !inf.cos_empty) begin
                // Crucial Check: Only compare if we have stored golden inputs
                if (expected_sin.size() > 0) begin
                    // Pop corresponding golden values 
                    g_sin    = expected_sin.pop_front();
                    g_cos    = expected_cos.pop_front();
                    deg_orig = input_degrees.pop_front();
                    
                    // Convert HW output (Q1.15) to real [cite: 24, 25]
                    // Note: Check if your HW scale is 16384 or 32768
                    hw_sin = real'($signed(inf.sin_dout)) / 32768.0;
                    hw_cos = real'($signed(inf.cos_dout)) / 32768.0;

                    $display("---------------------------------------------------------");
                    $display("@ %0t: [MATCHED] Count: %0d | Angle: %0f", $time, output_count, deg_orig);
                    $display("   HW  : Sin: %7.4f, Cos: %7.4f", hw_sin, hw_cos);
                    $display("   GOLD: Sin: %7.4f, Cos: %7.4f", g_sin, g_cos);
                    $display("   ERR : Sin: %7.4f, Cos: %7.4f", (g_sin-hw_sin), (g_cos-hw_cos));
                    
                    $fwrite(fd_out, "Deg: %f, SIN: %f, COS: %f\n", deg_orig, hw_sin, hw_cos);
                    output_count++;
                end
            end
            
            // Finish simulation after 721 samples [cite: 27, 28]
            if (output_count >= 721) begin
                $display("Simulation Finished. Results in results.txt");
                $fclose(fd_out);
                $stop;
            end
        end
    end

endmodule
