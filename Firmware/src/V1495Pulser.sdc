## Generated SDC file "V1495Pulser.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Full Version"

## DATE    "Tue Feb 11 11:57:16 2014"

##
## DEVICE  "EP1C20F400C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

set LCLK_period 25.000
set PLLCLK_period 10.000

create_clock -name {LCLK} -period $LCLK_period [get_ports {LCLK}]
create_clock -name virt_LCLK -period $LCLK_period
create_clock -name virt_PLLCLK -period 10.000

#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {PLLBlock_inst|altpll_component|pll|clk[0]} -source [get_pins {PLLBlock_inst|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 5 -divide_by 2 -master_clock {LCLK} [get_pins {PLLBlock_inst|altpll_component|pll|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

# setup
set_input_delay -clock virt_LCLK  -max [expr $LCLK_period - 5.000] [get_ports {LAD[*]}]
set_input_delay -clock virt_LCLK  -max [expr $LCLK_period - 8.000] [get_ports {WnR}]
set_input_delay -clock virt_LCLK  -max [expr $LCLK_period - 9.000] [get_ports {nADS}]
set_input_delay -clock virt_LCLK  -max [expr $LCLK_period - 9.000] [get_ports {nBLAST}]

# hold
set_input_delay -clock virt_LCLK  -min [expr 1.000] [get_ports {LAD[*]}]
set_input_delay -clock virt_LCLK  -min [expr 1.000] [get_ports {WnR}]
set_input_delay -clock virt_LCLK  -min [expr 1.000] [get_ports {nADS}]
set_input_delay -clock virt_LCLK  -min [expr 1.000] [get_ports {nBLAST}]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock virt_PLLCLK -max [expr $PLLCLK_period-5.000] [get_ports {C[*]}]
set_output_delay -clock virt_PLLCLK -max [expr $PLLCLK_period-5.000] [get_ports {D[*]}]
set_output_delay -clock virt_PLLCLK -max [expr $PLLCLK_period-5.000] [get_ports {E[*]}]
set_output_delay -clock virt_PLLCLK -max [expr $PLLCLK_period-5.000] [get_ports {F[*]}]
set_output_delay -clock virt_LCLK   -max [expr $LCLK_period-4.000] [get_ports {LAD[*]}]
set_output_delay -clock virt_LCLK   -max [expr $LCLK_period-4.000] [get_ports {nREADY}]

#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -from  [get_clocks {PLLBlock_inst|altpll_component|pll|clk[0]}]  -to  [get_clocks {LCLK}]
set_false_path  -from  [get_clocks {LCLK}]  -to  [get_clocks {PLLBlock_inst|altpll_component|pll|clk[0]}]
set_false_path -from {LCLK} -to {virt_PLLCLK}

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************

# hack: want 11.0ns max_delay, but set to 17.0ns to offset the -6ns added from clock (which isn't used by GIN!)
set_max_delay -from [get_ports {GIN[0]}] -to [get_ports *] 17.000

#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

