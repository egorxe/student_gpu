#include <cstdio> 
#include <cstdlib> 
#include <unistd.h>  

#include <gpu_pipeline.hh> 

#include "model.h"

int main(int argc, char **argv) 
{
    if (argc != 5)
    {
        puts("Wrong parameters!");
        return 1;
    }

    // Open output FIFO
    IoFifo iofifo(argv[3], argv[4]);
   
    while (1)
    {
        // Vertex cycle
        for (int vertex = 0; vertex < nvertices; vertex += 1)
        {
            // Add command: polygon vertex
            if ((vertex % 3) == 0)
	            iofifo.WriteToFifo32(GPU_PIPELINE_POLY_VERTEX);
            
            // three coords per vertex
            for (int i = 0; i < 3; ++i)
            {
                iofifo.WriteToFifoFloat(vertices[vertex*3+i]);
            }
            
            // four color floats per vertex    
            for (int i = 0; i < 4; ++i)
                iofifo.WriteToFifoFloat(colors[vertex*4+i]);
        }
        
        // Add command: mark frame end
        iofifo.WriteToFifo32(GPU_PIPELINE_FRAME_END);
        iofifo.Flush();
    }
 
    return 0; 
} 
