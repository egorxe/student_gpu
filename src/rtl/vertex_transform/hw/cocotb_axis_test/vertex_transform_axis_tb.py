import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor, AxiStreamFrame

import struct
import numpy as np
import ctypes as ct
import random as rnd

#parameters
TESTS_AMOUNT = 3

#configuration
WRD_P_PLGN = 22
WRD_P_WPLGN = 25
WRD_P_VRTX = 7
WRD_P_WVRTX = 8
BYTES_PER_WORD = 4
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
def float32ToBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!f', num)) #empty bits equal 0, alignement to the right border, 8-bits width

def intToBin32Str(num):
    return ''.join('{:0>8b}'.format(c) for c in struct.pack('!i', num))

#pyFloat and int (actually double in C terms) to signal
def float32ToSignal32(num):
    return int(float32ToBin32Str(num), 2)

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
    return struct.unpack("d", struct.pack("q", int(value, 2)))[0] #packing as long long and unpacking as C-double

#signal - float32 as int
def signal32ToFloat64(value):
    return bin64StrToFloat64(bin32StrToBin64Str(intToBin32Str(value)))

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
		self.sent_data = [] #float as signal32
		self.received_data = [] #float as signal32
		self.sent_point = (ct.c_float * 3)() 
		self.processed_point = (ct.c_float * 4)()
		
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
		await self.sendSignal32(float32ToSignal32(data))

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
			wordAsStr = ""
			byte_num = 0
			
			for byte in frame:
				wordAsStr = (intToBin32Str(byte))[24:32] + wordAsStr #order matters
				print(intToBin32Str(byte)[24:32])
				byte_num += 1

				if (byte_num % BYTES_PER_WORD == 0):
					word = int(wordAsStr, 2)
					self.received_words += 1
					self.received_data.append(word)
					print(wordAsStr, hex(word), "was received,", self.received_words, "words were received at all")
					wordAsStr =  ""

			self.received_frames += 1
			print(frame, "was received,", self.received_frames, "frames were received at all,", self.received_frames//4, "polygons were received at all")

	async def checkReception(self):
		vertex_transform = ct.CDLL('../hw/cocotb_axis_test/vertex_transform_cube.so')
		process_vertex = vertex_transform.process_vertex
		process_vertex.argtypes= [ct.POINTER(ct.c_float), ct.POINTER(ct.c_float)]

		while self.received_words < TESTS_AMOUNT*WRD_P_WPLGN: #1 + 8*3
			await RisingEdge(self.dut.clk_i)

		#polygons checking 
		for polyCnt in range(TESTS_AMOUNT):
			print("Polygon", polyCnt)
			print("Start code expected", hex(GPU_PIPE_CMD_POLY_VERTEX), "received", hex(self.received_data[polyCnt*WRD_P_WPLGN]))
			assert self.received_data[polyCnt*WRD_P_WPLGN] == GPU_PIPE_CMD_POLY_VERTEX, "GPU_PIPE_CMD_POLY_VERTEX wasn't transmitted"

			#points checking
			for pointCnt in range(3):
				print("Point", pointCnt)
				for i in range(3):
					self.sent_point[i] = (ct.c_float)(signal32ToFloat64(self.sent_data[i + WRD_P_VRTX*pointCnt + 1 + WRD_P_PLGN*polyCnt]))
				
				#vertices processing in C code
				process_vertex(ct.cast(self.sent_point, ct.POINTER(ct.c_float)), 
								ct.cast(self.processed_point, ct.POINTER(ct.c_float)))
					
				#coordinates checking
				for i in range(4):
					print("coordinate", 
							i, 
							"got", 
							signal32ToFloat64(self.received_data[i + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt]),
							hex(self.received_data[i + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt]), 
							"expected", 
							self.processed_point[i],
							hex(float32ToSignal32(self.processed_point[i]))
							)
					assert self.received_data[i + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt] == \
							float32ToSignal32(self.processed_point[i]), \
							"Answers are different"

				#colors checking
				for i in range(4):
					print("color", 
							i,
							"got", 
							signal32ToFloat64(self.received_data[i + 4 + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt]),
							hex(self.received_data[i + 4 + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt]),
							"expected", 
							signal32ToFloat64(self.sent_data[i + 3 + WRD_P_VRTX*pointCnt + 1 + WRD_P_PLGN*polyCnt]),
							hex(self.sent_data[i + 3 + WRD_P_VRTX*pointCnt + 1 + WRD_P_PLGN*polyCnt]))
					assert self.received_data[i + 4 + WRD_P_WVRTX*pointCnt + 1 + WRD_P_WPLGN*polyCnt] == \
							self.sent_data[i + 3 + WRD_P_VRTX*pointCnt + 1 + WRD_P_PLGN*polyCnt], \
							"Answers are different"

				print("");

			print("Test of polygon number", polyCnt + 1, "from", TESTS_AMOUNT, "is complete\n")

def randPoint(magnitude):
	return Point((rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude, 
				(rnd.random()*2 - 1)*magnitude)

#testbench
@cocotb.test()
async def testbech(dut):
	rnd.seed()

	tester = Vt_axi_tester(dut)

	await tester.reset()

	cocotb.start_soon(tester.startReception())
	
	# points = []
	for i in range(TESTS_AMOUNT):
		# for j in range(3):
		# 	points.append(randPoint(10))
		# polygon = Polygon(points[0], points[1], points[2])

		point = Point(i, i, i, i, i, i, i)
		polygon = Polygon(point, point, point)
		await tester.sendPolygon(polygon)

		# points = []

	await tester.checkReception();
