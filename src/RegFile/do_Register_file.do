
#CONFIGURABLE VARIABLES

set TEST_VALUE_COUNT "31" 
set WAIT_TIME "10 ns"

#CONFIGURABLE VARIABLE END


#DON'T TOUCH THE REST UNLESS YOU KNOW WHAT YOU ARE DOING
set WAIT_TIME_INTEGER [string trimright $WAIT_TIME "ns"]

catch { vdel -all -lib work }
vlib work
vmap work work

vcom -2008 bus_types_pkg.vhd
vcom -2008 Structural_mux/*.vhd
vcom -2008 One_bit_register/*.vhd
vcom -2008 N_bit_register/*.vhd
vcom -2008 Bus_Mux_32bit_32_to_1/*.vhd
vcom -2008 Decoder_5_to_32/*.vhd
vcom -2008 *.vhd
vsim -g ITERATIONS=${TEST_VALUE_COUNT} -g CLK_PERIOD=${WAIT_TIME} work.tb_Register_file -voptargs=+acc
add wave sim:/tb_Register_file/*
run [expr {($TEST_VALUE_COUNT * $WAIT_TIME_INTEGER * 2) * 2}]

