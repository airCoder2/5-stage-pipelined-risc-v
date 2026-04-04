vcom -2008 *.vhd
vsim work.tb_another_test -voptargs=+acc
add wave -position insertpoint sim:/tb_another_test/*
run 100
