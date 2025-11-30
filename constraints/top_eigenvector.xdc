## This file is a constraint file for the top_eigenvector module
## Based on Nexys-4 rev B board pin assignments
## https://github.com/Digilent/digilent-xdc/blob/master/Nexys-4-Master.xdc

# Clock signal
#Bank = 35, Pin name = IO_L12P_T1_MRCC_35,					Sch name = CLK100MHZ
set_property PACKAGE_PIN E3 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name clk -period 10.00 [get_ports clk]

# Reset signal
#Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15,				Sch name = CPU_RESET
set_property PACKAGE_PIN C12 [get_ports reset]				
	set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Switches
#Bank = 34, Pin name = IO_L21P_T3_DQS_34,					Sch name = Sw0
set_property PACKAGE_PIN U9 [get_ports {sw0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw0}]

#Bank = 34, Pin name = IO_25_34,							Sch name = Sw1
set_property PACKAGE_PIN U8 [get_ports {sw1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw1}]

#Bank = 34, Pin name = IO_L23P_T3_34,						Sch name = Sw2
set_property PACKAGE_PIN R7 [get_ports {sw_eps[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[0]}]

#Bank = 34, Pin name = IO_L19P_T3_34,						Sch name = Sw3
set_property PACKAGE_PIN R6 [get_ports {sw_eps[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[1]}]

#Bank = 34, Pin name = IO_L19N_T3_VREF_34,					Sch name = Sw4
set_property PACKAGE_PIN R5 [get_ports {sw_eps[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[2]}]

# LEDs
#Bank = 34, Pin name = IO_L24N_T3_34,						Sch name = LED0
set_property PACKAGE_PIN T8 [get_ports {led[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

#Bank = 34, Pin name = IO_L21N_T3_DQS_34,					Sch name = LED1
set_property PACKAGE_PIN V9 [get_ports {led[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

#Bank = 34, Pin name = IO_L24P_T3_34,						Sch name = LED2
set_property PACKAGE_PIN R8 [get_ports {led[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

#Bank = 34, Pin name = IO_L23N_T3_34,						Sch name = LED3
set_property PACKAGE_PIN T6 [get_ports {led[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

#Bank = 34, Pin name = IO_L12P_T1_MRCC_34,					Sch name = LED4
set_property PACKAGE_PIN T5 [get_ports {led[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

#Bank = 34, Pin name = IO_L12N_T1_MRCC_34,					Sch name = LED5
set_property PACKAGE_PIN T4 [get_ports {led[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

#Bank = 34, Pin name = IO_L22P_T3_34,						Sch name = LED6
set_property PACKAGE_PIN U7 [get_ports {led[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

#Bank = 34, Pin name = IO_L22N_T3_34,						Sch name = LED7
set_property PACKAGE_PIN U6 [get_ports {led[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

# 7 segment display
#Bank = 34, Pin name = IO_L2N_T0_34,						Sch name = Ca
set_property PACKAGE_PIN L3 [get_ports {ca}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ca}]

#Bank = 34, Pin name = IO_L3N_T0_DQS_34,					Sch name = Cb
set_property PACKAGE_PIN N1 [get_ports {cb}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cb}]

#Bank = 34, Pin name = IO_L6N_T0_VREF_34,					Sch name = Cc
set_property PACKAGE_PIN L5 [get_ports {cc}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cc}]

#Bank = 34, Pin name = IO_L5N_T0_34,						Sch name = Cd
set_property PACKAGE_PIN L4 [get_ports {cd}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cd}]

#Bank = 34, Pin name = IO_L2P_T0_34,						Sch name = Ce
set_property PACKAGE_PIN K3 [get_ports {ce}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ce}]

#Bank = 34, Pin name = IO_L4N_T0_34,						Sch name = Cf
set_property PACKAGE_PIN M2 [get_ports {cf}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cf}]

#Bank = 34, Pin name = IO_L6P_T0_34,						Sch name = Cg
set_property PACKAGE_PIN L6 [get_ports {cg}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cg}]

#Bank = 34, Pin name = IO_L16P_T2_34,						Sch name = Dp
set_property PACKAGE_PIN M4 [get_ports dp]							
	set_property IOSTANDARD LVCMOS33 [get_ports dp]

#Buttons
#Bank = 15, Pin name = IO_L11N_T1_SRCC_15,					Sch name = BTNC
set_property PACKAGE_PIN E16 [get_ports btnc]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnc]

#Bank = 15, Pin name = IO_L14P_T2_SRCC_15,					Sch name = BTNU
set_property PACKAGE_PIN F15 [get_ports btnu]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnu]

#Bank = CONFIG, Pin name = IO_L15N_T2_DQS_DOUT_CSO_B_14,	Sch name = BTNL
set_property PACKAGE_PIN T16 [get_ports btnl]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnl]

#Bank = 14, Pin name = IO_25_14,							Sch name = BTNR
set_property PACKAGE_PIN R10 [get_ports btnr]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnr]

#Bank = 14, Pin name = IO_L21P_T3_DQS_14,					Sch name = BTND
set_property PACKAGE_PIN V10 [get_ports btnd]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnd]

#VGA Connector
#Bank = 35, Pin name = IO_L8N_T1_AD14N_35,					Sch name = VGA_R0
set_property PACKAGE_PIN A3 [get_ports {vga_red[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[0]}]

#Bank = 35, Pin name = IO_L7N_T1_AD6N_35,					Sch name = VGA_R1
set_property PACKAGE_PIN B4 [get_ports {vga_red[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[1]}]

#Bank = 35, Pin name = IO_L1N_T0_AD4N_35,					Sch name = VGA_R2
set_property PACKAGE_PIN C5 [get_ports {vga_red[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[2]}]

#Bank = 35, Pin name = IO_L8P_T1_AD14P_35,					Sch name = VGA_R3
set_property PACKAGE_PIN A4 [get_ports {vga_red[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_red[3]}]

#Bank = 35, Pin name = IO_L2P_T0_AD12P_35,					Sch name = VGA_B0
set_property PACKAGE_PIN B7 [get_ports {vga_blue[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[0]}]

#Bank = 35, Pin name = IO_L4N_T0_35,						Sch name = VGA_B1
set_property PACKAGE_PIN C7 [get_ports {vga_blue[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[1]}]

#Bank = 35, Pin name = IO_L6N_T0_VREF_35,					Sch name = VGA_B2
set_property PACKAGE_PIN D7 [get_ports {vga_blue[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[2]}]

#Bank = 35, Pin name = IO_L4P_T0_35,						Sch name = VGA_B3
set_property PACKAGE_PIN D8 [get_ports {vga_blue[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_blue[3]}]

#Bank = 35, Pin name = IO_L1P_T0_AD4P_35,					Sch name = VGA_G0
set_property PACKAGE_PIN C6 [get_ports {vga_green[0]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[0]}]

#Bank = 35, Pin name = IO_L3N_T0_DQS_AD5N_35,				Sch name = VGA_G1
set_property PACKAGE_PIN A5 [get_ports {vga_green[1]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[1]}]

#Bank = 35, Pin name = IO_L2N_T0_AD12N_35,					Sch name = VGA_G2
set_property PACKAGE_PIN B6 [get_ports {vga_green[2]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[2]}]

#Bank = 35, Pin name = IO_L3P_T0_DQS_AD5P_35,				Sch name = VGA_G3
set_property PACKAGE_PIN A6 [get_ports {vga_green[3]}]				
	set_property IOSTANDARD LVCMOS33 [get_ports {vga_green[3]}]

#Bank = 15, Pin name = IO_L4P_T0_15,						Sch name = VGA_HS
set_property PACKAGE_PIN B11 [get_ports vga_hsync]						
	set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]

#Bank = 15, Pin name = IO_L3N_T0_DQS_AD1N_15,				Sch name = VGA_VS
set_property PACKAGE_PIN B12 [get_ports vga_vsync]						
	set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

