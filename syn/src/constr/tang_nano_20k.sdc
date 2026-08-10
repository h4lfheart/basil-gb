create_clock -name I_clk -period 37.037 -waveform {0 18.519} [get_ports {I_clk}] -add
create_clock -name pixel_clk -period 39.683 -waveform {0 19.841} [get_pins {u_pixel_div/CLKOUT}]
create_clock -name gb_clk -period 238.419 [get_nets {gb_clk_r}] -add

set_false_path -from [get_clocks {gb_clk}] -to [get_clocks {pixel_clk}]
set_false_path -from [get_clocks {pixel_clk}] -to [get_clocks {gb_clk}]
