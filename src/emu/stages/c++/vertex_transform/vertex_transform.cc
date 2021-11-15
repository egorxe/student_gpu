#include <cstdio> 
#include <cstdlib> 
#include <cstring>  
#include <unistd.h>  

#include <functional> 

#include <gpu_pipeline.hh> 
#include <pipeline_cmd.h> 

#define PERSPECTIVE_CORRECT     0

M4 model_matrix;
M4 proj_matrix;

// TGL function declarations
void gl_M4_MulV4(Vec4 a, M4* b, Vec4 c) ;
void gl_M4_MulLeft(M4* c, M4* b);
void glRotate(float angle, float x, float y, float z);

// Kind of viewport transformation
void ViewportTransform(Vec4 s, Vec4 &d, uint32_t size_x, uint32_t size_y)
{
    d[0] = (1 + s[0])/2. * (size_x-1);
    d[1] = (1 + s[1])/2. * (size_y-1);
    d[2] = (1 + s[2])/2.;
    d[3] = s[3];    // we will need w clip coord during rasterization for perspective correct vertex attribute (color) calculations
}
// Vertex to display coords
void ProcessVertex(const float *vert_ptr, Vec4 &vertex_out, uint32_t size_x, uint32_t size_y)
{
    Vec4 vertex_vec4 = {vert_ptr[0], vert_ptr[1], vert_ptr[2], 1};
    // multiply on model matrix
    gl_M4_MulV4(vertex_vec4, &model_matrix, vertex_vec4);
    // multiply on projection matrix
    gl_M4_MulV4(vertex_vec4, &proj_matrix, vertex_vec4);
    
    // ###TODO: clipping should be done here
    
    #if PERSPECTIVE_CORRECT
    // normalize coordinates (produce NDC)
    vertex_vec4[0] = vertex_vec4[0]/vertex_vec4[3];
    vertex_vec4[1] = vertex_vec4[1]/vertex_vec4[3];
    vertex_vec4[2] = vertex_vec4[2]/vertex_vec4[3];
    #endif
    ViewportTransform(vertex_vec4, vertex_out, size_x, size_y);
}

void WriteVertexToFifo(IoFifo &iofifo, Vec4 &v, float *colors)
{
    iofifo.WriteToFifoFloat(v[0]);
    iofifo.WriteToFifoFloat(v[1]);
    iofifo.WriteToFifoFloat(v[2]);
    iofifo.WriteToFifoFloat(v[3]);
    for (int i = 0; i < 4; ++i)
        iofifo.WriteToFifoFloat(colors[i]);
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
    
    // Create matrixes
    #if PERSPECTIVE_CORRECT
    // position on coordinate 3 on Z axis
    model_matrix = {{
        {1,         0,          0,          0           },
        {0,         1,          0,          0           },
        {0,         0,          1,          -3.0        },  
        {0,         0,          0,          1           },
    }};
    // perspective projection from gluPerspective(45, 4./3., 0.1, 10);
    proj_matrix = {{
        {1.810660,  0,          0,          0           },
        {0,         2.414214,   0,          0           },
        {0,         0,          -1.020202,  -0.202020   },
        {0,         0,          -1.000000,  0           },
    }};
    #else
    model_matrix = {{
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1},
    }};
    
    proj_matrix = {{
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1},
    }};
    #endif
    
    // !static rotate on 45 degrees for test!
    //glRotate(45, 1, 1, 1);
    
    while (1)
    {
        uint32_t cmd = iofifo.ReadFromFifo32();
        if (cmd != GPU_PIPE_CMD_POLY_VERTEX)
        {
            // just pass to next stage everything but polygon vertices
            iofifo.WriteToFifo32(cmd);
            iofifo.Flush();
            // ! rotate 2 degrees on each frame for test !
            glRotate(2, 1, 1, 1);
            continue;
        }
        
        // Read input vertices & colors
        float vertices[3*3];
        float colors[3*4];
        
        // three vertices per polygon
        for (int vertex = 0; vertex < 3; ++vertex)
        {
            // three coords per vertex
            for (int i = 0; i < 3; ++i)
            {
                vertices[vertex*3+i] = iofifo.ReadFromFifoFloat();
            }
            // four color floats per vertex
            for (int i = 0; i < 4; ++i)
                colors[vertex*4+i] = iofifo.ReadFromFifoFloat();
        }
        
        // Process polygon vertices
        Vec4 v0, v1, v2;
        ProcessVertex(vertices, v0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ProcessVertex(vertices+3, v1, SCREEN_WIDTH, SCREEN_HEIGHT);
        ProcessVertex(vertices+6, v2, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        // Pass resulting vertices to next stage
        iofifo.WriteToFifo32(GPU_PIPE_CMD_POLY_VERTEX);
        WriteVertexToFifo(iofifo, v0, &colors[0]);
        WriteVertexToFifo(iofifo, v1, &colors[4]);
        WriteVertexToFifo(iofifo, v2, &colors[8]);
    }
 
    return 0; 
} 
