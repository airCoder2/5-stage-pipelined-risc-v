vcom -2008 *.vhd
vsim work.tb_adder_subtractor -voptargs=+acc
add wave -position insertpoint sim:/tb_adder_subtractor/*
run 150
