import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame, AxiStreamMonitor

from cocotb.log import SimLog
from cocotb.triggers import Timer
from cocotb.utils import get_sim_steps, get_time_from_sim_steps, lazy_property

BYTES_PER_FRAME = 7
FRAMES_TO_TEST  = 1000

def IntToFrame(i):
    return (i).to_bytes(BYTES_PER_FRAME, byteorder='little')

def FrameToInt(f):
    return int.from_bytes(f, byteorder='little', signed=False)
        
class TB:
    def __init__(self, dut):
        self.dut = dut
        self.test_data = []
        self.recv_data = []

        cocotb.fork(Clock(dut.clk, 8, units="ns").start())
        
        self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.rst) 
        self.axis_mon = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.rst) 
        self.stream_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.rst) 
        
        self.recv_num = 0
        
    async def send_test_data(self):
        # Generate and send test data
        for i in range(FRAMES_TO_TEST):
            self.test_data.append(i)
            test_frame_axis = AxiStreamFrame(IntToFrame(self.test_data[i]), tuser=1,tdest=0)
            await self.axis_source.send(test_frame_axis) # Sending a frame
            print("Sent", i)
        
    async def recv_mon(self):
        # Monitor receiving stream data
        while True:
            stream_frame = await self.stream_sink.read()
            frame_int = FrameToInt(stream_frame)
            self.recv_data.append(frame_int)
            self.recv_num += 1
            print("Received", self.recv_num)
    
    async def test_fifo(self):
        # Wait for all frames to be received
        while self.recv_num != FRAMES_TO_TEST:
            await RisingEdge(self.dut.clk) 
        
        # Verify data
        for i in range(FRAMES_TO_TEST):
            print("Checking frame", i, "Got", hex(self.recv_data[i]), "Should be", hex(self.test_data[i]))
            assert(self.recv_data[i] == self.test_data[i])
        
        
    async def reset(self):
        # Reset process
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


@cocotb.test()
async def run_test(dut):

    tb = TB(dut)
        
    await tb.reset()
    
    # Launch receive monitor
    await cocotb.start(tb.recv_mon())
    
    # Launch send to fifo process
    await tb.send_test_data()
    
    # Check result
    await tb.test_fifo()
            

