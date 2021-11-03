import os
import numpy
from time import sleep
from threading import Thread

from gpu_display import GpuDisplay
from gpu_stage import GpuPipelineStage

class GpuPipeline():
    def __init__(self, config):
        # parse config
        self.config = config
        self.size_x = config["display_size_x"]
        self.size_y = config["display_size_y"]
        self.stage_num = len(config["stages"])

        # create stages
        self.stages = [None] * self.stage_num
        for s in range(self.stage_num):
            fifos = self.FifoNames(s)
            if s != 0:
                # no need to create first input fifo
                self.CreateFifo(fifos[0])
            self.CreateFifo(fifos[1])
            self.stages[s] = GpuPipelineStage(config, s, fifos)
            
        # create display & launch thread
        self.display = GpuDisplay(self.size_x, self.size_y)
        self.frame_count = 0
        self.display_finished = False
        self.global_finish = False
        self.display_thread = Thread(target = self.DisplayTickThread, daemon = False)
        self.display_thread.start()
        
        # open last stage FIFO for framebuffer
        self.fb_fifo = open(self.FifoNames(self.stage_num-1)[1], "rb")
    
    def FifoNames(self, stage):
        if stage == 0:
            fifo_in = self.config["input_file"]
        else:
            fifo_in = str(stage-1)+".fifo"
        return (fifo_in, str(stage)+".fifo")
        
    def CreateFifo(self, name):
        # remove old file if exists
        try:
            os.remove(name)
        except:
            pass
        os.mkfifo(name)
        
    def ReadFifo(self):
        bword = self.fb_fifo.read(8)
        return (int.from_bytes(bword[:2], "little"), int.from_bytes(bword[2:4], "little"), int.from_bytes(bword[4:8], "little"))
        
    def NextFrame(self):
        self.display.DrawFramebuffer()
        self.frame_count += 1
        print("Frame", self.frame_count)
        
    def Tick(self):
        try:
            words = self.ReadFifo()
            if words[0] >= 0xFF00:
                self.NextFrame()
                return False
        except:
            print("Failed to read FIFO!")
            return True
        
        self.display.PutPixel(words)

        return False
        
    def DisplayTickThread(self):
        finish = False
        while not (finish or self.global_finish):
            sleep(0.1)
            finish = self.display.Tick()
            for s in self.stages:
                # check that all stages are alive
                finish = finish or (not s.CheckAlive())
        self.display_finished = True
        
    def Run(self):
        finish = False
        while not finish:
            finish = self.Tick() or self.display_finished
            
        # cleanup
        self.global_finish = True
        for s in self.stages:
            s.Stop()
        sleep(0.2)
