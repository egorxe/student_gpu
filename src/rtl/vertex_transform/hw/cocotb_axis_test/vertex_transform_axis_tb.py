import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame

import struct
import numpy as np

#configuration
BYTES_PER_FRAME = 4

#constants
GPU_PIPE_CMD_POLY_VERTEX = int("FFFFFF00", 16)

#data structures
class Point:
	def __init__(self, x, y, z, r, g, b, alpha):
		self.x = x
		self.y = y
		self.z = z
		self.r = r
		self.g = g
		self.b = b
		self.alpha = alpha

class Polygon:
	def __init__(self, p1, p2, p3):
		self.p1 = p1
		self.p2 = p2
		self.p3 = p3

###conversion functions
#common
def toBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', num))

#pyFloat and int (actually double in C terms) to signal
def toSignal32(num):
    return int(toBin32Str(num), 2)

#signal to pyFloat (actually double in C terms)
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

def bin64StrToFloat64(value):
    hx = hex(int(value, 2))   
    return struct.unpack("d", struct.pack("q", int(hx, 16)))[0]

def signal32ToFloat64(value):
    return bin64StrToFloat64(bin32StrToBin64Str(toBin32Str(value)))

#for AXI-Stream
def intToBytes(i):
    return (i).to_bytes(BYTES_PER_FRAME, byteorder='little')

def bytesToInt(f):
    return int.from_bytes(f, byteorder='little', signed=False)

#tester class
class Vt_axi_tester:
	def __init__(self, dut):
		self.dut = dut;

		cocotb.start_soon(Clock(dut.clk_i, 10, units = "ns").start())

		self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk_i, dut.rst_i)
		self.axis_monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk_i, dut.rst_i)
		self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk_i, dut.rst_i)

	async def setSigForOneTact(self, signal, value):
		signal.value = value
		await RisingEdge(self.dut.clk_i)

	async def reset(self):
		await RisingEdge(self.dut.clk_i)
		await self.setSigForOneTact(self.dut.rst_i, 1)
		await self.setSigForOneTact(self.dut.rst_i, 0)
		print("Module was reseted")

	async def sendInt(self, data):
		frame = AxiStreamFrame(intToBytes(data), tuser = 0, tdest = 0)
		await self.axis_source.send(frame)
		print(intToBytes(data), data, "was sent")

	async def sendFloat(self, data):
		await self.sendInt(toSignal32(data))

	async def sendVertice(self, point):
		await self.sendFloat(point.x)
		await self.sendFloat(point.y)
		await self.sendFloat(point.z)
		await self.sendFloat(point.r)
		await self.sendFloat(point.g)
		await self.sendFloat(point.b)
		await self.sendFloat(point.alpha)

	async def sendPolygon(self, polygon):
		await self.sendInt(GPU_PIPE_CMD_POLY_VERTEX)
		await self.sendVertice(polygon.p1)
		await self.sendVertice(polygon.p2)
		await self.sendVertice(polygon.p3)

	async def startReception(self):
		while True:
			frame = await self.axis_sink.read()
			print(frame, bytesToInt(frame), "was received")

#testbench
@cocotb.test()
async def testbech(dut):
	tester = Vt_axi_tester(dut)
	point = Point(1, 1, 1, 2, 2, 2, 2)
	polygon = Polygon(point, point, point)

	await tester.reset()

	cocotb.start_soon(tester.startReception())
	
	await tester.sendPolygon(polygon)
