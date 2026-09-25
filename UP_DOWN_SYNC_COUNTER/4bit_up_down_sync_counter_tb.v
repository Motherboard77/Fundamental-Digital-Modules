

`timescale 1ns / 1ps

module tb_sync_up_down_count;

  // 1. Declare Testbench Signals
  reg clk;
  reg en;
  reg dir;
  wire [3:0] count_out;

  // 2. Instantiate the Unit Under Test (UUT)
  sync_up_down_count #(
    .MOD_VAL(12),
    .OUTPUT_WIDTH(4)
  ) uut (
    .clk(clk),
    .en(en),
    .dir(dir),
    .count_out(count_out)
  );

  // 3. Generate Clock Signal (50 MHz -> 20ns Period)
  always begin
    #10 clk = ~clk;
  end

  // 4. Test Stimulus Sequence
  initial begin
    // Initialize inputs
    clk = 0;
    en = 0;
    dir = 1; // Default to UP count
    
    // Force initial value to prevent 'X' propagation in simulation
    // (Simulates a clean power-on state)
    uut.up_down_count = 4'b0000; 
    
    #25; // Wait a bit before starting
    
    // --- TEST 1: Verify UP counting and Mod-12 Wrap-around (11 -> 0) ---
    $display("[TIME: %0t] Starting UP count test...", $time);
    en = 1; // Enable counter
    dir = 1; // Count UP
    #260;    // Let it run for 13 clock cycles (should go 0->11->0->1)
    
    // --- TEST 2: Verify Counter Disable (Hold Value) ---
    $display("[TIME: %0t] Disabling the counter (Holding value)...", $time);
    en = 0; 
    #60;     // Stay disabled for 3 clock cycles (output should freeze)
    
    // --- TEST 3: Verify DOWN counting and Underflow Wrap-around (0 -> 11) ---
    $display("[TIME: %0t] Starting DOWN count test...", $time);
    en = 1;  // Re-enable
    dir = 0; // Switch to DOWN count
    #260;    // Let it run for 13 clock cycles
    
    // --- TEST 4: Disable again to finalize ---
    en = 0;
    #40;
    
    $display("[TIME: %0t] Simulation finished successfully.", $time);
    $finish;
  end
  
  // 5. Monitor Output Window in Console
  initial begin
    $monitor("Time = %0t | en = %b | dir = %b | count_out = %d", $time, en, dir, count_out);
  end

endmodule

