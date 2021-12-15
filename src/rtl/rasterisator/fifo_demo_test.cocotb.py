AddFile('axi.vhd', libname='work', src_type='vhdl')
AddFile('hw/axis_fifo_wrapper_demo.vhd', libname='work', src_type='vhdl', vhdl='2008')
AddTestBench("hw/fifo_demo_test.py","-voptargs=\"+acc=npr\" -t ps -L unisims_ver -L unimacro_ver -L secureip -debugdb -logfile test.log")
SetTop('axis_fifo_wrapper')
