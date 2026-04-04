#CONFIGURABLE VARIABLES

set TEST_VALUE_COUNT "20"
set WAIT_TIME "10 ns"

#CONFIGURABLE VARIABLE END


#DON'T TOUCH THE REST UNLESS YOU KNOW WHAT YOU ARE DOING
set WAIT_TIME_INTEGER [string trimright $WAIT_TIME "ns"]

catch { vdel -all -lib work }
vlib work
vmap work work
vcom -2008 *.vhd
vsim -g ITERATIONS=${TEST_VALUE_COUNT} -g WAIT_TIME=${WAIT_TIME} work.tb_Decoder_5_to_32 -voptargs=+acc
add wave sim:/tb_Decoder_5_to_32/*
run [expr {$TEST_VALUE_COUNT * $WAIT_TIME_INTEGER}]

