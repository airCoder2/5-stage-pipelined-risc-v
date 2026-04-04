catch { vdel -all -lib work }
vlib work
vmap work work


vcom -2008 *.vhd

vcom -2008 ../ALU/AddSub_immediate/AddSub/Adder/*.vhd

vsim work.tb_pc_adder -voptargs=+acc
add wave sim:/tb_pc_adder/*
run 150

