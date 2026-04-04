
catch { vdel -all -lib work }
vlib work
vmap work work

vcom -2008 *.vhd

vsim work.tb_main_control_unit -voptargs=+acc
add wave sim:/tb_main_control_unit/*
run 100


