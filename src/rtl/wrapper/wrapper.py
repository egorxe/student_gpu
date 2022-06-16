from migen import *

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform

CLK_FREQUENCY = 200e6
_io = [
	("clk200", 0,
        Subsignal("p", Pins("AD12"), IOStandard("LVDS")),
        Subsignal("n", Pins("AD11"), IOStandard("LVDS"))
    ),

]

class Platform(XilinxPlatform):
    default_clk_name   = "clk200"
    default_clk_period = 1e9/CLK_FREQUENCY

    def __init__(self):
        XilinxPlatform.__init__(self, "xc7k325t-ffg900-2", _io, toolchain="vivado") #Genesys

platform = Platform()
platform.add_source("../vertex_transform/hw/vertex_transform_axis_type_wrapper.vhd")
platform.add_source("../rasterisator/rasteriser.vhd")
platform.add_source("../fragment_ops/fragmentops_axis.vhd")
platform.add_source("VGA_adapter/VGA_adapter_640_480.vhd")
platform.add_source("frame_buffer/frame_buffer.vhd")

class GPU(Module):
	sys_clk_freq = int(CLK_FREQUENCY)

	def __init__(self):

