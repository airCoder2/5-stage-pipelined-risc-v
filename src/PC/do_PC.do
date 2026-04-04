catch { vdel -all -lib work }
vlib work
vmap work work

vcom -2008 *.vhd
vcom -2008 ../RegFile/N_bit_register/*.vhd
vcom -2008 ../RegFile/One_bit_register/*.vhd
vcom -2008 ../RegFile/Structural_mux/*.vhd

vsim work.tb_pc -voptargs=+acc
add wave -position insertpoint sim:/tb_pc/*

run 250



