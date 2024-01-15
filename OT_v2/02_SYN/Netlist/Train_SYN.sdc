###################################################################

# Created by write_sdc on Sat Nov  4 15:27:19 2023

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_load -pin_load 0.05 [get_ports out_valid]
set_load -pin_load 0.05 [get_ports result]
set_max_capacitance 0.15 [get_ports clk]
set_max_capacitance 0.15 [get_ports rst_n]
set_max_capacitance 0.15 [get_ports in_valid]
set_max_capacitance 0.15 [get_ports {data[3]}]
set_max_capacitance 0.15 [get_ports {data[2]}]
set_max_capacitance 0.15 [get_ports {data[1]}]
set_max_capacitance 0.15 [get_ports {data[0]}]
set_max_fanout 10 [get_ports clk]
set_max_fanout 10 [get_ports rst_n]
set_max_fanout 10 [get_ports in_valid]
set_max_fanout 10 [get_ports {data[3]}]
set_max_fanout 10 [get_ports {data[2]}]
set_max_fanout 10 [get_ports {data[1]}]
set_max_fanout 10 [get_ports {data[0]}]
set_max_transition 3 [get_ports clk]
set_max_transition 3 [get_ports rst_n]
set_max_transition 3 [get_ports in_valid]
set_max_transition 3 [get_ports {data[3]}]
set_max_transition 3 [get_ports {data[2]}]
set_max_transition 3 [get_ports {data[1]}]
set_max_transition 3 [get_ports {data[0]}]
create_clock [get_ports clk]  -period 10  -waveform {0 5}
set_clock_uncertainty 0.1  [get_clocks clk]
set_clock_transition -max -rise 0.1 [get_clocks clk]
set_clock_transition -max -fall 0.1 [get_clocks clk]
set_clock_transition -min -rise 0.1 [get_clocks clk]
set_clock_transition -min -fall 0.1 [get_clocks clk]
set_input_delay -clock clk  0  [get_ports clk]
set_input_delay -clock clk  0  [get_ports rst_n]
set_input_delay -clock clk  -max 5  [get_ports in_valid]
set_input_delay -clock clk  -min 0  [get_ports in_valid]
set_input_delay -clock clk  -max 5  [get_ports {data[3]}]
set_input_delay -clock clk  -min 0  [get_ports {data[3]}]
set_input_delay -clock clk  -max 5  [get_ports {data[2]}]
set_input_delay -clock clk  -min 0  [get_ports {data[2]}]
set_input_delay -clock clk  -max 5  [get_ports {data[1]}]
set_input_delay -clock clk  -min 0  [get_ports {data[1]}]
set_input_delay -clock clk  -max 5  [get_ports {data[0]}]
set_input_delay -clock clk  -min 0  [get_ports {data[0]}]
set_output_delay -clock clk  -max 5  [get_ports out_valid]
set_output_delay -clock clk  -min 0  [get_ports out_valid]
set_output_delay -clock clk  -max 5  [get_ports result]
set_output_delay -clock clk  -min 0  [get_ports result]
set_input_transition -max 0.5  [get_ports clk]
set_input_transition -min 0.5  [get_ports clk]
set_input_transition -max 0.5  [get_ports rst_n]
set_input_transition -min 0.5  [get_ports rst_n]
set_input_transition -max 0.5  [get_ports in_valid]
set_input_transition -min 0.5  [get_ports in_valid]
set_input_transition -max 0.5  [get_ports {data[3]}]
set_input_transition -min 0.5  [get_ports {data[3]}]
set_input_transition -max 0.5  [get_ports {data[2]}]
set_input_transition -min 0.5  [get_ports {data[2]}]
set_input_transition -max 0.5  [get_ports {data[1]}]
set_input_transition -min 0.5  [get_ports {data[1]}]
set_input_transition -max 0.5  [get_ports {data[0]}]
set_input_transition -min 0.5  [get_ports {data[0]}]