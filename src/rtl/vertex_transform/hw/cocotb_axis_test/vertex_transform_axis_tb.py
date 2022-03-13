import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame

import struct
import numpy as np

#configuration
BYTES_PER_WORD = 4

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
def floatToBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', num))

def intToBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!l', num))

#pyFloat and int (actually double in C terms) to signal
def floatToSignal32(num):
    return int(floatToBin32Str(num), 2)

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
    return bin64StrToFloat64(bin32StrToBin64Str(floatToBin32Str(value)))

#for AXI-Stream
def intToBytes(i):
    return (i).to_bytes(BYTES_PER_WORD, byteorder='little')

def bytesToInt(f):
    return int.from_bytes(f, byteorder='little', signed=False)

#for human reading
def intToBytesBigEndian(i):
    return (i).to_bytes(BYTES_PER_WORD, byteorder='big')

def bytesToIntBigEndian(f):
    return int.from_bytes(f, byteorder='big', signed=False)

#tester class
class Vt_axi_tester:
	def __init__(self, dut):
		self.dut = dut;
		self.received_frames = 0
		self.received_words = 0
		self.sent_data = []
		self.received_data = [] 

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

	async def sendSignal32(self, data):
		frame = AxiStreamFrame(intToBytes(data), tuser = 0, tdest = 0)
		self.sent_data.append(data)
		await self.axis_source.send(frame)
		print(intToBytes(data), "was sent")

	async def sendFloat(self, data):
		await self.sendSignal32(floatToSignal32(data))

	async def sendVertice(self, point):
		await self.sendFloat(point.x)
		await self.sendFloat(point.y)
		await self.sendFloat(point.z)
		await self.sendFloat(point.r)
		await self.sendFloat(point.g)
		await self.sendFloat(point.b)
		await self.sendFloat(point.alpha)
		print("Point was sent")

	async def sendPolygon(self, polygon):
		await self.sendSignal32(GPU_PIPE_CMD_POLY_VERTEX)
		await self.sendVertice(polygon.p1)
		await self.sendVertice(polygon.p2)
		await self.sendVertice(polygon.p3)
		print("Polygon was sent")

	async def startReception(self):
		while True:
			frame = await self.axis_sink.read()
			wordAsRevStr = ""
			byte_num = 0
			
			for byte in frame:
				wordAsRevStr += (intToBin32Str(byte))[24:32]
				print(intToBin32Str(byte))
				byte_num += 1

				if (byte_num % BYTES_PER_WORD == 0):
					wordAsStr = wordAsRevStr[::-1]
					word = int(wordAsStr, 2)
					self.received_words += 1
					self.received_data.append(word)
					print(wordAsStr, "was received,", self.received_words, "words were received at all")
					wordAsRevStr = ""

			self.received_frames += 1
			print(frame, "was received,", self.received_frames, "frames were received at all")

	async def checkReception(self):
		while self.received_frames < 4:
			await RisingEdge(self.dut.clk_i)

		for i in range(len(self.received_data)):
			#passing weight of verice
			if (i == 4 or i == 12 or i == 20):
				print("Checking word", i, "Got", hex(self.received_data[i]))

			elif (i < 4):
				print("Checking word", i, "Got", hex(self.received_data[i]), "Should be", hex(self.sent_data[i]))
				#assert(self.received_data[i] == self.sent_data[i])

			elif (i < 12):
				print("Checking word", i, "Got", hex(self.received_data[i]), "Should be", hex(self.sent_data[i - 1]))
				#assert(self.received_data[i] == self.sent_data[i - 1])

			elif (i < 20):
				print("Checking word", i, "Got", hex(self.received_data[i]), "Should be", hex(self.sent_data[i - 2]))
				#assert(self.received_data[i] == self.sent_data[i - 2])

			else:
				print("Checking word", i, "Got", hex(self.received_data[i]), "Should be", hex(self.sent_data[i - 3]))
				#assert(self.received_data[i] == self.sent_data[i - 3])

#testbench
@cocotb.test()
async def testbech(dut):
	tester = Vt_axi_tester(dut)
	point = Point(1, 1, 1, 2, 2, 2, 2)
	polygon = Polygon(point, point, point)

	await tester.reset()

	cocotb.start_soon(tester.startReception())
	
	await tester.sendPolygon(polygon)

	await tester.checkReception();
