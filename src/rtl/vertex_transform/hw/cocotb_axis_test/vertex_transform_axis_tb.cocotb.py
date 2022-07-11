AddFile('../pkg/gpu_pkg.vhd')
AddFile('hw/M4_mul_V4/fpu100.vhd', libname='work', src_type='vhdl', vhdl='2008')
AddFile('hw/M4_mul_V4/M4_mul_V4.vhd', libname='work', src_type='vhdl', vhdl='2008')
AddFile('hw/vertex_transform.vhd', libname='work', src_type='vhdl', vhdl='2008')
AddFile('hw/vertex_transform_axis_wrapper.vhd', libname='work', src_type='vhdl', vhdl='2008')

AddTestBench("hw/cocotb_axis_test/vertex_transform_axis_tb.py")
SetTop('vertex_transform_axis_wrapper')
