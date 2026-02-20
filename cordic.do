vlib work
vmap work work

vlog -L uvm +incdir+$::env(UVM_HOME)/src \
    fifo.sv \
    cordic_stage.sv \
    cordic_top.sv \
    cordic_if.sv \
    cordic_pkg.sv \
    cordic_tb_top.sv

vsim -voptargs=+acc -L uvm cordic_tb_top +UVM_TESTNAME=cordic_base_test
run -all