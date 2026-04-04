catch { vdel -all -lib work }
vlib work
vmap work work

vcom -2008 *.vhd
vsim work.tb_extenders -voptargs=+acc
add wave -position insertpoint sim:/tb_extenders/*
run 150


