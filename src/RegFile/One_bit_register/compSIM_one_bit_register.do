vdel -all -lib work
vcom -2008 ../Structural_mux/*.vhd
vcom -2008 *.vhd
vsim work.tb_one_bit_register -voptargs=+acc
add wave sim:/tb_one_bit_register/*
run 1000

