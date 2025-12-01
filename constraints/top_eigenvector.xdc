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

# Switches - CORRECTED to match Nexys A7 pinout
#Bank = 15, Pin name = IO_L24N_T3_RS0_15,					Sch name = SW0
set_property PACKAGE_PIN J15 [get_ports {sw0}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw0}]

#Bank = 14, Pin name = IO_L3N_T0_DQS_EMCCLK_14,				Sch name = SW1
set_property PACKAGE_PIN L16 [get_ports {sw1}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw1}]

#Bank = 14, Pin name = IO_L6N_T0_D08_VREF_14,				Sch name = SW2
set_property PACKAGE_PIN M13 [get_ports {sw_eps[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[0]}]

#Bank = 14, Pin name = IO_L13N_T2_MRCC_14,					Sch name = SW3
set_property PACKAGE_PIN R15 [get_ports {sw_eps[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[1]}]

#Bank = 14, Pin name = IO_L12N_T1_MRCC_14,					Sch name = SW4
set_property PACKAGE_PIN R17 [get_ports {sw_eps[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw_eps[2]}]

# LEDs - CORRECTED to match Nexys A7 pinout
#Bank = 15, Pin name = IO_L18P_T2_A24_15,					Sch name = LED0
set_property PACKAGE_PIN H17 [get_ports {led[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

#Bank = 15, Pin name = IO_L24P_T3_RS1_15,					Sch name = LED1
set_property PACKAGE_PIN K15 [get_ports {led[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

#Bank = 15, Pin name = IO_L17N_T2_A25_15,					Sch name = LED2
set_property PACKAGE_PIN J13 [get_ports {led[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

#Bank = 14, Pin name = IO_L8P_T1_D11_14,					Sch name = LED3
set_property PACKAGE_PIN N14 [get_ports {led[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

#Bank = 14, Pin name = IO_L7P_T1_D09_14,					Sch name = LED4
set_property PACKAGE_PIN R18 [get_ports {led[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

#Bank = 14, Pin name = IO_L18N_T2_A11_D27_14,				Sch name = LED5
set_property PACKAGE_PIN V17 [get_ports {led[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

#Bank = 14, Pin name = IO_L17P_T2_A14_D30_14,				Sch name = LED6
set_property PACKAGE_PIN U17 [get_ports {led[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

#Bank = 14, Pin name = IO_L18P_T2_A12_D28_14,				Sch name = LED7
set_property PACKAGE_PIN U16 [get_ports {led[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

# 7 segment display - CORRECTED to match Nexys A7 pinout
#Bank = 14, Pin name = IO_L24N_T3_A00_D16_14,				Sch name = CA
set_property PACKAGE_PIN T10 [get_ports {ca}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ca}]

#Bank = 14, Pin name = IO_25_14,							Sch name = CB
set_property PACKAGE_PIN R10 [get_ports {cb}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cb}]

#Bank = 15, Pin name = IO_25_15,							Sch name = CC
set_property PACKAGE_PIN K16 [get_ports {cc}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cc}]

#Bank = 15, Pin name = IO_L17P_T2_A26_15,					Sch name = CD
set_property PACKAGE_PIN K13 [get_ports {cd}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cd}]

#Bank = 14, Pin name = IO_L13P_T2_MRCC_14,					Sch name = CE
set_property PACKAGE_PIN P15 [get_ports {ce}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {ce}]

#Bank = 14, Pin name = IO_L19P_T3_A10_D26_14,				Sch name = CF
set_property PACKAGE_PIN T11 [get_ports {cf}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cf}]

#Bank = 14, Pin name = IO_L4P_T0_D04_14,					Sch name = CG
set_property PACKAGE_PIN L18 [get_ports {cg}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cg}]

#Bank = 15, Pin name = IO_L19N_T3_A21_VREF_15,				Sch name = DP
set_property PACKAGE_PIN H15 [get_ports dp]							
	set_property IOSTANDARD LVCMOS33 [get_ports dp]

#Bank = 15, Pin name = IO_L23P_T3_FOE_B_15,				Sch name = An0
set_property PACKAGE_PIN J17 [get_ports an0]
	set_property IOSTANDARD LVCMOS33 [get_ports an0]

#Bank = 15, Pin name = IO_L23N_T3_FWE_B_15,				Sch name = An1
set_property PACKAGE_PIN J18 [get_ports an1]
	set_property IOSTANDARD LVCMOS33 [get_ports an1]

#Bank = 14, Pin name = IO_L24P_T3_A01_D17_14,			Sch name = An2
set_property PACKAGE_PIN T9 [get_ports an2]
	set_property IOSTANDARD LVCMOS33 [get_ports an2]

#Bank = 15, Pin name = IO_L19P_T3_A22_15,				Sch name = An3
set_property PACKAGE_PIN J14 [get_ports an3]
	set_property IOSTANDARD LVCMOS33 [get_ports an3]

#Bank = 14, Pin name = IO_L8N_T1_D12_14,				Sch name = An4
set_property PACKAGE_PIN P14 [get_ports an4]
	set_property IOSTANDARD LVCMOS33 [get_ports an4]

#Bank = 14, Pin name = IO_L14P_T2_SRCC_14,				Sch name = An5
set_property PACKAGE_PIN T14 [get_ports an5]
	set_property IOSTANDARD LVCMOS33 [get_ports an5]

#Bank = 35, Pin name = IO_L23P_T3_35,					Sch name = An6
set_property PACKAGE_PIN K2 [get_ports an6]
	set_property IOSTANDARD LVCMOS33 [get_ports an6]

#Bank = 14, Pin name = IO_L23N_T3_A02_D18_14,			Sch name = An7
set_property PACKAGE_PIN U13 [get_ports an7]
	set_property IOSTANDARD LVCMOS33 [get_ports an7]

#Buttons - CORRECTED to match Nexys A7 pinout
#Bank = 14, Pin name = IO_L9P_T1_DQS_14,					Sch name = BTNC
set_property PACKAGE_PIN N17 [get_ports btnc]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnc]

#Bank = 14, Pin name = IO_L4N_T0_D05_14,					Sch name = BTNU
set_property PACKAGE_PIN M18 [get_ports btnu]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnu]

#Bank = 14, Pin name = IO_L12P_T1_MRCC_14,					Sch name = BTNL
set_property PACKAGE_PIN P17 [get_ports btnl]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnl]

#Bank = 14, Pin name = IO_L10N_T1_D15_14,					Sch name = BTNR
set_property PACKAGE_PIN M17 [get_ports btnr]						
	set_property IOSTANDARD LVCMOS33 [get_ports btnr]

#Bank = 14, Pin name = IO_L9N_T1_DQS_D13_14,				Sch name = BTND
set_property PACKAGE_PIN P18 [get_ports btnd]						
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

