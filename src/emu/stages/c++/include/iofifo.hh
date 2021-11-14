#ifndef _IOFIFO_HH
#define _IOFIFO_HH

#include <string> 
#include <iostream> 
#include <fstream> 
#include <cassert> 
#include <cstdlib> 
#include <cstdint> 
#include <errno.h> 

#include "pipeline_cmd.h"

class IoFifo
{
    std::ofstream out_fifo;
    std::ifstream in_fifo;
    
    public:
    
    // ######################## Initialization ########################
    
    IoFifo(std::string ififo_name, std::string ofifo_name)
    {
        
        in_fifo.open(ififo_name.c_str());
        
        if (!ofifo_name.empty())
        {
            out_fifo.open(ofifo_name.c_str());
            if (!out_fifo.is_open())
            {
                std::cerr << "Failed to open output file " << ififo_name << std::endl;
                exit(ENFILE);
            }
        }
        
        if (!ififo_name.empty())
        {
            if (!in_fifo.is_open())
            {
                std::cerr << "Failed to open input file " << ififo_name << std::endl;
                exit(ENFILE);
            }
        }
    }
    
    // ######################## Basic ops ########################
    
    // Write 32-bit word to output FIFO
    void WriteToFifo32(uint32_t x)
    {
        out_fifo.write((char*)&x, sizeof(x));
    }
    
    // Write 32-bit word to output FIFO
    void WriteToFifoFloat(float x)
    {
        out_fifo.write((char*)&x, sizeof(x));
    }
    
    // Read 32-bit word from input FIFO
    uint32_t ReadFromFifo32()
    {
        uint32_t x;
        in_fifo.read((char*)&x, sizeof(x));
        return x;
    }
    
    // Read float from input FIFO
    float ReadFromFifoFloat()
    {
        float x;
        in_fifo.read((char*)&x, sizeof(x));
        return x;
    }
    
    // Force finish all FIFO writes from buffer
    void Flush()
    {
        out_fifo.flush();
    }
    
    
    // ######################## Complex ops ########################
    
    // Write fragment from rasterizer
    void WriteFragment(uint32_t x, uint32_t y, uint32_t z, float r, float g, float b)
    {
        WriteToFifo32(GPU_PIPE_CMD_FRAGMENT); 
        WriteToFifo32(x); 
        WriteToFifo32(y); 
        WriteToFifo32(z); 
        WriteToFifo32(((uint32_t)(r * 255) << 16) | ((uint32_t)(g * 255) << 8) | (uint32_t)(b * 255)); 
    }
    
    // Read fragment into fragment ops
    void ReadFragment(uint32_t fragment[])
    {
        fragment[0] = ReadFromFifo32();     // x
        fragment[1] = ReadFromFifo32();     // y
        fragment[2] = ReadFromFifo32();     // z
        fragment[3] = ReadFromFifo32();     // 32-bit Color
    }
    
    
};

#endif
