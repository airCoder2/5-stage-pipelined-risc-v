
vcom -2008 *.vhd

vcom -2008 AddSub/*.vhd
vcom -2008 AddSub/Adder/*.vhd
vcom -2008 AddSub/N_bit_mux/*.vhd
vcom -2008 AddSub/OnesComp/*.vhd

vsim work.tb_another_test_addSub_imm -voptargs=+acc
add wave -position insertpoint sim:/tb_another_test_addSub_imm/*
add wave -position insertpoint sim:/tb_another_test_addSub_imm/Adde_S/*
add wave -position insertpoint sim:/tb_another_test_addSub_imm/Adde_S/mux2t1_N/*
run 100
