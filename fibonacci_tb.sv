`timescale 1ns/1ns

module fibonacci_tb;

  // ---------------------------------------
  // Testbench signals
  // ---------------------------------------
  logic clk;
  logic reset;
  logic [15:0] din;
  logic start;
  logic [15:0] dout;
  logic done;

  // ---------------------------------------
  // Instantiate DUT
  // ---------------------------------------
  fibonacci dut (
    .clk   (clk),
    .reset (reset),
    .din   (din),
    .start (start),
    .dout  (dout),
    .done  (done)
  );

  // ---------------------------------------
  // Clock generator: 10 ns period
  // ---------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------------------------------
  // Test sequence
  // ---------------------------------------
  initial begin
    // INITIAL RESET
    reset = 1'b1;
    start = 1'b0;
    din   = 16'd0;

    repeat (2) @(posedge clk);
    reset = 1'b0;

    // =====================================================
    // TEST CASE 1: din = 5
    // =====================================================
    @(posedge clk);
    din   <= 16'd5;
    start <= 1'b1;

    @(posedge clk);
    start <= 1'b0;

    wait (done == 1'b1);

    $display("-----------------------------------------");
    $display("Time  : %0t ns", $time);
    $display("Input : %0d", din);

    if (dout === 16'd5)
      $display("CORRECT RESULT: %0d, GOOD JOB!", dout);
    else
      $display("INCORRECT RESULT: %0d, SHOULD BE: 5", dout);

    // RESET BETWEEN TESTS
    @(posedge clk);
    reset <= 1'b1;

    repeat (2) @(posedge clk);
    reset <= 1'b0;

    // =====================================================
    // TEST CASE 2: din = 10
    // =====================================================
    @(posedge clk);
    din   <= 16'd10;
    start <= 1'b1;

    @(posedge clk);
    start <= 1'b0;

    wait (done == 1'b1);

    $display("-----------------------------------------");
    $display("Time  : %0t ns", $time);
    $display("Input : %0d", din);

    if (dout === 16'd55)
      $display("CORRECT RESULT: %0d, GOOD JOB!", dout);
    else
      $display("INCORRECT RESULT: %0d, SHOULD BE: 55", dout);

    // END SIMULATION
    $display("-----------------------------------------");
    $display("Simulation finished.");
    $stop;
  end

endmodule

