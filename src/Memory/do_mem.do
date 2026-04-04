catch { vdel -all -lib work }
vlib work
vmap work work

#delete wave *

vcom -2008 *.vhd

vsim work.tb_dmem -voptargs=+acc
mem load -infile dmem.hex -format hex tb_dmem/dmem/ram

add wave sim:/tb_dmem/dmem/clk

add wave sim:/tb_dmem/dmem/ram

run 10000

mem save -o output.hex -f mti -data hex -addr hex tb_dmem/dmem/ram



