# Boolean Board (xc7s50csga324-1) Master XDC File

# Clock signal (100MHz on-board)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { sys_clk }];
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports { sys_clk }];

# Reset signal (connected to a button)
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { rst_n }];

# VGA Output
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { vga_hs }];
set_property -dict { PACKAGE_PIN B4    IOSTANDARD LVCMOS33 } [get_ports { vga_vs }];

set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[0] }];  # Blue[0]
set_property -dict { PACKAGE_PIN D5    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[1] }];  # Blue[1]
set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[2] }];  # Blue[2]
set_property -dict { PACKAGE_PIN F5    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[3] }];  # Blue[3]

set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[4] }];  # Green[0]
set_property -dict { PACKAGE_PIN B5    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[5] }];  # Green[1]
set_property -dict { PACKAGE_PIN C6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[6] }];  # Green[2]
set_property -dict { PACKAGE_PIN D6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[7] }];  # Green[3]

set_property -dict { PACKAGE_PIN E6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[8] }];  # Red[0]
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[9] }];  # Red[1]
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[10] }]; # Red[2]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { vga_rgb[11] }]; # Red[3]
# create_generated_clock -name pixel_clk -source [get_pins u_top/u_clk_wiz/clk_in1] -divide_by 4 [get_pins u_top/u_clk_wiz/clk_out1]

set_property INIT_FILE {D:/image_data.mem} [get_cells u_image_rom/image_memory_reg]
