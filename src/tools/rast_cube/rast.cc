#include <cstdio> 
#include <cstdlib> 
#include <cstring>  
#include <fstream> 

#include <functional> 

#include "rast.hh"
#include "model.h"

M4 cur_matrix;

const uint32_t SCREEN_WIDTH     = 512; 
const uint32_t SCREEN_HEIGHT    = 512; 

// Kind of viewport transformation
void ToRasterCoords(Vec4 s, Vec2 &d)
{
    d[0] = (s[0] + 1)/2. * (SCREEN_WIDTH-1);
    d[1] = (1 - s[1])/2. * (SCREEN_HEIGHT-1);
}

// Vertex to display coords
void ProcessVertex(const GLfloat *vert_ptr, Vec2 &vertex_out)
{
    Vec4 vertex_vec4 = {vert_ptr[0], vert_ptr[1], vert_ptr[2], 1};
    gl_M4_MulV4(vertex_vec4, &cur_matrix, vertex_vec4);
    //gl_M4_MulV4(vertex_vec4, &cur_matrix, vertex_vec4);
    ToRasterCoords(vertex_vec4, vertex_out);
}

float edgeFunction(const Vec2 &a, const Vec2 &b, const Vec2 &c) 
{ 
    return (c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0]); 
} 

int32_t MinCoord(GLfloat x0, GLfloat x1, GLfloat x2, int32_t lo, int32_t hi)
{
    int32_t min = std::min(std::min(x0, x1), x2);
    if (min > hi)
        return -1;
    else
        return std::max(min, lo);
} 

int32_t MaxCoord(GLfloat x0, GLfloat x1, GLfloat x2, int32_t lo, int32_t hi)
{
    int32_t max = std::max(std::max(x0, x1), x2);
    if (max < lo)
        return -1;
    else
        return std::min(max, hi);
} 
 
int main(int argc, char **argv) 
{ 
    // Create framebuffer
    Rgb *framebuffer = new Rgb[SCREEN_WIDTH * SCREEN_HEIGHT]; 
    memset(framebuffer, 0x0, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(Rgb)); 
    
    // Create rotation matrix
    cur_matrix = {{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}};
    
    glRotate(45, 1, 1, 1);
    
    // Vertex cycle
    for (int vertex = 0; vertex < nvertices; vertex += 3)
    {
        Vec2 v0, v1, v2;
        ProcessVertex(vertices + vertex*3, v0);
        ProcessVertex(vertices + vertex*3+3, v1);
        ProcessVertex(vertices + vertex*3+6, v2);
        
        // Create colors
        Vec3 c0 = {colors[vertex*4 + 0], colors[vertex*4 + 1], colors[vertex*4 + 2]}; 
        Vec3 c1 = {colors[vertex*4 + 4], colors[vertex*4 + 5], colors[vertex*4 + 6]}; 
        Vec3 c2 = {colors[vertex*4 + 8], colors[vertex*4 + 9], colors[vertex*4 + 10]};
        
        float area_inv = 1. / edgeFunction(v2, v1, v0); 
        bool back_face = false;
        
        if (area_inv < 0)
        {
            // back face
            back_face = true;
            // ?may be needed to flip vertex colors?
            #if 0
            c2[0] = colors[vertex*4 + 0]; c2[1] = colors[vertex*4 + 1]; c2[2] = colors[vertex*4 + 2]; 
            c0[0] = colors[vertex*4 + 8]; c0[1] = colors[vertex*4 + 9]; c0[2] = colors[vertex*4 + 10];
            #endif
        }
        
        // Calculate bounding box (min & max coords for triangle vertexes), if -1 - triangle is out of screen
        int32_t xmin = MinCoord(v0[0], v1[0], v2[0], 0, SCREEN_WIDTH);
        int32_t ymin = MinCoord(v0[1], v1[1], v2[1], 0, SCREEN_HEIGHT);
        int32_t xmax = MaxCoord(v0[0], v1[0], v2[0], 0, SCREEN_WIDTH);
        int32_t ymax = MaxCoord(v0[1], v1[1], v2[1], 0, SCREEN_HEIGHT);
        
        if (xmin < 0 || ymin < 0 || xmax < 0 || ymax < 0) continue; // skip out-of-screen triangles
        
        for (uint32_t x = xmin; x < xmax; ++x) 
        { 
            for (uint32_t y = ymin; y < ymax; ++y) 
            { 
                Vec2 p = {x + 0.5f, y + 0.5f}; 
                float w0 = edgeFunction(v1, v0, p); 
                float w1 = edgeFunction(v0, v2, p); 
                float w2 = edgeFunction(v2, v1, p); 
                
                if (((w0 >= 0 && w1 >= 0 && w2 >= 0) && !back_face) ||
                   ((w0 <= 0 && w1 <= 0 && w2 <= 0) && back_face))
                { 
                    w0 *= area_inv; 
                    w1 *= area_inv; 
                    w2 *= area_inv; 
                    float r = w0 * c0[0] + w1 * c1[0] + w2 * c2[0]; 
                    float g = w0 * c0[1] + w1 * c1[1] + w2 * c2[1]; 
                    float b = w0 * c0[2] + w1 * c1[2] + w2 * c2[2]; 
                    framebuffer[y * SCREEN_WIDTH + x][0] = (unsigned char)(r * 255); 
                    framebuffer[y * SCREEN_WIDTH + x][1] = (unsigned char)(g * 255); 
                    framebuffer[y * SCREEN_WIDTH + x][2] = (unsigned char)(b * 255); 
                } 
            } 
        } 
    }
 
    std::ofstream ofs; 
    ofs.open("./raster2d.ppm"); 
    ofs << "P6\n" << SCREEN_WIDTH << " " << SCREEN_HEIGHT << "\n255\n"; 
    ofs.write((char*)framebuffer, SCREEN_WIDTH * SCREEN_HEIGHT * 3); 
    ofs.close(); 
 
    delete [] framebuffer; 
 
    return 0; 
} 
