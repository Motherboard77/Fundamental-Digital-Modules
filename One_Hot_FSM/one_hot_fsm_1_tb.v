`timescale 1ns/1ps

module one_hot_fsm_tb;

    // Parameters
    parameter STATES = 5;

    // One-hot mapping definitions placed at module level for compatibility
    // S0=bit0, S1=bit1, S2=bit2, S3=bit3, S4=bit4
    localparam S0 = 5'b00001;
    localparam S1 = 5'b00010;
    localparam S2 = 5'b00100;
    localparam S3 = 5'b01000;
    localparam S4 = 5'b10000;

    // Testbench Inputs (Signals Driven by TB)
    reg clk;
    reg rst_n;
    reg inp;
    reg [STATES-1:0] state_reg; // Sequential state holder

    // Testbench Outputs (Signals Driven by DUT)
    wire [STATES-1:0] state_out;
    wire z;

    // Instantiate the Device Under Test (DUT)
    one_hot_fsm #(
        .STATES(STATES)
    ) dut (
        .inp(inp),
        .state_in(state_reg),
        .state_out(state_out),
        .z(z)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    // Sequential State Register Behavior
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= S0; // One-hot reset state: S0 active
        end else begin
            state_reg <= state_out; // Update to next state
        end
    end

       // Corrected Verification Task for Mealy Outputs
    task check_fsm(
        input [STATES-1:0] expected_state,
        input expected_z
    );
        begin
            #1; // Wait for combinational outputs (z) to settle after input change
            
            // 1. Check Mealy output BEFORE the clock edge
            if (z !== expected_z) begin
                $display("[ERROR] Time %0t: Current State 5'b%b with inp=%b, Expected z = %b, Got z = %b", 
                         $time, state_reg, inp, expected_z, z);
            end
            
            // 2. Now wait for the clock to transition to the next state
            @(posedge clk); 
            #1; // Allow state register to update
            
            // 3. Verify the state transition occurred correctly
            if (state_reg !== expected_state) begin
                $display("[ERROR] Time %0t: Expected Next State = 5'b%b, Got State = 5'b%b", 
                         $time, expected_state, state_reg);
            end else if (z === expected_z) begin 
                // Only print success if both passed
                $display("[SUCCESS] Time %0t: Transition to State = 5'b%b passed.", 
                         $time, state_reg);
            end
        end
    endtask


    // Main Stimulus Procedure
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        inp = 0;

        $display("--- Starting FSM One-Hot Verification ---");
        #15;
        rst_n = 1; // Release reset

        // 1. Verify S0 loop (inp=0, z=0)
        inp = 0;
        check_fsm(S0, 0);

        // 2. Transition S0 -> S1 (inp=1, z=1)
        inp = 1;
        check_fsm(S1, 1);

        // 3. Transition S1 -> S4 (inp=1, z=0)
        inp = 1;
        check_fsm(S4, 0);

        // 4. Transition S4 -> S2 (inp=1, z=1)
        inp = 1;
        check_fsm(S2, 1);

        // 5. Verify S2 loop (inp=0, z=0)
        inp = 0;
        check_fsm(S2, 0);

        // 6. Transition S2 -> S3 (inp=1, z=1)
        inp = 1;
        check_fsm(S3, 1);

        // 7. Transition S3 -> S1 (inp=1, z=1)
        inp = 1;
        check_fsm(S1, 1);

        // 8. Transition S1 -> S2 (inp=0, z=0)
        inp = 0;
        check_fsm(S2, 0);

        // 9. Transition S2 -> S3 (inp=1, z=1)
        inp = 1;
        check_fsm(S3, 1);

        // 10. Transition S3 -> S4 (inp=0, z=0)
        inp = 0;
        check_fsm(S4, 0);

        // 11. Transition S4 -> S0 (inp=0, z=0)
        inp = 0;
        check_fsm(S0, 0);

        $display("--- Verification Completed ---");
        $finish;
    end

endmodule
