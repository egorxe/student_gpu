#include <cstdio> 
#include <cstdint> 
#include <cstdlib> 

#include <gpu_pipeline.hh> 

#define DRAW_DEPTH_BUF  0

int main(int argc, char **argv) 
{
    if (argc != 5)
    {
        puts("Wrong parameters!");
        return 1;
    }
    
    const uint32_t SCREEN_WIDTH     = atoi(argv[1]); 
    const uint32_t SCREEN_HEIGHT    = atoi(argv[2]);
    
    // Fill depth buffer with some large vals
    uint32_t depthBuffer[SCREEN_WIDTH*SCREEN_HEIGHT];
    for (int i = 0; i < SCREEN_WIDTH; ++i)
        for (int j = 0; j < SCREEN_HEIGHT; ++j)
            depthBuffer[i*SCREEN_HEIGHT + j] = PIPELINE_MAX_Z;
        
    // Open input & output FIFOs
    IoFifo iofifo(argv[3], argv[4]);
    
    while (1)
    {
        uint32_t cmd = iofifo.ReadFromFifo32();
        if (cmd != GPU_PIPELINE_FRAGMENT)
		{
            #if DRAW_DEPTH_BUF
            for (uint32_t x = 0; x < SCREEN_WIDTH; ++x) 
            { 
                for (uint32_t y = 0; y < SCREEN_HEIGHT; ++y) 
                { 
                    iofifo.WriteToFifo32((uint32_t)x | ((uint32_t)y) << 16); 
                    iofifo.WriteToFifo32(((uint32_t)((PIPELINE_MAX_Z-depthBuffer[x*SCREEN_HEIGHT+y]) * 255. / PIPELINE_MAX_Z) << 16)); 
                }
            }
            #endif
            
			// just pass to next stage everything but fragment ops
			iofifo.WriteToFifo32(cmd);
            iofifo.WriteToFifo32(0);
            iofifo.Flush();
            
            // fill depth buffer with some large vals on new frame
            for (int i = 0; i < SCREEN_WIDTH; ++i)
                for (int j = 0; j < SCREEN_HEIGHT; ++j)
                    depthBuffer[i*SCREEN_HEIGHT + j] = PIPELINE_MAX_Z;
			continue;
		}
        
        // Read input fragments
        uint32_t fragment[4];
        iofifo.ReadFragment(fragment);
        
        uint32_t x = fragment[0];
        uint32_t y = fragment[1];
        uint32_t z = fragment[2];
        
        // Depth buffer test
        if (fragment[2] >= depthBuffer[fragment[0] * SCREEN_HEIGHT + fragment[1]]) 
            continue;
        depthBuffer[fragment[0] * SCREEN_HEIGHT + fragment[1]] = fragment[2]; 
        
        #if !DRAW_DEPTH_BUF
        iofifo.WriteToFifo32((uint32_t)x | ((uint32_t)y) << 16); 
        iofifo.WriteToFifo32(fragment[3]);  // color
        #endif
    }
 
    return 0; 
} 