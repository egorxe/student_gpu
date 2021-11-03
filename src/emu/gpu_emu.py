#! /usr/bin/env python3

import sys
import os
import json
import time
import signal
import traceback
from gpu_pipe import GpuPipeline

########### EXCEPTION HOOK ###########
def ExceptHook(type, value, tb):
    print(value)
    traceback.print_tb(tb)
    os.killpg(0, signal.SIGKILL)
    # prev_except_hook(type, value, tb)
    
################ MAIN ###############

JSON_CONFIG = "gpu_config.json"

# open config file
try:
    config = json.load(open(JSON_CONFIG, "r"))
except:
    print("Failed to read config file", JSON_CONFIG)
    sys.exit(1)

# do some dirty stuff to ensure all children are killed on exit or exception (Unix-specific!)
os.setpgrp()                        # create process group
prev_except_hook = sys.excepthook   # remember original exception hook
sys.excepthook = ExceptHook         # create  

# create & run GPU pipeline
gpu_pipe = GpuPipeline(config)
gpu_pipe.Run()

