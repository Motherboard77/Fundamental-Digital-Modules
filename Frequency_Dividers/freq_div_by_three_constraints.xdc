


# 1. Define your primary clock
create_clock -period 10.000 -name master_clk [get_ports clk]

# 2. THE ULTIMATE FIX FOR THE -END PERSPECTIVE
# Since Vivado forces '-end', a setup value of '1' means: 
# "Keep the capture edge at the immediate next falling edge (5.0ns)"
set_multicycle_path -setup -from [get_pins -hierarchical *pos_pulse_reg*/C] -to [get_pins -hierarchical *neg_pulse_reg*/D] 1

# Since Setup is now '1', we change Hold to '0' to pull the hold check 
# back to the launch edge (0.0ns)
set_multicycle_path -hold  -from [get_pins -hierarchical *pos_pulse_reg*/C] -to [get_pins -hierarchical *neg_pulse_reg*/D] 0

# 3. Clean up the reset paths
set_false_path -from [get_cells -hierarchical *rst_sync_out_reg*] -to [get_pins -hierarchical */CLR]
