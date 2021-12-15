import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge
from cocotb.binary import BinaryValue
from cocotb.result import TestFailure
from cocotb.result import TestSuccess
from pathlib import Path
import struct
import random as rand
import numpy as np
#import ctypes

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

async def sumOneTest(dut, opa, opb, testNum):
    clock = dut.clk_i
    await RisingEdge(clock);
    dut.opa_i.value = toSignal32(opa)
    dut.opb_i.value = toSignal32(opb)
    dut.fpu_op_i.value = int("000",2);
    dut.rmode_i.value = int("00",2);
    await RisingEdge(clock)
    dut.start_i.value = 1
    await RisingEdge(clock)
    dut.start_i.value = 0
    await RisingEdge(dut.ready_o)
    if dut.output_o.value == toSignal32(np.float32(opa) + np.float32(opb)):
        return 1
    else:
        print("Fail at test %i: \n%s + \n%s = \n%s(py), \n%s(vhd)" % \
             (testNum, toBin32Str(opa), toBin32Str(opb), toBin32Str(np.float32(opa) + np.float32(opb)), toBin32Str(dut.output_o.value)) \
             )
        print("Fail at test %i: %f + \n%f = \n%f(py), \n%f(vhd)" % \
             (testNum, opa, opb, np.float32(opa) + np.float32(opb), signal32ToFloat64(dut.output_o.value)) \
             )
        return 0

async def sumTest(dut, testsAmount):
    rand.seed()
    magnitude = 1.0e+37
    passed = 0
    for i in range(0, testsAmount):
        passed += await sumOneTest(dut, (rand.random()*2 - 1)*magnitude, (rand.random()*2 - 1)*magnitude, i)
    assert passed == testsAmount, "Fail: passed %i/%i tests" % (passed, testsAmount)

@cocotb.test()
async def fpu_test(dut):
    dut.start_i.value = 0
    cocotb.start_soon(Clock(dut.clk_i, 10, "ns").start())
    await sumTest(dut, 100)
        
# class FpuTester:

#     def __init__(self,fpu_entity):
#         self.dut = fpu_entity
#         self.clk = self.dut.clk_i
#         self.opa = self.dut.opa_i
#         self.opb = self.dut.opb_i
#         self.start = self.dut.start_i
#         self.rmode = self.dut.rmode_i
#         self.fpu_op = self.dut.fpu_op_i
#         self.ready = self.dut.ready_o
#         self.output = self.dut.output_o
#         self.testcases_path = Path('testcases.txt')
#         self.test_cases=[]
#         self.boundary_tests()
#         self.read_tests()
#         self.boundary_cases=[]

#     def boundary_tests(self):
#         self.test_cases.append({
#             'opa': int( "01111111011111111111111111111111",2),
#             'opb': int( "01111111011111111111111111111111",2),
#             'fpu_op':int("000",2),
#             'rmode':int("00",2),
#             'slv_out': int("01111111100000000000000000000000",2)
#             })
#         self.test_cases.append({
#             'opa': int( "00000000100100000000000000000000",2),
#             'opb': int( "10000000100000000000000000000000",2),
#             'fpu_op':int("000",2),
#             'rmode':int("00",2),
#             'slv_out': int("00000000000100000000000000000000",2)
#             })

#         self.test_cases.append({
#             'opa': int( "00000001000010000000000000000000",2),
#             'opb': int( "10000001000000000000000000000000",2),
#             'fpu_op':int("000",2),
#             'rmode':int("00",2),
#             'slv_out': int("00000000000100000000000000000000",2)
#             })
#         self.test_cases.append({
#             'opa': int( "10000000000000000000000000000000",2),
#             'opb': int( "10000000000000000000000000000000",2),
#             'fpu_op':int("000",2),
#             'rmode':int("00",2),
#             'slv_out': int("10000000000000000000000000000000",2)
#             })
#         self.test_cases.append({
#             'opa': int( "00000000000000000000000000000000",2),
#             'opb': int( "01000010001000001000000000100000",2),
#             'fpu_op':int("000",2),
#             'rmode':int("00",2),
#             'slv_out': int("01000010001000001000000000100000",2)
#             })

#     def read_tests(self):
#         with self.testcases_path.open('r') as tc:
#             line = tc.readline()
#             while line:
#                 if len(line) > 1:
#                     self.test_cases.append({'opa': int('0x' + line,16),
#                                       'opb':int('0x' + tc.readline().strip(), 16),
#                                       'fpu_op': int(tc.readline().strip(), 2),
#                                       'rmode': int(tc.readline().strip(),2),
#                                       'slv_out': int('0x' + tc.readline().strip(),16)})
#                 line = tc.readline()
#         print(self.test_cases[0])
#         print(self.test_cases[1])

#     def test_case(self,case):
#         self.opa.value = case['opa']
#         self.opb.value = case['opb']
#         self.fpu_op.value = case['fpu_op']
#         self.rmode.value = case['rmode']
#         return case['slv_out']

#     def read_out(self):
#         return self.output.value

# @cocotb.test()
# async def fpu_test(dut):
#     clock = dut.clk_i
#     ready = dut.ready_o
#     cocotb.fork(Clock(clock, 10, units="ns").start())
#     await RisingEdge(clock)
#     tester = FpuTester(dut)
#     dut._log.info("Run test")
#     dut.start_i.value = 0
#     await RisingEdge(clock)
#     test_num=0
#     for test in tester.test_cases:
#         dut.start_i.value = 1
#         check = tester.test_case(test)
#         await RisingEdge(clock)
#         dut.start_i.value = 0
#         test_num += 1
#         while True:
#             await RisingEdge(clock)
#             if dut.ready_o.value.binstr == '1':
#                 break
#         result = tester.read_out()
#         dut._log.info(f'test {test_num}: {hex(result)} == {hex(check)}')
#         assert check == result

