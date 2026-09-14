
`timescale 1ns/1ps

module rra_tb;

  // Parameters
  parameter DATA_WIDTH = 8;
  parameter CLK_PERIOD = 10; 

  // Testbench Signals
  reg clk;
  reg rst;
  reg [DATA_WIDTH-1:0] req_in;
  wire [DATA_WIDTH-1:0] grant_out;

  // Instantiate the Unit Under Test (UUT)
  rra #(.DATA_WIDTH(DATA_WIDTH)) uut (
    .clk(clk),
    .rst(rst),
    .req_in(req_in),
    .grant_out(grant_out)
  );

  // Clock Generation
  always #(CLK_PERIOD/2) clk = ~clk;

  // Storage for tracking expected golden values manually
  reg [DATA_WIDTH-1:0] expected_grant;

  initial begin
    // Initialize Signals
    clk = 0;
    rst = 1;
    req_in = 0;
    expected_grant = 0;

    // Reset Sequence
    $display("=== STARTING ROUND-ROBIN ARBITER TESTBENCH ===");
    #(CLK_PERIOD * 2);
    rst = 0;
    $display("--- System Reset Released ---");
    #(CLK_PERIOD);

    // =========================================================================
    // TESTCASE 1: Fallback out of reset (No previous history)
    // Inputs: Channels 2, 3, 5, 7 active. Lowest index (Channel 2) should win.
    // =========================================================================
    req_in = 8'b10101100; 
    expected_grant = 8'b00000100; // Channel 2
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC1 | Req=%b | Got Grant=%b (Channel 2)", req_in, grant_out);
    else
      $display("[ERROR]   TC1 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 2: Step Forward
    // Prev grant was Channel 2. Next active channel ahead of 2 is Channel 3.
    // =========================================================================
    req_in = 8'b10101100; 
    expected_grant = 8'b00001000; // Channel 3
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC2 | Req=%b | Got Grant=%b (Channel 3)", req_in, grant_out);
    else
      $display("[ERROR]   TC2 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 3: Skipping Idle Slots
    // Prev grant was Channel 3. Next ahead is Channel 5 (skipping idle Channel 4).
    // =========================================================================
    req_in = 8'b10101100;
    expected_grant = 8'b00100000; // Channel 5
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC3 | Req=%b | Got Grant=%b (Channel 5)", req_in, grant_out);
    else
      $display("[ERROR]   TC3 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 4: Moving toward the MSB Boundary
    // Prev grant was Channel 5. Next ahead is Channel 7 (skipping idle Channel 6).
    // =========================================================================
    req_in = 8'b10101100;
    expected_grant = 8'b10000000; // Channel 7
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC4 | Req=%b | Got Grant=%b (Channel 7)", req_in, grant_out);
    else
      $display("[ERROR]   TC4 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 5: Full Loop Wrap-Around
    // Prev grant was Channel 7. Next ahead wraps back around to Channel 2.
    // =========================================================================
    req_in = 8'b10101100;
    expected_grant = 8'b00000100; // Channel 2
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC5 | Req=%b | Got Grant=%b (Channel 2 Wrap)", req_in, grant_out);
    else
      $display("[ERROR]   TC5 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 6: Dynamic Request Changes
    // Prev grant was Channel 2. Channels 3 and 5 drop their requests. 
    // Remaining requests are 0 and 7. Scans ahead of 2 and must grant Channel 7.
    // =========================================================================
    req_in = 8'b10000001; 
    expected_grant = 8'b10000000; // Channel 7
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC6 | Req=%b | Got Grant=%b (Channel 7)", req_in, grant_out);
    else
      $display("[ERROR]   TC6 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 7: Dynamic Wrap-Around
    // Prev grant was Channel 7. Requests are 0 and 7. Wraps to grant Channel 0.
    // =========================================================================
    req_in = 8'b10000001; 
    expected_grant = 8'b00000001; // Channel 0
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC7 | Req=%b | Got Grant=%b (Channel 0 Wrap)", req_in, grant_out);
    else
      $display("[ERROR]   TC7 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 8: Idle Bus Handling
    // No requests are active. Grant output must fall back to all-zeros.
    // =========================================================================
    req_in = 8'b00000000;
    expected_grant = 8'b00000000; 
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC8 | Req=%b | Got Grant=%b (Idle Safe)", req_in, grant_out);
    else
      $display("[ERROR]   TC8 | Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 9: Starvation Prevention (Single Persistent Requester)
    // Only Channel 4 requests. It should get the grant and hold it continuously.
    // =========================================================================
    req_in = 8'b00010000; 
    expected_grant = 8'b00010000; // Channel 4
    #(CLK_PERIOD);
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC9a| Req=%b | Got Grant=%b (Channel 4)", req_in, grant_out);
    else
      $display("[ERROR]   TC9a| Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    #(CLK_PERIOD); // Hold for another cycle to verify stability
    if (grant_out == expected_grant)
      $display("[SUCCESS] TC9b| Req=%b | Got Grant=%b (Channel 4 Maintained)", req_in, grant_out);
    else
      $display("[ERROR]   TC9b| Req=%b | Expected=%b | Got=%b", req_in, expected_grant, grant_out);

    // =========================================================================
    // TESTCASE 10: Strict Round-Robin Rotation (All Channels Fighting)
    // When all requests are active, the grant pointer must strictly increment
    // by exactly 1 index position every single clock cycle.
    // =========================================================================
    $display("--- Starting Heavy Load Stress Test ---");
    req_in = 8'b11111111; 

    // Cycle 1: Prev grant was Channel 4. Next is 5.
    expected_grant = 8'b00100000; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P5 Fail. Got: %b", grant_out);
    
    // Cycle 2: Next is 6
    expected_grant = 8'b01000000; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P6 Fail. Got: %b", grant_out);
    
    // Cycle 3: Next is 7
    expected_grant = 8'b10000000; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P7 Fail. Got: %b", grant_out);
    
    // Cycle 4: Wraps around to 0
    expected_grant = 8'b00000001; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P0 Fail. Got: %b", grant_out);
    
    // Cycle 5: Next is 1
    expected_grant = 8'b00000010; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P1 Fail. Got: %b", grant_out);
    
    // Cycle 6: Next is 2
    expected_grant = 8'b00000100; #(CLK_PERIOD);
    if (grant_out != expected_grant) $display("[ERROR] Stress P2 Fail. Got: %b", grant_out);

    $display("=== TESTBENCH EXECUTION FINISHED VIA SUCCESS ===");
    $finish;
  end

  // Waveform Dump Configuration
  initial begin
    $dumpfile("rra_sim.vcd");
    $dumpvars(0, rra_tb);
  end

endmodule