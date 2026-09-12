



`timescale 1ns / 1ps

module tb_bus_resizer;

  // Parameters
  parameter INP_DAT_WIDTH = 8;
  parameter WORD_SIZE     = 4;
  parameter OUT_DAT_WIDTH = WORD_SIZE * INP_DAT_WIDTH;

  // Testbench Signals
  reg [INP_DAT_WIDTH-1:0] data_in;
  reg clk_dom1;
  reg clk_dom2;
  reg rst1;
  reg rst2;
  wire [OUT_DAT_WIDTH-1:0] data_out;

  // Clock Generation Periods
  // clk_dom1 = 200 MHz (Period = 5ns)
  // clk_dom2 = 50 MHz  (Period = 20ns)
  localparam CLK1_PERIOD = 5;
  localparam CLK2_PERIOD = 20;

  // Instantiate the Device Under Test (DUT)
  bus_resizer #(
    .inp_dat_width(INP_DAT_WIDTH),
    .WORD_SIZE(WORD_SIZE)
  ) dut (
    .data_in(data_in),
    .clk_dom1(clk_dom1),
    .clk_dom2(clk_dom2),
    .rst1(rst1),
    .rst2(rst2),
    .data_out(data_out)
  );

  // --- Clock Generators ---
  always #(CLK1_PERIOD/2.0) clk_dom1 = ~clk_dom1;
  always #(CLK2_PERIOD/2.0) clk_dom2 = ~clk_dom2;

  // --- Main Stimulus Procedure ---
  initial begin
    // Initialize signals
    clk_dom1 = 0;
    clk_dom2 = 0;
    rst1 = 1;
    rst2 = 1;
    data_in = 8'h00;

    // Hold reset states for a few cycles
    #(CLK2_PERIOD * 3);
    
    // Release resets asynchronously to mimic independent domains
    @(negedge clk_dom1) rst1 = 0;
    @(negedge clk_dom2) rst2 = 0;
    
    $display("[TB INFO] Resets released. Commencing streaming data...");
    #(CLK1_PERIOD * 2);

    // --- TEST CASE 1: Send Batch 1 (4 bytes: 0xAA, 0xBB, 0xCC, 0xDD) ---
    // Expected output word: 32'hDDCCBBAA
    send_byte(8'hAA);
    send_byte(8'hBB);
    send_byte(8'hCC);
    send_byte(8'hDD);

    // Wait for the full handshake cycle to safely clear the pipeline
    wait_for_handshake();
    $display("[TB CHECK] Batch 1 Output Observed: 32'h%h (Expected: 32'hddccbbaa)", data_out);

    // --- TEST CASE 2: Send Batch 2 (4 bytes: 0x11, 0x22, 0x33, 0x44) ---
    // Expected output word: 32'h44332211
    send_byte(8'h11);
    send_byte(8'h22);
    send_byte(8'h33);
    send_byte(8'h44);

    wait_for_handshake();
    $display("[TB CHECK] Batch 2 Output Observed: 32'h%h (Expected: 32'h44332211)", data_out);

    // --- TEST CASE 3: Send Batch 3 (4 sequential counters: 0x01, 0x02, 0x03, 0x04) ---
    send_byte(8'h01);
    send_byte(8'h02);
    send_byte(8'h03);
    send_byte(8'h04);

    wait_for_handshake();
    $display("[TB CHECK] Batch 3 Output Observed: 32'h%h (Expected: 32'h04030201)", data_out);

    // End Simulation
    #(CLK2_PERIOD * 5);
    $display("[TB INFO] Simulation complete.");
    $finish;
  end

  // --- Helper Tasks ---

  // Task to cleanly drive input data synchronous to the fast Domain 1 clock
  task send_byte(input [INP_DAT_WIDTH-1:0] byte_to_send);
    begin
      // If the domain is frozen waiting for an ACK to clear, hold data application
      while (dut.domain_one_req || dut.ack_dom2_to_dom1_ff2) begin
        @(posedge clk_dom1);
      end
      data_in = byte_to_send;
      @(posedge clk_dom1);
    end
  endtask

  // Task to monitor the complete cross-domain interlocking handshake sequence
  task wait_for_handshake;
    begin
      // 1. Wait for Domain 1 to finish gathering 4 bytes and signal a Request
      wait(dut.domain_one_req == 1'b1);
      
      // 2. Wait for Domain 2 to cross-synchronize the Req and assert its Acknowledge
      wait(dut.domain_two_ack == 1'b1);
      
      // 3. Wait for Domain 1 to see the synchronized ACK and pull down its Request
      wait(dut.domain_one_req == 1'b0);
      
      // 4. Wait for Domain 2 to see the dropped Req and lower its Acknowledge, freeing the engine
      wait(dut.domain_two_ack == 1'b0);
      
      // Allow extra Domain 2 clock ticks for data_out to register to stage 2 output
      @(posedge clk_dom2);
      @(posedge clk_dom2);
    end
  endtask

  // --- Waveform Dump (Optional, for tools like GTKWave or ModelSim/Vendido) ---
  initial begin
    $dumpfile("bus_resizer_dump.vcd");
    $dumpvars(0, tb_bus_resizer);
  end

endmodule
