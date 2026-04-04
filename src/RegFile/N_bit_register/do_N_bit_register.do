# please write something to make it understandable
#define variables
set N "32"
set TEST_VALUE_COUNT "20"
set HALF_CLOCK_PERIOD "50ns"
set HALF_CLOCK_PERIOD_INTEGER [string trimright $HALF_CLOCK_PERIOD "ns"]

catch { vdel -all -lib work }
vlib work
vmap work work
vcom -2008 ../Structural_mux/*.vhd
vcom -2008 ../One_bit_register/*.vhd
vcom -2008 *.vhd
vsim -g ITERATIONS=${TEST_VALUE_COUNT} -g gCLK_HPER=${HALF_CLOCK_PERIOD} -g N=${N} work.tb_N_bit_register -voptargs=+acc
add wave sim:/tb_N_bit_register/*
run [expr {$TEST_VALUE_COUNT * $HALF_CLOCK_PERIOD_INTEGER * 2}]

