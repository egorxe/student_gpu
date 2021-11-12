#include <cstdio> 
#include <cstdlib> 
#include <cstring>  
#include <unistd.h>  

#include <functional> 

#include <gpu_pipeline.hh> 

#define PERSPECTIVE_CORRECT     0

float edgeFunction(const Vec4 &a, const Vec4 &b, const Vec4 &c) 
{ 
    return (c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0]); 
} 

int32_t MinCoord(float x0, float x1, float x2, int32_t lo, int32_t hi)
{
    int32_t min = std::min(std::min(x0, x1), x2);
    if (min > hi)
        return -1;
    else
        return std::max(min, lo);
} 

int32_t MaxCoord(float x0, float x1, float x2, int32_t lo, int32_t hi)
{
    int32_t max = std::max(std::max(x0, x1), x2);
    if (max < lo)
        return -1;
    else
        return std::min(max, hi);
} 

int main(int argc, char **argv) 
{
    if (argc != 5)
    {
        puts("Wrong parameters!");
        return 1;
    }
    
    const uint32_t SCREEN_WIDTH     = atoi(argv[1]); 
    const uint32_t SCREEN_HEIGHT    = atoi(argv[2]);
        
    // Open output FIFO
    IoFifo iofifo(argv[3], argv[4]);
    
    while (1)
    {
        uint32_t cmd = iofifo.ReadFromFifo32();
        if (cmd != GPU_PIPELINE_POLY_VERTEX)
		{
			// just pass to next stage everything but polygon vertices
			iofifo.WriteToFifo32(cmd);
            iofifo.WriteToFifo32(0);
            iofifo.Flush();
			continue;
		}
        
        // Read input vertices & colors
        float vertices[3*4];
        float colors[3*4];
        
        // three vertices per polygon
        for (int vertex = 0; vertex < 3; ++vertex)
        {
            // four coords per vertex
            for (int i = 0; i < 4; ++i)
                vertices[vertex*4+i] = iofifo.ReadFromFifoFloat();
            
            // four color floats per vertex
            for (int i = 0; i < 4; ++i)
                colors[vertex*4+i] = iofifo.ReadFromFifoFloat();
        }

        // Polygon vertices
        Vec4 v0, v1, v2;
        for (int i = 0; i < 4; ++i)
            v0[i] = vertices[0+i];
        for (int i = 0; i < 4; ++i)
            v1[i] = vertices[4+i];
        for (int i = 0; i < 4; ++i)
            v2[i] = vertices[8+i];
        
        float area_inv = 1. / edgeFunction(v0, v1, v2); 
        bool back_face = false;
        
        if (area_inv < 0)
        {
            // back face
            back_face = true;
        }
        
        // Calculate bounding box (min & max coords for triangle vertexes), if -1 - triangle is out of screen
        int32_t xmin = MinCoord(v0[0], v1[0], v2[0], 0, SCREEN_WIDTH);
        int32_t ymin = MinCoord(v0[1], v1[1], v2[1], 0, SCREEN_HEIGHT);
        int32_t xmax = MaxCoord(v0[0], v1[0], v2[0], 0, SCREEN_WIDTH);
        int32_t ymax = MaxCoord(v0[1], v1[1], v2[1], 0, SCREEN_HEIGHT);
        
        if (xmin < 0 || ymin < 0 || xmax < 0 || ymax < 0) continue; // skip out-of-screen triangles
        
        // Create colors 
        #if PERSPECTIVE_CORRECT
        //precompute reciprocal of vertex w clip coordinate
        v0[3] = 1./v0[3];
        v1[3] = 1./v1[3];
        v2[3] = 1./v2[3];
        
        // divide colors on w coord in advance
        Vec3 c0 = {colors[0]*v0[3], colors[1]*v0[3], colors[2]*v0[3]}; 
        Vec3 c1 = {colors[4]*v1[3], colors[5]*v1[3], colors[6]*v1[3]}; 
        Vec3 c2 = {colors[8]*v2[3], colors[9]*v2[3], colors[10]*v2[3]};
        #else
        Vec3 c0 = {colors[0], colors[1], colors[2]}; 
        Vec3 c1 = {colors[4], colors[5], colors[6]}; 
        Vec3 c2 = {colors[8], colors[9], colors[10]};
        #endif
        
        for (uint32_t x = xmin; x < xmax; ++x) 
        { 
            for (uint32_t y = ymin; y < ymax; ++y) 
            { 
                Vec4 p = {x + 0.5f, y + 0.5f, 0, 0}; 
                float w0 = edgeFunction(v1, v2, p); 
                float w1 = edgeFunction(v2, v0, p); 
                float w2 = edgeFunction(v0, v1, p); 
                
                if (((w0 >= 0 && w1 >= 0 && w2 >= 0) && !back_face) ||
                   ((w0 <= 0 && w1 <= 0 && w2 <= 0) && back_face))
                {
                    w0 *= area_inv; 
                    w1 *= area_inv; 
                    w2 *= area_inv; 
                    
                    uint32_t z = (uint32_t)((v0[2] * w0 + v1[2] * w1 + v2[2] * w2) * PIPELINE_MAX_Z);

                    // calculate pixel color
                    #if PERSPECTIVE_CORRECT
                    float wn = w0*v0[3] + w1*v1[3] + w2*v2[3];
                    
                    float r = (w0 * c0[0] + w1 * c1[0] + w2 * c2[0]) / wn; 
                    float g = (w0 * c0[1] + w1 * c1[1] + w2 * c2[1]) / wn; 
                    float b = (w0 * c0[2] + w1 * c1[2] + w2 * c2[2]) / wn;
                    #else
                    float r = w0 * c0[0] + w1 * c1[0] + w2 * c2[0]; 
                    float g = w0 * c0[1] + w1 * c1[1] + w2 * c2[1]; 
                    float b = w0 * c0[2] + w1 * c1[2] + w2 * c2[2];
                    #endif

                    iofifo.WriteFragment(x, y, z, r, g, b); 
                } 
            } 
        } 
    }
 
    return 0; 
} 
