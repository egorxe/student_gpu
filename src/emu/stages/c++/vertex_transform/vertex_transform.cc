#include <cstdio> 
#include <cstdlib> 
#include <cstring>  
#include <unistd.h>  

#include <functional> 

#include <gpu_pipeline.hh> 
#include <pipeline_cmd.h> 

M4 model_matrix;
M4 proj_matrix;

// TGL function declarations
void gl_M4_MulV4(Vec4 a, M4* b, Vec4 c) ;
void gl_M4_MulLeft(M4* c, M4* b);
void glRotate(float angle, float x, float y, float z);

// Kind of viewport transformation
void ViewportTransform(Vec4 s, Vec3 &d, uint32_t size_x, uint32_t size_y)
{
    d[0] = (1 + s[0])/2. * (size_x-1);
    d[1] = (1 - s[1])/2. * (size_y-1);
    d[2] = (1 - s[2])/2.;
}

// Vertex to display coords
void ProcessVertex(const float *vert_ptr, Vec3 &vertex_out, uint32_t size_x, uint32_t size_y)
{
    Vec4 vertex_vec4 = {vert_ptr[0], vert_ptr[1], vert_ptr[2], 1};
    // multiply on model matrix
    gl_M4_MulV4(vertex_vec4, &model_matrix, vertex_vec4);
    // multiply on projection matrix
    gl_M4_MulV4(vertex_vec4, &proj_matrix, vertex_vec4);
    ViewportTransform(vertex_vec4, vertex_out, size_x, size_y);
}

void WriteVertexToFifo(IoFifo &iofifo, Vec3 &v, float *colors)
{
    iofifo.WriteToFifoFloat(v[0]);
    iofifo.WriteToFifoFloat(v[1]);
    iofifo.WriteToFifoFloat(v[2]);
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
    //glRotate(45, 1, 0, 0);
    
    while (1)
    {
        uint32_t cmd = iofifo.ReadFromFifo32();
        if (cmd != GPU_PIPELINE_POLY_VERTEX)
		{
			// just pass to next stage everything but polygon vertices
			iofifo.WriteToFifo32(cmd);
            iofifo.Flush();
            // ! rotate 1 degree on each frame for test !
			glRotate(1, 1, 1, 1);
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
        Vec3 v0, v1, v2;
        ProcessVertex(vertices, v0, SCREEN_WIDTH, SCREEN_HEIGHT);
        ProcessVertex(vertices+3, v1, SCREEN_WIDTH, SCREEN_HEIGHT);
        ProcessVertex(vertices+6, v2, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        // Pass resulting vertices to next stage
        iofifo.WriteToFifo32(GPU_PIPELINE_POLY_VERTEX);
        WriteVertexToFifo(iofifo, v0, &colors[0]);
        WriteVertexToFifo(iofifo, v1, &colors[4]);
        WriteVertexToFifo(iofifo, v2, &colors[8]);
    }
 
    return 0; 
} 
