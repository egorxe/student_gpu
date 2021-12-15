IncludeList('hw/fpu100.list.py')

AddFile('hw/tb/tb_fpu.vhd')
AddFile('hw/tb/txt_util.vhd')
SetTop('tb_fpu')
AddExtraFile('hw/tb/testcases.txt')

