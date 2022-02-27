import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame

import struct
import numpy as np

def toBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', num))

def toSignal32(num):
    return int(toBin32Str(num), 2)

def bin64StrToFloat64(value):
    hx = hex(int(value, 2))   
    return struct.unpack("d", struct.pack("q", int(hx, 16)))[0]

def bin32StrToBin64Str(value):
    sign = value[0]
    exponent32int = int(value[1:(8+1)], 2)
    mantissa32 = value[9:(31+1)]
    if (exponent32int == 0 and int(mantissa32, 2) == 0):
        exponent = 0
        exponent64 = "".join("0" for i in range(1, 11))
    else:
        exponent = exponent32int - 127
        exponent64 = "{0:0>11b}".format(exponent + 1023) 
    mantissa64 = mantissa32 + "".join("0" for i in range(1, 30))
    return sign + exponent64 + mantissa64

def signal32ToFloat64(value):
    return bin64StrToFloat64(bin32StrToBin64Str(toBin32Str(value)))

class vt_axi_tester:
	def __init__(self, dut):
		self.dut = dut;

		cocotb.start_soon(Clock(dut.clk_i, 10, units = "ns").start())

		self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk_i, dut.rst_i) 
        self.axis_monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk_i, dut.rst_i) 
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk_i, dut.rst_i)

	async def setSigForOneTact(self, signal, value):
		signal.value = value
		await ClockCycles(self.dut.clk_i, 1)

	async def reset(self):
		setSigForOneTact(self.dut.rst_i, 0)
		setSigForOneTact(self.dut.rst_i, 1)
		setSigForOneTact(self.dut.rst_i, 0)

	async def send(self, data):
		frame = AxiStreamFrame(IntToFrame(data), tuser = 1, tdest = 0)
		await self.axis_source.send(frame)
		print(i, "was sent")

	async def sendVertice(self, x, y, z, r, g, b, alpha):


	async def startReception(self):
		while True:
			frame = await self.axis_sink.read()
			print(FrameToInt(frame), "was received")



@cocotb.test()
async def testbech(dut):
	tester = vt_axi_tester(dut)
	await tester.reset()

	cocotb.start_soon(vt_axi_tester.startReception())
	await vt_axi_tester.send()
